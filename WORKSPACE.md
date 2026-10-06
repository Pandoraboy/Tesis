# Workspace operativo

## Base de trabajo

Se reaprovecharon los cinco avances adjuntos y la documentación del repositorio. El cambio de calendario es explícito: avanzar por incrementos terminados, con una sola entrega funcional en curso. No se prometen fechas sin conocer dedicación, fecha límite académica y entorno local.

## Decisiones tomadas de los avances

- Flutter Android, Laravel REST y PostgreSQL.
- Consulta pública de lugares y foros; escritura autenticada.
- Cuatro foros configurables en una sola tabla.
- Usuarios simples: nombre de usuario, contraseña protegida y al menos correo o teléfono.
- Destacado asociado a un mensaje normal; pierde prioridad al vencer y conserva el mensaje.
- Roles `user` y `admin`; administración sencilla.
- Pagos diferidos; validación administrativa para el piloto.

## Propuestas de adaptación

Estas propuestas habilitan el diseño, pero deben confirmarse antes de las migraciones correspondientes: foro temático en vez de plaza obligatoria; un único registro de destacado por mensaje en el MVP; solicitudes con estados; horarios nocturnos y de 24 horas; administración en pantallas Android protegidas; recuperación por correo primero y teléfono pendiente de proveedor. Ver ADR-004 y decisiones abiertas.

## Próxima entrega: E1, categorías de extremo a extremo

1. Revisar alcance y propuestas de E0.
2. Registrar versiones de PHP, Composer, PostgreSQL, Flutter, Dart y Android SDK del equipo de trabajo.
3. Inicializar Laravel en `backend/` y Flutter en `mobile/`, preservando documentación.
4. Configurar PostgreSQL local y una base exclusiva de pruebas.
5. Crear migración y modelo de categoría, validaciones, rutas públicas de lectura y escritura administrativa.
6. Probar éxito, entradas inválidas y permisos en API.
7. Crear pantalla Flutter: inicial, cargando, datos, vacío y error; evento de reintento.
8. Guardar evidencia y actualizar el avance.

Dependencia: la escritura administrativa necesita una identidad administrativa autenticada mínima; no dejar rutas de escritura abiertas para adelantar el CRUD.

## Forma de aprender mientras avanzamos

Cada tarea tendrá propósito, entidades afectadas, flujo petición/respuesta, ubicación del código, ejecución y resultado observado. En Laravel: ruta → autorización/validación → controlador → modelo o servicio justificado → PostgreSQL → JSON. En Flutter: evento → solicitud → estado → vista.

## Comprobación de esta sesión

No se localizaron ejecutables PHP, Composer, Flutter, Dart, PostgreSQL ni Docker en este entorno. La ausencia aquí no determina qué está instalado en el computador del usuario. Este entregable prepara el workspace; no presenta pruebas de ejecución del producto.

## Continuidad

Al cerrar una entrega, completar `docs/validacion/PLANTILLA-EVIDENCIA.md`, marcar solo lo demostrado y registrar el próximo paso. Las fuentes históricas y el SQL candidato no reemplazan las migraciones de Laravel.
