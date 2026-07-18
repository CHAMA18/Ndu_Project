import 'package:flutter/material.dart';
import 'package:ndu_project/screens/sign_in_screen.dart';

/// A shared bottom action bar with "Sign In" (left) and "Start Your Project"
/// (right, yellow button) on a black background. Used on all landing page
/// subpages (How It Works, Use Cases, Partner, Pricing, etc.) so they all
/// have the same call-to-action section.
class LandingSubpageActionBar extends StatelessWidget {
  const LandingSubpageActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sign In link
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SignInScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              // Start Your Project button (yellow)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SignInScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC812),
                  foregroundColor: const Color(0xFF151515),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size(200, 52),
                ),
                child: const Text(
                  'Start Your Project',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
