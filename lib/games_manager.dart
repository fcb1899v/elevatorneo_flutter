// =============================
// GamesManager: Game services integration for elevator simulator
//
// Handles Game Center integration, leaderboards, and internet connectivity.
// Key features: sign-in, score submission, leaderboards, connectivity checks
// =============================

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extension.dart';

class GamesManager {

  final bool isGamesSignIn;
  final bool isConnectedInternet;

  GamesManager({
    required this.isGamesSignIn,
    required this.isConnectedInternet
  });

  // --- Connectivity Management ---

  /// Check internet connectivity with timeout and fallback
  Future<bool> checkInternetConnection() async {
    final Duration timeout = const Duration(seconds: 10);
    // Log connectivity result but don't rely on it for decision
    try {
      final connectivity = await Connectivity().checkConnectivity();
      "Connectivity result: $connectivity".debugPrint();
    } catch (e) {
      "Connectivity check failed: $e".debugPrint();
    }
    // Perform direct connection test
    try {
      "Attempting socket connection to 1.1.1.1:53...".debugPrint();
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect('1.1.1.1', 53, timeout: timeout);
      socket.destroy();
      stopwatch.stop();
      "Socket connection successful in ${stopwatch.elapsedMilliseconds}ms".debugPrint();
      return true;
    } on SocketException catch (e) {
      "SocketException: $e".debugPrint();
    } on TimeoutException catch (e) {
      "Socket TimeoutException: $e".debugPrint();
    } catch (e) {
      "Socket connection failed with unknown error: $e".debugPrint();
    }
    // Fallback: DNS resolution test
    try {
      "Attempting DNS lookup for example.com...".debugPrint();
      final stopwatch = Stopwatch()..start();
      final res = await InternetAddress.lookup('example.com').timeout(timeout);
      stopwatch.stop();
      final result = res.isNotEmpty && res[0].rawAddress.isNotEmpty;
      "DNS lookup result: $result in ${stopwatch.elapsedMilliseconds}ms".debugPrint();
      if (result) {
        "Resolved addresses: ${res.map((addr) => addr.address).join(', ')}".debugPrint();
      }
      return result;
    } on TimeoutException catch (e) {
      "DNS TimeoutException: $e".debugPrint();
      return false;
    } on SocketException catch (e) {
      "DNS SocketException: $e".debugPrint();
      return false;
    } catch (e) {
      "DNS lookup failed with unknown error: $e".debugPrint();
      return false;
    }
  }

  // --- Game Services Authentication ---

  /// Sign in to Game Services if not already signed in
  Future<bool> gamesSignIn() async {
    if (!isConnectedInternet) {
      "Not connected Internet".debugPrint();
      return false;
    } else if (isGamesSignIn) {
      "Already signed in to games services: true".debugPrint();
      return true;
    } else {
      "gamesSignIn".debugPrint();
      try {
        await GameAuth.signIn();
        final isSignedIn = await GameAuth.isSignedIn;
        if (isSignedIn) {
          'Success to sign in to games services: $isSignedIn'.debugPrint();
          return true;
        } else {
          'Fail to sign in to games services: $isSignedIn'.debugPrint();
          return false;
        }
      } catch (e) {
        'Fail to sign in to games services: $e'.debugPrint();
        return false;
      }
    }
  }

  // --- Score Management ---

  /// Submit score to leaderboard and update local best score
  Future<void> gamesSubmitScore(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedBestScore = 'pointKey'.getSharedPrefInt(prefs, 0);
    final isSignedIn = (isGamesSignIn && isConnectedInternet) ? true : await gamesSignIn();
    if (isSignedIn) {
      "gamesSubmitScore".debugPrint();
      try {
        await Leaderboards.submitScore(
          score: Score(
            androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
            iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
            value: value,
          ),
        );
        "Success submitting leaderboard: $value".debugPrint();
      } catch (e) {
        'Error submitting score: $e'.debugPrint();
      }
    }
    if (value > savedBestScore) {
      "pointKey".setSharedPrefInt(prefs, value);
      "point: $value".debugPrint();
    }
  }

  // --- Leaderboard Display ---

  /// Show leaderboards if signed in
  Future<void> gamesShowLeaderboard() async {
    final isSignedIn = (isGamesSignIn && isConnectedInternet) ? true : await gamesSignIn();
    if (isSignedIn) {
      "gamesShowLeaderboard".debugPrint();
      try {
        await Leaderboards.showLeaderboards(
          androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
          iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID")
        );
        "Success showing leaderboard".debugPrint();
      } catch (e) {
        'Error showing leaderboards: $e'.debugPrint();
      }
    }
  }

  // --- Best Score Retrieval ---

  /// Get best score from server or local storage
  Future<int> getBestScore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedBestScore = "pointKey".getSharedPrefInt(prefs, 0);
    "savedBestScore: $savedBestScore".debugPrint();
    final isSignedIn = (isGamesSignIn && isConnectedInternet) ? true : await gamesSignIn();
    if (isSignedIn) {
      try {
        final gamesBestScore = await Player.getPlayerScore(
          androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
          iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
        ) ?? savedBestScore;
        "gamesBestScore: $gamesBestScore".debugPrint();
        if (gamesBestScore > savedBestScore) {
          'pointKey'.setSharedPrefInt(prefs, gamesBestScore);
          "gamesBestScore: $gamesBestScore".debugPrint();
          return gamesBestScore;
        } else {
          await gamesSubmitScore(savedBestScore);
          "bestScore: $savedBestScore".debugPrint();
          return savedBestScore;
        }
      } catch (e) {
        "bestScore: $savedBestScore (Fail to get from server)".debugPrint();
        return savedBestScore;
      }
    } else {
      "bestScore: $savedBestScore (Can't sign in the server)".debugPrint();
      return savedBestScore;
    }
  }

}