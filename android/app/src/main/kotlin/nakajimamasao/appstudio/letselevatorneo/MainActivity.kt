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
        // Use modern WindowCompat approach that works for all Android versions
        // This avoids deprecated APIs completely and provides edge-to-edge support
        
        // Allow content to extend behind system bars
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Configure system bars appearance for better visibility
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
        
        // Handle system insets properly to prevent content overlap
        windowInsetsController.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }
} 