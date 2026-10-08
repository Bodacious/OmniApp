# Omni

A demonstration of layered, domain-driven design. Read the README's
"No service objects" and "The repository pattern" sections before
changing the domain.

## Rules

- **Never add a service object**, whatever it's called: a class that
  gives a process its own home (`*Service`, `*UseCase`, `*Interactor`,
  `*Operation`, or anything whose public interface is one verb such as
  `call`, `perform` or `run`). `test/architecture_test.rb` fails the
  build if one appears. Put the behaviour on the structure it belongs to:
  - a rule about one aggregate goes on the aggregate (`List`, `User`);
  - a rule about a value goes on the value object (`Tag`);
  - a rule across a whole collection goes on its repository module in
    `domain/model/` (e.g. `UserRepository#add`, `ListRepository#fetch`);
  - coordination (load, tell, save) stays in the app layer: the
    controllers, the Node router, the browser UI.
- **One repository per aggregate root.** Todos live inside their List;
  don't give them a repository. Repositories are defined in the domain
  as collections, implemented by infrastructure, and checked by the
  contracts in `domain/test/support/`.
- **Name things for what they are.** No `ports/`, `adapters/`, `Ports::`
  or `Adapters::`. The domain is `domain/model/`, implementations are
  `infrastructure/`, templates are `presentation/`.
- **`domain/` requires nothing outside itself** and must run under Opal:
  no gems, no `Data`, no endless methods. `bin/omni-domain-check`
  enforces it.

## Checks

```sh
bundle exec rake test        # domain, repository contracts, architecture rules
bin/omni-domain-check        # domain purity, and the model on Opal + Node
bin/omni-matrix --run        # Cucumber against every stack cell
bin/omni-wasm-test           # the WebAssembly app's browser specs
```
