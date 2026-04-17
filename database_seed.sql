-- ==============================================================================
-- DRONELIVERY INITIAL DATABASE SEED SCRIPT
-- ==============================================================================
-- Utilize este arquivo para criar a tabela principal no seu cluster PostgreSQL
-- através do PGAdmin ou DBeaver para o Database "dronedelivery_db".
-- ==============================================================================

CREATE TABLE IF NOT EXISTS drones (
    id VARCHAR(24) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    max_payload_kg NUMERIC(10,2) NOT NULL,
    max_range_km NUMERIC(10,2) NOT NULL,
    battery_wh NUMERIC(10,2) NOT NULL,
    speed_kmh NUMERIC(10,2) NOT NULL,
    image_url VARCHAR(512),
    status VARCHAR(50) DEFAULT 'available'
);

-- ==============================================================================
-- EXTRAÇÃO DE DADOS MOCKADOS ORIGINAIS ("dronelivery.cgriff.dev")
-- ==============================================================================
INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) VALUES
('69dc1e4e5f546b415c37c859', 'DJI Agras T10', 10.0, 7.0, 1000.0, 54.0, 'https://dronelivery-express.cgriff.dev/drones/dji_agras_t10.png', 'available')
ON CONFLICT (id) DO NOTHING;

INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) VALUES
('69dc1e4e5f546b415c37c85a', 'Zipline P2 Zip', 1.75, 160.0, 3200.0, 128.0, 'https://dronelivery-express.cgriff.dev/drones/zipline_p2_zip.png', 'available')
ON CONFLICT (id) DO NOTHING;

INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) VALUES
('69dc1e4e5f546b415c37c85b', 'Wing Hummingbird', 1.5, 12.0, 800.0, 110.0, 'https://dronelivery-express.cgriff.dev/drones/wing_hummingbird.png', 'available')
ON CONFLICT (id) DO NOTHING;

INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) VALUES
('69dc1e4e5f546b415c37c85c', 'Amazon Prime Air MK27', 2.27, 24.0, 1600.0, 120.0, 'https://dronelivery-express.cgriff.dev/drones/amazon_prime_air_mk27.png', 'available')
ON CONFLICT (id) DO NOTHING;

INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) VALUES
('69dc1e4e5f546b415c37c85d', 'Flytrex Core 2', 3.0, 50.0, 2400.0, 80.0, 'https://dronelivery-express.cgriff.dev/drones/flytrex_core_2.png', 'maintenance')
ON CONFLICT (id) DO NOTHING;

INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) VALUES
('69dc1e4e5f546b415c37c85e', 'Matternet M2', 2.0, 20.0, 1200.0, 36.0, 'https://dronelivery-express.cgriff.dev/drones/matternet_m2.png', 'available')
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- DISTANCES AND LOCATIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS locations (
    id VARCHAR(24) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude NUMERIC(10,6) NOT NULL,
    longitude NUMERIC(10,6) NOT NULL,
    loc_type VARCHAR(20) NOT NULL
);

INSERT INTO locations (id, name, latitude, longitude, loc_type) VALUES
('base_hangar_01', 'Praça da Sé, São Paulo SP', -23.550520, -46.633308, 'base')
ON CONFLICT (id) DO NOTHING;
