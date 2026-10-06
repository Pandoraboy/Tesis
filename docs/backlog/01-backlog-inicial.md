# Backlog por entregas verificables

Actualizado 2026-10-06. Un incremento en curso; el calendario antiguo no determina avance. Backend validado no equivale a entrega completa si falta su pantalla.

| Entrega | Estado real | Restante |
|---|---|---|
| E0 · Workspace y alcance | Documentación y decisiones de base disponibles | Mantenerlas alineadas con producto |
| E1 · Categorías de extremo a extremo | API, permisos admin y pruebas implementados | Pantallas Flutter y evidencia integrada |
| E2 · Lugares y horarios | API de lugares, búsqueda, filtro, paginación, tramos y estado horario implementados | Lista/detalle Flutter y datos demo |
| E3 · Mapa Android | Flujo acordado | Proveedor, mapa, GPS y marcadores compartiendo capa de datos |
| E4 · Cuentas | Registro/login/me/logout Sanctum y pruebas implementados | Flutter, recuperación y gestión de cuentas |
| E5 · Foros | Nombres confirmados | Coordenadas, API, escritura, moderación y pantallas |
| E6 · Destacados | Alcance administrativo acordado | Solicitudes, aprobación, vencimiento y pruebas |
| E7 · Piloto y tesis | Pendiente | Despliegue, seguridad, respaldo, mediciones y evaluación |

## Incremento en curso: lista pública Flutter de lugares

- [ ] Confirmar corrección de UserFactory, DatabaseSeeder y .env.example.
- [ ] Confirmar Flutter/Android SDK/dispositivo con flutter doctor.
- [ ] Inicializar mobile preservando documentación.
- [ ] Configurar una URL de API adecuada al dispositivo.
- [ ] Crear capa de datos modular y reutilizable para lista y mapa.
- [ ] Mostrar cargando/datos/vacío/error y reintento.
- [ ] Mostrar categoría y estado abierto/cerrado/sin_horarios.
- [ ] Abrir detalle con horarios.
- [ ] Integrar búsqueda, filtro por categoría y paginación.
- [ ] Verificar en Android y registrar evidencia.

## Backend comprobado

- [x] Migraciones y base PostgreSQL exclusiva de pruebas.
- [x] Categorías: lectura activa, creación, edición y desactivación admin.
- [x] Registro con contacto, credenciales, roles protegidos y login de cuenta activa.
- [x] Token Sanctum, identidad y revocación por logout.
- [x] Lugares: CRUD administrativo, búsqueda, filtro, paginación y ocultación de inactivos.
- [x] Horarios: múltiples tramos, validaciones, nocturnos y superposiciones.
- [x] Estado semanal en America/Santiago, límites de apertura/cierre y domingo→lunes.
- [x] JSON de listado/detalle con horarios y estado.

Evidencia reportada: php artisan test, 49 pruebas aprobadas y 169 verificaciones, 2026-10-06. Incluye dos ejemplos de Laravel. No se ha probado integración móvil, concurrencia, producción ni piloto.

## Criterios de siguientes entregas

Mapa: marcadores del API; consulta posible si se deniega GPS; proveedor/licencia documentados. Lista y mapa reutilizan modelos y acceso a datos.

Cuentas: sesión almacenada de forma apropiada, logout, vencimiento y cuenta inactiva; recuperación sin enumeración. No presentar teléfono como recuperable sin un mecanismo real.

Foros: Plaza de Armas, Cementerio, Estación y Alameda; lectura visitante, escritura autenticada activa, rechazo de modificación de autor ajeno y moderación.

Destacados: solicitud no otorga prioridad; aprobación protegida; inicio/fin, mensaje oculto, duplicados y transiciones probados. Al vencer se conserva el mensaje normal.

Piloto: instalación reproducible, HTTPS, restauración en entorno de prueba y evidencia con usuarios reales. No inventar resultados académicos.

Pagos, iOS, ClaveÚnica, eventos, billetera, notificaciones, WebSockets y expansión territorial siguen diferidos. Registrar cualquier cambio de alcance antes de implementarlo.
