# Continuidad: calidad de vida en validación

Fecha 2026-11-04. Base publicada revisada de00404, más estabilización que el usuario aplicó y reportó con 97 pruebas Flutter aprobadas. PerfilApiTest: 12 pruebas/49 aserciones previamente reportadas. Recorrido reciente y suite backend completa no confirmados.

Actualización QoL preparada después: Atrás Android, confirmación de descarte en formularios, comprobación de escrituras inciertas, conservación del contenido al refrescar, reanudación de pantalla visible, cierre local opcional tras fallo remoto, cabecera única, filtros/resultados desplazables, contexto de consulta, mapa táctil/leyenda/errores de fondo y copia de datos.

16 casos nuevos integrados. Validación Linux aislada con Flutter 3.47.7/Dart 3.13.5: formato, lockfile preservado, analyze sin incidencias y 113 pruebas aprobadas. Backend y emulador no ejecutados. [Evidencia](docs/validacion/2026-11-04-ejecucion-qol.md). Procedimiento, correspondencia Q01–Q14 y límites: [validación QoL](docs/validacion/2026-11-04-calidad-de-vida.md).

## Al retomar

1. Aplicar paquete acumulativo sobre la versión ya estabilizada.
2. Las comprobaciones Flutter ya aprobaron en Linux; al integrar localmente comprobar analyze y flutter test con la configuración del proyecto.
3. Recorrido Android con backend real: Atrás, borradores, refresco fallido, teclado/texto grande, perfil y cierre local sin red.
4. Confirmar H1 de vínculo Google al mismo ID. Después continuar chats Android sobre API existente y luego contacto wa.me con permiso vigente comprobado en servidor.

No repetir catálogo, edición o perfil. Cuentas locales/Google, visitante, directorio, importación OSM, alta/edición admin, mapa completo/grupos y contacto privado ya están implementados. Chats móviles y contacto ajeno/apertura WhatsApp aún pendientes. Moderador/propietario, cupos, denuncias, timeouts y tickets son requisitos futuros.

## Límites

No hay idempotencia para altas ni concurrencia por versiones; el reenvío exige comprobación humana pero no garantiza ausencia de duplicados. No hay caché persistente ni modo offline. Renovar al reanudar no implica recalcular horarios en Flutter ni refresco continuo. API HTTPS, firma/OAuth y prueba de release siguen pendientes; INTERNET principal incluido.

Sin backend funcional, migraciones, dependencias, credenciales o datos modificados. Sin commit/push. Conservar envs, lockfiles y parámetros Google/API. Desarrollo ahora_local; pruebas exclusivas/descartables ahora_local_test.
