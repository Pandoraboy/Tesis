package cl.ahoralocal.ahora_local

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ahora_local/enlace_externo")
            .setMethodCallHandler { call, result ->
                if (call.method != "abrir") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                val uri = url?.let { Uri.parse(it) }
                if (uri?.scheme != "https" || uri.host != "wa.me" ||
                    uri.port != -1 || uri.userInfo != null || uri.query != null || uri.fragment != null ||
                    !Regex("/[1-9][0-9]{7,14}").matches(uri.path.orEmpty())) {
                    result.error("enlace_invalido", "Enlace de contacto no permitido", null)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, uri))
                    result.success(null)
                } catch (_: ActivityNotFoundException) {
                    result.error("sin_aplicacion", "No hay una aplicación para abrir el enlace", null)
                }
            }
    }
}
