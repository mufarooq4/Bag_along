const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');

dotenv.config({ path: 'root.env' });
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const CONFIGURED_USER_ID = process.env.SIMULATED_USER_ID;

if (!supabaseUrl || !supabaseKey) {
  console.error(
    'Missing required env vars. Expected SUPABASE_URL and SUPABASE_KEY.',
  );
  process.exit(1);
}

const runtimeKey = supabaseServiceRoleKey || supabaseKey;
const supabase = createClient(supabaseUrl, runtimeKey);
let ACTIVE_USER_ID = CONFIGURED_USER_ID || null;
const stepByUser = new Map();
const positionByUser = new Map();

// Starting Baseline: GIKI Campus Approximate Coordinates
const baseLat = 34.0680;
const baseLong = 72.6430;

const randomFloat = (min, max) => (Math.random() * (max - min) + min).toFixed(4);
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

async function validateProfileLink() {
  if (ACTIVE_USER_ID) {
    const { data, error } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', ACTIVE_USER_ID)
      .maybeSingle();
    if (error) {
      console.error('❌ Could not validate configured profile link:', error.message);
      return false;
    }
    if (data) {
      return true;
    }
    console.warn(
      `⚠️ Configured SIMULATED_USER_ID ${ACTIVE_USER_ID} has no profile row. Falling back to latest available profile.`,
    );
  }

  const { data: fallbackProfiles, error: fallbackError } = await supabase
    .from('profiles')
    .select('id')
    .order('created_at', { ascending: false })
    .limit(1);
  if (fallbackError) {
    console.error('❌ Could not fetch fallback profile:', fallbackError.message);
    return false;
  }
  if (!fallbackProfiles || fallbackProfiles.length == 0) {
    console.error(
      '❌ No profiles rows exist. Complete onboarding once before running simulator.',
    );
    return false;
  }

  ACTIVE_USER_ID = fallbackProfiles[0].id;
  console.warn(`⚠️ Using fallback profile user ${ACTIVE_USER_ID} for simulator data.`);
  return true;
}

async function fetchTargetUsers() {
  const ids = new Set();
  if (ACTIVE_USER_ID) ids.add(ACTIVE_USER_ID);

  // Include recent query users so app users asking questions also receive
  // sensor streams and autonomous recommendations.
  const { data: recentQueryUsers, error: queryErr } = await supabase
    .from('agent_queries')
    .select('user_id, created_at')
    .order('created_at', { ascending: false })
    .limit(5);
  if (queryErr) {
    console.warn('⚠️ Could not fetch recent query users:', queryErr.message);
  } else {
    for (const row of recentQueryUsers || []) {
      if (row.user_id) ids.add(row.user_id);
    }
  }

  return [...ids];
}

function getUserState(userId) {
  if (!stepByUser.has(userId)) {
    stepByUser.set(userId, randomInt(900, 1800));
  }
  if (!positionByUser.has(userId)) {
    positionByUser.set(userId, {
      lat: baseLat + parseFloat(randomFloat(-0.0007, 0.0007)),
      long: baseLong + parseFloat(randomFloat(-0.0007, 0.0007)),
    });
  }
  return {
    steps: stepByUser.get(userId),
    pos: positionByUser.get(userId),
  };
}

async function generateAndPushDataForUser(userId) {
  const state = getUserState(userId);
  state.pos.lat += parseFloat(randomFloat(-0.0001, 0.0001));
  state.pos.long += parseFloat(randomFloat(-0.0001, 0.0001));

  const temperature = randomFloat(21.0, 31.0);
  const humidity = randomFloat(35.0, 65.0);
  // Bias toward moderate/high UV so recommendation logic has enough signal.
  const isHighUvWindow = Math.random() < 0.4;
  const uv_index = isHighUvWindow ? randomInt(8, 11) : randomInt(3, 7);
  // Increase polluted cases so PM warnings are visible during short demos.
  const isPollutedArea = Math.random() < 0.35;
  const pm_level = isPollutedArea ? randomInt(80, 160) : randomInt(12, 55);
  const stepsTaken = randomInt(5, 15);
  state.steps += stepsTaken;
  stepByUser.set(userId, state.steps);
  positionByUser.set(userId, state.pos);

  const payload = {
    user_id: userId,
    latitude: state.pos.lat,
    longitude: state.pos.long,
    temperature: parseFloat(temperature),
    humidity: parseFloat(humidity),
    uv_index,
    pm_level,
    step_count: state.steps,
    recorded_at: new Date().toISOString(),
  };

  console.log(
    `🚶 Simulating walk for user ${userId}... Steps: ${state.steps} | UV: ${uv_index} | PM: ${pm_level}`,
  );

  const { error } = await supabase.from('sensor_readings').insert([payload]);

  if (error) {
    console.error('❌ Error pushing data:', error.message);
  } else {
    console.log('✅ Data pushed to Supabase successfully!');
  }
}

async function generateAndPushData() {
  const targetUsers = await fetchTargetUsers();
  if (targetUsers.length === 0) {
    console.warn('⚠️ No target users found for simulator cycle.');
    return;
  }

  for (const userId of targetUsers) {
    await generateAndPushDataForUser(userId);
  }
}

async function main() {
  console.log('🚀 Starting Agentic Campus IoT Simulator...');
  console.log(`🧭 Configured SIMULATED_USER_ID: ${CONFIGURED_USER_ID || 'not set'}`);
  console.log(
    `🔐 Simulator auth mode: ${supabaseServiceRoleKey ? 'service-role' : 'publishable key'}`,
  );
  const ready = await validateProfileLink();
  if (!ready) {
    process.exit(1);
  }
  console.log(`✅ Simulator active user: ${ACTIVE_USER_ID}`);
  stepByUser.set(ACTIVE_USER_ID, 1200);
  positionByUser.set(ACTIVE_USER_ID, { lat: baseLat, long: baseLong });
  await generateAndPushData();
  setInterval(generateAndPushData, 5000);
}

main();