import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/location.dart';
import '../utils/constants.dart';

class RouteMapPainter extends CustomPainter {
  final Location home;
  final List<Location> route;
  final bool isDark;

  RouteMapPainter({
    required this.home,
    required this.route,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid Background
    _drawGrid(canvas, size);

    final allNodes = [home, ...route];
    if (allNodes.isEmpty) return;

    // 2. Determine Coordinate Boundaries
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final node in allNodes) {
      if (node.latitude < minLat) minLat = node.latitude;
      if (node.latitude > maxLat) maxLat = node.latitude;
      if (node.longitude < minLon) minLon = node.longitude;
      if (node.longitude > maxLon) maxLon = node.longitude;
    }

    // Add padding to bounds so nodes aren't on the extreme edge
    final double latSpan = maxLat - minLat;
    final double lonSpan = maxLon - minLon;
    
    // Fallback if all points are the same
    final double padLat = latSpan == 0 ? 0.01 : latSpan * 0.15;
    final double padLon = lonSpan == 0 ? 0.01 : lonSpan * 0.15;

    minLat -= padLat;
    maxLat += padLat;
    minLon -= padLon;
    maxLon += padLon;

    final double activeLatSpan = maxLat - minLat;
    final double activeLonSpan = maxLon - minLon;

    // 3. Map Coordinates to Screen X/Y Offset
    Offset getOffset(Location dest) {
      final double x = ((dest.longitude - minLon) / activeLonSpan) * size.width;
      final double y = size.height - (((dest.latitude - minLat) / activeLatSpan) * size.height);
      return Offset(x, y);
    }

    final Offset homeOffset = getOffset(home);
    final List<Offset> stopOffsets = route.map(getOffset).toList();
    final List<Offset> fullPath = [homeOffset, ...stopOffsets, homeOffset];

    // 4. Draw Path Lines
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < fullPath.length - 1; i++) {
      final start = fullPath[i];
      final end = fullPath[i + 1];

      // Use a dashed line for return-to-home path, solid for forward path
      final isReturnLeg = i == fullPath.length - 2;
      
      if (isReturnLeg) {
        pathPaint
          ..color = AppColors.homeMarker.withOpacity(0.5)
          ..strokeWidth = 2.0;
        _drawDashedLine(canvas, start, end, pathPaint);
      } else {
        pathPaint
          ..shader = uiGradientShader(start, end)
          ..strokeWidth = 3.5;
        canvas.drawLine(start, end, pathPaint);
        _drawDirectionArrow(canvas, start, end, pathPaint.color);
      }
    }

    // 5. Draw Stop Nodes
    for (int i = 0; i < allNodes.length; i++) {
      final node = allNodes[i];
      final offset = getOffset(node);
      final bool isHomeNode = i == 0;

      final bool isVisited = node.visited;
      final glowPaint = Paint()
        ..color = (isHomeNode
                ? AppColors.homeMarker
                : (isVisited ? AppColors.visited : AppColors.primary))
            .withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(offset, 14.0, glowPaint);

      // Node Fill
      final fillPaint = Paint()
        ..color = isHomeNode
            ? AppColors.homeMarker
            : (isVisited ? AppColors.visited : AppColors.primary)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 9.0, fillPaint);

      // White Border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(offset, 9.0, borderPaint);

      // Draw Labels
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      if (isHomeNode) {
        textPainter.text = const TextSpan(
          text: 'H',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        textPainter.text = TextSpan(
          text: '$i',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
      }

      textPainter.layout();
      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Draw floating text name labels
      final labelPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 10,
            fontWeight: isHomeNode ? FontWeight.bold : FontWeight.normal,
            backgroundColor: (isDark ? AppColors.bgDark : AppColors.bgLight).withOpacity(0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      canvas.save();
      canvas.translate(offset.dx - labelPainter.width / 2, offset.dy + 12);
      labelPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    
    final double angle = math.atan2(dy, dx);
    double drawn = 0.0;
    
    while (drawn < distance) {
      final double currentDashWidth = math.min(dashWidth, distance - drawn);
      final double startX = start.dx + math.cos(angle) * drawn;
      final double startY = start.dy + math.sin(angle) * drawn;
      final double endX = startX + math.cos(angle) * currentDashWidth;
      final double endY = startY + math.sin(angle) * currentDashWidth;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      drawn += dashWidth + dashSpace;
    }
  }

  void _drawDirectionArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    
    if (distance < 30) return; // Don't draw if nodes are too close

    // Calculate midpoint to place the arrow
    final double midX = start.dx + dx / 2;
    final double midY = start.dy + dy / 2;
    final Offset mid = Offset(midX, midY);

    final double angle = math.atan2(dy, dx);
    const double arrowSize = 6.0;

    final arrowPath = Path();
    arrowPath.moveTo(
      mid.dx + math.cos(angle) * arrowSize,
      mid.dy + math.sin(angle) * arrowSize,
    );
    arrowPath.lineTo(
      mid.dx + math.cos(angle + 2.5) * arrowSize,
      mid.dy + math.sin(angle + 2.5) * arrowSize,
    );
    arrowPath.lineTo(
      mid.dx + math.cos(angle - 2.5) * arrowSize,
      mid.dy + math.sin(angle - 2.5) * arrowSize,
    );
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  Shader uiGradientShader(Offset start, Offset end) {
    return LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
    ).createShader(Rect.fromPoints(start, end));
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) {
    return oldDelegate.home != home || 
           oldDelegate.route != route || 
           oldDelegate.isDark != isDark;
  }
}
