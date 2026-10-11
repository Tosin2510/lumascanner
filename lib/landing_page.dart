import 'package:flutter/material.dart';
import 'package:lumascanner/camera_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPage();
}

class _LandingPage extends State<LandingPage> with SingleTickerProviderStateMixin {
  late final AnimationController colorsInText;
  static const String appTextName = 'LumaScanner';

  static const Color whiteTextColour = Color(0xFFFFFFFF);
  static const Color blueTextColour = Color(0xFF4A9EFF);

  @override
  void initState() {
    super.initState();
    colorsInText = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200),);

    colorsInText.forward();
  }

  @override
  void dispose() {
    colorsInText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        textWithColourTile(),
                        const SizedBox(height: 13),
                        const Text(
                          'Scan, edit and share your documents',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  options(
                    icon: Icons.document_scanner_outlined,
                    title: 'Start scanning',
                    subtitle: 'Open the camera and scan a document',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  
                  options(
                    icon: Icons.folder_open_rounded,
                    title: 'View scanned documents',
                    subtitle: 'Open the documents you saved',
                    onTap: () {
                      // To be implemented.
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget options({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      tileColor: const Color(0xFF0D1118),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
    );
  }

  bool isLetterBlue(int position, double progressPart) {
    final lastLetter = appTextName.length - 1;

    if (progressPart < 0.1) return false;

    if (progressPart < 0.5) {
      final value = (((progressPart - 0.1) / 0.4) * appTextName.length).floor().clamp(0, lastLetter);
      return (position - value).abs() <= 1;
    }

    if (progressPart < 0.95) {
      final spot = lastLetter - (((progressPart - 0.5) / 0.45) * appTextName.length).floor().clamp(0, lastLetter);
      return position >= spot - 1;
    }

    return true;
  }

  Widget textWithColourTile() {
    return AnimatedBuilder(
      animation: colorsInText,
      builder: (context, child) {
        return Text.rich(
          TextSpan(
            children: [
              for (int val = 0; val < appTextName.length; val++)
                TextSpan(
                  text: appTextName[val],
                  style: TextStyle(
                    color: isLetterBlue(val, colorsInText.value) ? blueTextColour : whiteTextColour,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        );
      },
    );
  }
}