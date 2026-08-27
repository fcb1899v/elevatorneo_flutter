package nakajimamasao.appstudio.letselevatorneo

import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import com.google.android.gms.games.PlayGamesSdk

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Must run before super.onCreate() per Play Games SDK v2 docs
        PlayGamesSdk.initialize(this)
        super.onCreate(savedInstanceState)
        setupEdgeToEdgeDisplay()
    }
    
    private fun setupEdgeToEdgeDisplay() {
        // Draw behind the system bars.
        //
        // This is what puts the app edge to edge on API 24 through 34. From
        // API 35 the platform does it on its own and Window#setDecorFitsSystemWindows
        // is deprecated and has no effect, so the call below is a no-op there --
        // keep it anyway, or older devices lose edge to edge entirely.
        //
        // Google's replacement, enableEdgeToEdge(), is an extension on
        // ComponentActivity and cannot be used here: FlutterActivity extends
        // android.app.Activity (FlutterActivity.java:211). Reaching it would mean
        // moving to FlutterFragmentActivity, which is not worth it while the
        // display is correct on device.
        //
        // Flutter handles the insets: main.dart sets SystemUiMode.edgeToEdge and
        // the screens wrap their content in SafeArea.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Configure system bars appearance for better visibility
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
        
        // Handle system insets properly to prevent content overlap
        windowInsetsController.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }
} 