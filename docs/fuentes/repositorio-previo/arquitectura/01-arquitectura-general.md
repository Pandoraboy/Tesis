# Arquitectura general

## Componentes

```text
Flutter
    |
    | HTTPS / JSON
    v
Laravel API
    |
    | Eloquent
    v
MySQL
```

## Flutter

Responsable de:

- Interfaz.
- Navegación.
- Estados.
- Formularios.
- Ubicación.
- Mapas.
- Consumo de API.
- Almacenamiento seguro de token.
- Integración con compras móviles.

## Laravel

Responsable de:

- Validaciones.
- Autenticación.
- Autorización.
- Reglas de negocio.
- Consultas geográficas.
- Moderación.
- Gestión de anuncios.
- Gestión de créditos.
- Verificación de compras.
- Respuestas JSON.

## MySQL

Responsable de almacenar:

- Usuarios.
- Identidades externas.
- Roles.
- Lugares.
- Categorías.
- Horarios.
- Plazas.
- Salas.
- Mensajes.
- Reportes.
- Eventos.
- Anuncios.
- Compras.
- Movimientos de créditos.
