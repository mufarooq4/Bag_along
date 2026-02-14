# Quick Start Guide - SmartCampus App

## 🚀 Run the App (5 minutes)

### Step 1: Install Dependencies
```bash
cd smart_campus_app
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

Or for specific platforms:
- **Web**: `flutter run -d chrome`
- **Android**: `flutter run -d android`
- **iOS**: `flutter run -d ios`

## 🎨 What You'll See

### Screen Flow
1. **Splash Screen** (3 seconds) → Auto-navigates
2. **Welcome Screen** → Choose "Get Started" or "Log In"
3. **Sign Up Screen** → Fill form, click "Sign Up"
4. **Onboarding** → Complete 3 steps
   - Step 1: Health profile
   - Step 2: Schedule & routing  
   - Step 3: Green Points opt-in
5. **Success Dialog** → Setup complete!

## 🔌 Add Supabase (15 minutes)

### 1. Install Package
Add to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

Run: `flutter pub get`

### 2. Initialize Supabase
In `lib/main.dart`, add before `runApp()`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_PROJECT_URL',
    anonKey: 'YOUR_ANON_KEY',
  );
  
  runApp(const SmartCampusApp());
}
```

### 3. Sign Up Integration
In `lib/screens/signup_screen.dart`, replace TODO in `_handleSignUp()`:

```dart
Future<void> _handleSignUp() async {
  if (!_acceptTerms) {
    // Show error
    return;
  }

  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {'full_name': _nameController.text},
      );
      
      if (response.user != null) {
        // Navigate to onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

### 4. Login Integration
In `lib/screens/login_screen.dart`, replace TODO in `_handleLogin()`:

```dart
Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // Navigate to home or onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

### 5. Onboarding Data Submission
In `lib/screens/onboarding_screen.dart`, replace TODO in `_submitOnboarding()`:

```dart
Future<void> _submitOnboarding() async {
  final provider = Provider.of<OnboardingProvider>(context, listen: false);
  
  if (!provider.isComplete()) {
    // Show error
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final user = Supabase.instance.client.auth.currentUser;
    final data = provider.toJson();
    data['user_id'] = user!.id;
    
    await Supabase.instance.client
        .from('user_preferences')
        .insert(data);
    
    // Show success and navigate to home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welcome to SmartCampus! 🎉')),
    );
    
    // TODO: Navigate to home screen
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

### 6. Create Database Table
Run this SQL in your Supabase dashboard:

```sql
CREATE TABLE user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  fitness_goal TEXT,
  allergies TEXT[],
  daily_step_goal INTEGER DEFAULT 5000,
  earliest_class_time TIME,
  campus_transport_method TEXT,
  green_points_opt_in BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Enable Row Level Security
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id);
```

## 🎬 Add Lottie Animations (Optional, 10 minutes)

### 1. Add Lottie File
Download a suitable animation from [LottieFiles](https://lottiefiles.com) and save to:
```
assets/animations/welcome.json
```

### 2. Update pubspec.yaml
```yaml
flutter:
  assets:
    - assets/animations/
```

### 3. Update Welcome Screen
In `lib/screens/welcome_screen.dart`, replace the placeholder Container (around line 60) with:

```dart
import 'package:lottie/lottie.dart';

// Replace the Container with animated circles with:
Lottie.asset(
  'assets/animations/welcome.json',
  height: 280,
  width: 280,
  fit: BoxFit.contain,
),
```

## 📱 Test the Complete Flow

1. **Launch App** → See splash screen animation
2. **Click "Get Started"** → Fill out sign-up form
3. **Submit Sign-Up** → Navigate to onboarding
4. **Step 1**: Select fitness goal, allergies, step goal
5. **Click Continue** → Move to step 2
6. **Step 2**: Set class time, select transport
7. **Click Continue** → Move to step 3
8. **Step 3**: Toggle Green Points on/off
9. **Click "Complete Setup"** → Data saved!

## 🐛 Common Issues

### Hot Reload Not Working?
```bash
flutter clean
flutter pub get
flutter run
```

### Build Errors?
```bash
flutter doctor
# Fix any issues reported
```

### Provider Error?
Make sure you wrapped the app in `MultiProvider` in `main.dart` (already done!)

### Supabase Connection Error?
- Check your URL and anon key
- Verify project is not paused
- Check internet connection

## 📚 File Structure

```
lib/
├── main.dart                    # App entry + providers
├── theme/app_theme.dart         # Colors & styles
├── providers/                   # State management
├── widgets/                     # Reusable components
└── screens/                     # All screens
    ├── splash_screen.dart
    ├── welcome_screen.dart
    ├── login_screen.dart
    ├── signup_screen.dart
    ├── onboarding_screen.dart
    └── onboarding_steps/
        ├── health_step.dart
        ├── schedule_step.dart
        └── community_step.dart
```

## 🎨 Customization

### Change Colors
Edit `lib/theme/app_theme.dart`:
```dart
static const Color deepForestGreen = Color(0xFF0B3D2E);
static const Color neonMint = Color(0xFF00FFA3);
```

### Add More Fields
1. Add property to `OnboardingProvider`
2. Add setter method
3. Add UI element in appropriate step
4. Update `toJson()` method

### Change Animation Speed
In any screen with animations, adjust:
```dart
Duration(milliseconds: 1500) // Make larger = slower
```

## 💡 Tips

- **Hot Reload**: Press `r` in terminal while app is running
- **Hot Restart**: Press `R` for full restart
- **Inspect Widget**: Enable Flutter DevTools in your IDE
- **State Changes**: Use Provider's `notifyListeners()` to trigger UI updates

## 🚀 Next Steps

After setup:
1. Build home/dashboard screen
2. Add IoT device pairing
3. Implement real-time monitoring
4. Create Green Points system
5. Add campus map integration

## 📞 Need Help?

- Check `README.md` for detailed documentation
- Review `IMPLEMENTATION_SUMMARY.md` for architecture overview
- All code has inline comments explaining functionality
- Search for `// TODO:` comments for integration points

---

**Ready to code!** 🎉 The frontend is complete and waiting for your backend magic.
