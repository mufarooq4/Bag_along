import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type AskAgentInput = {
  user_id?: string;
  question?: string;
  current_tab_agent_type?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function normalizeType(raw: string): string {
  const value = raw.trim().toLowerCase();
  if (value === "health" || value === "health agent") return "Health Agent";
  if (value === "routing" || value === "routing agent") return "Routing Agent";
  if (value === "scheduler" || value === "scheduler agent") return "Scheduler Agent";
  if (value === "community" || value === "community agent") return "Community Agent";
  if (
    value === "admin" ||
    value === "admin agent" ||
    value === "administrator agent"
  ) {
    return "Administrator Agent";
  }
  return "Administrator Agent";
}

function asCsv(value: unknown): string {
  return Array.isArray(value) ? value.join(", ") : String(value ?? "None");
}

function stripCodeFences(text: string): string {
  const raw = String(text ?? "").trim();
  const match = raw.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  return (match ? match[1] : raw).trim();
}

function safeNum(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function contextualFallbackReply(
  question: string,
  agentType: string,
  profile: Record<string, unknown> | null,
  sensor: Record<string, unknown> | null,
) {
  const normalized = normalizeType(agentType);
  const uv = safeNum(sensor?.uv_index);
  const pm = safeNum(sensor?.pm_level);
  const temp = safeNum(sensor?.temperature);
  const steps = safeNum(sensor?.step_count);
  const allergies = asCsv(profile?.allergies);
  const mobility = asCsv(profile?.mobility_needs);
  const earliestClass = String(profile?.earliest_class ?? "08:00");
  let isWarning = false;
  let recommendation =
    "Take a short check-in route and monitor updates over the next 20 minutes.";

  if (normalized === "Health Agent") {
    if ((uv ?? 0) >= 8 || (pm ?? 0) >= 80) {
      isWarning = true;
      recommendation = `Because allergies are ${allergies}, shift indoors and reduce outdoor exposure for the next 30 minutes.`;
    } else {
      recommendation = `With allergies listed as ${allergies}, stay on shaded paths and hydrate before your next walk.`;
    }
  } else if (normalized === "Routing Agent") {
    recommendation = `Based on mobility needs (${mobility}), prefer accessible shaded routes and avoid high-traffic roads while PM stays elevated.`;
    if ((pm ?? 0) >= 80) isWarning = true;
  } else if (normalized === "Scheduler Agent") {
    recommendation = `Before your earliest class at ${earliestClass}, prioritize indoor tasks now and defer outdoor blocks to lower UV periods.`;
    if ((uv ?? 0) >= 8) isWarning = true;
  }

  return {
    message:
      `Current sensors show UV ${uv ?? "N/A"}, PM ${pm ?? "N/A"}, temperature ${temp ?? "N/A"}°C, and steps ${steps ?? "N/A"}. ` +
      `${recommendation} Question context: "${question}".`,
    agent_type: normalized,
    is_warning: isWarning,
  };
}

async function parseJsonWithRepair(
  rawText: string,
  key: string,
  instruction: string,
) {
  const cleaned = stripCodeFences(rawText);
  try {
    return JSON.parse(cleaned);
  } catch (error) {
    console.error("gemini parse error", String(error));
    const repairPrompt = `${instruction}\n\nINPUT:\n${cleaned}`;
    const repairResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${key}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: repairPrompt }] }],
          generationConfig: { responseMimeType: "application/json" },
        }),
      },
    );
    if (!repairResponse.ok) {
      const text = await repairResponse.text();
      console.error("gemini repair error", repairResponse.status, text);
      return null;
    }
    const repairData = await repairResponse.json();
    const repairedText = repairData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!repairedText || typeof repairedText !== "string") {
      return null;
    }
    try {
      return JSON.parse(stripCodeFences(repairedText));
    } catch {
      return null;
    }
  }
}

