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

  Future<bool> checkInternetConnection() async {
    final Duration timeout = const Duration(seconds: 5);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return false;
    try {
      final socket = await Socket.connect('1.1.1.1', 53, timeout: timeout);
      socket.destroy();
      return true;
    } on SocketException catch (e) {
      "SocketException: $e".debugPrint();
    }
    try {
      final res = await InternetAddress.lookup('example.com').timeout(timeout);
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } on TimeoutException catch (e) {
      "TimeoutException: $e".debugPrint();
      return false;
    } on SocketException catch (e) {
      "SocketException: $e".debugPrint();
      return false;
    }
  }

  ///Signing in to Game Services
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

  ///Submitting games score
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

  ///Showing games leaderboards
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

  ///Get best score games leaderboards
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
          return savedBestScore;
        } else {
          await gamesSubmitScore(savedBestScore);
          "bestScore: $savedBestScore".debugPrint();
          return gamesBestScore;
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