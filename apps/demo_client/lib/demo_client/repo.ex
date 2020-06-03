defmodule DemoClient.Repo do
  use Ecto.Repo,
    otp_app: :demo_client,
    adapter: Ecto.Adapters.Postgres
end
