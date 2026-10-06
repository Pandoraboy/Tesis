# Backlog por entregas

Un incremento en curso. Cada entrega debe tener API validada, pantalla cuando corresponde y evidencia. No usar el calendario anterior como indicador de avance.

| Entrega | Resultado | Dependencias | Estado |
|---|---|---|---|
| E0 | Workspace, alcance conciliado, modelo y contratos candidatos | Cinco avances y repo | Documentación lista; revisar propuestas |
| E1 | Categorías Laravel → PostgreSQL → Flutter y acceso admin mínimo | E0, entorno y autenticación mínima | Pendiente |
| E2 | Lugares, contactos, filtros, búsqueda y horarios | E1 | Pendiente |
| E3 | Mapa Android y detalle desde datos reales del API | E2, proveedor de mapa | Pendiente |
| E4 | Registro, sesión, recuperación y perfiles mínimos completos | Base auth E1 | Pendiente |
| E5 | Cuatro foros, publicación propia y moderación | E4 | Pendiente |
| E6 | Solicitud y aprobación de destacados con vencimiento | E5 | Pendiente |
| E7 | Despliegue, seguridad, carga, piloto y tesis | E1–E6 | Pendiente |

## E1, siguiente trabajo concreto

- [ ] Registrar entorno y versiones compatibles.
- [ ] Inicializar proyectos y base de pruebas.
- [ ] Crear autenticación administrativa mínima y permiso servidor.
- [ ] Migración categorías y seed demo claramente identificado.
- [ ] Lectura pública, escritura admin, validaciones y desactivación.
- [ ] Probar 200/201, 401/403, 422 y exclusión de inactivos.
- [ ] Flutter con cargando/datos/vacío/error/reintento.
- [ ] Evidencia API y pantalla, documentación y commit.

## Aceptación por entrega

E2: categoría activa, coordenadas válidas, búsqueda, filtro y horarios incluidos; casos nocturnos/desconocidos probados si propuesta aceptada.
E3: marcadores coinciden con API; permiso GPS denegado no impide consultar mapa; fuente/licencia del mapa documentada.
E4: username/contacto válidos, contraseña protegida, sesión revocable, recuperación sin enumeración; teléfono no presentado como recuperable sin mecanismo real.
E5: cuatro foros, lectura visitante, escritura autenticada, rechazo de autor ajeno y moderación.
E6: solicitud sin prioridad, aprobación protegida, tiempo antes/inicio/fin, mensaje oculto, estados terminales y duplicados probados.
E7: reproducir instalación, HTTPS, restauración de respaldo en entorno de prueba, medición RNF y evaluación con usuarios reales. No inventar evidencia académica.

## Lo diferido no bloquea el piloto

Pagos, iOS, ClaveÚnica, eventos, billetera, notificaciones, WebSockets y expansión territorial. Si cambia el alcance académico, registrar la decisión y ajustar backlog antes de implementarlo.
