# Chapter 2: Setup

Nothing about mapping structs to tables matters until a connection opens. This chapter turns an empty directory into a Go module with GORM installed, a driver chosen, and a first connection verified. It then takes apart what you pass to `gorm.Open`, what the handle it returns manages underneath, and the few pool settings worth deciding on early. By the end you will have a running program — checked into this book's repository at `example/setup/` — that creates a table, writes a row, and reads it back.

## Installing GORM and a driver

GORM is distributed as two modules, and you install them separately. The first, `gorm.io/gorm`, is the ORM itself: models, queries, hooks, transactions, and the SQL builder. It contains no knowledge of any particular database. The second is a driver package, which teaches the core how to talk to one specific database and plugs it into a `database/sql` driver underneath.

Start a module and pull both in:

```bash
go mod init example.com/bookstore
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

`go mod init` runs once per project and its argument is a name you choose; the `example.com/` style is only a convention that avoids collisions if the module is ever published. `go get -u` downloads the latest release and records it in `go.mod`, with `go.sum` pinning the exact content afterward. Running `go list -m gorm.io/gorm` prints the version you actually have.

Pick the driver for the database you run. Each is a separate module, so install only the one you need:

| Database | Driver module | Built on |
| --- | --- | --- |
| SQLite | `gorm.io/driver/sqlite` | `github.com/mattn/go-sqlite3` (requires CGO) |
| MySQL and compatible servers such as TiDB | `gorm.io/driver/mysql` | `github.com/go-sql-driver/mysql` |
| PostgreSQL | `gorm.io/driver/postgres` | `github.com/jackc/pgx` |

The examples in this chapter were checked with Go 1.25 against `gorm.io/gorm` v1.31.2 and `gorm.io/driver/sqlite` v1.6.0. Run `go list -m all | findstr gorm` — or `grep` on Linux and macOS — if you want to compare versions.

### CGO and the SQLite driver

The SQLite driver deserves its own warning because it is the one almost every reader starts with, and it is the only one of the three with a build requirement beyond Go itself.

`gorm.io/driver/sqlite` is backed by `github.com/mattn/go-sqlite3`, which embeds the SQLite C library. Compiling it needs CGO: `CGO_ENABLED=1` — the default whenever a C compiler is found — plus a compiler on your `PATH`. That is `gcc` on Linux, the Xcode command line tools on macOS, and MinGW-w64 or an equivalent GCC distribution on Windows (WSL also works, since the standard Linux toolchain includes everything needed).

The failure mode is worth recognizing, because it looks like a success first. Without a compiler the program still compiles — `go-sqlite3` ships a stub that satisfies the build — and then refuses to run:

```text
failed to connect database: Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work. This is a stub
```

If you cannot install a C compiler, the official documentation lists pure-Go replacements that need nothing beyond the Go toolchain: `github.com/glebarez/sqlite` and `github.com/libtnb/sqlite`. They present the same package name and the same `sqlite.Open` function, so only the import line changes:

```go
import "github.com/glebarez/sqlite" // pure Go — no C compiler required
```

The examples in this book use `gorm.io/driver/sqlite`. Keep the swap above in mind if you hit the stub error, and the rest of the code stays exactly as written.

![Installed GORM stack from your program down to the database server](images/fig2-1.png)

The diagram shows where the pieces you just installed sit relative to one another. Your program holds the `*gorm.DB` handle and calls methods on it; `gorm.io/gorm` builds the SQL; the driver package contributes the dialect — how this particular database names identifiers, what its types are — and opens the right kind of connection; `database/sql` owns the actual connections in a pool; and the server, or an SQLite file, answers at the bottom. Your code touches the top layer and the data that comes back up it, while everything in between is the plumbing this chapter is unpacking.

## Connecting to SQLite, MySQL, and PostgreSQL

Every connection in GORM begins with `gorm.Open`, whose signature is:

```go
func Open(dialector Dialector, opts ...Option) (db *DB, err error)
```

The first argument is a *dialector*: the driver's `Open` function takes a DSN string and returns an object describing how to reach that database. The second argument holds options, and in practice is almost always `&gorm.Config{}`. The call returns the handle you will pass around your program together with an error.

It does more than record the DSN. `gorm.Open` initializes the driver and pings the database by default, so a wrong host, a missing database, or a refused connection surfaces here rather than at your first query. The pattern is therefore fixed for the rest of the book:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
if err != nil {
	log.Fatal("failed to connect database: ", err)
}
```

