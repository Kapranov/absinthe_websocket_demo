use Mix.Config

config :demo_client, DemoClient.Repo,
  username: "postgrey",
  password: "postgrey",
  database: "postgrey",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :demo_client, DemoClientWeb.Endpoint,
  http: [port: 4003],
  server: false


config :demo_client, DemoServerQLApi,
  client: DemoServerQLApi.Client,
  query_caller: CommonGraphQLClient.Caller.Http,
  http_api_url: "http://127.0.0.1:4003/api"

config :demo_client, DemoServerQLApi,
  client: DemoServerQLApi.Client,
  query_caller: CommonGraphQLClient.Caller.Http,
  http_api_url: "http://127.0.0.1:4000/api",
  subscription_caller: CommonGraphQLClient.Caller.WebSocket,
  websocket_api_url: "ws://127.0.0.1:4003/socket/websocket"

config :logger, level: :warn
