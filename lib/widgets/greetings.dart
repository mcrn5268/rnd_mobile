import 'package:flutter/material.dart';

class GreetingsScreen extends StatelessWidget {
  const GreetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/PrimeLogo.png'),
            const SizedBox(height: 25),
            // const Text('Welcome!', style: TextStyle(fontSize: 30)),
          ],
        ),
      ),
    );
  }
}
