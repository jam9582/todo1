import 'package:flutter/material.dart';
import '../../widgets/ad_banner_widget.dart';
import 'sections/header_section.dart';
import 'sections/daily_message_section.dart';
import 'sections/time_input_section.dart';
import 'sections/calendar_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 광고 영역
            const AdBannerWidget(),

            // 스크롤 가능한 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    // 헤더 (오늘의 한마디 제목 + 햄버거 메뉴)
                    HeaderSection(),

                    // 한마디 입력
                    DailyMessageSection(),

                    // 시간 입력 섹션 (4개 카테고리)
                    TimeInputSection(),

                    // 달력
                    CalendarSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
