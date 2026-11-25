package cl.ahoralocal.ahora_local

import android.content.ActivityNotFoundException
import android.content.Intent
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.CancellationSignal
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var ubicacionPendiente: MethodChannel.Result? = null
    private val permisoUbicacion = 5401

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ahora_local/ubicacion")
            .setMethodCallHandler { call, result ->
                if (call.method != "obtener") {
                    result.notImplemented()
                } else if (ubicacionPendiente != null) {
                    result.error("ocupado", "Ya se está consultando la ubicación", null)
                } else {
                    ubicacionPendiente = result
                    if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                        checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                        consultarUbicacion()
                    } else {
                        requestPermissions(arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION,
                        ), permisoUbicacion)
                    }
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permisoUbicacion) {
            if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                consultarUbicacion()
            } else {
                terminarUbicacion("permiso_denegado", "Permiso de ubicación denegado")
            }
        }
    }

    private fun terminarUbicacion(codigo: String, mensaje: String) {
        ubicacionPendiente?.error(codigo, mensaje, null)
        ubicacionPendiente = null
    }

    private fun consultarUbicacion() {
        try {
            val servicio = getSystemService(LOCATION_SERVICE) as LocationManager
            val permisoPreciso = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            val proveedor = when {
                permisoPreciso && servicio.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
                servicio.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
                else -> {
                    terminarUbicacion("gps_desactivado", "Activa la ubicación del dispositivo")
                    return
                }
            }
            val handler = Handler(Looper.getMainLooper())
            var terminado = false
            val cancelar = CancellationSignal()
            val tiempoLimite = Runnable {
                if (!terminado) {
                    terminado = true
                    cancelar.cancel()
                    terminarUbicacion("sin_senal", "No se obtuvo una posición a tiempo")
                }
            }
            fun entregar(posicion: Location?) {
                if (terminado) return
                terminado = true
                handler.removeCallbacks(tiempoLimite)
                if (posicion == null) {
                    terminarUbicacion("sin_senal", "No se pudo obtener la posición")
                } else {
                    ubicacionPendiente?.success(mapOf(
                        "latitud" to posicion.latitude,
                        "longitud" to posicion.longitude,
                    ))
                    ubicacionPendiente = null
                }
            }
            handler.postDelayed(tiempoLimite, 15000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                servicio.getCurrentLocation(proveedor, cancelar, mainExecutor) { posicion ->
                    entregar(posicion)
                }
            } else {
                @Suppress("DEPRECATION")
                servicio.requestSingleUpdate(proveedor, object : android.location.LocationListener {
                    override fun onLocationChanged(location: Location) {
                        entregar(location)
                    }
                }, Looper.getMainLooper())
            }
        } catch (_: SecurityException) {
            terminarUbicacion("permiso_denegado", "No hay permiso de ubicación")
        } catch (_: Exception) {
            terminarUbicacion("sin_senal", "No se pudo consultar la ubicación")
        }
    }
}
