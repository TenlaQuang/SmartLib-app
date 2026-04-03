import 'package:flutter/material.dart';

// --- Header Widget ---
class IntroHeader extends StatelessWidget {
  const IntroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.notifications_none_rounded, size: 28),
        const Text("SmartLib AI v3.4", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.person_outline_rounded, size: 18),
        )
      ],
    );
  }
}

// --- Verification Bar Widget ---
class VerificationBar extends StatelessWidget {
  const VerificationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(10)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 20),
              SizedBox(width: 10),
              Text("NFC System State"),
            ],
          ),
          Text("100% / Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// --- Custom Icon Button Widget ---
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  const CustomIconButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.blueAccent),
    );
  }
}

// --- Demo Card Widget ---
class DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DemoCard({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        height: 110,
        decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueAccent),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}