const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const dotenv = require('dotenv');

dotenv.config({ path: 'root.env' });
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const CONFIGURED_USER_ID = process.env.SIMULATED_USER_ID;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error(
    'Missing required env vars. Expected SUPABASE_URL and SUPABASE_KEY.',
  );
  process.exit(1);
}

const runtimeKey = supabaseServiceRoleKey || supabaseKey;
const supabase = createClient(supabaseUrl, runtimeKey);
let ACTIVE_USER_ID = CONFIGURED_USER_ID || null;
const genAI = GEMINI_API_KEY ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;
const model = genAI
  ? genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      generationConfig: { responseMimeType: 'application/json' },
    })
  : null;

const AGENT_TYPES = [
  'Health Agent',
  'Scheduler Agent',
  'Routing Agent',
  'Community Agent',
  'Administrator Agent',
];

function normalizeAgentType(value) {
  const v = String(value ?? '').trim().toLowerCase();
  if (v === 'health' || v === 'health agent') return 'Health Agent';
  if (v === 'scheduler' || v === 'scheduler agent') return 'Scheduler Agent';
  if (v === 'routing' || v === 'routing agent') return 'Routing Agent';
  if (v === 'community' || v === 'community agent') return 'Community Agent';
  if (v === 'admin' || v === 'admin agent' || v === 'administrator agent') {
    return 'Administrator Agent';
  }
  return 'Administrator Agent';
}

function asCsv(value) {
  return Array.isArray(value) ? value.join(', ') : (value || 'None');
}

