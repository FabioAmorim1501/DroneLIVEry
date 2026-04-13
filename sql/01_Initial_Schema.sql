-- 01_Initial_Schema.sql
-- Modelo Relacional para o Drone Delivery Problem

CREATE TABLE locais (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Base', 'Cliente'))
);

CREATE TABLE drones (
    id VARCHAR(50) PRIMARY KEY, -- MongoDB style ID from external API
    name VARCHAR(100) NOT NULL,
    max_payload_kg DOUBLE PRECISION NOT NULL,
    max_range_km DOUBLE PRECISION NOT NULL, 
    battery_wh DOUBLE PRECISION NOT NULL,
    speed_kmh DOUBLE PRECISION NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available' -- available, in_flight, maintenance
);

CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    local_origem_id INTEGER NOT NULL REFERENCES locais(id),
    local_destino_id INTEGER NOT NULL REFERENCES locais(id),
    peso_liquido DOUBLE PRECISION NOT NULL, -- Peso do pacote (Kg)
    status VARCHAR(20) NOT NULL DEFAULT 'Pendente'
);

CREATE TABLE rotas_paradas (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER NOT NULL REFERENCES pedidos(id),
    drone_id VARCHAR(50) NOT NULL REFERENCES drones(id),
    local_id INTEGER NOT NULL REFERENCES locais(id),
    ordem INTEGER NOT NULL,
    distancia_percorrida DOUBLE PRECISION NOT NULL
);
