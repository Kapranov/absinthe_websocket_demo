use Mix.Config

config :demo_server, DemoServer.Repo,
  username: "postgrey",
  password: "postgrey",
  database: "postgrey",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :demo_client, DemoClient.Repo,
  username: "postgrey",
  password: "postgrey",
  database: "postgrey",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
