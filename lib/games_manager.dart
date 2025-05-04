import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extension.dart';
import 'main.dart';

Future<bool> gamesIsSignedIn() async => await GameAuth.isSignedIn;

///Signing in to Game Services
Future<bool> gamesSignIn() async {
  if (!Platform.isAndroid || isTest) {
    "gamesSignIn".debugPrint();
    final isSignedIn = await gamesIsSignedIn();
    if (isSignedIn) {
      "Already signed in to games services: true".debugPrint();
      return true;
    } else {
      try {
        final auth = await GamesServices.signIn();
        "auth: $auth".debugPrint();
        final isSignIn = await gamesIsSignedIn();
        if (isSignIn) {
          'Success to sign in to games services: $isSignIn'.debugPrint();
          return true;
        } else {
          'Fail to sign in to games services: $isSignIn'.debugPrint();
          return false;
        }
      } catch (e) {
        'Fail to sign in to games services: $e'.debugPrint();
        return false;
      }
    }
  } else {
    return false;
  }
}

///Submitting games score
gamesSubmitScore(int value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final prefBestScore = prefs.getInt('pointKey') ?? 0;
  if (!Platform.isAndroid || isTest) {
    "gamesSubmitScore".debugPrint();
    final isSignedIn = await gamesSignIn();
    if (isSignedIn) {
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
    if (value > prefBestScore) {
      await "bestScore".setSharedPrefInt(prefs, value);
      "bestScore: $value".debugPrint();
    }
  } else {
    if (value > prefBestScore) {
      await "bestScore".setSharedPrefInt(prefs, value);
      "bestScore: $value".debugPrint();
    }
  }
}

///Showing games leaderboards
gamesShowLeaderboard() async {
  if (!Platform.isAndroid || isTest) {
    "gamesShowLeaderboard".debugPrint();
    final isSignedIn = await gamesSignIn();
    if (isSignedIn) {
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
}

///Get best score games leaderboards
Future<int> getBestScore() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final prefBestScore = prefs.getInt('pointKey') ?? 0;
  if (!Platform.isAndroid || isTest) {
    return prefBestScore;
  } else {
    "gamesBestScore".debugPrint();
    final isSignedIn = await gamesSignIn();
    if (isSignedIn) {
      try {
        final gamesBestScore = await Player.getPlayerScore(
          androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
          iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
        ) ?? 0;
        "gamesBestScore: $gamesBestScore".debugPrint();
        if (prefBestScore >= gamesBestScore) {
          if (gamesBestScore != 0) gamesSubmitScore(prefBestScore);
          "bestScore: $prefBestScore".debugPrint();
          return prefBestScore;
        } else {
          await "pointKey".setSharedPrefInt(prefs, gamesBestScore);
          "bestScore: $gamesBestScore".debugPrint();
          return gamesBestScore;
        }
      } catch (e) {
        "bestScore: $prefBestScore (Fail to get)".debugPrint();
        return prefBestScore;
      }
    } else {
      "bestScore: $prefBestScore (Can't sign in)".debugPrint();
      return prefBestScore;
    }
  }
}
