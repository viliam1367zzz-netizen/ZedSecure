package com.zedsecure.vpn

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VPN_CONTROL_CHANNEL = "com.zedsecure.vpn/vpn_control"
    private var vpnControlChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        PingMethodChannel.registerWith(flutterEngine, context)
        AppListMethodChannel.registerWith(flutterEngine, context)
        SettingsMethodChannel.registerWith(flutterEngine, context)
        
        vpnControlChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CONTROL_CHANNEL)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "FROM_DISCONNECT_BTN") {
            vpnControlChannel?.invokeMethod("disconnectFromNotification", null)
        }
    }
}
