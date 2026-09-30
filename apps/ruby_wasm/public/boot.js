// Boots the ruby_wasm app. This file is the only JavaScript in it:
//
// 1. Start SQLite, compiled to WebAssembly, and wrap it in a small
//    synchronous facade (window.omniSqlite) for the Ruby adapter.
// 2. Download CRuby 3.4, compiled to WebAssembly (wasm32-wasi).
// 3. Mount this repo's Ruby files (the domain, its port contract and
//    apps/ruby_wasm/app) into CRuby's virtual filesystem at /omni,
//    laid out exactly as on disk, so require_relative just works.
// 4. require apps/ruby_wasm/app/main.rb. From then on it's Ruby: the
//    UI, the composition root and the adapters all run in CRuby, and
//    reach the browser through the js gem.
import { ConsoleStdout, Directory, File, OpenFile, PreopenDirectory, WASI } from "@bjorn3/browser_wasi_shim";
import { RubyVM } from "@ruby/wasm-wasi";
import sqlite3InitModule from "@sqlite.org/sqlite-wasm";

const RUBY_WASM = "/vendor/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm";

const bootPanel = document.querySelector("[data-region=boot]");
const statusLine = bootPanel.querySelector("[data-boot-status]");
const progressBar = bootPanel.querySelector("[data-boot-progress]");
const status = (text) => { statusLine.textContent = text; };

// SQLite's own API is synchronous once initialised, like the domain's
// repository port. Ruby sees three kinds of database, all SQLite:
// "memory" (gone on reload), "local_storage" (kept in localStorage, so
// it survives a reload) and "session_storage" (a scratch database the
// port contract runs against, so it never touches your todos).
function sqliteFacade(sqlite3) {
  return {
    version: sqlite3.version.libVersion,
    open(kind) {
      const db = kind === "memory"
        ? new sqlite3.oo1.DB(":memory:")
        : new sqlite3.oo1.JsStorageDb(kind === "local_storage" ? "local" : "session");
      return {
        query(sql, ...bind) {
          return db.exec({ sql, bind: bind.length ? bind : undefined, rowMode: "object", returnValue: "resultRows" });
        },
        changes() { return db.changes(); },
      };
    },
  };
}

// Streams the module so the page can show download progress.
async function compileWithProgress(url, onProgress) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url} returned ${response.status}`);
  const total = Number(response.headers.get("content-length")) || 0;
  let loaded = 0;
  const counted = response.body.pipeThrough(new TransformStream({
    transform(chunk, controller) {
      loaded += chunk.byteLength;
      onProgress(loaded, total);
      controller.enqueue(chunk);
    },
  }));
  return WebAssembly.compileStreaming(new Response(counted, { headers: { "content-type": "application/wasm" } }));
}

// Fetches every Ruby file in the manifest into an in-memory directory
// tree for CRuby's WASI filesystem.
async function mountSources() {
  const manifest = await (await fetch("/manifest.json")).json();
  const root = new Map();
  const encoder = new TextEncoder();
  await Promise.all(manifest.files.map(async (path) => {
    const source = await (await fetch(`/src/${path}`)).text();
    const parts = path.split("/");
    const name = parts.pop();
    let dir = root;
    for (const part of parts) {
      if (!dir.has(part)) dir.set(part, new Directory(new Map()));
      dir = dir.get(part).contents;
    }
    dir.set(name, new File(encoder.encode(source), { readonly: true }));
  }));
  return { mount: manifest.mount, tree: new Directory(root), count: manifest.files.length };
}

async function boot() {
  const started = performance.now();
  document.body.dataset.bootId = crypto.randomUUID();

  status("Starting SQLite (WebAssembly)…");
  window.omniSqlite = sqliteFacade(await sqlite3InitModule());

  status("Downloading CRuby 3.4 (WebAssembly)…");
  const [module, sources] = await Promise.all([
    compileWithProgress(RUBY_WASM, (loaded, total) => {
      const mb = (bytes) => (bytes / 1048576).toFixed(1);
      status(`Downloading CRuby 3.4 (WebAssembly)… ${mb(loaded)} of ${mb(total)} MB`);
      if (total) progressBar.style.width = `${Math.round((loaded / total) * 100)}%`;
    }),
    mountSources(),
  ]);

  status(`Starting Ruby and requiring ${sources.count} files from the repo…`);
  const fds = [
    new OpenFile(new File([])),
    ConsoleStdout.lineBuffered((line) => console.log(`[ruby] ${line}`)),
    ConsoleStdout.lineBuffered((line) => console.warn(`[ruby] ${line}`)),
    new PreopenDirectory("/", new Map([[sources.mount.replace(/^\//, ""), sources.tree]])),
  ];
  const wasi = new WASI([], [], fds, { debug: false });
  const { vm } = await RubyVM.instantiateModule({ module, wasip1: wasi });

  window.omniBoot = { ms: Math.round(performance.now() - started), files: sources.count };
  // For the curious (and the demo): run Ruby in this page's VM from the
  // browser console, e.g. omniRuby("RUBY_PLATFORM").
  window.omniRuby = (code) => vm.eval(code).toString();
  vm.eval(`require "${sources.mount}/apps/ruby_wasm/app/main"`);
}

boot().catch((error) => {
  console.error(error);
  bootPanel.classList.add("boot--failed");
  status(`Couldn't start: ${error.message}`);
});
