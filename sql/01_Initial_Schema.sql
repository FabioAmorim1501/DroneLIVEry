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
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    payload_maximo DOUBLE PRECISION NOT NULL, -- Capacidade de Peso (Kg)
    autonomia_km DOUBLE PRECISION NOT NULL,   -- Bateria/Distância (Km)
    velocidade_kmh DOUBLE PRECISION NOT NULL  -- Velocidade (Km/h)
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
    drone_id INTEGER NOT NULL REFERENCES drones(id),
    local_id INTEGER NOT NULL REFERENCES locais(id),
    ordem INTEGER NOT NULL,
    distancia_percorrida DOUBLE PRECISION NOT NULL
);
