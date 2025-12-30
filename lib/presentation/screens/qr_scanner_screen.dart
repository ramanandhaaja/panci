// ignore_for_file: undefined_class, undefined_method, undefined_identifier, non_type_as_type_argument
// TODO: Re-enable this file when mobile_scanner dependency is restored

import 'package:flutter/material.dart';
// TODO: Uncomment when mobile_scanner is re-enabled
// import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR code scanner for scanning canvas IDs.
///
/// This screen provides a camera preview with a scanning overlay to guide users.
/// When a QR code is detected, it automatically validates and returns the scanned
/// canvas ID to the calling screen. Includes proper permission handling and
/// error states.
class QrScannerScreen extends StatefulWidget {
  /// Creates a QR scanner screen.
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  /// Controller for the mobile scanner.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  /// Whether the scanner has already processed a QR code.
  bool _hasScannedCode = false;

  /// Whether the torch/flashlight is enabled.
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the torch/flashlight on or off.
  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  /// Handles scanned barcode/QR code data.
  void _handleBarcodeScanned(BarcodeCapture capture) {
    // Prevent multiple scans
    if (_hasScannedCode) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) {
      _showErrorSnackBar('Invalid QR code: No data detected');
      return;
    }

    // Mark as scanned to prevent duplicate processing
    setState(() {
      _hasScannedCode = true;
    });

    // Validate canvas ID format (basic validation)
    final canvasId = code.trim();
    if (canvasId.length < 3) {
      _showErrorSnackBar('Invalid canvas ID: Too short');
      setState(() {
        _hasScannedCode = false;
      });
      return;
    }

    // Return the scanned canvas ID to the previous screen
    Navigator.pop(context, canvasId);
  }

  /// Shows an error message in a snackbar.
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeScanned,
            errorBuilder: (context, error, child) {
              return _buildErrorScreen(theme, error.toString());
            },
          ),

          // Scanning overlay with frame
          _buildScanningOverlay(theme),

          // Top controls (close button)
          _buildTopControls(theme),

          // Bottom controls (torch toggle, instructions)
          _buildBottomControls(theme),
        ],
      ),
    );
  }

  /// Builds the scanning overlay with a frame to guide users.
  Widget _buildScanningOverlay(ThemeData theme) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        borderColor: theme.colorScheme.primary,
        overlayColor: Colors.black.withValues(alpha: 0.5),
      ),
      child: const SizedBox.expand(),
    );
  }

  /// Builds the top control bar with close button.
  Widget _buildTopControls(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton.filledTonal(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom control bar with instructions and torch toggle.
  Widget _buildBottomControls(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instructions
              Text(
                'Point camera at QR code',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The code will be scanned automatically',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Torch toggle button
              FilledButton.icon(
                onPressed: _toggleTorch,
                icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
                label: Text(_isTorchOn ? 'Turn Off Flash' : 'Turn On Flash'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Builds an error screen when the camera fails to initialize.
  Widget _buildErrorScreen(ThemeData theme, String error) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Camera Error',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize camera. Please try again.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the scanner overlay with a scanning frame.
class _ScannerOverlayPainter extends CustomPainter {
  /// Creates a scanner overlay painter.
  const _ScannerOverlayPainter({
    required this.borderColor,
    required this.overlayColor,
  });

  /// Color of the scanning frame border.
  final Color borderColor;

  /// Color of the overlay outside the scanning frame.
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw overlay with cutout
    final Paint overlayPaint = Paint()..color = overlayColor;
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw scanning frame border
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final RRect scanRRect = RRect.fromRectAndRadius(
      scanRect,
      const Radius.circular(16),
    );
    canvas.drawRRect(scanRRect, borderPaint);

    // Draw corner accents
    final Paint cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top + cornerLength),
      Offset(left + scanAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
