# Omni

A to-do app that exists to show a properly layered, domain-driven design.
People sign up and sign in. Each user owns lists, and each list holds its
own todos, which can be tagged. The business logic in `domain/` is plain
Ruby that depends on nothing: aggregates, value objects and the
repositories that hold them. Around it sit three swappable axes: the app
layer, the persistence, and the interface (template language). The same domain files run unchanged in every
combination, including compiled to JavaScript by Opal and run by Node, and
in your browser on CRuby compiled to WebAssembly.

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
domain/model/              Plain Ruby. Requires nothing outside itself.
  user.rb                    Aggregate root: an account, a normalised email and a password digest
                               (never the password). User.register makes one; #authenticate checks one
  user_repository.rb         Every User: the collection the domain defines, with one account per email
  list.rb                    Aggregate root: a named list, owned by one user, holding its todos.
                               Adding, completing, tagging and removing todos happen here
  todo.rb                    An entity inside a List: a title that can't be blank, at most 5 tags
  tag.rb                     A value object: normalised (#Home -> home), letters, digits, dashes
  list_repository.rb         Every List, todos and all. There is no todo repository
  password_hasher.rb         What a User needs to keep a password safe
  not_found.rb, invalid_input.rb   The two ways the model says no
infrastructure/            Ruby implementations, shared by Rails and Sinatra
  sql/                       The repositories over Sequel: SQLite in memory, or Postgres via DATABASE_URL
  scrypt_password_hasher.rb  scrypt, from OpenSSL
presentation/              The page template, once per engine (erb/, slim/); plain HTML plus locals
lib/omni/                  Stack selection (OMNI_*) and the Ruby composition root
apps/
  sinatra/                 Sinatra app layer
  rails/                   Rails app layer (ActionController + ActionView only; no Active Record)
  opal_node/               Ruby compiled with Opal and run by Node, with its own infrastructure:
    app/omni_node/infrastructure/  node:sqlite (DatabaseSync), pg-native (querySync), node:crypto (scrypt, UUIDs)
  ruby_wasm/               CRuby compiled to WebAssembly, in the browser (outside the matrix; see below)
test/architecture_test.rb  The rules below, enforced: no service objects, no ports or adapters
features/                  One set of Cucumber specs, run unchanged against every cell
bin/                       omni, omni-test, omni-matrix, omni-domain-check, omni-wasm, omni-wasm-test
```

The composition root reads the stack from the environment and builds the
infrastructure: the two repositories and the password hasher. Each app
layer only translates HTTP into the same three moves: load an aggregate
from its repository, tell it what to do, save it. It then renders a
shared template. `/health` reports what was actually built (the
connected database, the loaded template engine), not an echo of the
environment.

### No service objects

There isn't one, and `test/architecture_test.rb` fails the build if one
appears. A service object gives a process a class of its own
(`TodoService#add_todo`, `CreateList.call`), which pulls behaviour out of
the structures it belongs to and leaves them as bags of data. Here the
behaviour lives where the data does:

- **Aggregates enforce their own rules.** A `List` is the only way to
  reach its todos: `list.add(...)`, `list.complete(id)`,
  `list.tag(id, tags)`, `list.remove(id)`. A todo id from another list is
  `NotFound`, because the list doesn't have it.
- **Entities and value objects validate themselves.** A `Todo` refuses a
  blank title or a sixth tag; a `Tag` normalises itself; a `User`
  registers itself and checks its own password.
- **Rules about the whole collection live on the repository.** One
  account per email (`UserRepository#add`), and "someone else's list
  looks exactly like a missing one" (`ListRepository#fetch`).
- **The app layer coordinates.** A controller action is the only place
  a use case is spelled out, and it's three lines:
  ```ruby
  list = lists.fetch(params[:list_id], owner: current_user)
  list.complete(params[:id])
  lists.save(list)
  ```

### The repository pattern

- **One repository per aggregate root.** `UserRepository` and
  `ListRepository`. A `Todo` is part of its `List`, so it is loaded with
  it, saved with it and removed with it; there is no todo repository,
  and nothing can change a todo without going through its list.
- **The domain defines them, as collections.** Each is a module in
  `domain/model/` saying what the collection must do (`find`,
  `owned_by`, `save`, `remove`), checked for every implementation by a
  shared contract in `domain/test/support/*_contract.rb`. Infrastructure
  includes the module and supplies the storage.
- **The domain's rules ride along.** The same module gives every
  implementation the methods built on that storage: `fetch(id, owner:)`
  raises `NotFound` for a list that isn't yours, `add(user)` refuses a
  taken email, `account_for(email)` returns `User::NOBODY` for a stranger
  so that signing in as one fails exactly like a wrong password. Four
  implementations (Sequel, Node SQL, a Ruby Hash, SQLite in the browser)
  get them for free.
- **Identity comes from the repository.** `next_identity` hands out
  ids before anything is stored, so no aggregate's identity depends on a
  database sequence.
- **Whole aggregates in, whole aggregates out.** `lists.find(id)` returns
  a `List` with its todos and their tags, however they're stored (three
  tables in SQL, one Hash in memory). It's a copy: nothing changes in
  storage until `lists.save(list)`.
