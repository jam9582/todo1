import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          const Text(
            '오늘의 한마디',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // TODO: 햄버거 메뉴 기능 (나중에 구현)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메뉴 기능은 나중에 구현 예정')),
              );
            },
          ),
        ],
      ),
    );
  }
}
