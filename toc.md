# Table of Contents — GORM: ORM in Go for beginners

This outline maps every chapter to its source file, its planned sections, and the official GORM documentation it is based on. Citations live here (never inside chapter files), so an agent writing a chapter can verify each API against the listed source before writing code.

**Primary source:** GORM official documentation — https://gorm.io/docs/
**API reference:** https://pkg.go.dev/gorm.io/gorm
**Terminology:** Standard engineering terms, product names, API and CLI identifiers stay in English; explanations follow the language rules in `AGENTS.md`.

---

## Preface

- **File:** `chapters/00_preface.md`
- **Purpose:** Why this book exists, who it is for, what you will be able to build by the end, and how to read the chapters.
- **Sections:**
  - Who this book is for
  - What you will learn
  - How the examples are set up
- **References:**
  - https://gorm.io/docs/index.html

---

## Chapter 1: Introduction

- **File:** `chapters/01_introduction.md`
- **Purpose:** What an ORM is, the problems it solves, and where it stops being the right tool. Introduces GORM's feature set and its two API styles (traditional and generics).
- **Sections:**
  - What is an ORM
  - Raw SQL vs. an ORM
  - What GORM provides
  - Traditional API and Generics API
  - What GORM does not do for you
- **References:**
  - https://gorm.io/docs/index.html
  - https://gorm.io/docs/the_generics_way.html

---

## Chapter 2: Setup

- **File:** `chapters/02_setup.md`
- **Purpose:** Install Go tooling, add GORM and a database driver, open the first connection, and understand the options passed to `gorm.Open`.
- **Sections:**
  - Installing GORM and a driver
  - Connecting to SQLite, MySQL, and PostgreSQL
  - `gorm.Config` and connection options
  - Connection pools and `database/sql` settings
  - A first working program
- **References:**
  - https://gorm.io/docs/index.html
  - https://gorm.io/docs/connecting_to_the_database.html
  - https://gorm.io/docs/gorm_config.html

---

## Chapter 3: Declaring Models and Conventions

- **File:** `chapters/03_declaring_models.md`
- **Purpose:** Turn Go structs into tables. Cover field tags, naming conventions, the built-in `gorm.Model`, and the default primary key and timestamp behavior.
- **Sections:**
  - Structs as tables
  - `gorm.Model`
  - Field tags (`column`, `type`, `primaryKey`, `not null`, `default`, `index`, `uniqueIndex`)
  - Naming conventions and pluralization
  - Default values and serialization
- **References:**
  - https://gorm.io/docs/models.html
  - https://gorm.io/docs/conventions.html
  - https://gorm.io/docs/serializer.html
  - https://gorm.io/docs/data_types.html

---

## Chapter 4: Creating Records

- **File:** `chapters/04_create.md`
- **Purpose:** Insert data with `Create`, batch inserts, default values, and the hooks that run during creation.
- **Sections:**
  - Creating one record
  - Creating from a slice (batch insert)
  - Returning created fields
  - `CreateInBatches`
  - Upsert
- **References:**
  - https://gorm.io/docs/create.html

---

## Chapter 5: Querying Records

- **File:** `chapters/05_query.md`
- **Purpose:** The core read operations — `First`, `Take`, `Last`, `Find`, `FindInBatches` — plus conditions, ordering, limits, field selection, and counting.
- **Sections:**
  - Primary key and condition queries
  - `Where` with strings, structs, and maps
  - `Order`, `Limit`, `Offset`, `Select`
  - Counting and `Distinct`
  - Plucking columns and scanning into maps
  - Batch reads with `FindInBatches`
- **References:**
  - https://gorm.io/docs/query.html
  - https://gorm.io/docs/advanced_query.html
  - https://gorm.io/docs/method_chaining.html

---

## Chapter 6: Updating Records

