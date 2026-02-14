import 'package:flutter/material.dart';

/// Provider to manage onboarding questionnaire data
/// Holds user responses from all onboarding steps before submission
class OnboardingProvider with ChangeNotifier {
  // Step 1: Basic Profile & Academics
  String? _name;
  int? _age;
  String? _faculty;
  String? _graduationYear;

  // Step 2: Physical Metrics & Accessibility
  double _height = 170; // in cm
  double _weight = 70; // in kg
  bool _useMetric = true; // true = cm/kg, false = ft/lbs
  final Set<String> _mobilityNeeds = {};

  // Step 3: Lifestyle & Goals (Health & Community)
  String? _fitnessGoal;
  final Set<String> _allergies = {};
  double _dailyStepGoal = 5000;
  String? _eventAttendance;

  // Step 4: Schedule & Data Consent
  TimeOfDay? _earliestClassTime;
  String? _campusTransportMethod;
  bool _greenPointsOptIn = false;

  // Getters - Step 1
  String? get name => _name;
  int? get age => _age;
  String? get faculty => _faculty;
  String? get graduationYear => _graduationYear;

  // Getters - Step 2
  double get height => _height;
  double get weight => _weight;
  bool get useMetric => _useMetric;
  Set<String> get mobilityNeeds => _mobilityNeeds;

  // Getters - Step 3
  String? get fitnessGoal => _fitnessGoal;
  Set<String> get allergies => _allergies;
  double get dailyStepGoal => _dailyStepGoal;
  String? get eventAttendance => _eventAttendance;

  // Getters - Step 4
  TimeOfDay? get earliestClassTime => _earliestClassTime;
  String? get campusTransportMethod => _campusTransportMethod;
  bool get greenPointsOptIn => _greenPointsOptIn;

  // Setters with notification - Step 1
  void setName(String? value) {
    _name = value;
    notifyListeners();
  }

  void setAge(int? value) {
    _age = value;
    notifyListeners();
  }

  void setFaculty(String? value) {
    _faculty = value;
    notifyListeners();
  }

  void setGraduationYear(String? value) {
    _graduationYear = value;
    notifyListeners();
  }

  // Setters with notification - Step 2
  void setHeight(double value) {
    _height = value;
    notifyListeners();
  }

  void setWeight(double value) {
    _weight = value;
    notifyListeners();
  }

  void toggleUnitSystem() {
    _useMetric = !_useMetric;
    // Convert values when switching
    if (_useMetric) {
      // Convert from imperial to metric
      _height = _height * 2.54; // inches to cm
      _weight = _weight * 0.453592; // lbs to kg
    } else {
      // Convert from metric to imperial
      _height = _height / 2.54; // cm to inches
      _weight = _weight / 0.453592; // kg to lbs
    }
    notifyListeners();
  }

  void toggleMobilityNeed(String need) {
    if (_mobilityNeeds.contains(need)) {
      _mobilityNeeds.remove(need);
    } else {
      _mobilityNeeds.add(need);
    }
    notifyListeners();
  }

  // Setters with notification - Step 3
  void setFitnessGoal(String? goal) {
    _fitnessGoal = goal;
    notifyListeners();
  }

  void toggleAllergy(String allergy) {
    if (_allergies.contains(allergy)) {
      _allergies.remove(allergy);
    } else {
      _allergies.add(allergy);
    }
    notifyListeners();
  }

  void setDailyStepGoal(double goal) {
    _dailyStepGoal = goal;
    notifyListeners();
  }

  void setEventAttendance(String? attendance) {
    _eventAttendance = attendance;
    notifyListeners();
  }

  // Setters with notification - Step 4
  // Setters with notification - Step 4
  void setEarliestClassTime(TimeOfDay? time) {
    _earliestClassTime = time;
    notifyListeners();
  }

  void setCampusTransportMethod(String? method) {
    _campusTransportMethod = method;
    notifyListeners();
  }

  void setGreenPointsOptIn(bool value) {
    _greenPointsOptIn = value;
    notifyListeners();
  }

  /// Validate if all required fields are filled
  bool isComplete() {
    return _name != null && _name!.isNotEmpty &&
        _age != null &&
        _faculty != null &&
        _graduationYear != null &&
        _fitnessGoal != null &&
        _eventAttendance != null &&
        _earliestClassTime != null &&
        _campusTransportMethod != null;
  }

  /// Helper: Calculate BMI for Health Agent
  double calculateBMI() {
    if (_height <= 0 || _weight <= 0) return 0;
    final heightInMeters = _useMetric ? _height / 100 : (_height * 2.54) / 100;
    final weightInKg = _useMetric ? _weight : _weight * 0.453592;
    return weightInKg / (heightInMeters * heightInMeters);
  }

  /// Get all data as a Map for submission
  /// TODO: This will be sent to Supabase backend
  Map<String, dynamic> toJson() {
    return {
      // Step 1: Basic Profile & Academics
      'name': _name,
      'age': _age,
      'faculty': _faculty,
      'graduation_year': _graduationYear,
      
      // Step 2: Physical Metrics & Accessibility
      'height_cm': _useMetric ? _height : _height * 2.54,
      'weight_kg': _useMetric ? _weight : _weight * 0.453592,
      'mobility_needs': _mobilityNeeds.toList(),
      'bmi': calculateBMI(),
      
      // Step 3: Lifestyle & Goals
      'fitness_goal': _fitnessGoal,
      'allergies': _allergies.toList(),
      'daily_step_goal': _dailyStepGoal,
      'event_attendance': _eventAttendance,
      
      // Step 4: Schedule & Data Consent
      'earliest_class_time': _earliestClassTime != null
          ? '${_earliestClassTime!.hour}:${_earliestClassTime!.minute}'
          : null,
      'campus_transport_method': _campusTransportMethod,
      'green_points_opt_in': _greenPointsOptIn,
      
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Reset all data
  void reset() {
    _name = null;
    _age = null;
    _faculty = null;
    _graduationYear = null;
    _height = 170;
    _weight = 70;
    _useMetric = true;
    _mobilityNeeds.clear();
    _fitnessGoal = null;
    _allergies.clear();
    _dailyStepGoal = 5000;
    _eventAttendance = null;
    _earliestClassTime = null;
    _campusTransportMethod = null;
    _greenPointsOptIn = false;
    notifyListeners();
  }
}
