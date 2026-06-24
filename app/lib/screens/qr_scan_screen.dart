import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

/// Full-screen QR scanner. On a successful scan it updates the user's position
/// in [AppState] and pops back to the calling screen.
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false; // prevent double-processing a single scan

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    _handled = true;
    final appState = context.read<AppState>();
    appState.onQrScanned(code);

    final known = appState.hasLocation;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(known ? 'Location updated!' : 'Unknown QR code.'),
        backgroundColor: known ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Location QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _controller.toggleTorch,
            tooltip: 'Toggle torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scanning frame overlay
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Hint text
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Point at a QR code on the wall or floor map',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // Debug panel — visible only in debug builds for emulator testing
          if (kDebugMode)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: _DebugQRPanel(onCode: _simulateScan),
            ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  void _simulateScan(String code) {
    if (_handled) return;
    _handled = true;
    final appState = context.read<AppState>();
    appState.onQrScanned(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated: $code — Location updated!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }
}

class _DebugQRPanel extends StatefulWidget {
  final ValueChanged<String> onCode;
  const _DebugQRPanel({required this.onCode});

  @override
  State<_DebugQRPanel> createState() => _DebugQRPanelState();
}

class _DebugQRPanelState extends State<_DebugQRPanel> {
  bool _expanded = false;

  static const _qrCodes = {
    'Ground Floor': ['QR_G_01', 'QR_G_02', 'QR_G_03', 'QR_G_04', 'QR_G_05'],
    'Upper Floor':  ['QR_U_01', 'QR_U_02', 'QR_U_03', 'QR_U_04', 'QR_U_05'],
  };

  static const _labels = {
    'QR_G_01': 'North Entrance',
    'QR_G_02': 'West Wing',
    'QR_G_03': 'Center / Escalators',
    'QR_G_04': 'Food Court',
    'QR_G_05': 'South Entrance',
    'QR_U_01': 'Cinema',
    'QR_U_02': 'Upper Center',
    'QR_U_03': 'Near Zara',
    'QR_U_04': 'Kids Zone',
    'QR_U_05': 'Near Apple Store',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _expanded ? 'Hide test QR codes' : 'Test QR codes',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _qrCodes.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.value.map((qr) {
                        return GestureDetector(
                          onTap: () => widget.onCode(qr),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _labels[qr] ?? qr,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
