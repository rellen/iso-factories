import Config

# TEMPORARY: Expresso 3acb139 reads its esbuild profile from its own config, which a
# dependency never loads. Remove this file once the talk pins a commit with the fix.
config :esbuild,
  version: "0.28.2",
  presenter: [
    args:
      ~w(src/main.ts --bundle --format=iife --target=es2020 --minify --outfile=../priv/static/presenter.js),
    cd: Path.expand("../deps/expresso/assets", __DIR__)
  ]
