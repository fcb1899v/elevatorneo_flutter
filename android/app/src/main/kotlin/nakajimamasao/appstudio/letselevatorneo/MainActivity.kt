package nakajimamasao.appstudio.letselevatorneo

import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity
import com.google.android.gms.games.PlayGamesSdk

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Google Play Games SDK
        PlayGamesSdk.initialize(this)
        
        // Edge-to-edge display support for Android 15+ compatibility
        setupEdgeToEdgeDisplay()
    }
    
    private fun setupEdgeToEdgeDisplay() {
        // Use WindowCompat approach which works for all Android versions
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Configure system bars appearance for better visibility
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
        
        // Handle system insets properly to prevent content overlap
        windowInsetsController.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        
        // For Android 15+, avoid using deprecated APIs completely
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Only set colors on Android 14 and below to avoid deprecation warnings
            try {
                window.statusBarColor = android.graphics.Color.TRANSPARENT
                window.navigationBarColor = android.graphics.Color.TRANSPARENT
            } catch (e: Exception) {
                // Ignore any deprecation warnings for older Android versions
            }
        }
        
        // Let Flutter handle insets automatically - don't interfere with layout
        window.decorView.setOnApplyWindowInsetsListener { view, windowInsets ->
            // Flutter will handle the insets automatically
            windowInsets
        }
    }
} 