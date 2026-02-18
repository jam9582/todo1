import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/colors.dart';
import '../../providers/record_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/ad_banner_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isWeekly = true; // true: 주간, false: 월간
  bool _isLoading = true;

  Map<String, List<({DateTime date, int minutes})>> _chartData = {};
  Map<int, int> _categoryTotals = {};

  // 범례 버튼 선택 상태 (categories 배열 인덱스)
  int? _selectedCategoryIndex;
  // 선택된 점 (툴팁 토글)
  ({int barIndex, int spotIndex})? _selectedSpot;

  // 카테고리별 색상 (최대 4개)
  final List<Color> _categoryColors = [
    const Color(0xFFE8A87C), // 웜 오렌지
    const Color(0xFF85C1E9), // 소프트 블루
    const Color(0xFF82E0AA), // 소프트 그린
    const Color(0xFFF1948A), // 소프트 핑크
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _selectedCategoryIndex = null;
      _selectedSpot = null;
    });

    final recordProvider = context.read<RecordProvider>();
    final now = DateTime.now();

    if (_isWeekly) {
      _chartData = await recordProvider.getWeeklyStats();
      final weekStart = now.subtract(const Duration(days: 6));
      _categoryTotals = await recordProvider.getCategoryTotals(weekStart, now);
    } else {
      _chartData = await recordProvider.getMonthlyStats();
      final monthStart = DateTime(now.year, now.month, 1);
      _categoryTotals = await recordProvider.getCategoryTotals(monthStart, now);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '통계',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPeriodToggle(),
                          const SizedBox(height: 24),
                          _buildLineChart(),
                          const SizedBox(height: 32),
                          _buildCategoryTotals(),
                        ],
                      ),
                    ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isWeekly) {
                  setState(() => _isWeekly = true);
                  _loadData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isWeekly ? AppColors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '주간',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isWeekly ? AppColors.textPrimary : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isWeekly) {
                  setState(() => _isWeekly = false);
                  _loadData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isWeekly ? AppColors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '월간',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_isWeekly ? AppColors.textPrimary : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    if (_chartData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '데이터가 없습니다',
            style: TextStyle(color: AppColors.grey500),
          ),
        ),
      );
    }

    // 차트 데이터 준비
    // barToCategoryIndex[barIndex] = categoryIndex (데이터 없는 카테고리는 lineBars에서 제외)
    final List<LineChartBarData> lineBars = [];
    final List<int> barToCategoryIndex = [];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final key = category.id.toString();
      final data = _chartData[key];

      if (data != null && data.isNotEmpty) {
        final spots = <FlSpot>[];

        if (_isWeekly) {
          // 주간: 7일
          final weekStart = DateTime.now().subtract(const Duration(days: 6));
          for (int j = 0; j < 7; j++) {
            final date = weekStart.add(Duration(days: j));
            final dayData = data.where((d) =>
              d.date.year == date.year &&
              d.date.month == date.month &&
              d.date.day == date.day
            ).firstOrNull;
            spots.add(FlSpot(j.toDouble(), (dayData?.minutes ?? 0) / 60.0));
          }
        } else {
          // 월간
          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          for (int day = 1; day <= daysInMonth && day <= now.day; day++) {
            final dayData = data.where((d) => d.date.day == day).firstOrNull;
            spots.add(FlSpot((day - 1).toDouble(), (dayData?.minutes ?? 0) / 60.0));
          }
        }

        final color = _categoryColors[i % _categoryColors.length];
        final bool isActive = _selectedCategoryIndex == null || _selectedCategoryIndex == i;

        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: isActive ? color : color.withValues(alpha: 0.15),
            barWidth: isActive ? 2 : 1,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: isActive ? 3 : 2,
                  color: barData.color ?? Colors.blue,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        );
        barToCategoryIndex.add(i);
      }
    }

    if (lineBars.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '데이터가 없습니다',
            style: TextStyle(color: AppColors.grey500),
          ),
        ),
      );
    }

    // 최대값 계산 후 적절한 interval 설정 (약 4-6개 라벨 목표)
    double maxY = 0;
    for (final bar in lineBars) {
      for (final spot in bar.spots) {
        if (spot.y > maxY) maxY = spot.y;
      }
    }
    // interval 계산: 최대값을 5로 나눠서 올림, 최소 1
    final yInterval = maxY <= 5 ? 1.0 : (maxY / 5).ceil().toDouble();
    // maxY를 interval 배수로 올림 + 여유 공간 (최상단 그리드선이 보이도록)
    final chartMaxY = (maxY / yInterval).ceil() * yInterval + (yInterval * 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isWeekly ? '주간 활동 추이' : '월간 활동 추이',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        // 범례
        _buildChartLegend(categories),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.only(right: 16, top: 16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: chartMaxY, // interval 배수로 올림하여 모든 데이터가 그리드 내부에
              lineBarsData: lineBars,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      // 0 미만이거나 소수점이면 숨김
                      if (value < 0 || value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${value.toInt()}h',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1, // 중복 방지
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (_isWeekly) {
                        // 주간: 7일 날짜 표시
                        if (index < 0 || index > 6) return const SizedBox.shrink();
                        final weekStart = DateTime.now().subtract(const Duration(days: 6));
                        final date = weekStart.add(Duration(days: index));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.grey500,
                            ),
                          ),
                        );
                      } else {
                        // 월간: 5일 간격으로 표시
                        final day = index + 1;
                        if (day == 1 || day % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.grey500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                checkToShowHorizontalLine: (value) {
                  // 0부터 chartMaxY까지 yInterval 간격으로 모두 표시
                  return value >= 0 && value <= chartMaxY;
                },
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.grey300,
                    strokeWidth: 0.5,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              showingTooltipIndicators: _selectedSpot != null
                  ? [
                      ShowingTooltipIndicators([
                        LineBarSpot(
                          lineBars[_selectedSpot!.barIndex],
                          _selectedSpot!.barIndex,
                          lineBars[_selectedSpot!.barIndex].spots[_selectedSpot!.spotIndex],
                        ),
                      ]),
                    ]
                  : [],
              lineTouchData: LineTouchData(
                enabled: _selectedCategoryIndex != null,
                handleBuiltInTouches: false,
                touchSpotThreshold: 20,
                touchCallback: (event, response) {
                  if (_selectedCategoryIndex == null) return;
                  if (event is! FlTapUpEvent) return;
                  if (response?.lineBarSpots == null || response!.lineBarSpots!.isEmpty) return;

                  // 선택된 카테고리의 barIndex 찾기
                  final selectedBarIndex = barToCategoryIndex.indexOf(_selectedCategoryIndex!);
                  if (selectedBarIndex == -1) return;

                  // 선택된 카테고리의 점만 필터
                  final spots = response.lineBarSpots!
                      .where((s) => s.barIndex == selectedBarIndex)
                      .toList();
                  if (spots.isEmpty) return;

                  final spot = spots.first;
                  final newSelection = (barIndex: spot.barIndex, spotIndex: spot.spotIndex);

                  setState(() {
                    if (_selectedSpot?.barIndex == newSelection.barIndex &&
                        _selectedSpot?.spotIndex == newSelection.spotIndex) {
                      _selectedSpot = null;
                    } else {
                      _selectedSpot = newSelection;
                    }
                  });
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final hours = spot.y.floor();
                      final minutes = ((spot.y - hours) * 60).round();
                      return LineTooltipItem(
                        '${hours}h ${minutes}m',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(List categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(categories.length, (index) {
        final category = categories[index];
        final color = _categoryColors[index % _categoryColors.length];
        final isSelected = _selectedCategoryIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedCategoryIndex == index) {
                _selectedCategoryIndex = null;
              } else {
                _selectedCategoryIndex = index;
              }
              _selectedSpot = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : AppColors.grey300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${category.emoji} ${category.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryTotals() {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    if (_categoryTotals.isEmpty || categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // 최대값 찾기 (프로그레스 바 비율 계산용)
    final maxMinutes = _categoryTotals.values.fold(0, (a, b) => a > b ? a : b);
    if (maxMinutes == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isWeekly ? '주간 카테고리별 총합' : '월간 카테고리별 총합',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(categories.length, (index) {
          final category = categories[index];
          final minutes = _categoryTotals[category.id] ?? 0;
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          final ratio = maxMinutes > 0 ? minutes / maxMinutes : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.emoji} ${category.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${hours}h ${mins}m',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _categoryColors[index % _categoryColors.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