### SQLite

For SQLite the DSN is a file path, and nothing else is required:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
```

The file is created on first write if it does not exist, and it appears in the working directory of the process. For tests and experiments you can skip the file entirely with `file::memory:?cache=shared`, which keeps the database in system memory.

That shared form matters. A bare `:memory:` database is private to the connection that opened it, and a pooled application opens more than one connection — the symptom is a bewildering "no such table" error that appears only under load. The `cache=shared` form gives every connection in the process one shared in-memory database, which is what you want.

### MySQL

MySQL takes a DSN in the `user:pass@tcp(host:port)/dbname?params` form understood by `go-sql-driver/mysql`:

```go
dsn := "user:pass@tcp(127.0.0.1:3306)/gorm?charset=utf8mb4&parseTime=True&loc=Local"
db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
```

Two of those parameters are not optional in practice. `parseTime=True` is required for `time.Time` fields to scan correctly, and `charset=utf8mb4` — not `charset=utf8` — is what gives you full UTF-8, including four-byte characters such as emoji. The driver's documentation lists the rest of the parameters.

### PostgreSQL

PostgreSQL uses a space-separated list of `key=value` pairs:

```go
dsn := "host=localhost user=gorm password=gorm dbname=gorm port=5432 sslmode=disable TimeZone=UTC"
db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
```

`sslmode=disable` is acceptable against a local development server; anything reaching a real server should verify TLS rather than disable it. The PostgreSQL driver wraps `pgx` and enables a prepared statement cache by default. If something between your application and the database does not tolerate implicitly prepared statements, the driver can fall back to the simple query protocol:

```go
db, err := gorm.Open(postgres.New(postgres.Config{
	DSN:                  dsn,
	PreferSimpleProtocol: true,
}), &gorm.Config{})
```

### Keeping credentials out of the source

Every DSN above contains a password, and every one of them ends up committed if you hard-code it. Read it from the environment instead:

```go
dsn := os.Getenv("DATABASE_DSN")
if dsn == "" {
	log.Fatal("DATABASE_DSN is not set")
}
```

The same applies to real credentials of any kind: the source tree is not a secret store, and the DSN belongs with the rest of the deployment configuration.

One more door into the same place: if your program already owns a `*sql.DB` — opened elsewhere, or shared with code that does not use GORM — hand it to the driver rather than letting GORM open its own:

```go
sqlDB, err := sql.Open("mysql", dsn)
if err != nil {
	log.Fatal(err)
}

db, err := gorm.Open(mysql.New(mysql.Config{Conn: sqlDB}), &gorm.Config{})
```

The pool that connection already carries is the pool GORM will use, which is the subject of the section after next.

## gorm.Config and connection options

The second argument to `gorm.Open` is where the behavior of the handle is decided. Its effects start at one moment and then persist: options are applied while `gorm.Open` initializes the connection, copied into the handle, and inherited by everything chained from it.

![Steps inside gorm.Open from dialector and config to the returned handle or error](images/fig2-2.png)

The diagram follows a single call to `gorm.Open`. The dialector establishes the connection and teaches GORM the dialect, the config is applied on top of that initialization, and then — unless you opted out with `DisableAutomaticPing` — the database is pinged. A reachable database gives you the `*gorm.DB` handle to keep; an unreachable one comes back as an error, before any query of yours has run. This ordering is why a configuration mistake or a dead server both show up at the same place: the `gorm.Open` call you already check.

For a first program the right config is the empty one, because the defaults are deliberately sane:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})
```

The options you are most likely to reach for first:

| Option | What it changes |
| --- | --- |
| `SkipDefaultTransaction` | Every single create, update, and delete runs inside its own transaction by default; set this to `true` to send them without one. |
| `NamingStrategy` | Table and column naming: prefixes, singular table names, name replacement. Chapter 3. |
| `Logger` | Replaces the default logger. Detailed below and in Chapter 16. |
| `NowFunc` | Supplies the timestamps GORM writes; it defaults to `time.Now().Local()`. |
| `DryRun` | Builds SQL without executing it, for inspecting or testing what a chain would generate. Chapter 14. |
| `PrepareStmt` | Parses each statement once and caches the prepared form for reuse. Chapter 16. |
| `DisableAutomaticPing` | Skips the startup ping described above. |
| `AllowGlobalUpdate` | Permits an update or delete with no condition, which GORM otherwise refuses outright. Chapter 6. |
| `DisableNestedTransaction` | Turns off save points for transactions started inside a transaction. Chapter 12. |
| `DisableForeignKeyConstraintWhenMigrating` | `AutoMigrate` then creates tables without foreign key constraints. Chapter 10. |

