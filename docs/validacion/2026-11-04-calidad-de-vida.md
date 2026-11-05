# Calidad de vida: navegación, recuperación y claridad

Preparado el 4 de noviembre de 2026. Base: de00404 más estabilización aplicada por el usuario. El usuario reportó 97 pruebas Flutter aprobadas de esa versión; PerfilApiTest había aprobado 12 casos/49 aserciones. Este paquete añade cambios posteriores, ejecutados y corregidos en un entorno Linux aislado: 113 pruebas aprobadas y flutter analyze sin incidencias. Ver [evidencia de ejecución](2026-11-04-ejecucion-qol.md).

## Flujos preparados

| Tema del análisis | Implementación candidata | Límite |
|---|---|---|
| Q01 Atrás Android | NavigatorPopHandler delega al navegador de sesión; desde una sección principal vuelve a Inicio | Gesto/teclado requieren recorrido Android |
| Q02 Borradores | SalidaConCambios pregunta solo con cambios; aplicado a lugares, contacto y registros local/Google | Borradores en memoria, sin persistir datos personales |
| Q03 Guardado incierto | Bloquea reenvío; edición consulta y compara por ID; alta abre Búsqueda conservando borrador y requiere confirmación para habilitar otro intento | No ofrece idempotencia de servidor ni deduplicación por nombre |
| Q04 Refresco fallido | Conserva último listado/ficha de la misma consulta ante fallo de conexión; aviso y reintento | 401/403/404 no se ocultan como fallo de red |
| Q05 Antigüedad | Pantalla visible comprueba al reanudar o activarse tras al menos un minuto; muestra hora de consulta en lista/mapa | No hay sondeo periódico ni cálculo horario en Flutter |
| Q06 Cierre sin red | Tras fallo remoto ofrece cierre de este dispositivo; éxito solo si se borra almacenamiento | No confirma revocación remota; otros dispositivos no cambian |
| Q07 Espacio | Una cabecera por sección y acceso a cuenta conservado; filtros/resultados se desplazan juntos | Pendiente emulador, texto grande y teclado real |
| Q08 Contexto | PageStorageKey por consulta/página conserva desplazamiento; cámara y filtros continúan | Una consulta distinta tiene identidad distinta |
| Q09 Mapa | Ayuda visible, semántica de botón y área táctil 48 sin agrandar pines 22/28 | Validar TalkBack/gestos |
| Q10 Filtros | Avisa si el texto no fue aplicado; vacío filtrado con acción Limpiar filtros | Sin búsqueda automática ni nuevas peticiones por tecla |
| Q11 Vocabulario | Buscar lugares; dirección no informada resumida en tarjeta | Dato original y atribución OSM intactos |
| Q12 Errores | Muestra primer campo inválido; 403 permite actualizar cuenta; 404 contextual con vuelta/refresco; sesión vencida explicada | Regla de permisos permanece en servidor |
| Q13 Fondo mapa | Aviso separado de imágenes y reintento del fondo, conservando catálogo | Sin descarga masiva/offline ni cambio de proveedor |
| Q14 Copia | Copiar dirección informada, ubicación válida y teléfono desde detalle | No contacta negocios ni envía mensajes |

El selector de ubicación abre con zoom de detalle cuando ya hay punto. Se protegió además el respaldo del detalle para que una consulta anterior a la edición no reemplace el lugar actualizado.

## Estados y responsabilidades

Los controladores/repositories existentes siguen coordinando sesión y HTTP. Los widgets compartidos son pequeños: salida con borrador, actualización al reanudar, contenido con estado de refresco y acercamiento al primer error de formulario. No se añade un framework de estado ni paquetes.

La navegación autenticada y visitante sigue separada. Los diálogos de estos flujos pertenecen al navegador de sesión para retirarse con él. Atrás del sistema pasa por maybePop, respetando los bloqueos/confirmaciones de la pantalla. Durante envío se conserva el bloqueo de salida y doble pulsación.

El cierre normal conserva su comportamiento anterior. La salida local es una opción explícita tras fallo: elimina credencial y memoria si el almacenamiento lo permite. Si falla ese borrado, no anuncia cierre. El permiso en el servidor, la validez del token y la expiración remota siguen rigiéndose por Laravel/Sanctum.

## Cómo aplicar

Paquete acumulativo sobre de00404, que también incluye la estabilización anterior. Copiar sus carpetas y documentos raíz sobre el proyecto actual. No reemplaza .env, credenciales, pubspec/composer ni lockfiles. Backend contiene solamente documentación actualizada.

No requiere migraciones, importaciones o dependencias nuevas. Conservar parámetros Google/API del comando habitual de flutter run.

Desde mobile:

```powershell
dart format lib/core/widgets lib/core/session lib/core/navigation lib/features/lugares/presentation lib/features/mapa/presentation lib/features/perfil/presentation lib/features/auth/presentation/register_page.dart lib/features/auth/presentation/google_register_page.dart test/calidad_vida_test.dart test/lugar_editar_test.dart test/agrupacion_mapa_test.dart test/visitante_test.dart
flutter analyze
flutter test test/calidad_vida_test.dart
flutter test test/lugar_editar_test.dart
flutter test test/agrupacion_mapa_test.dart
flutter test test/visitante_test.dart
flutter test
```

