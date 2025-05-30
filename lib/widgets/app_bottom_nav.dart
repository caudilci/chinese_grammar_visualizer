import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.format_list_bulleted),
          label: 'Grammar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Dictionary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Word Lists',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Flash Cards',
        ),
      ],
    );
  }
}