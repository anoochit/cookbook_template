# Chapter 1: Introduction

Most Go services that outgrow a prototype eventually arrive at the same place: a growing pile of hand-written SQL strings scattered through the codebase, each one a small chance to get a column name wrong or forget a parameter placeholder. GORM exists to take that job off your hands. This chapter explains what an ORM actually does for you, what GORM specifically provides, and — just as importantly — where its responsibility ends and yours begins.

## What is an ORM

An ORM, short for Object-Relational Mapping, is a library that maps your programming language's data structures onto the tables and columns of a relational database. In Go, that means your structs become tables, struct fields become columns, and queries you express in Go get translated into SQL and sent to the database.

The mapping works in both directions. Going in, GORM takes a struct value and writes it as a row. Coming back, it reads rows and fills in struct values for you, so you rarely write the code that copies a column into a field by hand.

This solves a real problem known as the object-relational impedance mismatch. Structs and tables are built on different assumptions: a struct is a set of named fields with Go types, while a table is a set of rows with SQL types, constraints, and keys. Bridging the two by hand is tedious and error-prone. An ORM does the bridging systematically, once, in one place.

![Fig 1.1 Where GORM sits between your Go application and the database server](images/fig1-1.png)

The diagram shows GORM as a layer between your application and the database server. Your code calls GORM methods such as `db.Model`, `db.Where`, and `db.Create`. GORM builds a SQL statement from those calls and hands it to the configured database driver, which sends it to the server. Rows come back through the driver, and GORM scans them into your structs. You work with structs at the top and receive structs at the bottom; the SQL and the wire protocol stay underneath the layer.

## Raw SQL vs an ORM

Before going further, it is worth being honest about the alternative. You can write every query by hand using `database/sql` or a query builder, and for plenty of systems that is the right call. Raw SQL gives you exact control over the generated statement, makes the performance characteristics easy to reason about, and never surprises you with a query you did not intend to write.

The trade-off is repetition and drift. Every struct you add means new insert, update, and select code. Every table join means another string to keep in sync with the schema. When a column is renamed, you are the one finding every query that mentions it.

An ORM inverts that trade-off. You describe what you want in terms of your Go types, and the library generates the SQL. In exchange you accept a layer of indirection: the generated query is not always the one you would have written, and understanding it sometimes means inspecting what GORM produced.

A pragmatic middle ground, and the one this book leans toward, is to use the ORM for the routine ninety percent of your data access and drop to raw SQL for the queries where you need precise control. GORM supports this directly — it exposes the underlying connection and a SQL builder — so the two styles coexist in one program rather than competing.

## What GORM provides

GORM is a full-featured ORM for Go, and it helps to see the shape of the feature set before using any of it.

At its core are the CRUD operations: creating, querying, updating, and deleting records, individually or in batches. Around that core sit associations, which model the relationships between tables — has one, has many, belongs to, and many to many — along with preloading to load related data efficiently.

Schema management comes through migrations, with automatic migration that creates tables and adds missing columns from your model definitions. Lifecycle hooks let you run your own code at fixed points, such as before a record is created or after it is found, which is where validation and timestamp bookkeeping usually live.

For correctness, GORM provides transactions, including nested transactions and save points. For working at a lower level, it offers a SQL builder, subqueries, raw SQL execution, and prepared statement mode. It can also log the SQL it generates, which is invaluable while you are learning.

Two pieces matter for everything that follows. The first is the `*gorm.DB` handle returned by `gorm.Open` — it is what you pass around and call methods on. The second is error handling: GORM returns errors from its operations and also records them in `db.Error`, and checking them correctly is the difference between code that fails loudly and code that fails silently.

![Fig 1.2 Lifecycle of a single GORM query from struct declaration through to scanned results](images/fig1-2.png)

The diagram traces one query end to end. It begins with a model struct you have declared, then a method call such as `db.Where(...).Find(&users)`. GORM assembles the SQL string from that call, the driver transmits it, and the database returns matching rows. GORM then scans those rows into the slice you passed in, and your code receives the result alongside `db.Error` to check. Every query in this book follows that same path; the chapters ahead differ only in which stage they focus on.

## Traditional API and Generics API

GORM offers two ways to express the same operations, and you will see both in real codebases.

The traditional API is method-based and centers on the `*gorm.DB` handle. You call methods in a chain, and the final method executes the query:

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

The generics API, available from version 1.30.0 onward, wraps the same engine in type-safe functions. Instead of passing a destination pointer to `Find`, you name the type once and the compiler knows what comes back:

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

The two styles are interchangeable and can be mixed freely in one program, because the generics API is a thin layer over the same underlying implementation. The generics form catches more mistakes at compile time and returns errors directly instead of only storing them in `db.Error`. The traditional form has more examples, more blog posts, and more answered questions behind it. For a beginner, either is a reasonable starting point; this book shows the traditional API in most examples and calls out the generics equivalent where it differs meaningfully.

## What GORM does not do for you

It is just as important to see the boundary of the tool as its features, because the gap between what an ORM handles and what a production system needs is where most real problems live.

GORM generates SQL from your calls, but it does not verify that the SQL is fast. A query that works correctly on ten rows can take minutes on ten million, and GORM will not warn you. Reading the generated SQL and understanding the execution plan remains your job.

GORM can create and alter tables through automatic migration, but running that against a production database is a decision, not a default. Automatic migration is convenient in development and risky in deployment, where a dropped or narrowed column can destroy data.

GORM manages a connection pool, but the correct settings depend on your database server, your traffic, and your latency. The defaults are a starting point, not an answer.

Finally, GORM provides transactions but cannot decide where your transaction boundaries should be. Only you know which operations must succeed or fail together.

![Fig 1.3 Division of responsibility between GORM and your application code](images/fig1-3.png)

The diagram splits the work of building a feature into two columns. On the left, GORM handles the mechanical mapping: structs to tables and columns, method calls to SQL, rows back to structs, plus the association and hook machinery. On the right, the decisions stay with you: how the schema changes in production, how the connection pool is sized, whether a query is fast enough, and where a transaction begins and ends. Reading the book from here on, it helps to keep asking which side of that line each topic falls on.

## Summary

An ORM maps your Go structs onto relational tables, translating method calls into SQL in both directions and shielding you from the object-relational mismatch that makes hand-written data access tedious. GORM is Go's most widely used implementation of that idea, providing CRUD operations, associations, migrations, hooks, transactions, a SQL builder, and logging, all reachable through a single `*gorm.DB` handle.

You have also seen the two API styles GORM offers — the traditional chained method API and the type-safe generics API added in version 1.30.0 — and that they share one implementation, so choosing between them is a matter of preference rather than capability. Just as significant is the boundary drawn in this chapter: GORM generates SQL but does not guarantee it is fast, it can migrate schemas but should not be trusted to do so blindly in production, it pools connections but cannot size the pool for you, and it provides transactions without knowing where yours belong.

The next chapter turns to the practical first step — installing GORM, opening a connection, and getting a program running — before the following chapters take up models and conventions, which are the foundation everything else in the book is built on.