- **File:** `chapters/06_update.md`
- **Purpose:** Update single fields, multiple fields, and expressions safely, and understand why a `Model` with no conditions is refused.
- **Sections:**
  - Updating a single field with `Update`
  - Updating multiple fields with `Updates`
  - Struct vs. map updates
  - SQL expressions and `clause`
  - Updating and deleting with `Batch`
- **References:**
  - https://gorm.io/docs/update.html

---

## Chapter 7: Deleting Records

- **File:** `chapters/07_delete.md`
- **Purpose:** Delete rows, understand soft delete via `gorm.DeletedAt`, and know how soft delete changes every query.
- **Sections:**
  - Deleting a record
  - Deleting with conditions
  - Soft delete
  - Retrieving soft-deleted records
  - Unscoped delete
- **References:**
  - https://gorm.io/docs/delete.html
  - https://gorm.io/docs/conventions.html

---

## Chapter 8: Modeling Relationships

- **File:** `chapters/08_modeling_relationships.md`
- **Purpose:** Model the four main associations — Belongs To, Has One, Has Many, Many to Many — plus polymorphism, and learn how records are saved through them.
- **Sections:**
  - Belongs To
  - Has One
  - Has Many
  - Many to Many and join tables
  - Polymorphic associations
  - Association Mode
  - Constraints and delete/update rules
- **References:**
  - https://gorm.io/docs/belongs_to.html
  - https://gorm.io/docs/has_one.html
  - https://gorm.io/docs/has_many.html
  - https://gorm.io/docs/many_to_many.html
  - https://gorm.io/docs/polymorphism.html
  - https://gorm.io/docs/associations.html
  - https://gorm.io/docs/constraints.html

---

## Chapter 9: Preloading and Eager Loading

- **File:** `chapters/09_preloading.md`
- **Purpose:** Load related data without N+1 queries. Cover `Preload`, `Joins`, eager loading with conditions, and selecting related fields.
- **Sections:**
  - The N+1 problem
  - `Preload` basics
  - Preloading with conditions
  - Preloading nested and multiple relations
  - `Joins` and selecting related fields
- **References:**
  - https://gorm.io/docs/preload.html
  - https://gorm.io/docs/advanced_query.html
  - https://gorm.io/docs/performance.html

---

## Chapter 10: Migrations and Schema Management

- **File:** `chapters/10_migration.md`
- **Purpose:** Create and evolve tables with `AutoMigrate`, then move to versioned migration files for real projects.
- **Sections:**
  - `AutoMigrate`
  - What AutoMigrate does and does not do
  - Adding columns and indexes
  - Constraints and composite primary keys
  - Versioned migrations in a real project
- **References:**
  - https://gorm.io/docs/migration.html
  - https://gorm.io/docs/indexes.html
  - https://gorm.io/docs/constraints.html
  - https://gorm.io/docs/composite_primary_key.html

---

## Chapter 11: Hooks and Callbacks

- **File:** `chapters/11_hooks.md`
- **Purpose:** Run logic at fixed points in the ORM lifecycle — validation, timestamp handling, denormalization — and register custom callbacks.
- **Sections:**
  - Available hooks
  - `BeforeSave`, `AfterSave`, `BeforeCreate`, `AfterCreate`
  - `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete`
  - `AfterFind` and modifying query results
  - Modifying data with `tx`
  - Registering custom callbacks
- **References:**
  - https://gorm.io/docs/hooks.html

---

## Chapter 12: Transactions and Error Handling

- **File:** `chapters/12_transactions.md`
- **Purpose:** Group operations atomically and handle errors the way GORM expects — checking `db.Error`, using `errors.Is`, and rolling back correctly.
- **Sections:**
  - Why transactions matter
  - `Transaction` with a closure
  - Nested transactions and save points
  - Manual transaction control
  - GORM error handling patterns
  - `ErrRecordNotFound` and typed errors
- **References:**
  - https://gorm.io/docs/transactions.html
  - https://gorm.io/docs/error_handling.html

---

