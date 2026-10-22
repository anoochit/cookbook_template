# Chapter 1: Introduction

Hand-written SQL tends to accumulate. A query that was fine at first becomes one of forty scattered across a service, each a chance to misspell a column or forget a parameter placeholder. GORM removes that repetition by translating your Go structs into database operations. This chapter sets out what an ORM does, what GORM specifically offers, and where its responsibility stops and yours begins.

## What is an ORM

An ORM — Object-Relational Mapping — maps your language's data structures onto the tables and columns of a relational database. In Go, your structs become tables, struct fields become columns, and queries you express in Go are translated into SQL and sent to the database.

The mapping runs in both directions. A struct value you pass in is written as a row; rows that come back are read into struct values, so you rarely copy a column into a field by hand.

This addresses the object-relational impedance mismatch: a struct is a set of named fields with Go types, while a table is a set of rows governed by SQL types, constraints, and keys. Bridging the two manually is tedious and easy to get wrong. An ORM does it once, systematically, in one place.

![Fig 1.1 Where GORM sits between your Go application and the database server](images/fig1-1.png)

The diagram places GORM as a layer between your application and the database server. Your code calls methods such as `db.Model`, `db.Where`, and `db.Create`; GORM builds a SQL statement from those calls and hands it to the configured driver, which sends it to the server. Rows return through the driver and GORM scans them into your structs. You deal in structs at both ends, while SQL and the wire protocol stay underneath.

## Raw SQL vs an ORM

Raw SQL is a legitimate alternative, and for some systems it is the better one. Writing queries by hand with `database/sql` gives exact control over each statement, keeps performance characteristics easy to reason about, and never produces a query you did not intend.

The cost is repetition and drift. Every new struct means more insert, update, and select code; every join is another string to keep in sync with the schema. Rename a column and the burden of finding every query that mentions it falls on you.

An ORM inverts that trade-off: you state what you want in terms of your Go types and the library generates the SQL. What you accept in return is indirection — the generated query is not always the one you would have written, and understanding it can mean inspecting what GORM actually produced.

This book takes the middle position it recommends: use the ORM for the routine bulk of data access, and drop to raw SQL where you need precise control. GORM supports both in one program, since it exposes the underlying connection and a SQL builder.

## What GORM provides

GORM is a full-featured ORM for Go. Its feature set falls into a few groups:

- **CRUD** — create, query, update, and delete records, individually or in batches.
- **Associations** — has one, has many, belongs to, and many to many, plus preloading to load related data efficiently.
- **Schema management** — migrations driven by your model definitions, including automatic migration that creates tables and adds missing columns.
- **Lifecycle hooks** — your own code runs at fixed points, such as before a record is created or after it is found. Validation and timestamp bookkeeping usually live here.
- **Correctness** — transactions, including nested transactions and save points.
- **Lower-level access** — a SQL builder, subqueries, raw SQL execution, and prepared statement mode.
- **Diagnostics** — logging of the SQL GORM generates, which is invaluable while learning.

Two pieces underpin everything that follows. The first is the `*gorm.DB` handle returned by `gorm.Open`: it is what you pass around and call methods on. The second is error handling. GORM both returns errors from its operations and records them in `db.Error`, and checking them correctly is what separates code that fails loudly from code that fails silently.

![Fig 1.2 Lifecycle of a single GORM query from struct declaration through to scanned results](images/fig1-2.png)

The diagram follows one query from end to end. It starts with the model struct you declared, then a call such as `db.Where(...).Find(&users)`. GORM assembles the SQL, the driver transmits it, and the database returns matching rows. GORM scans those rows into the slice you passed, and your code receives the result together with `db.Error` to check. Every query in this book follows this path; the later chapters differ only in which stage they examine.

## Traditional API and Generics API

GORM offers two ways to write the same operations, and you will meet both in real codebases.

The traditional API is method-based and centers on the `*gorm.DB` handle. Methods are chained, and the final method executes:

```go
package main

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type Product struct {
	gorm.Model
	Code  string
	Price uint
}

func main() {
	db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
	if err != nil {
		panic("failed to connect database")
	}

	db.AutoMigrate(&Product{})

	// Create
	db.Create(&Product{Code: "D42", Price: 100})

	// Read
	var product Product
	db.First(&product, "code = ?", "D42")

	// Update
	db.Model(&product).Update("Price", 200)

	// Delete
	db.Delete(&product, 1)
}
```

The generics API, added in version 1.30.0, wraps the same engine in type-safe functions. You name the type once and the compiler knows what comes back, so there is no destination pointer to pass and no ambiguity about the result:

```go
ctx := context.Background()

// Create
err = gorm.G[Product](db).Create(ctx, &Product{Code: "D42", Price: 100})

// Read
product, err := gorm.G[Product](db).Where("code = ?", "D42").First(ctx)

// Update
err = gorm.G[Product](db).Where("id = ?", product.ID).Update(ctx, "Price", 200)

// Delete
err = gorm.G[Product](db).Where("id = ?", product.ID).Delete(ctx)
```

The two styles are interchangeable and mix freely, because the generics API is a thin layer over the same implementation. The generics form catches more mistakes at compile time and returns errors directly rather than only recording them in `db.Error`. The traditional form carries more examples, blog posts, and answered questions behind it. Either is a sound starting point; this book uses the traditional API for most examples and notes the generics equivalent where the difference matters.

## What GORM does not do for you

Seeing the tool's boundary matters as much as seeing its features, because the gap between what an ORM handles and what a production system needs is where most real problems live.

GORM generates SQL but never judges whether it is fast. A query that returns instantly on ten rows can take minutes on ten million, and GORM will not warn you. Reading the generated SQL and reasoning about the execution plan stays your job.

GORM can create and alter tables through automatic migration, but running that against a production database is a decision rather than a default. It is convenient in development and risky in deployment, where a dropped or narrowed column can destroy data.

GORM manages a connection pool, but the right settings depend on your database server, your traffic, and your latency. The defaults are a starting point, not an answer.

GORM provides transactions but cannot decide where your transaction boundaries belong. Only you know which operations must succeed or fail together.

![Fig 1.3 Division of responsibility between GORM and your application code](images/fig1-3.png)

The diagram splits building a feature into two sides. On one, GORM handles the mechanical mapping: structs to tables and columns, method calls to SQL, rows back to structs, along with the association and hook machinery. On the other, the decisions remain yours: how the schema changes in production, how the pool is sized, whether a query is fast enough, and where a transaction begins and ends. As you read on, it helps to keep asking which side each topic falls on.

## Summary

An ORM maps Go structs onto relational tables and translates method calls into SQL in both directions, shielding you from the object-relational mismatch that makes hand-written data access tedious. GORM supplies CRUD operations, associations, migrations, hooks, transactions, a SQL builder, and logging, all reached through a single `*gorm.DB` handle — and it offers two API styles over that one implementation, the traditional chained method API and the type-safe generics API from version 1.30.0, so the choice between them is one of preference rather than capability.

The boundary matters more than the feature list. GORM generates SQL without guaranteeing it is fast, migrates schemas you should not let run unattended in production, pools connections it cannot size for you, and provides transactions without knowing where yours belong. Holding on to that division of responsibility is what will keep the code you build with it healthy.

The next chapter takes the practical first step — installing GORM, opening a connection, and getting a program running — before models and conventions, which the rest of the book is built on.