The struct carries more fields than this table — batch sizing, error translation, context timeouts among them — but these are the ones that surface during setup.

The `Logger` option is the one to change first while you are learning. The default logger writes to standard output at the `Warn` level, which means you see errors and slow statements — anything taking 200 ms or more — and nothing else. That is the right volume for a production service and the wrong one for someone reading GORM for the first time, so turn every statement on:

```go
import "gorm.io/gorm/logger"

db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
	Logger: logger.Default.LogMode(logger.Info),
})
```

`LogMode` accepts `Silent`, `Error`, `Warn`, or `Info` and returns a new logger, leaving the original untouched, so the same default can be re-leveled per handle. You can also build your own with `logger.New`, pointing it at any `io.Writer` — or at `log/slog` through `logger.NewSlogLogger` — and Chapter 16 goes further into configuring it. Until then, `logger.Info` is the setting that makes the rest of this book observable:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
	Logger: logger.Default.LogMode(logger.Info), // drop back to Warn once the queries look right
	PrepareStmt:            true,
})
```

Config is settled once, at `gorm.Open`. When a single query later needs different treatment than the handle it came from — a longer timeout, a disabled prepared statement, a dry run — that is done with `Session` rather than by reopening the database, and Chapter 14 covers it.

## Connection pools and `database/sql` settings

GORM does not maintain connections of its own. Underneath every handle sits a `database/sql` pool, and that pool is where the limits on concurrency actually live. GORM's own documentation is explicit about this: pooling is `database/sql`'s job.

You reach it through the handle:

```go
sqlDB, err := db.DB()
if err != nil {
	log.Fatal("failed to get database handle: ", err)
}
defer sqlDB.Close()
```

`db.DB()` returns the `*sql.DB` the handle was built on, so anything you set on it applies to every query GORM sends from then on. The `defer` matters too: closing `sqlDB` at shutdown drains the pool, and it is how connections are released when the process exits.

Four settings are worth knowing, and three of them have defaults you would not choose yourself:

| Setting | Default | Meaning |
| --- | --- | --- |
| `SetMaxOpenConns(n)` | `0` — unlimited | The most connections that may be open at once. |
| `SetMaxIdleConns(n)` | `2` | Connections kept open and ready for immediate reuse. |
| `SetConnMaxLifetime(d)` | `0` — no limit | The longest a connection may be reused at all. |
| `SetConnMaxIdleTime(d)` | `0` — no limit | The longest a connection may sit idle before being closed (Go 1.15+). |

The default of two idle connections is a deliberate baseline rather than an oversight — the standard library keeps the pool small until told otherwise — but an unlimited number of open connections is not a setting, it is the absence of one. A reasonable starting point for a single service instance:

```go
sqlDB.SetMaxOpenConns(25)
sqlDB.SetMaxIdleConns(10)
sqlDB.SetConnMaxLifetime(time.Hour)
```

Treat those numbers as a beginning to measure from, not an answer. `MaxOpenConns` must stay below the connection limit of the database server once every replica and instance of your service is counted, and below that ceiling, more headroom means queries wait less. Set it too low and requests queue behind the pool, showing up as latency spikes; set it too high and the server spends its time and memory on connections instead of queries. `ConnMaxLifetime` exists to recycle connections politely — around load balancers, firewall idling, and server restarts — rather than to fix a specific failure.

![Goroutines sharing one handle through the database/sql connection pool](images/fig2-3.png)

The diagram shows why these settings are global rather than per query. Any number of goroutines share the one `*gorm.DB` handle — it is safe to pass around — and every call descends into the same `database/sql` pool, which lends out a physical connection for the duration of the call and takes it back afterward. The four settings sit on that middle layer, sizing how many connections may exist and how long each may be kept, so they shape the behavior of every query at once.

SQLite needs one caveat here. A file-backed SQLite database allows a single writer at a time, so pooled connections issuing writes concurrently will collide and report "database is locked". Keep `MaxOpenConns` low — single digits — for anything SQLite-backed, or serialize writes yourself. When that constraint starts to hurt, it is the signal that the project has outgrown SQLite and belongs on MySQL or PostgreSQL.

## A first working program

Everything in this chapter now assembles into one program. The complete source is checked in at `example/setup/` as its own module, so you can run it directly — the first `go run` downloads the modules it needs:

```bash
cd example/setup
go run .
```

If you see the CGO stub error from earlier in the chapter, apply the fix from that section first. The program itself:

```go
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
```

With `logger.Info` enabled, the run prints the SQL behind each step:

```text
2026/10/22 19:38:33 .../example/setup/main.go:32 [6.255ms] [rows:0] CREATE TABLE `products` (`id` integer PRIMARY KEY AUTOINCREMENT,`created_at` datetime,`updated_at` datetime,`deleted_at` datetime,`code` text,`price` integer)
2026/10/22 19:38:33 .../example/setup/main.go:36 [4.261ms] [rows:1] INSERT INTO `products` (`created_at`,`updated_at`,`deleted_at`,`code`,`price`) VALUES ("2026-10-22 19:38:33.945","2026-10-22 19:38:33.945",NULL,"D42",100) RETURNING `id`
2026/10/22 19:38:33 .../example/setup/main.go:41 [0.522ms] [rows:1] SELECT * FROM `products` WHERE code = "D42" AND `products`.`deleted_at` IS NULL ORDER BY `products`.`id` LIMIT 1
2026/10/22 19:38:33 found product: code=D42 price=100
```

(The records wrap onto two lines in a terminal, with the file path and elapsed time leading the statement; they are joined here, colour codes stripped, absolute paths shortened, and timings trimmed. `AutoMigrate`'s catalog checks and its `CREATE INDEX` line are omitted. The line numbers match `example/setup/main.go`.)

Read the output top to bottom and the whole chapter is on display. `AutoMigrate` created `test.db`'s `products` table from the struct — you can see the columns it derived, and that the soft-delete column `deleted_at` is already there. The insert wrote one row and used `RETURNING id` to fetch the primary key back in the same statement. The query then shows two habits GORM takes on without being asked: it quoted the column, and it added `deleted_at IS NULL` — soft delete is active from your very first query, which Chapter 7 explains — while `First` contributed the `ORDER BY` and `LIMIT 1` that make "first" mean first.

Two details in the code itself deserve naming. `db.Create` and `db.First` are chained calls, so their result is a `*gorm.DB` and the error arrives through `.Error`; `gorm.Open` and `db.AutoMigrate`, by contrast, return an `error` directly. Both styles are GORM's, and mixing the checks is not a mistake — it is the API telling you which shape each call has.

Run the program a second time and a second row appears: nothing in this model yet says a `Code` must be unique, so `D42` is inserted again, and `First` still returns the oldest row. That is the chapter's honest ending — the connection works, and the modeling rules have not been written yet. Delete `example/setup/test.db` to start clean, because declaring those rules is what Chapter 3 does.

## Summary

Setup turns out to be four decisions rather than one. You split GORM into its two modules, the pure-Go core and a driver package, and accepted whatever that driver brought with it — for SQLite, a C toolchain, unless you swap in a pure-Go driver. You built a DSN per database and learned the parameter each of them cannot do without: `parseTime` for MySQL, `sslmode` for PostgreSQL, `cache=shared` for an in-memory SQLite that survives pooling. And you found that `gorm.Open` does not merely record that DSN — it initializes the driver, applies your config, and pings, so a bad connection fails at the one line you already check.

Beneath the handle, `database/sql` runs the pool: two idle connections and no open limit until you say otherwise, reachable through `db.DB()` and closed with a `defer`. Sizing it is a measurement, not a setting — with one caveat for SQLite, whose single writer makes a large pool a liability rather than a feature. The config you inherited is quiet by default and was turned up to `Info` so the SQL GORM generates stays visible while you learn.

The next chapter is where the real mapping begins: what your struct declares becomes the table this program just created, decided by field names, tags, and the conventions GORM applies whether you asked for them or not.
