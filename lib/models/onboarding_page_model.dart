import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final String? imageUrl; // Make imageUrl nullable for flexibility
  final String? imageAsset; // New field for local assets
  final Color bgColor;
  final Color textColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    this.imageUrl,
    this.imageAsset,
    this.bgColor = Colors.blue,
    this.textColor = Colors.white,
  });
}
