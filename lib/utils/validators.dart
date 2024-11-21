class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter your password';
    } else if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? password, String? confirmPassword) {
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Please enter a username';
    } else if (username.length < 3) {
      return 'Username must be at least 3 characters';
    } else if (username.length > 15) {
      return 'Username cannot exceed 15 characters';
    } else if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscores, and periods';
    }
    return null;
  }
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Please enter your name';
    } else if (name.length > 15) {
      return 'Name cannot exceed 15 characters';
    }
    return null;
  }

  static String? validateLocation(String? location) {
    if (location != null && location.isNotEmpty && location.length > 15) {
      return 'Location cannot exceed 15 characters';
    }
    return null;
  }
}
