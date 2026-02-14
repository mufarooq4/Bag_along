# SmartCampus IoT App - Authentication & Onboarding Flow

A stunning Flutter application for a smart-campus IoT system that connects to a hardware bag charm and uses Agentic AI to monitor health, scheduling, and micro-climate data.

## 🎨 Design Features

- **Modern Glassmorphism UI**: Beautiful frosted glass effects with backdrop blur
- **Dark Mode Theme**: Deep Forest Green (#0B3D2E) with Neon Mint (#00FFA3) accents
- **Smooth Animations**: Page transitions and micro-interactions
- **Responsive Layout**: Adapts to different screen sizes

## 📁 Project Structure

```
lib/
├── main.dart                           # App entry point
├── theme/
│   └── app_theme.dart                  # Color palette and theme configuration
├── providers/
│   └── onboarding_provider.dart        # State management for onboarding data
├── widgets/
│   ├── glass_card.dart                 # Reusable glassmorphism card widget
│   ├── custom_text_field.dart          # Styled text input widget
│   └── custom_button.dart              # Gradient button with loading states
└── screens/
    ├── splash_screen.dart              # Animated splash screen
    ├── welcome_screen.dart             # Welcome/landing page with CTAs
    ├── login_screen.dart               # User login form
    ├── signup_screen.dart              # User registration form
    ├── onboarding_screen.dart          # Multi-step questionnaire container
    └── onboarding_steps/
        ├── health_step.dart            # Step 1: Health profile
        ├── schedule_step.dart          # Step 2: Schedule & routing
        └── community_step.dart         # Step 3: Green Points program
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.10.7)
- Dart SDK
- Android Studio / VS Code

### Installation

1. Navigate to the project directory:
```bash
cd smart_campus_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📱 Screens Overview

### 1. Splash Screen
- Animated logo with gradient glow effect
- Tagline: "Your Campus. Your Environment. Your Agents."
- Auto-navigates to Welcome screen after 3 seconds

### 2. Welcome Screen
- Animated background with pulsing circles
- **TODO**: Replace placeholder animation with Lottie file
  - Add your Lottie JSON to `assets/animations/`
  - Update `pubspec.yaml` to include assets
  - Replace the Container widget with: `Lottie.asset('assets/animations/welcome.json')`
- Two CTA buttons: "Get Started" and "Log In"

### 3. Sign Up Screen
- Form fields: Name, Email, Password, Confirm Password
- Terms & Conditions checkbox
- Form validation
- **TODO - Supabase Integration**: Located in `_handleSignUp()` method

### 4. Login Screen
- Form fields: Email, Password
- Password visibility toggle
- "Forgot Password" link
- **TODO - Supabase Integration**: Located in `_handleLogin()` method

### 5. Onboarding Questionnaire (Multi-Step)

#### Step 1: Health Profile
- **Fitness Goal**: Dropdown selection
  - Options: Weight Loss, Muscle Gain, General Fitness, Endurance Training, Stress Management
- **Allergies**: Multi-select checkboxes
  - Options: Dust, Pollen, Mold, Pet Dander
- **Daily Step Goal**: Slider (1,000 - 20,000 steps)

#### Step 2: Schedule & Routing
- **Earliest Class Time**: Time picker
- **Campus Transport Method**: Radio button selection
  - Options: Walking, Bicycle, Campus Shuttle, Electric Scooter, Car

#### Step 3: Community & Green Points
- Beautiful info card explaining the Green Points program
- **Benefits displayed**:
  - Earn Rewards
  - Redeem Perks
  - Build Community
  - Make Impact
- **Toggle Switch**: Opt-in to anonymous data sharing
- Privacy notice about data anonymization

## 🔌 Backend Integration Points

All Supabase integration points are clearly marked with `// TODO:` comments in the code.

### 1. Authentication (`signup_screen.dart` - Line ~50)

```dart
Future<void> _handleSignUp() async {
  // TODO: Call Supabase sign up API
  // const supabase = SupabaseClient(...);
  // final response = await supabase.auth.signUp(
  //   email: _emailController.text,
  //   password: _passwordController.text,
  //   data: {'full_name': _nameController.text},
  // );
}
```

### 2. Login (`login_screen.dart` - Line ~38)

```dart
Future<void> _handleLogin() async {
  // TODO: Implement Supabase login
  // Example: await supabase.auth.signInWithPassword(
  //   email: email, 
  //   password: password
  // )
}
```

### 3. Onboarding Data Submission (`onboarding_screen.dart` - Line ~72)

```dart
Future<void> _submitOnboarding() async {
  // TODO: Send data to Supabase
  // final data = provider.toJson();
  // await supabase.from('user_preferences').insert(data);
}
```

### Suggested Supabase Schema

```sql
-- User preferences table
CREATE TABLE user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  fitness_goal TEXT,
  allergies TEXT[],
  daily_step_goal INTEGER,
  earliest_class_time TIME,
  campus_transport_method TEXT,
  green_points_opt_in BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data
CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own data
CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own data
CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id);
```

## 🎨 Color Palette

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Deep Forest Green | `#0B3D2E` | Primary color, accents |
| Neon Mint | `#00FFA3` | Secondary color, CTAs, highlights |
| Dark Background | `#0A0E1A` | Main background |
| Card Background | `#1A1F35` | Glass cards, containers |
| Text Primary | `#FFFFFF` | Main text |
| Text Secondary | `#B0B8C8` | Hints, descriptions |
| Error Color | `#FF6B6B` | Error messages |

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  lottie: ^3.0.0            # Animation support (for future use)
  google_fonts: ^6.1.0      # Custom fonts (Inter & Poppins)
```

## ✨ State Management

The app uses `Provider` for state management. The `OnboardingProvider` class manages all questionnaire data:

- Health preferences (fitness goal, allergies, step goal)
- Schedule data (class time, transport method)
- Community preferences (Green Points opt-in)

All data is validated before submission and converted to JSON format ready for backend integration.

## 🔄 Data Flow

1. User completes sign-up → Creates auth user
2. User navigates to onboarding → State managed by `OnboardingProvider`
3. User completes all 3 steps → Data validated
4. User clicks "Complete Setup" → JSON payload ready for Supabase
5. Success → Navigate to home screen (to be implemented)

## 🎯 Next Steps

1. **Add Lottie Animations**: Replace placeholder animations with actual Lottie files
2. **Integrate Supabase**: 
   - Add `supabase_flutter` package
   - Initialize Supabase client in `main.dart`
   - Implement authentication methods
   - Create database tables
   - Set up Row Level Security policies
3. **Build Home Screen**: Dashboard with IoT device connection status
4. **Implement Device Pairing**: BLE/Wi-Fi connection to bag charm
5. **Add Real-time Data Monitoring**: Health, schedule, and environment tracking

## 📄 License

This project is part of a hackathon submission for a smart-campus IoT application.

## 👥 Contributing

This is a hackathon project. The codebase is heavily commented to make integration easier for backend developers.

---

**Built with Flutter 💙 | Designed for Smart Campus IoT 🌿**