El formato se limita a las zonas afectadas; revisar su diff antes de Git. Los archivos específicos verifican cambios de este paquete y la suite comprueba regresión. La ejecución aislada de esta versión aprobó 113 casos; una versión distinta puede tener otra cifra.

## Pruebas preparadas

16 casos nuevos respecto de las 97 anteriores:

- calidad_vida_test.dart: 12 casos (Atrás autenticado, protección del borrador de lugar, alta incierta, listado conservado, ficha conservada/404, filtros sin mezcla, borrador de contacto, cierre local, fallo de almacenamiento, copia, reanudación activa y pantalla pequeña con teclado/texto grande).
- lugar_editar_test.dart: un caso de PATCH guardado con respuesta perdida, confirmado después por GET sin repetir escritura. El caso anterior de cancelación ahora confirma Descartar y salir, acorde con la protección añadida.
- agrupacion_mapa_test.dart: dos casos para área táctil/pin y fallo/reintento del fondo sin retirar lugares.
- visitante_test.dart: un caso de Atrás del sistema desde detalle público.

Las pruebas de logout normal permanecen: cambiar la experiencia ofreciendo una alternativa local no convierte automáticamente un logout fallido en éxito remoto. Los tests HTTP usan respuestas simuladas y los de mapa usan teselas locales.

## Evidencia de ejecución

Flutter 3.47.7 / Dart 3.13.5 instalados en una copia aislada con el paquete aplicado. Formato de los archivos afectados, resolución con lockfile preservado, analyze sin incidencias y suite completa de **113 pruebas aprobadas**. Se corrigieron errores asíncronos al refrescar y un desborde de horario con texto grande, además de ajustar fixtures y navegación de las pruebas. [Resultados, comandos y límites](2026-11-04-ejecucion-qol.md).

No se ejecutaron backend ni emulador Android. El recorrido siguiente sigue pendiente.

## Recorrido manual al volver

1. Con cuenta admin, Búsqueda → detalle → editar. Cambiar nombre y volver por botón/gesto Android: Seguir editando conserva; Descartar y salir vuelve sin PATCH. Repetir desde visitante con detalle público y comprobar que Atrás lleva a Inicio desde Búsqueda.
2. Guardar edición y alta normales; confirmar actualización de lista/mapa. Comprobar copia de dirección/ubicación/teléfono cuando existan.
3. Tras una carga correcta, interrumpir red y pulsar Actualizar: lista/ficha permanecen y aparece aviso; primera carga sin red ofrece reintento sin fingir datos.
4. Probar pérdida de respuesta con mocks de los archivos específicos. En alta real incierta, revisar Búsqueda antes de habilitar otro intento; nunca considerar una coincidencia de nombre como identidad garantizada.
5. Mi cuenta: cambiar número/permiso, volver y cancelar/descarte. Guardar normalmente y comprobar persistencia con backend real.
6. Cerrar sesión sin red: cancelación conserva; cierre local confirmado retira cuenta de este dispositivo, sin afirmar revocación del servidor.
7. Dejar app en segundo plano más de un minuto y volver a Búsqueda/Mapa: comprobar refresco de la sección visible y cámara/filtros. No hay actualizaciones por segundo ni descarga masiva.
8. Pantalla 320/360 de ancho, teclado, escala de texto 1,3 y 2,0. Comprobar que controles sean alcanzables y que TalkBack identifique pines/grupos.
9. Repetir login Google y recorrido H1 pendiente al mismo ID. No ampliar a chats hasta validar esta actualización.

## Límites que permanecen

- Las 113 pruebas aprobadas no sustituyen el recorrido Android ni garantizan ausencia total de errores.
- Conservación en memoria durante esta navegación; no incorpora caché persistente ni modo offline.
- Una alta puede duplicarse si se vuelve a enviar después de revisar/confirmar: garantía completa exige idempotencia backend separada.
- Última escritura administrativa prevalece: sin control de versiones entre dispositivos.
- Horario se renueva al consultar/reanudar, no se promete cambio exacto mientras una pantalla queda abierta indefinidamente.
- Siguen pendientes HTTPS, firma/OAuth release, prueba de APK, recuperación de acceso, precisión de datos OSM y módulos restantes. INTERNET principal ya está incluido, pero no completa release.
- Sin cambios funcionales backend, esquema, paquetes, credenciales o datos. Sin commit/push.

Referencias de implementación: [NavigatorPopHandler](https://api.flutter.dev/flutter/widgets/NavigatorPopHandler-class.html), [validateGranularly](https://api.flutter.dev/flutter/widgets/FormState/validateGranularly.html) y [errorTileCallback de flutter_map 8.3.2](https://pub.dev/documentation/flutter_map/latest/flutter_map/ErrorTileCallBack.html). En perfil, reanudar comprueba la cuenta y conserva el borrador del contacto; no sobrescribe el número con una consulta automática.
