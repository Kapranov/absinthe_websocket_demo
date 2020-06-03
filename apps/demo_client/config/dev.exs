use Mix.Config

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

config :demo_client, DemoClientWeb.Endpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :demo_client, DemoClientWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/demo_client_web/{live,views}/.*(ex)$",
      ~r"lib/demo_client_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
