# Ahora San Carlos

Aplicación móvil orientada a la comunidad de San Carlos. Permitirá consultar puntos de interés cercanos, revisar información útil de la ciudad y participar en chats territoriales vinculados a cuatro plazas.

El proyecto será desarrollado como tesis entre agosto y diciembre de 2026.

## Estado

**Etapa actual:** análisis, definición de alcance y preparación técnica.

## Objetivo general

Desarrollar una aplicación móvil multiplataforma para Android e iOS que permita consultar información local de San Carlos, visualizar puntos de interés cercanos y participar en espacios de conversación territorial.

## Funciones principales

### Acceso público

- Consultar lugares sin iniciar sesión.
- Ver puntos de interés cercanos.
- Ver la farmacia abierta más cercana.
- Ver el cajero disponible más cercano.
- Revisar actividades y anuncios vigentes.
- Leer los chats de las plazas.

### Usuarios registrados

- Crear una cuenta.
- Iniciar sesión.
- Configurar un apodo público.
- Escribir en los chats.
- Publicar anuncios.
- Comprar y utilizar créditos.
- Reportar contenido inapropiado.

### Administración

- Gestionar categorías y lugares.
- Gestionar horarios.
- Moderar chats.
- Revisar anuncios.
- Aprobar o rechazar publicaciones.
- Gestionar sanciones y reportes.

## Chats territoriales

La aplicación tendrá cuatro chats públicos representados en un mapa de San Carlos. Cada chat estará vinculado a una plaza.

Los usuarios podrán ingresar a cualquiera de los cuatro chats, sin importar su ubicación actual.

## Monetización

Los usuarios podrán comprar créditos mediante Google Play o Apple In-App Purchase. Los créditos se utilizarán para publicar anuncios dentro de la aplicación.

La plataforma no almacenará datos de tarjetas ni procesará pagos directamente. Laravel validará las compras y mantendrá el historial de créditos.

## Tecnologías

### Backend

- PHP
- Laravel
- MySQL
- API REST
- Laravel Sanctum

### Aplicación móvil

- Flutter
- Dart
- Android
- iOS

### Herramientas

- Git y GitHub
- Postman
- Composer
- Android Studio
- Xcode
- MySQL Workbench o phpMyAdmin

## Arquitectura general

```text
Aplicación Flutter
        |
        | HTTPS / JSON
        v
API REST Laravel
        |
        | Eloquent ORM
        v
Base de datos MySQL
```

## Estructura del repositorio

```text
ahora-san-carlos/
├── backend/
├── mobile/
├── docs/
│   ├── arquitectura/
│   ├── requisitos/
│   ├── decisiones/
│   └── backlog/
├── .github/
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

## Alcance inicial

La primera versión incluirá:

- Visualización de lugares.
- Categorías: tiendas, plazas, cajeros y farmacias.
- Horarios de atención.
- Ubicación del usuario.
- Resultados cercanos.
- Cuatro chats territoriales.
- Registro e inicio de sesión local.
- Moderación básica.
- Eventos y anuncios.
- Billetera de créditos.
- Integración preparada para Android e iOS.

## Fuera del alcance inicial

- Delivery.
- Pedidos.
- Seguimiento de repartidores.
- Pagos directos a comercios.
- Mensajes privados.
- Expansión a otras comunas.
- Publicidad automatizada.
- Subastas de anuncios.

## Plan general

### Agosto

- Requisitos.
- Actores.
- Procesos.
- Reglas de negocio.
- Modelo entidad-relación.
- Modelo relacional.
- Arquitectura.

### Septiembre

- Backend Laravel.
- Base de datos.
- Categorías.
- Lugares.
- Horarios.
- Autenticación.

### Octubre

- Flutter.
- Inicio.
- Ubicación.
- Lugares cercanos.
- Mapa.

### Noviembre

- Chats.
- Eventos.
- Anuncios.
- Créditos.
- Moderación.

### Diciembre

- Pruebas.
- Correcciones.
- Documentación.
- Presentación de tesis.

## Convención de commits

```bash
docs: define alcance inicial
docs: agrega requisitos funcionales
feat: crea modulo de categorias
feat: implementa consulta de lugares cercanos
fix: corrige validacion de horarios
test: agrega pruebas de autenticacion
```

## Autor

**Proyecto:** Ahora San Carlos  
**Tipo:** Tesis  
**Período:** Agosto a diciembre de 2026
