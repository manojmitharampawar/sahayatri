package shapefile

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sync"
)

// GeoJSONFeatureCollection represents a GeoJSON FeatureCollection.
type GeoJSONFeatureCollection struct {
	Type     string           `json:"type"`
	Features []GeoJSONFeature `json:"features"`
}

type GeoJSONFeature struct {
	Type       string                 `json:"type"`
	Geometry   GeoJSONGeometry        `json:"geometry"`
	Properties map[string]interface{} `json:"properties"`
}

type GeoJSONGeometry struct {
	Type        string      `json:"type"`
	Coordinates interface{} `json:"coordinates"`
}

// Loader loads and serves railway track shapefiles as GeoJSON.
type Loader struct {
	mu       sync.RWMutex
	tracks   *GeoJSONFeatureCollection
	dataPath string
}

func NewLoader(dataPath string) *Loader {
	return &Loader{
		dataPath: dataPath,
	}
}

// Load reads a GeoJSON file from disk and caches it in memory.
func (l *Loader) Load() error {
	l.mu.Lock()
	defer l.mu.Unlock()

	data, err := os.ReadFile(l.dataPath)
	if err != nil {
		if os.IsNotExist(err) {
			log.Printf("Shapefile not found at %s, serving empty collection", l.dataPath)
			l.tracks = &GeoJSONFeatureCollection{
				Type:     "FeatureCollection",
				Features: []GeoJSONFeature{},
			}
			return nil
		}
		return fmt.Errorf("read shapefile: %w", err)
	}

	var fc GeoJSONFeatureCollection
	if err := json.Unmarshal(data, &fc); err != nil {
		return fmt.Errorf("parse shapefile: %w", err)
	}

	l.tracks = &fc
	log.Printf("Loaded %d features from shapefile", len(fc.Features))
	return nil
}

// GetTracks returns the cached GeoJSON track data.
func (l *Loader) GetTracks() *GeoJSONFeatureCollection {
	l.mu.RLock()
	defer l.mu.RUnlock()

	if l.tracks == nil {
		return &GeoJSONFeatureCollection{
			Type:     "FeatureCollection",
			Features: []GeoJSONFeature{},
		}
	}
	return l.tracks
}

// SnapToTrack finds the nearest point on the track to the given coordinates.
// Returns the snapped lat/lon. Falls back to original coordinates if no track data.
func (l *Loader) SnapToTrack(lat, lon float64) (float64, float64) {
	l.mu.RLock()
	defer l.mu.RUnlock()

	if l.tracks == nil || len(l.tracks.Features) == 0 {
		return lat, lon
	}

	// TODO: implement proper nearest-point-on-line algorithm
	return lat, lon
}
