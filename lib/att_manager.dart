// =============================
// AttManager: App Tracking Transparency flow
//
// Shows an explanatory pre-prompt before the system ATT dialog so that more
// users grant tracking, which directly raises iOS ad eCPM.
// Key features:
// - Runs at most once per launch, after the splash screen is gone
// - Localized pre-prompt matching the app dialog style
// - Ad loading waits on `ready` so the first impression can use the IDFA
// =============================

import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';

class AttManager {

  static final Completer<void> _completer = Completer<void>();
  static bool _started = false;

  /// Completes once the tracking status is settled (immediately on Android)
  /// Ad widgets await this so they do not request before ATT is resolved
  static Future<void> get ready => _completer.future.timeout(
    const Duration(seconds: attWaitTimeoutSec),
    onTimeout: () => "ATT wait timed out".debugPrint(),
  );

  /// Run the pre-prompt and the system ATT dialog, once per launch
  /// Safe to call on every platform: non-Apple platforms complete right away
  static Future<void> request(BuildContext context) async {
    if (_started) return;
    _started = true;
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        "ATT status: $status".debugPrint();
        if (status == TrackingStatus.notDetermined) {
          if (context.mounted) await _showPrePrompt(context);
          final result = await AppTrackingTransparency.requestTrackingAuthorization();
          "ATT result: $result".debugPrint();
          await AnalyticsManager.attResult(result.name);
        } else {
          await AnalyticsManager.attResult(status.name);
        }
      }
    } catch (e) {
      "ATT error: $e".debugPrint();
    } finally {
      if (!_completer.isCompleted) _completer.complete();
    }
  }

  /// Explain why tracking helps before the one-shot system dialog appears
  static Future<void> _showPrePrompt(BuildContext context) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.attTitle(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertTitleFontSize(),
          fontFamily: context.font(),
        ),
      ),
      content: Text(context.attDesc(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertDescFontSize(),
          fontFamily: context.font(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.popPage(),
          child: Text(context.ok(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
      ],
    ),
  );
}
