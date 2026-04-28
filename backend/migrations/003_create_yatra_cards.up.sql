CREATE TABLE IF NOT EXISTS yatra_cards (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pnr VARCHAR(20) NOT NULL,
    train_number VARCHAR(10) NOT NULL,
    boarding_station_id BIGINT NOT NULL REFERENCES stations(id),
    destination_station_id BIGINT NOT NULL REFERENCES stations(id),
    berth_info VARCHAR(50) DEFAULT '',
    journey_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'upcoming',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS train_status_cache (
    train_number VARCHAR(10) PRIMARY KEY,
    current_lat DOUBLE PRECISION NOT NULL DEFAULT 0,
    current_lon DOUBLE PRECISION NOT NULL DEFAULT 0,
    delay_minutes INTEGER NOT NULL DEFAULT 0,
    last_fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS breadcrumbs (
    id BIGSERIAL PRIMARY KEY,
    yatra_id BIGINT NOT NULL REFERENCES yatra_cards(id) ON DELETE CASCADE,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    snapped_lat DOUBLE PRECISION NOT NULL DEFAULT 0,
    snapped_lon DOUBLE PRECISION NOT NULL DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_yatra_cards_user ON yatra_cards(user_id);
CREATE INDEX idx_yatra_cards_status ON yatra_cards(status);
CREATE INDEX idx_breadcrumbs_yatra ON breadcrumbs(yatra_id);
