# ADR-001: API como núcleo del sistema

## Estado

Aceptada.

## Decisión

Laravel será el núcleo del sistema y expondrá una API REST consumida por Flutter.

## Motivo

La aplicación necesita centralizar:

- Datos.
- Reglas de negocio.
- Autenticación.
- Moderación.
- Anuncios.
- Créditos.
- Compras.

## Consecuencia

La API será construida y probada con Postman antes de integrar cada módulo en Flutter.
