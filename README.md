# Sahayatri

**Your Indian Railways Travel Companion** — an offline-first mobile application that automates journey tracking, provides real-time train status, GPS-based arrival alerts, and family live-sharing.

## Project Structure

```
sahayatri/
├── backend/          # Go backend (Gin + PostgreSQL + Redis)
│   ├── cmd/server/   # Application entry point
│   ├── internal/
│   │   ├── api/      # HTTP handlers & router
│   │   ├── models/   # Data models
│   │   ├── store/    # PostgreSQL repository layer
│   │   ├── cache/    # Redis cache layer
│   │   ├── auth/     # JWT authentication
│   │   ├── scheduler/# Cron jobs (train/PNR status refresh)
│   │   ├── ws/       # WebSocket hub for family sharing
│   │   └── shapefile/# GeoJSON track data loader
│   ├── migrations/   # SQL migration files
│   ├── config/       # Viper-based configuration
│   ├── Dockerfile
│   └── docker-compose.yml
├── app/              # Flutter mobile application
│   └── lib/
│       ├── core/     # API client, WebSocket, auth, local DB
│       ├── features/ # Feature modules
│       │   ├── yatra_khoj/     # Journey detection (SMS parsing)
│       │   ├── samay_suchna/   # Time intelligence & delay info
│       │   ├── safar_rakshak/  # GPS tracking & arrival alerts
│       │   ├── rail_darshan/   # Map visualization
│       │   └── family/         # Family group sharing
│       ├── models/   # Shared data models
│       └── theme/    # Material 3 theming
└── README.html       # Product design document
```

## Running the Go Backend

### Prerequisites

- Docker & Docker Compose
- Go 1.22+ (for local development without Docker)

### Quick Start with Docker

```bash
cd backend
docker-compose up --build
```

This starts:
- **PostgreSQL** on port `5432`
- **Redis** on port `6379`
- **Sahayatri Backend** on port `8080`

Database migrations run automatically via the `docker-entrypoint-initdb.d` mount.

### Local Development (without Docker)

```bash
# Start PostgreSQL and Redis separately, then:
cd backend
go mod tidy
go run ./cmd/server
```

The server starts on `http://localhost:8080`.

### Health Check

```bash
curl http://localhost:8080/health
# {"status":"ok"}
```

## Running the Flutter App

### Prerequisites

- Flutter SDK 3.2+
- Android Studio / Xcode (for device/emulator)

### Setup

```bash
cd app
flutter pub get
flutter run
```

### Running Tests

```bash
cd app
flutter test
```

## API Documentation

Base URL: `http://localhost:8080/api/v1`

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register a new user |
| POST | `/auth/login` | Login with email/password |
| POST | `/auth/refresh` | Refresh access token |

### Stations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/stations` | List all stations |
| GET | `/stations/search?q=` | Search stations by name/code |
| GET | `/stations/:id` | Get station by ID |

### Train Status

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/trains/:number/status` | Get live train status |

### PNR Status

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pnr/:pnr/status` | Get PNR booking status |

### Yatra (Journey) Cards

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/yatra` | Create a new yatra card |
| GET | `/yatra` | List user's yatra cards |
| GET | `/yatra/:id` | Get yatra card by ID |
| PUT | `/yatra/:id/location` | Update traveler location (broadcasts to family) |

### Family Groups

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/family` | Create a family group |
| GET | `/family` | List user's family groups |
| GET | `/family/:id` | Get group with members |
| POST | `/family/:id/members` | Add member to group |
| DELETE | `/family/:id/members/:userId` | Remove member |
| WS | `/family/live/:yatraId` | WebSocket for live location sharing |

### Shapefiles

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/shapefiles/tracks` | Get railway track GeoJSON data |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SAHAYATRI_SERVER_PORT` | `8080` | HTTP server port |
| `SAHAYATRI_DB_HOST` | `localhost` | PostgreSQL host |
| `SAHAYATRI_DB_PORT` | `5432` | PostgreSQL port |
| `SAHAYATRI_DB_USER` | `sahayatri` | Database user |
| `SAHAYATRI_DB_PASSWORD` | `sahayatri` | Database password |
| `SAHAYATRI_DB_NAME` | `sahayatri` | Database name |
| `SAHAYATRI_DB_SSL_MODE` | `disable` | PostgreSQL SSL mode |
| `SAHAYATRI_REDIS_ADDR` | `localhost:6379` | Redis address |
| `SAHAYATRI_REDIS_PASSWORD` | (empty) | Redis password |
| `SAHAYATRI_JWT_SECRET` | `change-me-in-production` | JWT signing secret |
| `SAHAYATRI_JWT_ACCESS_TOKEN_TTL` | `15m` | Access token TTL |
| `SAHAYATRI_JWT_REFRESH_TOKEN_TTL` | `168h` | Refresh token TTL |

## Architecture Highlights

- **Offline-first**: The Flutter app caches all API responses in local SQLite. On network failure, data is served from the local cache.
- **On-device privacy**: SMS/email parsing for journey detection happens entirely on-device. Only structured YatraCard data is sent to the backend.
- **GPS tracking**: Haversine-based distance calculations run locally. Adaptive polling adjusts GPS frequency based on proximity to destination.
- **Real-time family sharing**: WebSocket-based pub/sub hub broadcasts GPS breadcrumbs to connected family members.
- **Scheduled data refresh**: Background cron jobs poll train status (every 2 min) and PNR status (every 15 min) for active journeys.
