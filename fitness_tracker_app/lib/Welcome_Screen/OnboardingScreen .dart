import 'package:fitness_tracker_app/Welcome_Screen/WelcomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Onboarding data
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Track Your Steps",
      "subtitle": "Monitor your daily walking activity easily.",
      "animation": "assets/steps.json",
    },
    {
      "title": "Calories Burned",
      "subtitle": "See how much energy you burn every day.",
      "animation": "assets/calories.json",
    },
    {
      "title": "Workout Progress",
      "subtitle": "Track workouts and improve performance.",
      "animation": "assets/workout.json",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Skip Button (Top Right - Professional Style)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),

            // 🔹 PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder:
                    (context, index) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // JSON animation
                        Lottie.asset(
                          onboardingData[index]["animation"]!,
                          width: 250,
                          height: 250,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          onboardingData[index]["title"]!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            onboardingData[index]["subtitle"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
            ),

            // 🔹 Dots + Next/Get Started Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots Indicator
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 22 : 8,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? Colors.blueAccent
                                  : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started Button (Professional Gradient Style)
                  InkWell(
                    onTap: () {
                      if (_currentPage == onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _currentPage == onboardingData.length - 1
                            ? "Get Started"
                            : "Next",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
