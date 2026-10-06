# Actores y permisos

| Acción | Visitante | Usuario activo | Administrador activo |
|---|---|---|---|
| Consultar lugares, mapa, horarios y foros | Sí | Sí | Sí |
| Publicar mensaje | No | Sí | Sí |
| Eliminar mensaje propio | No | Sí | Sí |
| Solicitar destacado propio | No | Sí | Sí |
| Aprobar o cancelar destacado | No | No | Sí |
| Gestionar lugares, categorías y horarios | No | No | Sí |
| Ocultar mensaje ajeno | No | No | Sí |
| Gestionar usuarios y cuatro foros | No | No | Sí |

`user` y `admin` son suficientes para el piloto. Cambiar el rol nunca será una operación permitida al usuario sobre su propia cuenta. Cuenta inactiva no puede operar con una sesión anterior.
