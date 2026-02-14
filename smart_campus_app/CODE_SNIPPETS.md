# Code Snippets - SmartCampus App

Quick copy-paste code for common customizations and extensions.

## 🎨 Customizing Colors

### Change the entire color scheme
**File**: `lib/theme/app_theme.dart`

```dart
// Replace these constants:
static const Color deepForestGreen = Color(0xFF0B3D2E);  // Your primary color
static const Color neonMint = Color(0xFF00FFA3);         // Your accent color
static const Color darkBackground = Color(0xFF0A0E1A);   // Main background
static const Color cardBackground = Color(0xFF1A1F35);   // Card/container bg
```

## 🔌 Supabase Integration

### Complete Supabase Setup
**File**: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'providers/onboarding_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const SmartCampusApp());
}

// Add this helper getter
final supabase = Supabase.instance.client;

class SmartCampusApp extends StatelessWidget {
  const SmartCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Campus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
```

### Sign Up with Error Handling
**File**: `lib/screens/signup_screen.dart` - Replace `_handleSignUp()` method

```dart
Future<void> _handleSignUp() async {
  if (!_acceptTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please accept the terms and conditions', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.errorColor,
      ),
    );
    return;
  }

  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
        },
      );

      if (mounted && response.user != null) {
        setState(() => _isLoading = false);
        
        // Navigate to onboarding
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
```

### Login with Error Handling
**File**: `lib/screens/login_screen.dart` - Replace `_handleLogin()` method

```dart
Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Check if user has completed onboarding
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final preferences = await Supabase.instance.client
            .from('user_preferences')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        
        if (preferences == null) {
          // User hasn't completed onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          // User has completed onboarding, go to home
          // TODO: Navigate to home screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back!', style: GoogleFonts.inter()),
              backgroundColor: AppTheme.deepForestGreen,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
```

### Save Onboarding Data
**File**: `lib/screens/onboarding_screen.dart` - Replace `_submitOnboarding()` method

```dart
Future<void> _submitOnboarding() async {
  final provider = Provider.of<OnboardingProvider>(context, listen: false);
  
  if (!provider.isComplete()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please complete all required fields', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.errorColor,
      ),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final data = provider.toJson();
    data['user_id'] = user.id;
    
    await Supabase.instance.client
        .from('user_preferences')
        .insert(data);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome to SmartCampus! 🎉', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.deepForestGreen,
        ),
      );

      // TODO: Navigate to home screen
      // For now, show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Setup Complete!', style: GoogleFonts.poppins(color: AppTheme.textPrimary)),
          content: Text(
            'Your preferences have been saved. Connect your IoT bag charm to get started.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: GoogleFonts.inter(color: AppTheme.neonMint)),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preferences: $e', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
```

## 🗄️ Supabase Database Setup

### Create Tables SQL
Run this in your Supabase SQL Editor:

```sql
-- User preferences table
CREATE TABLE user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  fitness_goal TEXT,
  allergies TEXT[] DEFAULT '{}',
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

-- Policies
CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own preferences"
  ON user_preferences FOR DELETE
  USING (auth.uid() = user_id);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 🎬 Adding Lottie Animation

### Update Welcome Screen
**File**: `lib/screens/welcome_screen.dart`

1. Add import at top:
```dart
import 'package:lottie/lottie.dart';
```

2. Replace the animated circles Container (around line 60) with:
```dart
FadeTransition(
  opacity: _fadeAnimation,
  child: Lottie.asset(
    'assets/animations/welcome.json',
    height: 280,
    width: 280,
    fit: BoxFit.contain,
    repeat: true,
    animate: true,
  ),
),
```

3. Update `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/animations/
```

4. Create folder and add animation:
```bash
mkdir assets
mkdir assets/animations
# Add your welcome.json file here
```

## 📝 Adding New Onboarding Fields

### Example: Add "Dietary Restrictions" to Health Step

1. **Update Provider** - `lib/providers/onboarding_provider.dart`:
```dart
// Add property
final Set<String> _dietaryRestrictions = {};

// Add getter
Set<String> get dietaryRestrictions => _dietaryRestrictions;

// Add method
void toggleDietaryRestriction(String restriction) {
  if (_dietaryRestrictions.contains(restriction)) {
    _dietaryRestrictions.remove(restriction);
  } else {
    _dietaryRestrictions.add(restriction);
  }
  notifyListeners();
}

// Update toJson()
Map<String, dynamic> toJson() {
  return {
    // ... existing fields ...
    'dietary_restrictions': _dietaryRestrictions.toList(),
  };
}
```

2. **Add UI** - `lib/screens/onboarding_steps/health_step.dart`:
```dart
// Add after allergies section
const SizedBox(height: 24),

GlassCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.neonMint.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppTheme.neonMint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Dietary Restrictions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      ...['Vegetarian', 'Vegan', 'Gluten-Free', 'Lactose-Free'].map((diet) {
        final isSelected = provider.dietaryRestrictions.contains(diet);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => provider.toggleDietaryRestriction(diet),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.neonMint.withOpacity(0.1)
                    : AppTheme.darkBackground.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.neonMint : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    diet,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.neonMint, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ],
  ),
),
```

3. **Update Database**:
```sql
ALTER TABLE user_preferences
ADD COLUMN dietary_restrictions TEXT[] DEFAULT '{}';
```

## 🏠 Creating Home Screen Template

**Create**: `lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.deepForestGreen.withOpacity(0.2),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Your SmartCampus Dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.neonMint, AppTheme.deepForestGreen],
                        ),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // IoT Device Status
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.neonMint.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bluetooth_connected_rounded,
                          color: AppTheme.neonMint,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bag Charm Connected',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Last synced 2 minutes ago',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Add more cards for health metrics, schedule, etc.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## 🔐 Password Reset Flow

**Create**: `lib/screens/forgot_password_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          _emailController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Check Your Email', style: GoogleFonts.poppins(color: AppTheme.textPrimary)),
              content: Text(
                'We\'ve sent a password reset link to ${_emailController.text}',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: GoogleFonts.inter(color: AppTheme.neonMint)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e', style: GoogleFonts.inter()),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.deepForestGreen.withOpacity(0.2),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.textPrimary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Enter your email and we\'ll send you a reset link',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  GlassCard(
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'your.email@university.edu',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        CustomButton(
                          text: 'Send Reset Link',
                          onPressed: _sendResetEmail,
                          isLoading: _isLoading,
                          icon: Icons.email_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
```

---

**Need more snippets?** Check the inline comments in each file - they contain example code for common operations!
