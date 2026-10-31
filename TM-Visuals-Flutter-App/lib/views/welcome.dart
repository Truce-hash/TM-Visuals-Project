import 'package:flutter/material.dart';

const _amber = Color(0xFFFFB300);

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        '',
                        width: 64,
                        height: 64,
                      ),
                    ],
                  ),
                  const Text(
                    'Visuals',
                    style: TextStyle(
                      color: _amber,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Text(
                'Welcome...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _amber,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
