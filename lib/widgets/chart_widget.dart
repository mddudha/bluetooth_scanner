// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import '../utils/constants.dart';

// /// Widget for displaying line charts
// class LineChartWidget extends StatelessWidget {
//   final String title;
//   final List<FlSpot> points;
//   final double? yMin;
//   final double? yMax;
//   final Color? color;
//   final double? yInterval;
//   final String? xLabelFormat;

//   const LineChartWidget({
//     super.key,
//     required this.title,
//     required this.points,
//     this.yMin,
//     this.yMax,
//     this.color,
//     this.yInterval,
//     this.xLabelFormat,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final fmt = DateFormat(xLabelFormat ?? 'H:mm');
//     final lineColor = color ?? Theme.of(context).colorScheme.primary;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Card(
//         elevation: 1.5,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                   color: Theme.of(context).colorScheme.onSurface,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: AppConstants.chartHeight.toDouble(),
//                 child: Padding(
//                   padding: const EdgeInsets.all(4),
//                   child: LineChart(
//                     LineChartData(
//                       minX: points.isEmpty ? 0 : points.first.x,
//                       maxX: points.isEmpty ? 1 : points.last.x,
//                       minY: yMin,
//                       maxY: yMax,
//                       lineTouchData: LineTouchData(
//                         handleBuiltInTouches: true,
//                         touchTooltipData: LineTouchTooltipData(
//                           tooltipBgColor: Colors.black87,
//                           getTooltipItems: (touchedSpots) => touchedSpots.map((
//                             t,
//                           ) {
//                             final dt = DateTime.fromMillisecondsSinceEpoch(
//                               t.x.toInt(),
//                             );
//                             return LineTooltipItem(
//                               '${fmt.format(dt)}\n${t.y.toStringAsFixed(1)}',
//                               const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 11,
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                       gridData: FlGridData(
//                         drawVerticalLine: false,
//                         horizontalInterval: (yMax != null && yMin != null)
//                             ? ((yMax! - yMin!) / 3).clamp(1, double.infinity)
//                             : null,
//                         getDrawingHorizontalLine: (value) => FlLine(
//                           color: Colors.grey.withOpacity(0.15),
//                           strokeWidth: 0.5,
//                         ),
//                       ),
//                       titlesData: FlTitlesData(
//                         bottomTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             reservedSize: AppConstants.bottomAxisReservedSize
//                                 .toDouble(),
//                             interval: points.length < 2
//                                 ? null
//                                 : (points.last.x - points.first.x) / 3,
//                             getTitlesWidget: (value, meta) {
//                               final dt = DateTime.fromMillisecondsSinceEpoch(
//                                 value.toInt(),
//                               );
//                               return Padding(
//                                 padding: const EdgeInsets.only(top: 8),
//                                 child: Text(
//                                   fmt.format(dt),
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.onSurface.withOpacity(0.7),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         leftTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             reservedSize: AppConstants.leftAxisReservedSize
//                                 .toDouble(),
//                             interval: yInterval,
//                             getTitlesWidget: (value, meta) {
//                               return Padding(
//                                 padding: const EdgeInsets.only(right: 8),
//                                 child: Text(
//                                   value.toStringAsFixed(0),
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.onSurface.withOpacity(0.7),
//                                   ),
//                                   textAlign: TextAlign.right,
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         rightTitles: const AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         topTitles: const AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                       ),
//                       borderData: FlBorderData(show: false),
//                       lineBarsData: [
//                         LineChartBarData(
//                           spots: points,
//                           isCurved: false,
//                           isStrokeCapRound: true,
//                           dotData: const FlDotData(show: false),
//                           barWidth: 2,
//                           color: lineColor,
//                           belowBarData: BarAreaData(
//                             show: true,
//                             gradient: LinearGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                               colors: [
//                                 lineColor.withOpacity(0.15),
//                                 lineColor.withOpacity(0.01),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
