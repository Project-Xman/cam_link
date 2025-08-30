package com.example.photoUploader

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.wifi.WifiManager
import android.content.Intent
import android.provider.Settings
import android.net.ConnectivityManager
import android.net.NetworkInfo
import android.os.Build
import java.lang.reflect.Method
import android.util.Log

class MainActivity: FlutterActivity() {
    private val HOTSPOT_CHANNEL = "com.photoUploader/hotspot"
    private val WIFI_CHANNEL = "com.photoUploader/wifi"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup hotspot method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOTSPOT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isHotspotEnabled" -> {
                    result.success(isHotspotEnabled())
                }
                "startHotspot" -> {
                    val ssid = call.argument<String>("ssid") ?: "PhotoUploader"
                    val password = call.argument<String>("password") ?: "PhotoUpload123"
                    val security = call.argument<String>("security") ?: "WPA2"
                        result.success(startHotspot(ssid, password, security))
                }
                "stopHotspot" -> {
                    result.success(stopHotspot())
                }
                "getConnectedDevices" -> {
                    result.success(getConnectedDevices())
                }
                "supportsSimultaneous" -> {
                    result.success(supportsSimultaneous())
                }
                "isSupported" -> {
                    result.success(isHotspotSupported())
                }
                "openHotspotSettings" -> {
                    openHotspotSettings()
                    result.success(true)
                }
                "getDeviceLimitations" -> {
                    result.success(getDeviceLimitations())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup WiFi method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIFI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableWifi" -> {
                    result.success(enableWifi())
                }
                "disableWifi" -> {
                    result.success(disableWifi())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isHotspotEnabled(): Boolean {
        return try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val method: Method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
            method.isAccessible = true
            method.invoke(wifiManager) as Boolean
        } catch (e: Exception) {
            Log.e("HotspotService", "Error checking hotspot status", e)
            false
        }
    }
    
    private fun startHotspot(ssid: String, password: String, security: String): Boolean {
        return try {
            // For Android 8.0+ (API 26+), we need to use different approach
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // On newer Android versions, we can only request the user to enable hotspot
                Log.i("HotspotService", "Android 8.0+ detected, opening settings for manual setup")
                openHotspotSettings()
                // Indicate the hotspot could not be started programmatically on this Android version
                return false
            } else {
                // For older versions, try reflection (may not work on all devices)
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                
                // Try to disable WiFi first if it's enabled (for non-simultaneous devices)
                if (wifiManager.isWifiEnabled && !supportsSimultaneous()) {
                    Log.i("HotspotService", "Disabling WiFi for hotspot on non-simultaneous device")
                    wifiManager.isWifiEnabled = false
                    Thread.sleep(2000) // Wait for WiFi to disable
                }
                
                val method: Method = wifiManager.javaClass.getDeclaredMethod("setWifiApEnabled", null, Boolean::class.javaPrimitiveType)
                method.isAccessible = true
                val result = method.invoke(wifiManager, null, true) as Boolean
                Log.i("HotspotService", "Legacy hotspot start result: $result")
                result
            }
        } catch (e: Exception) {
            Log.e("HotspotService", "Error starting hotspot", e)
            // Fallback to opening settings when programmatic control fails
            openHotspotSettings()
            false
        }
    }
    
    private fun stopHotspot(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // On newer Android versions, we can only request the user to disable hotspot
                Log.i("HotspotService", "Android 8.0+ detected, opening settings for manual disable")
                openHotspotSettings()
                // Indicate the hotspot could not be stopped programmatically on this Android version
                return false
            } else {
                // For older versions, try reflection
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val method: Method = wifiManager.javaClass.getDeclaredMethod("setWifiApEnabled", null, Boolean::class.javaPrimitiveType)
                method.isAccessible = true
                val result = method.invoke(wifiManager, null, false) as Boolean
                Log.i("HotspotService", "Legacy hotspot stop result: $result")
                result
            }
        } catch (e: Exception) {
            Log.e("HotspotService", "Error stopping hotspot", e)
            // Fallback to opening settings when programmatic control fails
            openHotspotSettings()
            false
        }
    }
    
    private fun enableWifi(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ doesn't allow programmatic WiFi control
                Log.i("WiFiService", "Android 10+ detected, opening WiFi settings")
                val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
                false
            } else {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val result = wifiManager.setWifiEnabled(true)
                Log.i("WiFiService", "WiFi enable result: $result")
                result
            }
        } catch (e: Exception) {
            Log.e("WiFiService", "Error enabling WiFi", e)
            false
        }
    }
    
    private fun disableWifi(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ doesn't allow programmatic WiFi control
                Log.i("WiFiService", "Android 10+ detected, opening WiFi settings")
                val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
                false
            } else {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val result = wifiManager.setWifiEnabled(false)
                Log.i("WiFiService", "WiFi disable result: $result")
                result
            }
        } catch (e: Exception) {
            Log.e("WiFiService", "Error disabling WiFi", e)
            false
        }
    }
    
    private fun getConnectedDevices(): List<Map<String, Any>> {
        // Note: Getting connected devices requires system permissions that regular apps don't have
        // This is a placeholder implementation
        return emptyList()
    }
    
    private fun supportsSimultaneous(): Boolean {
        // Most modern Android devices support simultaneous WiFi and hotspot
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.N // Android 7.0+
    }
    
    private fun isHotspotSupported(): Boolean {
        return try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiManager != null
        } catch (e: Exception) {
            false
        }
    }
    
    private fun openHotspotSettings() {
        try {
            val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("HotspotService", "Error opening hotspot settings", e)
        }
    }
    
    private fun getDeviceLimitations(): Map<String, Any> {
        return mapOf(
            "maxConnectedDevices" to 8, // Most devices support up to 8 connections
            "supportsSimultaneous" to supportsSimultaneous(),
            "supportedSecurityTypes" to listOf("WPA2", "WPA3"),
            "requiresSettings" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
        )
    }
}