- **Everything is synchronous**, so the same domain runs on Sequel under
  MRI and on `pg-native` under Node.

### Users, sign-in and who owns what

- **Ownership is a domain rule.** `ListRepository#fetch(id, owner:)`
  opens one of that user's lists, and a todo is found only within its
  own list. Someone else's list, or a todo from another list, raises
  `NotFound` exactly as a missing one does, so every app answers 404 and
  ids reveal nothing.
- **Accounts are the domain's too.** Emails are normalised
  (`Ada@Example.com` is `ada@example.com`) and must be unique. Passwords
  need 8 characters. A wrong password and an unknown email get the same
  answer.
- **Passwords go through a `PasswordHasher`.** The domain never
  sees how they're hashed. Both hashers use scrypt (N=16384, r=8, p=1),
  one through OpenSSL in Ruby and one through `node:crypto` in Node.
  They write the same format, `scrypt$16384$8$1$<salt>$<hash>`, so an
  account made on a Ruby stack signs in on `opal_node` against the same
  Postgres, and vice versa.
- **Who is signed in is the app layer's business.** The domain only
  ever receives a `User`.
  - Rails: its session, reset on sign-in, with its CSRF token on every form.
  - Sinatra: its cookie session.
  - `opal_node`: its own HMAC-signed cookie.

  The cookies are HttpOnly and SameSite=Lax. Set `SESSION_SECRET` to keep
  sessions across restarts; without it, each process makes up a random
  secret.

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
   - You're asked to sign in. Create an account, then a list or two.
   - Open a list, add a couple of todos and complete one.
   - Submit a blank title to see the domain's rule come back as an error.
   - Add tags (`home, #Urgent` becomes `home` and `urgent`), then filter by one.
     Try a sixth tag, or `not ok!`, and see the model's rules on every stack.
   - Restart the server: the in-memory accounts, lists and todos are gone.
3. **Rails on Postgres, with Slim.** Stop the server and boot `rails / postgres / slim`.
   - It's the same page, but the badge says rails / postgres / slim.
   - Sign up, make a list and add todos. They're in Postgres now.
   - Sign up again as someone else, in a private window. Paste the first
     user's list address: 404, because the domain says it isn't yours.
4. **The same domain on Node.** Stop it and boot `opal_node / postgres / erb`.
   - Sign in with the account you made on Rails. Node checks the password
     Ruby hashed: the same scrypt format, through `node:crypto`.
   - The lists and todos Rails just wrote are there. It's the same tables, now read by Ruby compiled to JavaScript, through `pg-native`.
   - `ps aux | grep omni.js` shows it really is a Node process.
5. **The domain is pure.** `bin/omni-domain-check` does two things:
   - loads every `domain/` file with `ruby --disable-gems`;
   - compiles `domain/` alone with Opal and runs the whole model on Node.

   Open `domain/model/`: nothing in it knows about Rails, Sinatra, SQL, HTTP sessions or Node.
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
- reset the data: every user, list and todo;
- check that `/health` matches `OMNI_*`, so a misconfigured cell fails rather than testing the wrong stack.

