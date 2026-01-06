import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Service for smoothing drawing strokes using Catmull-Rom spline interpolation.
///
/// This is a domain service that provides pure business logic for stroke smoothing.
/// It has no external dependencies and operates only on geometric data.
class StrokeSmoother {
  /// Private constructor to prevent instantiation.
  ///
  /// This class only contains static methods and should not be instantiated.
  StrokeSmoother._();

  /// Smooths a list of raw points using Catmull-Rom spline interpolation.
  ///
  /// This algorithm creates smooth curves through the given points by using
  /// Catmull-Rom splines, which pass through all control points and provide
  /// continuous first derivatives.
  ///
  /// For fewer than 4 points, the original points are returned as smoothing
  /// requires at least 4 control points for the algorithm.
  ///
  /// Parameters:
  /// - [rawPoints]: The raw points captured from user input
  ///
  /// Returns:
  /// A new list of smoothed points that form a continuous curve through the
  /// original points.
  static List<Offset> smoothPoints(List<Offset> rawPoints) {
    // Need at least 4 points for Catmull-Rom spline interpolation
    if (rawPoints.length < 4) {
      return rawPoints;
    }

    final smoothedPoints = <Offset>[];

    // Number of interpolated points between each pair of control points
    const int interpolationSteps = 10;

    // Process points in overlapping groups of 4 for Catmull-Rom splines
    for (int i = 0; i < rawPoints.length - 3; i++) {
      final p0 = rawPoints[i];
      final p1 = rawPoints[i + 1];
      final p2 = rawPoints[i + 2];
      final p3 = rawPoints[i + 3];

      // Add the first control point on the first iteration
      if (i == 0) {
        smoothedPoints.add(p1);
      }

      // Generate interpolated points between p1 and p2
      for (int step = 1; step <= interpolationSteps; step++) {
        final t = step / interpolationSteps;
        final point = _catmullRomInterpolation(p0, p1, p2, p3, t);
        smoothedPoints.add(point);
      }
    }

    // Add the last control point
    if (rawPoints.length >= 2) {
      smoothedPoints.add(rawPoints[rawPoints.length - 2]);
    }

    return smoothedPoints;
  }

  /// Performs Catmull-Rom spline interpolation for a single point.
  ///
  /// Given four control points (p0, p1, p2, p3) and a parameter t in [0, 1],
  /// this computes a point on the curve segment between p1 and p2.
  ///
  /// The Catmull-Rom spline formula:
  /// q(t) = 0.5 * [(2*p1) +
  ///               (-p0 + p2) * t +
  ///               (2*p0 - 5*p1 + 4*p2 - p3) * t^2 +
  ///               (-p0 + 3*p1 - 3*p2 + p3) * t^3]
  ///
  /// Parameters:
  /// - [p0]: Control point before the curve segment
  /// - [p1]: Start point of the curve segment
  /// - [p2]: End point of the curve segment
  /// - [p3]: Control point after the curve segment
  /// - [t]: Parameter in range [0, 1] representing position along the curve
  ///
  /// Returns:
  /// The interpolated point on the curve.
  static Offset _catmullRomInterpolation(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    // Calculate x coordinate using Catmull-Rom formula
    final x = 0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    // Calculate y coordinate using Catmull-Rom formula
    final y = 0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  /// Simplifies a stroke by reducing the number of points while preserving shape.
  ///
  /// This uses the Ramer-Douglas-Peucker algorithm to remove redundant points
  /// from a path while maintaining its overall shape within a tolerance.
  ///
  /// This method is useful for reducing the data size of strokes without
  /// significant visual quality loss.
  ///
  /// Parameters:
  /// - [points]: The points to simplify
  /// - [tolerance]: The maximum distance a point can be from the simplified path
  ///
  /// Returns:
  /// A simplified list of points.
  static List<Offset> simplifyPoints(List<Offset> points, {double tolerance = 2.0}) {
    if (points.length < 3) {
      return points;
    }

    return _ramerDouglasPeucker(points, tolerance);
  }

  /// Implements the Ramer-Douglas-Peucker algorithm for path simplification.
  static List<Offset> _ramerDouglasPeucker(List<Offset> points, double tolerance) {
    if (points.length < 3) {
      return points;
    }

    // Find the point with maximum distance from the line segment
    // connecting the first and last points
    double maxDistance = 0;
    int maxIndex = 0;

    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If the maximum distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      // Recursively simplify the two segments
      final left = _ramerDouglasPeucker(
        points.sublist(0, maxIndex + 1),
        tolerance,
      );
      final right = _ramerDouglasPeucker(
        points.sublist(maxIndex),
        tolerance,
      );

      // Combine results, removing the duplicate point at maxIndex
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // Maximum distance is within tolerance, return just the endpoints
      return [start, end];
    }
  }

  /// Calculates the perpendicular distance from a point to a line segment.
  static double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    // Handle degenerate case where line segment is a point
    if (dx == 0 && dy == 0) {
      return _distance(point, lineStart);
    }

    // Calculate perpendicular distance using the cross product formula
    final numerator = ((point.dx - lineStart.dx) * dy - (point.dy - lineStart.dy) * dx).abs();
    final denominator = _distance(lineStart, lineEnd);

    return numerator / denominator;
  }

  /// Calculates the Euclidean distance between two points.
  static double _distance(Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}
