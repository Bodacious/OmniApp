# Omni

A to-do app that exists to show hexagonal (ports-and-adapters) architecture.
The business logic in `domain/` is plain Ruby that depends on nothing. Around it
sit three swappable axes: the app layer, the persistence adapter, and the
interface (template language). The same domain files run unchanged in every
combination, including compiled to JavaScript by Opal and run by Node.

| Axis        | Values                              |
|-------------|-------------------------------------|
| Persistence | `sqlite_memory`, `postgres`         |
| App layer   | `rails`, `sinatra`, `opal_node`     |
| Interface   | `erb`, `slim`                       |

That makes 10 valid cells. `opal_node × slim` is excluded because there is no
Slim compiler for Opal. [`config/stack_matrix.yml`](config/stack_matrix.yml) is
the single source of truth for the axes and exclusions, and every script and
the CI matrix read it.

## How it fits together

```
domain/                    Plain Ruby. Requires nothing outside itself.
  todo.rb                  The entity. Its one rule: a title can't be blank.
  todo_list.rb             The use cases: list, add, complete, delete.
  ports/                   What the domain needs from outside, which adapters implement:
    todo_repository.rb       storing todos (synchronous)
    id_generator.rb          new ids (so identity never depends on a database)
adapters/                  Ruby adapters, shared by Rails and Sinatra
  persistence/sql/         Sequel: SQLite in memory, or Postgres via DATABASE_URL
  ids/                     SecureRandom UUIDs
  interface/erb/, slim/    The page template, once per engine; plain HTML plus locals
lib/omni/                  Stack selection (OMNI_*) and the Ruby composition root
apps/
  sinatra/                 Sinatra app layer
  rails/                   Rails app layer (ActionController + ActionView only; no Active Record)
  opal_node/               Ruby compiled with Opal and run by Node, with its own adapters:
    app/omni_node/adapters/  node:sqlite (DatabaseSync), pg-native (querySync), node:crypto
features/                  One set of Cucumber specs, run unchanged against every cell
bin/                       omni, omni-test, omni-matrix, omni-domain-check
```

Each app layer only translates HTTP into use-case calls on `TodoList` and
renders a shared template. The composition root reads the stack from the
environment, builds the adapters and injects them into the domain. `/health`
reports what was actually built (the connected database, the loaded template
engine), not an echo of the environment.

## Running the demo

### 1. Set up (once)

You need:
- **Ruby 3.4.1** (`.ruby-version`).
- **Node 22.22.2** (`.node-version`). Any Node 22.13+ has `node:sqlite` without a flag.
- **Docker**, for Postgres. A local Postgres works too; see step 3.
- **Chrome or Chromium**, for the specs only.
- **libpq-dev**, for the `pg` gem and `pg-native`: `apt-get install libpq-dev`, or on macOS `brew install libpq`.

```sh
bundle install
npm ci --prefix apps/opal_node      # pg-native for the Node app
docker compose up -d                # Postgres with an `omni` and an `omni_test` database
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/omni
```

### 2. Boot any stack

Choose one value per axis. All three variables are required. There are no defaults.

```sh
OMNI_APP=sinatra   OMNI_PERSISTENCE=sqlite_memory OMNI_INTERFACE=erb  bin/omni
OMNI_APP=rails     OMNI_PERSISTENCE=postgres      OMNI_INTERFACE=slim bin/omni
OMNI_APP=opal_node OMNI_PERSISTENCE=postgres      OMNI_INTERFACE=erb  bin/omni
```

Then open http://127.0.0.1:9292. The badge in the header shows the running
stack, as does `curl http://127.0.0.1:9292/health`. Use `PORT=` and `HOST=` to
change where it listens. For `opal_node`, `bin/omni` compiles the bundle first
(it takes about a second), then runs `node apps/opal_node/build/omni.js`.

### 3. A suggested walkthrough

1. **The matrix.** `bin/omni-matrix` prints the 10 cells, and the one exclusion with its reason.
2. **Sinatra on in-memory SQLite.** Boot `sinatra / sqlite_memory / erb`.
   - Add a couple of todos and complete one.
   - Submit a blank title to see the domain's rule come back as an error.
   - Restart the server: the in-memory todos are gone.
3. **Rails on Postgres, with Slim.** Stop the server and boot `rails / postgres / slim`.
   - It's the same page, but the badge says rails / postgres / slim.
   - Add todos. They're in Postgres now.
4. **The same domain on Node.** Stop it and boot `opal_node / postgres / erb`.
   - The todos Rails just wrote are there. It's the same table, now read by Ruby compiled to JavaScript, through `pg-native`.
   - `ps aux | grep omni.js` shows it really is a Node process.
5. **The domain is pure.** `bin/omni-domain-check` does two things:
   - loads every `domain/` file with `ruby --disable-gems`;
   - compiles `domain/` alone with Opal and runs the use cases on Node.

   Open `domain/todo_list.rb` and `domain/ports/`: nothing in them knows about Rails, Sinatra, SQL or Node.
6. **No silent defaults.** Each of these stops at boot with a message saying what to fix:
   - `bin/omni` with nothing set;
   - `OMNI_APP=opal_node OMNI_PERSISTENCE=postgres OMNI_INTERFACE=slim bin/omni`.
7. **One set of specs, every stack.** See "Running the specs" below. Run one cell, then the whole matrix.
8. **CI.** The `stack-matrix` workflow in GitHub Actions runs each cell as its own job, named like `sinatra · postgres · slim`.
   - "Run workflow" (workflow_dispatch) can filter by app, persistence or interface.
   - `matrix-green` is the single check to require in branch protection.

If Docker isn't available, point `DATABASE_URL` at any Postgres you can reach
(for example, `createdb omni && createdb omni_test` on a local server). The `sqlite_memory`
stacks need no database at all.

### Running the specs

`bin/omni-test` does four things:
- boots the selected stack on a free port, with `OMNI_ENV=test` (which mounts `POST /__test__/reset`);
- waits for `/health`;
- runs Cucumber against it in headless Chrome;
- stops the stack.

The command is the same locally and in CI. Before every scenario, the specs:
- reset the todos;
- check that `/health` matches `OMNI_*`, so a misconfigured cell fails rather than testing the wrong stack.

The specs delete every todo, so give them the `omni_test` database, not the one you demo from:

```sh
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/omni_test

OMNI_APP=opal_node OMNI_PERSISTENCE=sqlite_memory OMNI_INTERFACE=erb bin/omni-test
bin/omni-matrix --run                     # every cell in turn, then a pass/fail table
bin/omni-matrix --run --app rails         # filter by any axis
bundle exec rake test                     # domain unit tests + the repository contract on each Ruby adapter
bin/omni-domain-check                     # the domain purity checks
```

Cuprite finds Chrome or Chromium on the usual paths. Set `BROWSER_PATH` if
yours lives somewhere else. A failing run prints the tail of the server log,
which is kept in `tmp/omni-test/`.

### Adding an adapter

1. Write it against the port in `domain/ports/`, and run the contract in
   `domain/test/support/todo_repository_contract.rb` against it.
2. Register it:
   - persistence: `adapters/persistence/sql.rb`, or `CompositionRoot::PERSISTENCE` in `apps/opal_node`;
   - interface: add a template directory in `adapters/interface/`.
3. Add its name to `config/stack_matrix.yml`. Every script and the CI matrix pick it up from there.