The specs delete everything, so give them the `omni_test` database, not the one you demo from:

```sh
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/omni_test

OMNI_APP=opal_node OMNI_PERSISTENCE=sqlite_memory OMNI_INTERFACE=erb bin/omni-test
bin/omni-matrix --run                     # every cell in turn, then a pass/fail table
bin/omni-matrix --run --app rails         # filter by any axis
bundle exec rake test                     # domain unit tests, the repository contracts on the Ruby infrastructure, the architecture rules
bin/omni-domain-check                     # the domain purity checks
```

Cuprite finds Chrome or Chromium on the usual paths. Set `BROWSER_PATH` if
yours lives somewhere else. A failing run prints the tail of the server log,
which is kept in `tmp/omni-test/`.

## The WebAssembly app

`apps/ruby_wasm` runs the whole app in your browser. Real CRuby 3.4, compiled
to WebAssembly (`wasm32-wasi`), loads the same `domain/` files as every other
app, using its own `require`. The server only hands over files; nothing runs
server-side.

```sh
npm ci --prefix apps/ruby_wasm    # once: CRuby and SQLite, compiled to WebAssembly (about 100 MB)
bin/omni-wasm                     # then open http://127.0.0.1:9393
bin/omni-wasm-test                # its browser specs (apps/ruby_wasm/features)
```

How it boots:
- `public/boot.js` starts SQLite, which is also compiled to WebAssembly.
- It downloads CRuby (about 30 MB) and mounts this repo's Ruby files into
  CRuby's virtual filesystem, laid out as on disk.
- Then it requires `app/main.rb`. From there on everything is Ruby: the UI,
  the composition root and the repositories all reach the browser through the
  `js` gem.

What the interface adds over the server-rendered pages:
- **No page loads.** Adding, completing and deleting happen in place,
  alongside All, Active and Completed filters and a live count.
- **Swap the storage while it runs.** There are three implementations of
  the same `ListRepository`:
  - a plain Ruby Hash;
  - SQLite in memory;
  - SQLite kept in localStorage, which survives a reload.
- **Inside the layers.** A diagram lights up the parts each action passes
  through. A live trace shows every call through them: the action the UI
  asked of the `List`, the repository calls made for it (fetch, find,
  next_identity, save), and what the storage did underneath (the SQL it
  ran). The trace comes from a tracing decorator the composition root
  wraps around the repository, so the domain can't tell it's there.
- **Run the repository contract in the browser.** One button runs
  `domain/test/support/list_repository_contract.rb`, the same contract CI
  runs against the Sequel repositories. It uses Minitest from CRuby's own
  stdlib and runs against the selected storage, on a scratch store.
- **Ruby in the console.** `omniRuby("RUBY_PLATFORM")` in the browser console
  evaluates Ruby in the page's VM.

It has no accounts yet. The browser has one user, who owns one list, and
the page works on that list exactly as the server apps do: fetch it from
the `ListRepository`, change it, save it. The composition root makes them with fixed ids, so the
todos kept in localStorage are still that list's after a reload.

It isn't a cell of the stack matrix. The matrix specs drive a server-side
stack through `/health` and `/__test__/reset`, and here there's no server-side
stack. Its own specs cover the same behaviour (adding, tagging, the domain's rules,
completing, deleting), plus:
- the filters;
- the persistence switcher;
- the trace;
- the contract on all three repositories;
- persistence across a reload.

CI runs them in the `ruby_wasm · browser` job.

### Adding a persistence

1. Implement the repositories: include `UserRepository` and
   `ListRepository` (from `domain/model/`) and supply their storage
   methods. Run their contracts against it; they're in
   `domain/test/support/` (`*_contract.rb`), one per repository and one
   for the password hasher.
2. Register it:
   - persistence: `infrastructure/sql.rb`, or `CompositionRoot::PERSISTENCE` in `apps/opal_node`;
   - interface: add a template directory in `presentation/`.
3. Add its name to `config/stack_matrix.yml`. Every script and the CI matrix pick it up from there.
