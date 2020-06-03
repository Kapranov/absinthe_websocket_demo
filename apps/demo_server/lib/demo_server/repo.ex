defmodule DemoServer.Repo do
  use Ecto.Repo,
    otp_app: :demo_server,
    adapter: Ecto.Adapters.Postgres
end