async function geminiReply(
  question: string,
  agentType: string,
  profile: Record<string, unknown> | null,
  sensor: Record<string, unknown> | null,
) {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) {
    console.warn("GEMINI_API_KEY missing in ask-agent env; using contextual fallback.");
    return null;
  }

  const prompt = `
You are ${agentType} in a smart campus assistant.
Answer the user's question using the profile and latest sensor context.

User question: "${question}"
Profile:
- Major: ${profile?.faculty ?? "Engineering"}
- Allergies: ${asCsv(profile?.allergies)}
- Mobility needs: ${asCsv(profile?.mobility_needs)}
- Earliest class: ${profile?.earliest_class ?? "08:00"}
- Event attendance: ${profile?.event_attendance ?? "Occasionally"}

Latest sensors:
- UV: ${sensor?.uv_index ?? "unknown"}
- PM: ${sensor?.pm_level ?? "unknown"}
- Temperature: ${sensor?.temperature ?? "unknown"}
- Humidity: ${sensor?.humidity ?? "unknown"}
- Steps: ${sensor?.step_count ?? "unknown"}

Rules:
- Mention at least two concrete sensor values.
- Mention at least one profile factor.
- End with one actionable recommendation.

Return strict JSON only:
{"message":"...","agent_type":"${agentType}","is_warning":false}
`;

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${key}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json" },
      }),
    },
  );

  if (!response.ok) {
    const text = await response.text();
    console.error("gemini error", response.status, text);
    return null;
  }
  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== "string") {
    console.error("gemini error missing text candidate");
    return null;
  }
  const parsed = await parseJsonWithRepair(
    text,
    key,
    `Convert INPUT to one valid JSON object with schema {"message":"string","agent_type":"${agentType}","is_warning":boolean}. No markdown.`,
  );
  if (!parsed || typeof parsed !== "object") return null;
  const message = String((parsed as Record<string, unknown>).message ?? "").trim();
  if (!message) {
    console.error("gemini error empty message content");
    return null;
  }
  return {
    message,
    agent_type: normalizeType(
      String((parsed as Record<string, unknown>).agent_type ?? agentType),
    ),
    is_warning: Boolean((parsed as Record<string, unknown>).is_warning),
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnon = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseAnon || !supabaseServiceRole) {
      return new Response(
        JSON.stringify({
          error:
            "Missing SUPABASE_URL, SUPABASE_ANON_KEY, or SUPABASE_SERVICE_ROLE_KEY in function env.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const authClient = createClient(supabaseUrl, supabaseAnon, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: authData, error: authError } = await authClient.auth.getUser();
    if (authError || !authData.user) {
      return new Response(JSON.stringify({ error: "Invalid auth session" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = (await req.json()) as AskAgentInput;
    const userId = String(body.user_id ?? "");
    const question = String(body.question ?? "").trim();
    const tabType = normalizeType(String(body.current_tab_agent_type ?? ""));

    if (!userId || !question) {
      return new Response(
        JSON.stringify({ error: "user_id and question are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (authData.user.id !== userId) {
      return new Response(JSON.stringify({ error: "user_id mismatch" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRole);
    const { data: profile, error: profileError } = await adminClient
      .from("profiles")
      .select("*")
      .eq("id", userId)
      .maybeSingle();
    if (profileError) {
      console.error("profile lookup failed", profileError.message);
    }
    const { data: sensors, error: sensorError } = await adminClient
      .from("sensor_readings")
      .select("*")
      .eq("user_id", userId)
      .order("recorded_at", { ascending: false })
      .limit(1);
    if (sensorError) {
      console.error("sensor lookup failed", sensorError.message);
    }
    const currentSensor = Array.isArray(sensors) && sensors.length > 0
      ? (sensors[0] as Record<string, unknown>)
      : null;

    const reply =
      (await geminiReply(question, tabType, profile as Record<string, unknown> | null, currentSensor)) ??
      contextualFallbackReply(
        question,
        tabType,
        profile as Record<string, unknown> | null,
        currentSensor,
      );

    await adminClient.from("agent_insights").insert({
      user_id: userId,
      agent_type: reply.agent_type,
      message: reply.message,
      is_warning: reply.is_warning,
    });

    return new Response(JSON.stringify(reply), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ask-agent function error", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
