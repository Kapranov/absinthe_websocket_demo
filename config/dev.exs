use Mix.Config

config :demo_server, DemoServer.Repo,
  username: "postgrey",
  password: "postgrey",
  database: "postgrey",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :demo_client, DemoClient.Repo,
  username: "postgrey",
  password: "postgrey",
  database: "postgrey",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :demo_client, DemoServerQLApi,
  client: DemoServerQLApi.Client,
  query_caller: CommonGraphQLClient.Caller.Http,
  http_api_url: "http://127.0.0.1:4000/api"

config :demo_client, DemoServerQLApi,
  client: DemoServerQLApi.Client,
  query_caller: CommonGraphQLClient.Caller.Http,
  http_api_url: "http://127.0.0.1:4000/api",
  subscription_caller: CommonGraphQLClient.Caller.WebSocket,
  websocket_api_url: "ws://127.0.0.1:4000/socket/websocket"
