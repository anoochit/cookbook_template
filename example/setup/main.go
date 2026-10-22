package main

import (
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type Product struct {
	gorm.Model
	Code  string
	Price uint
}

func main() {
	db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatal("failed to connect database: ", err)
	}

	// the connection pool lives underneath the handle — close it when main returns
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("failed to get database handle: ", err)
	}
	defer sqlDB.Close()

	if err := db.AutoMigrate(&Product{}); err != nil {
		log.Fatal("failed to migrate database: ", err)
	}

	if err := db.Create(&Product{Code: "D42", Price: 100}).Error; err != nil {
		log.Fatal("failed to create product: ", err)
	}

	var product Product
	if err := db.First(&product, "code = ?", "D42").Error; err != nil {
		log.Fatal("failed to find product: ", err)
	}

	log.Printf("found product: code=%s price=%d", product.Code, product.Price)
}
