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

// Starting Baseline: GIKI Campus Approximate Coordinates
let currentLat = 34.0680; 
let currentLong = 72.6430;
let totalSteps = 1200; 

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

async function generateAndPushData() {
  currentLat += parseFloat(randomFloat(-0.0001, 0.0001));
  currentLong += parseFloat(randomFloat(-0.0001, 0.0001));

  const temperature = randomFloat(21.0, 31.0);
  const humidity = randomFloat(35.0, 65.0);
  // Bias toward moderate/high UV so recommendation logic has enough signal.
  const isHighUvWindow = Math.random() < 0.4;
  const uv_index = isHighUvWindow ? randomInt(8, 11) : randomInt(3, 7);
  // Increase polluted cases so PM warnings are visible during short demos.
  const isPollutedArea = Math.random() < 0.35;
  const pm_level = isPollutedArea ? randomInt(80, 160) : randomInt(12, 55);
  const stepsTaken = randomInt(5, 15);
  totalSteps += stepsTaken;

  const payload = {
    user_id: ACTIVE_USER_ID,
    latitude: currentLat,
    longitude: currentLong,
    temperature: parseFloat(temperature),
    humidity: parseFloat(humidity),
    uv_index,
    pm_level,
    step_count: totalSteps,
    recorded_at: new Date().toISOString(),
  };

  console.log(
    `🚶 Simulating walk for user ${ACTIVE_USER_ID}... Steps: ${totalSteps} | UV: ${uv_index} | PM: ${pm_level}`,
  );

  const { error } = await supabase.from('sensor_readings').insert([payload]);

  if (error) {
    console.error('❌ Error pushing data:', error.message);
  } else {
    console.log('✅ Data pushed to Supabase successfully!');
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
  await generateAndPushData();
  setInterval(generateAndPushData, 5000);
}

main();