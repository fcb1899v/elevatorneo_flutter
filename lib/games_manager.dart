import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extension.dart';

///Signing in to Game Services
Future<bool> gamesSignIn(bool isGamesSignIn) async {
  if (isGamesSignIn) {
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
Future<void> gamesSubmitScore(int value, bool isGamesSignIn) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final prefBestScore = prefs.getInt('pointKey') ?? 0;
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
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
  if (value > prefBestScore) {
    "bestScore".setSharedPrefInt(prefs, value);
    "bestScore: $value".debugPrint();
  }
}

///Showing games leaderboards
Future<void> gamesShowLeaderboard(bool isGamesSignIn) async {
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
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
Future<int> getBestScore(bool isGamesSignIn) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final prefBestScore = prefs.getInt('pointKey') ?? 0;
  final isSignedIn = (isGamesSignIn) ? isGamesSignIn: await gamesSignIn(isGamesSignIn);
  if (isSignedIn) {
    "gamesBestScore".debugPrint();
    try {
      final gamesBestScore = await Player.getPlayerScore(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
      ) ?? 0;
      "gamesBestScore: $gamesBestScore".debugPrint();
      if (prefBestScore >= gamesBestScore) {
        if (gamesBestScore != 0) gamesSubmitScore(prefBestScore, isGamesSignIn);
        "bestScore: $prefBestScore".debugPrint();
        return prefBestScore;
      } else {
        "pointKey".setSharedPrefInt(prefs, gamesBestScore);
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
