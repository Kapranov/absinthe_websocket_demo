use Mix.Config

config :demo_server, DemoServer.Repo,
  username: "postgrey",
  password: "postgrey",
  database: "postgrey",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :demo_server, DemoServerWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
