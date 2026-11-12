package nakajimamasao.appstudio.letselevatorneo

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.games.PlayGamesSdk

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Must run before super.onCreate() per Play Games SDK v2 docs
        PlayGamesSdk.initialize(this)
        super.onCreate(savedInstanceState)
        setupEdgeToEdgeDisplay()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Store promo channel: checks the ADVENTURE install and opens the Play inline install.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORE_PROMO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isInstalled" -> result.success(isPackageInstalled(ADVENTURE_PACKAGE))
                    "openPlay" -> result.success(openPlay(call.argument<String>("url")))
                    else -> result.notImplemented()
                }
            }
    }

    private fun isPackageInstalled(target: String): Boolean {
        return try {
            packageManager.getPackageInfo(target, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    // Returns false when no activity can take the intent, so Dart can fall back to a URL.
    private fun openPlay(url: String?): Boolean {
        if (url == null) return false
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse(url)
            setPackage("com.android.vending")
            putExtra("overlay", true)
            putExtra("callerId", this@MainActivity.packageName)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
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

    companion object {
        // Same name as the Dart side in lib/promo.
        private const val STORE_PROMO_CHANNEL = "nakajimamasao.appstudio/store_promo"
        private const val ADVENTURE_PACKAGE = "nakajimamasao.appstudio.elevator3d"
    }
} 