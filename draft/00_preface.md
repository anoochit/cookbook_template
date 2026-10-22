# Preface

Most Go developers meet SQL long before they meet an ORM, and the first ORM they meet tends to be the one that arrives with a tutorial. This book is for the moment after that: you have written a few queries by hand, you have started to repeat yourself, and you want to know whether GORM is worth putting between your structs and your database — and exactly what it will cost you if you do.

## Who this book is for

This book is written for Go developers who are new to GORM, or new to ORMs in general. You do not need prior GORM experience. You do need to be comfortable with Go itself: structs, interfaces, error handling, and running a program from the command line. If you can read a function signature and reason about what it returns, you have enough to start.

You will get the most out of this book if you have a real project in mind — a service that stores users, orders, or events — because the chapters build toward the decisions that project will force on you. If you have never run a database at all, Chapter 2 walks through installing a driver and opening a connection from nothing.

This book is not a reference manual. GORM's full API surface is large, and the official documentation at https://gorm.io/docs/ is the right place to look up an individual method. What this book adds is the order: which concept you need before which other one, where the sharp edges are, and why the API behaves the way it does.

## What you will learn

The book starts with the two things GORM is built on: declaring models, and the conventions that map your Go structs onto tables and columns. Once that foundation is in place, the four core operations — create, query, update, and delete — each get a chapter, because most bugs in day-to-day GORM code live in the details of one of them.

From there the book moves into the parts that separate working code from code you can maintain. You will model relationships between tables and learn how to load related data without falling into the N+1 trap. You will use migrations to evolve a schema without losing data, hooks to run logic at fixed points in the write lifecycle, and transactions to make several operations succeed or fail together. Later chapters cover the SQL builder for the cases the fluent API does not reach, scopes and sessions for keeping query logic reusable, and the type-safe generics API alongside the traditional one.

The closing chapters are about production: performance, observability, security, and testing against a real database engine. By the end you should be able to take a service from an empty schema to something you would be willing to run, and to explain the trade-offs you made along the way.

## How the examples are set up

The examples are written to be run, not just read. They target GORM v2, the version distributed as `gorm.io/gorm`, and the commands to install it appear at the start of Chapter 2:

```bash
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

Most examples use SQLite through `gorm.io/driver/sqlite`, because it runs in memory with no server to install and keeps the focus on the GORM code rather than on database administration. Where a behavior differs on PostgreSQL or MySQL — locking, upsert syntax, JSON handling — the text says so explicitly and shows the driver-specific form. Nothing in the core chapters depends on SQLite-only behavior.

Struct and field names follow GORM's own conventions, so a `User` struct becomes a `users` table and an `ID` field becomes the primary key. Where an example deliberately breaks a convention, it says why.

Code is kept as small as it can be while still being complete enough to run. When a snippet omits something — error handling around a `gorm.Open` call, say — it is because that code has already been established in an earlier chapter, not because it can be skipped in a real program.

One note on accuracy: GORM ships frequently, and behavior can change between releases. Every API in this book was checked against the official documentation, and where a feature depends on a particular version, that version is stated. When your own GORM version disagrees with this book, the documentation wins.
