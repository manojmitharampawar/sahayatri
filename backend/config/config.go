package config

import (
	"log"
	"time"

	"github.com/spf13/viper"
)

// Config holds all application configuration.
type Config struct {
	Server   ServerConfig
	DB       DBConfig
	Redis    RedisConfig
	JWT      JWTConfig
	External ExternalConfig
}

type ServerConfig struct {
	Port         string        `mapstructure:"port"`
	ReadTimeout  time.Duration `mapstructure:"read_timeout"`
	WriteTimeout time.Duration `mapstructure:"write_timeout"`
}

type DBConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Name     string `mapstructure:"name"`
	SSLMode  string `mapstructure:"ssl_mode"`
}

type RedisConfig struct {
	Addr     string `mapstructure:"addr"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type JWTConfig struct {
	Secret           string        `mapstructure:"secret"`
	AccessTokenTTL   time.Duration `mapstructure:"access_token_ttl"`
	RefreshTokenTTL  time.Duration `mapstructure:"refresh_token_ttl"`
}

type ExternalConfig struct {
	NTESBaseURL    string `mapstructure:"ntes_base_url"`
	PNRAPIBaseURL  string `mapstructure:"pnr_api_base_url"`
}

// DSN returns the PostgreSQL connection string.
func (d DBConfig) DSN() string {
	return "host=" + d.Host +
		" port=" + d.Port +
		" user=" + d.User +
		" password=" + d.Password +
		" dbname=" + d.Name +
		" sslmode=" + d.SSLMode
}

// Load reads configuration from environment variables and optional config file.
func Load() *Config {
	v := viper.New()

	v.SetConfigName("config")
	v.SetConfigType("yaml")
	v.AddConfigPath(".")
	v.AddConfigPath("./config")

	// Defaults
	v.SetDefault("server.port", "8080")
	v.SetDefault("server.read_timeout", "15s")
	v.SetDefault("server.write_timeout", "15s")

	v.SetDefault("db.host", "localhost")
	v.SetDefault("db.port", "5432")
	v.SetDefault("db.user", "sahayatri")
	v.SetDefault("db.password", "sahayatri")
	v.SetDefault("db.name", "sahayatri")
	v.SetDefault("db.ssl_mode", "disable")

	v.SetDefault("redis.addr", "localhost:6379")
	v.SetDefault("redis.password", "")
	v.SetDefault("redis.db", 0)

	v.SetDefault("jwt.secret", "change-me-in-production")
	v.SetDefault("jwt.access_token_ttl", "15m")
	v.SetDefault("jwt.refresh_token_ttl", "168h")

	v.SetDefault("external.ntes_base_url", "https://enquiry.indianrail.gov.in")
	v.SetDefault("external.pnr_api_base_url", "https://indianrailapi.com")

	v.AutomaticEnv()
	v.SetEnvPrefix("SAHAYATRI")

	if err := v.ReadInConfig(); err != nil {
		log.Println("No config file found, using defaults and environment variables")
	}

	cfg := &Config{}
	if err := v.UnmarshalKey("server", &cfg.Server); err != nil {
		log.Fatalf("failed to parse server config: %v", err)
	}
	if err := v.UnmarshalKey("db", &cfg.DB); err != nil {
		log.Fatalf("failed to parse db config: %v", err)
	}
	if err := v.UnmarshalKey("redis", &cfg.Redis); err != nil {
		log.Fatalf("failed to parse redis config: %v", err)
	}
	if err := v.UnmarshalKey("jwt", &cfg.JWT); err != nil {
		log.Fatalf("failed to parse jwt config: %v", err)
	}
	if err := v.UnmarshalKey("external", &cfg.External); err != nil {
		log.Fatalf("failed to parse external config: %v", err)
	}

	return cfg
}