function safeNum(value) {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

function stripCodeFences(text) {
  const raw = String(text ?? '').trim();
  if (!raw) return '';
  const fenceMatch = raw.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  return (fenceMatch ? fenceMatch[1] : raw).trim();
}

function buildDeterministicInsights(profile, currentData) {
  const uv = safeNum(currentData?.uv_index) ?? 0;
  const pm = safeNum(currentData?.pm_level) ?? 0;
  const temp = safeNum(currentData?.temperature) ?? 0;
  const steps = safeNum(currentData?.step_count) ?? 0;
  const allergies = asCsv(profile?.allergies);
  const mobility = asCsv(profile?.mobility_needs);
  const earliestClass = profile?.earliest_class || '08:00';

  const insights = [];

  insights.push({
    agent_type: 'Health Agent',
    message:
      pm >= 80
        ? `PM is high at ${pm} with UV ${uv}. Because allergies are ${allergies}, use an indoor route now and wear a mask outdoors for short transitions.`
        : `UV is ${uv} and PM is ${pm}. Keep hydration up and take shaded paths, especially with allergies (${allergies}).`,
    is_warning: pm >= 80 || uv >= 8,
  });

  insights.push({
    agent_type: 'Routing Agent',
    message:
      pm >= 80
        ? `Air quality hotspot detected (PM ${pm}). Switch to an alternate low-traffic route with better ventilation and avoid congested roads.`
        : `Current route conditions are moderate (PM ${pm}, UV ${uv}). Prefer accessible pathways based on mobility needs (${mobility}).`,
    is_warning: pm >= 80,
  });

  insights.push({
    agent_type: 'Scheduler Agent',
    message:
      uv >= 8
        ? `UV is ${uv} before your earliest class at ${earliestClass}. Move outdoor tasks to later periods and keep indoor blocks now.`
        : `Temperature is ${temp}°C with ${steps} steps logged. Continue planned schedule and cluster nearby errands to reduce exposure.`,
    is_warning: uv >= 8,
  });

  insights.push({
    agent_type: 'Community Agent',
    message:
      pm >= 80
        ? `Community safety update: PM is ${pm} and UV is ${uv}. Encourage peers in your faculty (${profile?.faculty || 'General'}) to use indoor connectors and postpone outdoor gatherings.`
        : `Community status is stable (PM ${pm}, UV ${uv}). Promote eco-walk checkpoints and low-emission paths for your group (${profile?.event_attendance || 'active'}).`,
    is_warning: pm >= 80 || uv >= 9,
  });

  insights.push({
    agent_type: 'Administrator Agent',
    message:
      pm >= 100 || uv >= 9
        ? `Admin alert: PM ${pm}, UV ${uv}, temperature ${temp}°C. Trigger zone advisory and suggest alternate pedestrian routing near high-exposure areas.`
        : `Admin monitor: PM ${pm}, UV ${uv}, temperature ${temp}°C, steps ${steps}. Maintain current operations and continue periodic environmental checks.`,
    is_warning: pm >= 100 || uv >= 9,
  });

  return insights;
}

function ensureAgentCoverage(insights, profile, currentData) {
  const fallback = buildDeterministicInsights(profile, currentData);
  const byType = new Map();

  for (const item of insights || []) {
    const agentType = normalizeAgentType(item.agent_type);
    const message = String(item.message ?? '').trim();
    if (!message) continue;
    if (!byType.has(agentType)) {
      byType.set(agentType, {
        agent_type: agentType,
        message,
        is_warning: Boolean(item.is_warning),
      });
    }
  }

  for (const fallbackItem of fallback) {
    if (!byType.has(fallbackItem.agent_type)) {
      byType.set(fallbackItem.agent_type, fallbackItem);
    }
  }

  return AGENT_TYPES.map((type) => byType.get(type)).filter(Boolean);
}

function buildContextualFallbackReply(question, preferredAgent, profile, currentData) {
  const agent = normalizeAgentType(preferredAgent);
  const uv = safeNum(currentData?.uv_index);
  const pm = safeNum(currentData?.pm_level);
  const temp = safeNum(currentData?.temperature);
  const steps = safeNum(currentData?.step_count);
  const mobility = asCsv(profile?.mobility_needs);
  const allergies = asCsv(profile?.allergies);
  const earliestClass = profile?.earliest_class || '08:00';

  const sensorLine =
    `Current sensors show UV ${uv ?? 'N/A'}, PM ${pm ?? 'N/A'}, ` +
    `temperature ${temp ?? 'N/A'}°C, and steps ${steps ?? 'N/A'}.`;

  let advice;
  let isWarning = false;
  if (agent === 'Health Agent') {
    if ((uv ?? 0) >= 8 || (pm ?? 0) >= 80) {
      advice =
        `Given allergies (${allergies}), reduce outdoor exposure now and move to an indoor route for the next 30-45 minutes.`;
      isWarning = true;
    } else {
      advice =
        `With your allergies (${allergies}), continue activity but prefer shaded sections and carry water for the next session.`;
    }
  } else if (agent === 'Routing Agent') {
    advice =
      `Based on mobility needs (${mobility}), use accessible paths and avoid crowded corridors if PM spikes above 60 along your route.`;
    if ((pm ?? 0) >= 80) isWarning = true;
  } else if (agent === 'Scheduler Agent') {
    advice =
      `Before your earliest class at ${earliestClass}, shift outdoor tasks to lower UV windows and keep indoor study blocks when PM rises.`;
    if ((uv ?? 0) >= 8) isWarning = true;
  } else if (agent === 'Community Agent') {
    advice =
      `If conditions stay stable, take a low-emission route and log activity to improve your Green Points streak this afternoon.`;
  } else {
    advice =
      `Campus trend action: monitor this zone for 20 minutes and issue a local alert if UV or PM rises further.`;
    if ((uv ?? 0) >= 9 || (pm ?? 0) >= 100) isWarning = true;
  }

  return {
    agent_type: agent,
    message: `${sensorLine} ${advice} Question context: "${question}".`,
    is_warning: isWarning,
  };
}

async function resolveActiveUserId() {
  if (ACTIVE_USER_ID) {
    const { data, error } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', ACTIVE_USER_ID)
      .maybeSingle();
    if (error) {
      console.error('❌ Could not validate SIMULATED_USER_ID:', error.message);
    } else if (data) {
      return ACTIVE_USER_ID;
    } else {
      console.warn(
        `⚠️ Configured SIMULATED_USER_ID ${ACTIVE_USER_ID} has no profile row.`,
      );
    }
  }

  const { data: fallbackProfiles, error: fallbackError } = await supabase
    .from('profiles')
    .select('id')
    .order('created_at', { ascending: false })
    .limit(1);
  if (fallbackError) {
    throw new Error(`Could not fetch fallback profile: ${fallbackError.message}`);
  }
  if (!fallbackProfiles || fallbackProfiles.length === 0) {
    throw new Error('No profiles rows exist. Complete onboarding once first.');
  }
  ACTIVE_USER_ID = fallbackProfiles[0].id;
  console.warn(`⚠️ Falling back to latest profile user ${ACTIVE_USER_ID}.`);
  return ACTIVE_USER_ID;
}

async function parseJsonWithRepair(rawText, repairInstruction) {
  const cleaned = stripCodeFences(rawText);
  try {
    return JSON.parse(cleaned);
  } catch (error) {
    if (!model) return null;
    try {
      const repairResult = await model.generateContent(
        `${repairInstruction}\n\nINPUT:\n${cleaned}`,
      );
      const repaired = stripCodeFences(repairResult.response.text());
      return JSON.parse(repaired);
    } catch (repairError) {
      console.error('JSON repair failed:', repairError?.message || repairError);
      console.error('Original JSON parse failed:', error?.message || error);
      return null;
    }
  }
}

async function fetchUserContext(userId) {
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle();
  if (profileError) {
    throw new Error(
      `Could not fetch profiles row for user ${userId}: ${profileError.message}`,
    );
  }
  if (!profile) {
    throw new Error(
      `No profiles row for user ${userId}. Complete onboarding or insert matching profile row.`,
    );
  }

  const { data: sensors } = await supabase
    .from('sensor_readings')
    .select('*')
    .eq('user_id', userId)
    .order('recorded_at', { ascending: false })
    .limit(1);

  const currentData = sensors && sensors.length > 0 ? sensors[0] : null;
  console.log(
    `📊 Context user=${userId} | UV=${currentData?.uv_index ?? 'N/A'} PM=${currentData?.pm_level ?? 'N/A'} Temp=${currentData?.temperature ?? 'N/A'} Steps=${currentData?.step_count ?? 'N/A'} | Allergies=${asCsv(profile?.allergies)} Mobility=${asCsv(profile?.mobility_needs)} EarliestClass=${profile?.earliest_class || 'N/A'}`,
  );
  return { profile, currentData };
}

async function generateInsightBatch(profile, currentData) {
  if (!model) {
    console.warn(
      'Gemini unavailable for autonomous insights (missing GEMINI_API_KEY). Using deterministic fallback insights.',
    );
    return buildDeterministicInsights(profile, currentData);
  }

  const safeMobility = asCsv(profile?.mobility_needs);
  const safeAllergies = asCsv(profile?.allergies);

  const prompt = `
You are the core AI Orchestrator for a smart campus app at a university.
Generate exactly 5 relevant insights, one per agent type.

USER PROFILE:
- Major: ${profile?.faculty || 'Engineering'}
- Allergies: ${safeAllergies}
- Mobility Needs: ${safeMobility}
- Earliest Class: ${profile?.earliest_class || '08:00'}
- Event Attendance: ${profile?.event_attendance || 'Active'}

LIVE HARDWARE DATA:
- UV Index: ${currentData?.uv_index ?? 'unknown'}
- PM Level: ${currentData?.pm_level ?? 'unknown'}
- Steps: ${currentData?.step_count ?? 'unknown'}
- Temperature: ${currentData?.temperature ?? 'unknown'}

Allowed agent_type values only:
${AGENT_TYPES.join(', ')}

Rules:
- Mention at least one concrete sensor value in each message.
- Mention one user-profile factor in each message.
- Keep each message to 1-2 sentences with one action.
- Do not repeat the same recommendation phrasing across agents.

Return strict JSON array only:
[
  {"agent_type":"Health Agent","message":"...","is_warning":true},
  {"agent_type":"Routing Agent","message":"...","is_warning":false},
  {"agent_type":"Scheduler Agent","message":"...","is_warning":false},
  {"agent_type":"Community Agent","message":"...","is_warning":false},
  {"agent_type":"Administrator Agent","message":"...","is_warning":false}
]
`;

  const result = await model.generateContent(prompt);
  const parsed = await parseJsonWithRepair(
    result.response.text(),
    'Convert INPUT into a valid JSON array only. Do not include markdown. Keep schema: [{"agent_type":"Health Agent|Scheduler Agent|Routing Agent|Community Agent|Administrator Agent","message":"string","is_warning":boolean}]',
  );
  if (!Array.isArray(parsed)) return buildDeterministicInsights(profile, currentData);
  const normalized = parsed
    .map((d) => ({
      agent_type: normalizeAgentType(d.agent_type),
      message: String(d.message ?? '').trim(),
      is_warning: Boolean(d.is_warning),
    }))
    .filter((d) => d.message.length > 0);
  return ensureAgentCoverage(normalized, profile, currentData);
}

async function generateReplyForQuestion(question, preferredAgent, profile, currentData) {
  if (!model) {
    console.warn('Gemini unavailable for query reply (missing GEMINI_API_KEY).');
    return buildContextualFallbackReply(
      question,
      preferredAgent,
      profile,
      currentData,
    );
  }

  const safeMobility = asCsv(profile?.mobility_needs);
  const safeAllergies = asCsv(profile?.allergies);
  const safeEarliestClass = profile?.earliest_class || '08:00';
  const safeEventAttendance = profile?.event_attendance || 'Occasionally';
  const prompt = `
You are ${normalizeAgentType(preferredAgent)} inside a smart campus assistant.
Respond to the user's question in 1-2 actionable sentences grounded in the provided profile and sensor context.

User question: "${question}"
User major: ${profile?.faculty || 'Engineering'}
Allergies: ${safeAllergies}
Mobility needs: ${safeMobility}
Earliest class: ${safeEarliestClass}
Event attendance: ${safeEventAttendance}
Latest UV: ${currentData?.uv_index ?? 'unknown'}
Latest PM: ${currentData?.pm_level ?? 'unknown'}
Latest Steps: ${currentData?.step_count ?? 'unknown'}
Latest Temperature: ${currentData?.temperature ?? 'unknown'}
Latest Humidity: ${currentData?.humidity ?? 'unknown'}

Rules:
- Mention at least two concrete sensor values in the message.
- Mention at least one profile factor (allergy, mobility, class time, or attendance).
- End with one explicit action recommendation.

Return strict JSON object only:
{"agent_type":"${normalizeAgentType(preferredAgent)}","message":"...","is_warning":false}
`;

  try {
    const result = await model.generateContent(prompt);
    const obj = await parseJsonWithRepair(
      result.response.text(),
      `Convert INPUT into one valid JSON object only with schema {"agent_type":"${normalizeAgentType(preferredAgent)}","message":"string","is_warning":boolean}. No markdown.`,
    );
    if (!obj || typeof obj !== 'object') {
      console.warn('Gemini reply parse failed; using contextual fallback.');
      return buildContextualFallbackReply(
        question,
        preferredAgent,
        profile,
        currentData,
      );
    }
    const message = String(obj.message ?? '').trim();
    if (!message) {
      console.warn('Gemini reply empty message; using contextual fallback.');
      return buildContextualFallbackReply(
        question,
        preferredAgent,
        profile,
        currentData,
      );
    }
    return {
      agent_type: normalizeAgentType(obj.agent_type || preferredAgent),
      message,
      is_warning: Boolean(obj.is_warning),
    };
  } catch (error) {
    console.error('Question generation fallback:', error?.message || error);
    return buildContextualFallbackReply(
      question,
      preferredAgent,
      profile,
      currentData,
    );
  }
}

async function processPendingQueries() {
  const { data: pending, error } = await supabase
    .from('agent_queries')
    .select('id, user_id, question, agent_type, status, created_at')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(5);

  if (error) {
    console.error('❌ Could not fetch pending queries:', error.message);
    return;
  }
  if (!pending || pending.length === 0) {
    return;
  }

  console.log(`📥 Processing ${pending.length} pending question(s)...`);

  for (const query of pending) {
    try {
      console.log(
        `➡️ Processing query ${query.id} for user ${query.user_id} (agent=${query.agent_type})`,
      );
      const { error: lockError } = await supabase
        .from('agent_queries')
        .update({ status: 'processing' })
        .eq('id', query.id)
        .eq('status', 'pending');
      if (lockError) {
        console.error(`❌ Could not lock query ${query.id}:`, lockError.message);
        continue;
      }

      const { profile, currentData } = await fetchUserContext(query.user_id);
      const reply = await generateReplyForQuestion(
        query.question,
        query.agent_type,
        profile,
        currentData,
      );

      const normalizedAgent = normalizeAgentType(reply.agent_type);
      const { error: insertError } = await supabase.from('agent_insights').insert({
        user_id: query.user_id,
        agent_type: normalizedAgent,
        message: reply.message,
        is_warning: reply.is_warning,
      });
      if (insertError) {
        throw insertError;
      }

      // Keep app chat response path aligned with query_id -> answer_text.
      // Supports UIs that read from agent_answers directly.
      const { error: answerError } = await supabase
        .from('agent_answers')
        .upsert(
          {
            query_id: query.id,
            answer_text: reply.message,
          },
          { onConflict: 'query_id' },
        );
      if (answerError) {
        throw answerError;
      }

      const { error: doneError } = await supabase
        .from('agent_queries')
        .update({ status: 'done' })
        .eq('id', query.id);
      if (doneError) {
        console.error(
          `⚠️ Query ${query.id} response inserted but status not updated:`,
          doneError.message,
        );
      } else {
        console.log(`✅ Query ${query.id} processed -> done`);
      }
    } catch (queryError) {
      console.error(`❌ Failed processing query ${query.id}:`, queryError.message || queryError);
      const errorText = String(queryError?.message || queryError || 'unknown');
      const { error: failWithDetail } = await supabase
        .from('agent_queries')
        .update({ status: 'failed', error_message: errorText })
        .eq('id', query.id);
      if (failWithDetail) {
        const { error: failSimple } = await supabase
          .from('agent_queries')
          .update({ status: 'failed' })
          .eq('id', query.id);
        if (failSimple) {
          console.error(`⚠️ Failed to mark query ${query.id} as failed:`, failSimple.message);
        }
      }
    }
  }
}

async function pushAutonomousInsights(profile, currentData, userId) {
  if (!currentData) {
    console.log(`⏳ Waiting for bag charm data for user ${userId}...`);
    return;
  }

  const insights = await generateInsightBatch(profile, currentData);
  if (!insights || insights.length === 0) {
    return;
  }

  const payload = insights.map((d) => ({
    user_id: userId,
    agent_type: normalizeAgentType(d.agent_type),
    message: d.message,
    is_warning: Boolean(d.is_warning),
  }));
  const { error } = await supabase.from('agent_insights').insert(payload);
  if (error) {
    console.error('❌ Could not insert autonomous insights:', error.message);
    return;
  }
  console.log(`🧠 Inserted ${payload.length} autonomous insight(s).`);
}

async function runMultiAgentSystem() {
  console.log(
    `🧠 Orchestrator wake-up (configured=${CONFIGURED_USER_ID || 'none'} active=${ACTIVE_USER_ID || 'none'})...`,
  );
  try {
    await processPendingQueries();

    if (!ACTIVE_USER_ID) {
      await resolveActiveUserId();
    }

    // Run autonomous recommendations for all recently active users instead of
    // a single configured user. This avoids app/simulator user-id mismatch.
    const targetUsers = new Set([ACTIVE_USER_ID]);

    const { data: sensorUsers, error: sensorUsersErr } = await supabase
      .from('sensor_readings')
      .select('user_id, recorded_at')
      .order('recorded_at', { ascending: false })
      .limit(20);
    if (sensorUsersErr) {
      console.warn('⚠️ Could not fetch recent sensor users:', sensorUsersErr.message);
    } else {
      for (const row of sensorUsers || []) {
        if (row.user_id) targetUsers.add(row.user_id);
      }
    }

    const { data: queryUsers, error: queryUsersErr } = await supabase
      .from('agent_queries')
      .select('user_id, created_at')
      .order('created_at', { ascending: false })
      .limit(10);
    if (queryUsersErr) {
      console.warn('⚠️ Could not fetch recent query users:', queryUsersErr.message);
    } else {
      for (const row of queryUsers || []) {
        if (row.user_id) targetUsers.add(row.user_id);
      }
    }

    for (const userId of targetUsers) {
      try {
        const { profile, currentData } = await fetchUserContext(userId);
        await pushAutonomousInsights(profile, currentData, userId);
      } catch (userError) {
        console.warn(
          `⚠️ Skipping autonomous insight generation for user ${userId}:`,
          userError?.message || userError,
        );
      }
    }
  } catch (error) {
    console.error('❌ Orchestrator Error:', error);
  }
}

console.log(
  `🚀 Starting AI Brain (configured SIMULATED_USER_ID=${CONFIGURED_USER_ID || 'not set'})...`,
);
console.log(
  `🔐 AI brain auth mode: ${supabaseServiceRoleKey ? 'service-role' : 'publishable key'}`,
);
if (!supabaseServiceRoleKey) {
  console.warn(
    '⚠️ SUPABASE_SERVICE_ROLE_KEY is empty. Queue status updates may fail under RLS; add it in root.env.',
  );
}
runMultiAgentSystem();
setInterval(runMultiAgentSystem, 15000);