## Chapter 13: Advanced Queries and the SQL Builder

- **File:** `chapters/13_advanced_queries.md`
- **Purpose:** Subqueries, grouping, locking, raw SQL, and building clauses by hand when the fluent API runs out.
- **Sections:**
  - Subqueries
  - `Group` and `Having`
  - `Distinct` and `Pluck`
  - Row scanning and `Rows`
  - Raw SQL and `Exec`
  - SQL Builder and `clause`
  - Named arguments and hints
- **References:**
  - https://gorm.io/docs/advanced_query.html
  - https://gorm.io/docs/sql_builder.html
  - https://gorm.io/docs/hints.html
  - https://gorm.io/docs/generic_interface.html

---

## Chapter 14: Scopes, Sessions, and Context

- **File:** `chapters/14_scopes_sessions.md`
- **Purpose:** Reuse query logic with scopes, understand chain safety through `Session` and `NewDB`, and pass `context.Context` through every operation.
- **Sections:**
  - Reusable scopes
  - Chain conditions and `Method Chaining`
  - `Session` and `NewDB`
  - Chained methods vs. chained conditions
  - Using `context.Context`
- **References:**
  - https://gorm.io/docs/scopes.html
  - https://gorm.io/docs/method_chaining.html
  - https://gorm.io/docs/session.html
  - https://gorm.io/docs/context.html

---

## Chapter 15: Generics API and GORM CLI

- **File:** `chapters/15_generics_and_cli.md`
- **Purpose:** Use the type-safe generics API (`gorm.G[T]`) for everyday CRUD, then generate interface-based query code with the GORM CLI.
- **Sections:**
  - Why type safety matters
  - `gorm.G[T]` for CRUD
  - Generated interfaces with the GORM CLI
  - Writing query generation directives
  - When to prefer the traditional API
- **References:**
  - https://gorm.io/docs/the_generics_way.html
  - https://gorm.io/cli/index.html
  - https://gorm.io/gen/index.html

---

## Chapter 16: Performance and Production Practice

- **File:** `chapters/16_performance.md`
- **Purpose:** Keep GORM fast and observable in production — prepared statements, logging, metrics, and the mistakes that quietly cost the most.
- **Sections:**
  - Prepared statement mode
  - Batch operations and `FindInBatches` sizing
  - Reading and write splitting with Database Resolver
  - Logging and observability
  - Common performance mistakes
  - Security: injection risks and safe practices
- **References:**
  - https://gorm.io/docs/performance.html
  - https://gorm.io/docs/logger.html
  - https://gorm.io/docs/dbresolver.html
  - https://gorm.io/docs/prometheus.html
  - https://gorm.io/docs/security.html
  - https://gorm.io/docs/settings.html

---

## Chapter 17: Testing Database Code

- **File:** `chapters/17_testing.md`
- **Purpose:** Write tests against real database behavior — in-memory SQLite, per-test setup and teardown, and assertions that survive refactoring.
- **Sections:**
  - Why database tests need a real engine
  - In-memory SQLite for unit tests
  - Test setup and teardown
  - Isolating tests with transactions
  - What to assert
- **References:**
  - https://gorm.io/docs/connecting_to_the_database.html
  - https://gorm.io/docs/transactions.html

---

## Chapter 18: Where to Go Next

- **File:** `chapters/18_next_steps.md`
- **Purpose:** Point readers at the advanced surfaces they now have the foundation for, and at the wider Go data-access ecosystem.
- **Sections:**
  - Sharding and multi-database setups
  - Custom serializers and plugins
  - Writing your own driver
  - Gen for generated models and query code
  - Reading the changelog and tracking releases
- **References:**
  - https://gorm.io/docs/sharding.html
  - https://gorm.io/docs/serializer.html
  - https://gorm.io/docs/write_plugins.html
  - https://gorm.io/docs/write_driver.html
  - https://gorm.io/gen/index.html
  - https://gorm.io/docs/changelog.html
