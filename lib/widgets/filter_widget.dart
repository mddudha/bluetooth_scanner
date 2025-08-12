// import 'package:flutter/material.dart';
// import '../utils/constants.dart';

// /// Widget for displaying and managing device filters
// class FilterWidget {
//   /// Shows a bottom sheet with filter options
//   static void showFiltersBottomSheet(
//     BuildContext context, {
//     required int minRssi,
//     required bool onlyNamed,
//     required bool onlyConnectable,
//     required void Function({
//       int? minRssi,
//       bool? onlyNamed,
//       bool? onlyConnectable,
//     })
//     onChanged,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) {
//         int tempRssi = minRssi;
//         bool tempNamed = onlyNamed;
//         bool tempConn = onlyConnectable;
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Filters',
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Min RSSI (dBm)'),
//                       Text('$tempRssi dBm'),
//                     ],
//                   ),
//                   Slider(
//                     value: tempRssi.toDouble(),
//                     min: AppConstants.minRssiThreshold.toDouble(),
//                     max: AppConstants.maxRssiThreshold.toDouble(),
//                     divisions: 100,
//                     label: '$tempRssi',
//                     onChanged: (v) => setModalState(() => tempRssi = v.round()),
//                   ),
//                   SwitchListTile(
//                     contentPadding: EdgeInsets.zero,
//                     title: const Text('Only named devices'),
//                     value: tempNamed,
//                     onChanged: (v) => setModalState(() => tempNamed = v),
//                   ),
//                   SwitchListTile(
//                     contentPadding: EdgeInsets.zero,
//                     title: const Text('Only connectable devices'),
//                     value: tempConn,
//                     onChanged: (v) => setModalState(() => tempConn = v),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel'),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton(
//                         onPressed: () {
//                           onChanged(
//                             minRssi: tempRssi,
//                             onlyNamed: tempNamed,
//                             onlyConnectable: tempConn,
//                           );
//                           Navigator.pop(context);
//                         },
//                         child: const Text('Apply'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
