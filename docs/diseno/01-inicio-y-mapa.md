# Inicio y mapa: referencia vigente

Decisiones del usuario, 2026-10-08. [Boceto](bocetomain.jfif).

## Implementado

Inicio muestra la pregunta «¿Qué quieres hacer hoy?», tarjeta principal Mapa Local y accesos Chat / Tablón y Búsqueda. Barra inferior: Inicio, Mapa, Búsqueda, Chat / Tablón. PrincipalPage centraliza navegación con IndexedStack; crea secciones al abrirlas y conserva estado. Búsqueda utiliza LugaresPage con filtros, paginación y detalle existentes. Mapa/Chat son pantallas provisionales.

## Objetivo acordado

Inicio será la pantalla después del login; hoy abre directamente porque la sesión Flutter no existe. Perfil e icono junto al perfil del boceto no están implementados; significado de ese segundo icono pendiente. Las tarjetas inferiores sin contenido no autorizan funcionalidades nuevas. Logo/colores definitivos pendientes; conservar tema provisional.

Mapa 2D sencillo, inspirado en iconos del radar GTA SA. Usar flutter_map por facilidad; proveedor de fondo pendiente y dependencias aún no añadidas. La propuesta anterior MapLibre + OpenFreeMap no es la elección vigente. Iconos iniciales Material para tienda/comida/cajero/etc.; no hay archivos originales GTA incorporados.

Tocar marcador → tarjeta inferior del negocio → deslizar para ampliar descripción, dirección y horarios. Reutilizar Lugar, repositorio y componentes; estado abierto/cerrado viene del servidor America/Santiago. Datos e identidad del local son propios en Laravel, independientes del proveedor del mapa.

## Coordenadas y captura

Guardar latitud y longitud de la entrada del local, no confundir su orden. Google Maps puede usarse como referencia manual: acercar el mapa, clic derecho sobre la entrada y copiar latitud/longitud; revisar condiciones de la fuente antes de reutilizar datos. No integrar extracción masiva ni APIs de catálogo de negocios por este acuerdo. Verificar el punto en terreno cuando sea posible; GPS y mapas pueden tener error. Coordenadas DEMO son ilustrativas y deben sustituirse por datos reales validados.

## Próximo incremento

Seleccionar proveedor y documentar condiciones/atribución; instalar flutter_map compatible; mostrar tres DEMO con iconos y tarjeta ampliable. Resolver carga de marcadores con API paginada: no asumir que página 1 contiene todo. Después filtros compartidos, ubicación del usuario opcional y cuatro foros con coordenadas verificadas. No se requieren rutas, tráfico ni seguimiento de vehículos.

## Evidencia y límites

Usuario reportó tests de filtros aprobados y navegación real funcionando con Laravel encendido. Cuatro tests móviles existentes; navegación principal/detalle sin cobertura automática. Esta revisión documental no ejecutó Flutter, no implementa el mapa ni prepara release.
