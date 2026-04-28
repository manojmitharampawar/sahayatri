package models

type Station struct {
	ID   int64   `json:"id" db:"id"`
	Code string  `json:"code" db:"code"`
	Name string  `json:"name" db:"name"`
	Lat  float64 `json:"lat" db:"lat"`
	Lon  float64 `json:"lon" db:"lon"`
	Zone string  `json:"zone" db:"zone"`
}
