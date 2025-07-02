import 'package:audio_classification_final/about.dart';
import 'package:audio_classification_final/main.dart';
import 'package:audio_classification_final/settings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Navigation extends StatefulWidget {
  Navigation({Key? key, required this.index}) : super(key: key);
  final int index;
  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  late int _currentIndex = widget.index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.info_rounded, 'About'),
              _buildNavItem(2, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });

        // Navigate to the selected page
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyApp()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => About()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Settings()),
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Color(0xFF1E3A8A).withOpacity(0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Color(0xFF1E3A8A)
                        : Color(0xFF9CA3AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Color(0xFF6B7280),
                size: 20,
              ),
            ),
            SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 250),
              style: GoogleFonts.inter(
                color: isSelected ? Color(0xFF1E3A8A) : Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
