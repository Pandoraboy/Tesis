-- =========================================================
-- AHORA LOCAL
-- ESQUEMA CANDIDATO: documento de diseño, NO migración ejecutada
-- PostgreSQL
-- =========================================================

-- =========================================================
-- 1. USUARIOS
-- =========================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,

    username VARCHAR(50) NOT NULL UNIQUE,

    password VARCHAR(255) NOT NULL,

    email VARCHAR(150) UNIQUE,

    phone VARCHAR(20) UNIQUE,

    role VARCHAR(20) NOT NULL DEFAULT 'user',

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_user_role
        CHECK (role IN ('user', 'admin')),

    CONSTRAINT chk_user_contact
        CHECK (NULLIF(TRIM(email), '') IS NOT NULL OR NULLIF(TRIM(phone), '') IS NOT NULL)
);


-- =========================================================
-- 2. CATEGORÍAS DE LUGARES
-- =========================================================

CREATE TABLE categorias_lugar (
    id BIGSERIAL PRIMARY KEY,

    nombre VARCHAR(100) NOT NULL UNIQUE,

    descripcion VARCHAR(255),

    activo BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- 3. LUGARES
-- =========================================================

CREATE TABLE lugares (
    id BIGSERIAL PRIMARY KEY,

    categoria_lugar_id BIGINT NOT NULL,

    nombre VARCHAR(150) NOT NULL,

    descripcion TEXT,

    direccion VARCHAR(255),

    telefono VARCHAR(30),

    latitud DECIMAL(10, 7) NOT NULL CHECK (latitud BETWEEN -90 AND 90),

    longitud DECIMAL(10, 7) NOT NULL CHECK (longitud BETWEEN -180 AND 180),

    activo BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_lugar_categoria
        FOREIGN KEY (categoria_lugar_id)
        REFERENCES categorias_lugar(id)
        ON DELETE RESTRICT
);


-- =========================================================
-- 4. HORARIOS DE LOS LUGARES
-- =========================================================

CREATE TABLE horarios_lugar (
    id BIGSERIAL PRIMARY KEY,

    lugar_id BIGINT NOT NULL,

    dia_semana SMALLINT NOT NULL,

    hora_apertura TIME NOT NULL,

    hora_cierre TIME NOT NULL,

    turno VARCHAR(50),
    cierra_dia_siguiente BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_horario_lugar
        FOREIGN KEY (lugar_id)
        REFERENCES lugares(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_dia_semana
        CHECK (dia_semana BETWEEN 1 AND 7),

    CONSTRAINT chk_horario
        CHECK ((NOT cierra_dia_siguiente AND hora_cierre > hora_apertura)
            OR (cierra_dia_siguiente AND hora_cierre <= hora_apertura))
);


-- =========================================================
-- 5. FOROS
-- =========================================================

CREATE TABLE foros (
    id BIGSERIAL PRIMARY KEY,

    nombre VARCHAR(100) NOT NULL UNIQUE,

    descripcion VARCHAR(255),

    activo BOOLEAN NOT NULL DEFAULT TRUE,

    orden SMALLINT NOT NULL UNIQUE CHECK (orden BETWEEN 1 AND 4),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- 6. MENSAJES
-- =========================================================

CREATE TABLE mensajes (
    id BIGSERIAL PRIMARY KEY,

    foro_id BIGINT NOT NULL,

    user_id BIGINT NOT NULL,

    contenido TEXT NOT NULL,

    activo BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_mensaje_foro
        FOREIGN KEY (foro_id)
        REFERENCES foros(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_mensaje_usuario
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_mensaje_contenido
        CHECK (LENGTH(TRIM(contenido)) > 0)
);


-- =========================================================
-- 7. MENSAJES DESTACADOS
-- =========================================================

CREATE TABLE mensajes_destacados (
    id BIGSERIAL PRIMARY KEY,

    mensaje_id BIGINT NOT NULL UNIQUE,

    fecha_inicio TIMESTAMPTZ,

    fecha_fin TIMESTAMPTZ,

    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',

    tipo VARCHAR(20) NOT NULL DEFAULT 'validacion',
    revisado_por BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    revisado_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_destacado_mensaje
        FOREIGN KEY (mensaje_id)
        REFERENCES mensajes(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_destacado_estado
        CHECK (
            estado IN (
                'pendiente',
                'aprobado',
                'rechazado',
                'cancelado'
            )
        ),

    CONSTRAINT chk_destacado_tipo
        CHECK (
            tipo IN (
                'pago',
                'validacion'
            )
        ),

    CONSTRAINT chk_destacado_fechas
        CHECK ((fecha_inicio IS NULL AND fecha_fin IS NULL)
           OR (fecha_inicio IS NOT NULL AND fecha_fin IS NOT NULL AND fecha_fin > fecha_inicio)),
    CONSTRAINT chk_destacado_aprobado
        CHECK (estado <> 'aprobado' OR
          (fecha_inicio IS NOT NULL AND fecha_fin IS NOT NULL AND revisado_por IS NOT NULL AND revisado_at IS NOT NULL))
);

CREATE INDEX idx_mensajes_foro
    ON mensajes(foro_id);

CREATE INDEX idx_mensajes_usuario
    ON mensajes(user_id);

CREATE INDEX idx_mensajes_fecha
    ON mensajes(created_at DESC);

CREATE INDEX idx_lugares_categoria
    ON lugares(categoria_lugar_id);

CREATE INDEX idx_horarios_lugar
    ON horarios_lugar(lugar_id);

-- mensaje_id ya tiene índice por UNIQUE.

CREATE INDEX idx_destacados_fechas
    ON mensajes_destacados(fecha_inicio, fecha_fin);

-- DEFAULT no actualiza updated_at: mantenerlo desde Eloquent.
-- Pago se reserva en el modelo; su activación está bloqueada en el MVP.
CREATE UNIQUE INDEX idx_users_username_normalizado ON users (LOWER(username));
CREATE UNIQUE INDEX idx_users_email_normalizado ON users (LOWER(email)) WHERE email IS NOT NULL;
CREATE INDEX idx_mensajes_foro_paginacion ON mensajes (foro_id, activo, created_at DESC, id DESC);
