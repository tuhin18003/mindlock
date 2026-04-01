import 'package:flutter/material.dart';
class ChallengeScreen extends StatelessWidget {
  final String challengeId;
  final String? packageName;
  const ChallengeScreen({super.key, required this.challengeId, this.packageName});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Challenge')));
}
