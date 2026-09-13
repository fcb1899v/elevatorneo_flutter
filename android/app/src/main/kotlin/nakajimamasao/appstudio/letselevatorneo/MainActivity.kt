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
        // Edge to edge on API 24-34; a no-op from 35 but keep it, or 24-34 lose it.
        // enableEdgeToEdge() needs ComponentActivity; FlutterActivity is not one.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Configure system bars appearance for better visibility
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
        
        // Handle system insets properly to prevent content overlap
        windowInsetsController.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }
} 