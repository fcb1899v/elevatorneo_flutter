package nakajimamasao.appstudio.letselevatorneo

import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import com.google.android.gms.games.PlayGamesSdk

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Google Play Games SDK
        PlayGamesSdk.initialize(this)
        
        // Edge-to-edge display support for Android 15+ compatibility
        // FlutterActivityではenableEdgeToEdge()の代わりにWindowCompatを使用
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Configure system bars appearance for better visibility
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
    }
} 