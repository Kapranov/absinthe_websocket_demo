# AbsintheWebsocketDemo

**TODO: Add description**

```
Elixir  1.10.3
phoenix 1.5
jason

```

### The GraphQL Schema and Subscription

```
bash> mix new absinthe_websocket_demo --umbrella
bash> cd absinthe_websocket_demo/apps
bash> mix phx.new demo_server
bash> mix phx.gen.html Cache Employee employees name:string email:string
```

Add the resource to your browser scope: `resources "/employees", EmployeeController`

```
bash> mix ecto.create
bash> mix ecto.migrate
bash> mix phx.new demo_client
bash> mix phx.gen.html Cache Timesheet timesheets notes:text employee_email:string employee_id:integer
```

Add the resource to your browser scope: `resources "/timesheets", TimesheetController`

```
bash> mix ecto.create
bash> mix ecto.migrate
```

You can now test the server by visiting `http://127.0.0.1:4000/graphiql`

```
query {
  employees { id email name },
  employee(id: 1) { id email name }
  employee(email: "some.one@some-domain.com") { id email name }
}

subscription {
  employee_created {
    id
    email
    name
  }
}
```

Now you can manually publish to the subscription by running this in the
console:

```
employee = DemoServer.Cache.get_employee!(1)
Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)
```

### An Elixir GraphQL Client

Now we can run `iex -S mix phx.server` and see our applications on ports
server - `localhost:4000` and client - `localhost:4001`

```
bash> iex -S mix phx.server

iex> query = "query { employee(id: 1) { id email name } }"
iex> HTTPoison.post("http://127.0.0.1:4000/api", query)
```

### CommonGraphQLClient Setup

Now you have access to commands like these:

```
DemoServerQLApi.list(:employees)
DemoServerQLApi.get(:employee, 1)
DemoServerQLApi.get_by(:employee, %{email: "some.one@some-domain.com"})

DemoServerQLApi.list!(:employees)
DemoServerQLApi.get!(:employee, 1)
DemoServerQLApi.get_by!(:employee, %{email: "some.one@some-domain.com"})

employee = DemoServer.Cache.get_employee!(1)
Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)
```

### AbsintheWebsocket Setup

You can now test it by running:

```
bash> http://localhost:4000/graphiql subscription { employeeCreated { id email name } }
iex> args = %{email: "edward_witten@gmail.com", name: "Edward G.Witten"}
iex> {:ok, employee} = DemoServer.Cache.create_employee(args)
iex> Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GraphQL Subscriptions - Connecting Phoenix Applications with Absinthe and Websockets

Eric Sullivan Chief Technology Officer 13 Jul 2018
`absinthe` `graphql` `common_graphql_client` `absinthe_websocket`

At Annkissam we’ve been updating our internal tooling. We transformed several
independent rails applications into a Constellation of Phoenix applications.
This service-oriented design has worked well, as most use cases involve a
single application (for instance, there’s a time-keeping system). However, some
use cases require coordination between services. For that, we needed
event-driven messaging. We choose GraphQL to meet that need (and as a
replacement for our REST APIs).

The first caveat to this approach is that it’s non-standard. Absinthe (The
GraphQL toolkit for Elixir) expects you’ll use Phoenix channels to manage
subscriptions via WebSockets. It provides a package to integrate with Phoenix
as well as support for javascript frameworks. Connecting from another Phoenix
application requires some effort. We created two hex packages to help with
that. If you’ve already setup absinthe subscriptions, you can skip ahead to An
Elixir GraphQL Client. The repository for this demo can be found here.

Absinthe Setup

Creating an Umbrella Project with two Phoenix Applications

For the purpose of this demo, we’re going to create an umbrella project with
two Phoenix applications. Usually these would be separate projects, but I
wanted to keep the code in one repository. Also, we’ll call one application a
server, and one a client. In practice, an application could fill both roles.

# create the umbrella app

```
$ mix new absinthe_websocket_demo --umbrella
```

# server app setup:

```
$ cd <path>/<to>/absinthe_websocket_demo/apps
$ mix phx.new demo_server
$ cd <path><to>/absinthe_websocket_demo/apps/demo_server
$ mix ecto.create
```

# client app setup:

```
$ cd <path>/<to>/absinthe_websocket_demo/apps
$ mix phx.new demo_client
$ cd <path>/<to>/absinthe_websocket_demo/apps/demo_client
$ mix ecto.create
```

We need to make one additional change to make the Phoenix endpoints happy. In
`apps/demo_client/config/dev.exs`

```
config :demo_client, DemoClientWeb.Endpoint,
  http: [port: 4001],
```

Now we can run `mix phx.server` and see our applications on ports 4000 and 4001.

The Employee and Timesheet Models

One use case we needed to solve was linking employees and timesheets. This was
complicated because we use 3rd party software for HR and Timekeeping
respectively. Email is the only common identifier, but sometimes the two
systems would disagree on that. The order of data entry was also not
consistent, and sometimes a timesheet could exist before the employee was
created.

Part of our architecture includes one Phoenix application per 3rd party
application. Its job is to synchronize with the upstream data source and add
some additional functionality. To solve the foreign key issue, we allowed the
systems to supplement the upstream data. To demonstrate this in practice, we’ll
add an employee_id field to timesheets.

It’s worth noting that the actual implementation was more complicated. We added
email records to employees and planned a workflow where unknown email records
(from timesheets and other sources) would be resolved in the HR system. For
this demo though, we’ll cover a simple case where a timesheet is created
without an employee_id. The server (which will contain employees) will notify
the client (which will contain timesheets) when a new employee is created
(through a client-initiated GraphQL Subscription). The client will then use
that data to add employee_id’s to timesheets.

Let’s add some (simplified) data models:

```
$ cd apps/demo_server
$ mix phx.gen.html Cache Employee employees name:string email:string
```

Add the resource to your browser scope in `lib/demo_server_web/router.ex`:

```
  scope "/", DemoServerWeb do
    pipe_through :browser

    get "/", PageController, :index

    resources "/employees", EmployeeController
  end
```


Remember to update your repository by running migrations:

```
$ mix ecto.migrate
$ cd apps/demo_client
$ mix phx.gen.html Cache Timesheet timesheets notes:text employee_email:string employee_id:integer
```

Add the resource to your browser scope in `lib/demo_client_web/router.ex`:

```
  scope "/", DemoClientWeb do
    pipe_through :browser

    get "/", PageController, :index

    resources "/timesheets", TimesheetController
  end
```


Remember to update your repository by running migrations:

```
$ mix ecto.migrate
```

Finally, update the `employee_id` on timesheets so that it’s not required:

```
defmodule DemoClient.Cache.Timesheet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "timesheets" do
    field :employee_email, :string
    field :employee_id, :integer
    field :notes, :string

    timestamps()
  end

  @doc false
  def changeset(timesheet, attrs) do
    timesheet
    |> cast(attrs, [:notes, :employee_email, :employee_id])
    |> validate_required([:notes, :employee_email])
  end
end
```

The UI will now allow managing of employees and timesheets (at `http://
127.0.0.1:4000/employees` and `http://127.0.0.1:4001/timesheets/`).
To link them, we’ll add GraphQL.

The GraphQL Schema

Absinthe has an excellent guide for getting started. If the following code is
new, I’d suggest starting there or with this Absinthe tutorial. After we make
these additions we’ll be able to query employees using GraphQL.

In `apps/demo_server/mix.exs`, add the following dependencies:

```
  defp deps do
    [
      {:absinthe, "~> 1.5"},
      {:absinthe_phoenix, "~> 2.0"},
      {:dataloader, "~> 1.0"},
      {:ecto_sql, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
```

Then, get those dependencies: `$ mix deps.get`

Note: At the time of writing, I had to run `mix deps.update`,
`phoenix_ecto` due to a versioning issue (that may be resolved
at this point)

In `apps/demo_server/lib/demo_server_web/router.ex` add:

```
  if Mix.env == :dev do
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: DemoServerQL.Schema,
      socket: DemoServerWeb.UserSocket,
      interface: :advanced
  end

  scope "/api" do
    pipe_through [:api]

    forward "/", Absinthe.Plug,
      schema: DemoServerQL.Schema
  end
```

Create `apps/demo_server/lib/demo_server_ql/demo_server_ql.ex`:

```
defmodule DemoServerQL.Schema do
  use Absinthe.Schema
  import_types DemoServerQL.Schema.Types

  query do
    field :employees, list_of(:employee) do
      resolve &DemoServerQL.Cache.EmployeeResolver.all/2
    end

    field :employee, :employee do
      arg :id, :id
      arg :email, :string

      resolve &DemoServerQL.Cache.EmployeeResolver.get/2
    end
  end

  subscription do
    field :employee_created, :employee do
      config fn _, _ ->
        {:ok, topic: true}
      end
    end
  end
end
```

Create `apps/demo_server/lib/demo_server_ql/types.ex`:

```
defmodule DemoServerQL.Schema.Types do
  use Absinthe.Schema.Notation

  object :employee do
    field :id, :id
    field :name, :string
    field :email, :string
  end
end
```

Create `apps/demo_server/lib/demo_server_ql/cache/employee_resolver.ex`:

```
defmodule DemoServerQL.Cache.EmployeeResolver do
  alias DemoServer.{Cache.Employee, Repo}

  import Ecto.Query, warn: false

  def all(_args, _info) do
    {:ok, Repo.all(Employee)}
  end


  def get(%{id: id}, _info) do
    case Repo.get(Employee, id) do
      nil -> {:error, :no_resource_found}
      record -> {:ok, record}
    end
  end

  def get(%{email: email}, _info) do
    query = from e in Employee, where: e.email == ^email

    case Repo.one(query) do
      nil -> {:error, :no_resource_found}
      record -> {:ok, record}
    end
  end
end
```

You can now test the server by visiting `http://127.0.0.1:4000/graphiql`. If
you haven’t already created an employee, you can use the UI to do that first.
Some queries to try:

```
query {
  employees {
    id
    name
    email
  }
}

query {
  employee(id: 1) {
    id
    name
    email
  }
}

query {
  employee(email: "some.one@some-domain.com") {
    id
    name
    email
  }
}
```

The GraphQL Subscription

Absinthe has instructions for setting up subscriptions. The abridged version is
as follows:

In `apps/demo_server/lib/demo_server/application.ex` add:

```
defmodule DemoServer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      DemoServer.Repo,
      DemoServerWeb.Endpoint,
      {Phoenix.PubSub, name: DemoServer.PubSub},
      {Absinthe.Subscription, DemoServerWeb.Endpoint}
    ]

    opts = [strategy: :one_for_one, name: DemoServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DemoServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

In `apps/demo_server/lib/demo_server_web/endpoint.ex` add:

```
defmodule DemoServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :demo_server
  use Absinthe.Phoenix.Endpoint

  socket "/socket", DemoServerWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :demo_server,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_demo_server_key",
    signing_salt: "O7Cyb9lS"

  plug DemoServerWeb.Router
end
```

In `apps/demo_server/lib/demo_server_web/channels/user_socket.ex` add:

```
defmodule DemoServerWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: DemoServerQL.Schema

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
```

We need to add subscriptions to the schema,
`apps/demo_server/lib/demo_server_ql/demo_server_ql.ex`:

```
defmodule DemoServerQL.Schema do
  use Absinthe.Schema
  import_types DemoServerQL.Schema.Types

  query do
    field :employees, list_of(:employee) do
      resolve &DemoServerQL.Cache.EmployeeResolver.all/2
    end

    field :employee, :employee do
      arg :id, :id
      arg :email, :string

      resolve &DemoServerQL.Cache.EmployeeResolver.get/2
    end
  end

  subscription do
    field :employee_created, :employee do
      config fn _, _ ->
        {:ok, topic: true}
      end
    end
  end
end
```

We now have subscriptions that we can test through the UI. To see it in action
we’ll want to start the server with a console `iex -S mix phx.server`, navigate
to `http://127.0.0.1:4000/graphiql` and execute the following query:

```
subscription {
  employee_created {
    id
    name
    email
  }
}
```

Now you can manually publish to the subscription by running this in the
console:

```
employee = DemoServer.Cache.get_employee!(1)
Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)
```

If you’ve been following along, congratulations. Seeing the javascript client
in action is pretty cool. The Absinthe team also did a great job making the
setup very simple and straightforward. If you’ll be using your subscriptions
with javascript this tutorial will no longer be useful. On the other hand, if
you’d like to communicate with the subscriptions over Elixir read on.

An Elixir GraphQL Client

Sending queries to a GraphQL endpoint is not difficult. To do this in Elixir,
first update the deps in `mix.exs`:

```
  defp deps do
    [
      {:absinthe_websocket, "~> 0.2.2"},
      {:common_graphql_client, "~> 0.6.1"},
      {:ecto_sql, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
```

Then the following command will return JSON:

```
query = """
  query {
    employee(id: 1) {
      id
      name
      email
    }
  }
"""
```

`HTTPoison.post("http://127.0.0.1:4000/api", query)`

Working with JSON is fine for a javascript front-end, but for Elixir we wanted
to map the results into structs. After duplicating identical code in several
repositories we created the CommonGraphQLClient.

CommonGraphQLClient Setup

Update the deps in `apps/demo_client/mix.exs`:

```
  defp deps do
    [
      {:absinthe_websocket, "~> 0.2.2"},
      {:common_graphql_client, "~> 0.6.1"},
      {:ecto_sql, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
```

Update the dev config in `apps/demo_client/config/dev.exs`:

```
use Mix.Config

config :demo_client, DemoClient.Repo,
  username: "kapranov",
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
```

The various queries you’ll be executing need to be stored somewhere. We adopted
a convention of placing them in a query folder. It contains a module for each
primary object. Create the following employee queries at `apps/demo_client/lib/
demo_server_ql_api/query/employee.ex`:

```
defmodule DemoServerQLApi.Query.Employee do
  @moduledoc """
  Query adapter module Employee

  The methods defined here correspond to queries for list/get helpers for api
  resource.
  """

  @doc false
  def list do
    """
    query {
      employees {
        id
        email
        name
      }
    }
    """
  end

  def get_by(%{id: _}) do
    """
    query get_employee($id: ID!) {
      employee(id: $id) {
        id
        email
        name
      }
    }
    """
  end

  def get_by(%{email: _}) do
    """
    query get_employee($email: String) {
      employee(email: $email) {
        id
        email
        name
      }
    }
    """
  end
end
```

We also need a schema that the query response will be mapped into. Our
convention is to place these in a schema folder. Create the employee schema at
`apps/demo_client/lib/demo_server_ql_api/schema/employee.ex`:

```
defmodule DemoServerQLApi.Schema.Employee do
  use CommonGraphQLClient.Schema

  api_schema do
    field :id, :integer
    field :name, :string
    field :email, :string
  end

  @cast_params ~w(id name email)a

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @cast_params)
  end
end
```

Next, we need a client that’ll gather the correct queries, post them to the
GraphQL endpoint, and map the results into the appropriate schema. The
`common_graphql_client` package includes a client module that can be used to
implement your own client. For each action, you create a handle methods that
takes 2 or 3 params. The first is the action `[:list, :list_by, :get, :get_by]`
the second is a term, and the third are any variables (optional). It’ll then
just call `do_post` with the same term, the schema, the query and the variables.

Create the client at `apps/demo_client/lib/demo_server_ql_api/client.ex`:

```
defmodule DemoServerQLApi.Client do
  use CommonGraphQLClient.Client,
    otp_app: :demo_client,
    mod: DemoServerQLApi

  defp handle(:list, :employees) do
    do_post(
      :employees,
      DemoServerQLApi.Schema.Employee,
      DemoServerQLApi.Query.Employee.list()
    )
  end

  defp handle(:get, :employee, id), do: handle(:get_by, :employee, %{id: id})

  defp handle(:get_by, :employee, variables) do
    do_post(
      :employee,
      DemoServerQLApi.Schema.Employee,
      DemoServerQLApi.Query.Employee.get_by(variables),
      variables
    )
  end

  defp handle_subscribe_to(subscription_name, mod) when subscription_name in [:employee_created] do
    do_subscribe(
      mod,
      subscription_name,
      DemoServerQLApi.Schema.Employee,
      apply(DemoServerQLApi.Subscription.Employee, subscription_name, [])
    )
  end
end
```

Lastly, we need a context. In its simplest form, it’ll act as a proxy for
calling the client. You can add additional methods, but it knows about
`[:list, :list_by, :get, :get_by]` and their ! methods. Create the context
at `apps/demo_client/lib/demo_server_ql_api.ex`:

```
defmodule DemoServerQLApi do
  @moduledoc """
  Documentation for DemoServerQLApi.

  DemoServerQLApi.list(:employees)
  DemoServerQLApi.get(:employee, 1)
  DemoServerQLApi.get_by(:employee, %{email: "some.one@some-domain.com"})

  DemoServerQLApi.list!(:employees)
  DemoServerQLApi.get!(:employee, 1)
  DemoServerQLApi.get_by!(:employee, %{email: "some.one@some-domain.com"})

  employee = DemoServer.Cache.get_employee!(1)
  Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)
  """

  use CommonGraphQLClient.Context, otp_app: :demo_client

  def subscribe do
    client().subscribe_to(:employee_created, __MODULE__)

    list!(:employees)
    |> sync_employees()
  end

  def receive(subscription_name, %{id: id, email: email}) when subscription_name in [:employee_created] do
    import Ecto.Query, warn: false
    alias DemoClient.{Cache.Timesheet, Repo}

    query = from t in Timesheet, where: t.employee_email == ^email and is_nil(t.employee_id)

    Repo.all(query)
    |> Enum.each(fn(timesheet) ->
      timesheet
      |> Ecto.Changeset.change(employee_id: id)
      |> Repo.update!()
    end)
  end

  def sync_employees(employees) do
    IO.puts "Beginning Re-connection Sync"

    employees
    |> Enum.each(fn(employee) -> receive(:employee_created, employee) end)

    IO.puts "Completed Re-connection Sync"
  end
end
```

Now you have access to commands like these:

```
  DemoServerQLApi.list(:employees)
  DemoServerQLApi.get(:employee, 1)
  DemoServerQLApi.get_by(:employee, %{email: "some.one@some-domain.com"})

  DemoServerQLApi.list!(:employees)
  DemoServerQLApi.get!(:employee, 1)
  DemoServerQLApi.get_by!(:employee, %{email: "some.one@some-domain.com"})
```

They’ll all map the results into the employee schema. You can also create more
descriptive methods in your context, like `list_employees/0` or
`find_employee_by_email/1`. Additionally, you can embed records in your GraphQL
queries and use cast_embed to map complex results into the appropriate structs.

A benefit of splitting the context from the client is that it makes testing
easier. We use the Mox library, setting the client to `DemoServerQLApi.ClientMox`
in the config, and then mocking the results to return employees as needed.

This example also doesn’t cover security. The common_graphql_client has support
for bearer tokens, but that is out of scope for this article. Additional
information and tutorials will be made available in the repository.

AbsintheWebsocket Setup

To take advantage of subscriptions we had to incorporate some new technologies,
namely WebSocket support. The connection will be persistent and so we need a
tool to support that. We settled on a WebSocket client called websockex.
However, it doesn’t know about Phoenix channels or how Absinthe subscriptions
are built on top of them. The solution was another abstraction, the
AbsintheWebsocket. It uses the WebSocket client and adds some methods for
interacting with Absinthe over Phoenix channels. It also handles the Phoenix
and Absinthe channel requirements (heartbeats and `__absinthe__:control “topics”`
respectively).

Update the deps in `apps/demo_client/mix.exs`:

```
  defp deps do
    [
      {:absinthe_websocket, "~> 0.2.2"},
      {:common_graphql_client, "~> 0.6.1"},
      {:ecto_sql, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
```

Update the dev config in `apps/demo_client/config/dev.exs`:

```
use Mix.Config

config :demo_client, DemoClient.Repo,
  username: "kapranov",
  password: ":postgrey",
  database: ":postgrey",
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
```

`absinthe_websocket` also requires adding a supervisor to your supervision tree.
Update `apps/demo_client/lib/demo_client/application.ex`:

```
defmodule DemoClient.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      DemoClient.Repo,
      {Phoenix.PubSub, name: DemoClient.PubSub},
      DemoClientWeb.Endpoint
    ] ++ [DemoServerQLApi.Client.supervisor()]

    opts = [strategy: :one_for_one, name: DemoClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DemoClientWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

At this point, the application should be able to connect. On each WebSocket
connection (or when it’s re-connected) the `subscribe/0` method will be called
on the `DemoServerQLApi` context. That’s where we’ll initiate the subscriptions.
First though, let’s create a module to store your subscriptions. Similar to
queries, we adopted the convention of a subscription folder. Create the
employee subscriptions in `apps/demo_client/lib/demo_server_ql_api/subscription/
employee.ex`:

```
defmodule DemoServerQLApi.Subscription.Employee do
  @moduledoc """
  Subscription adapter module Employee
  """

  @doc false
  def employee_created do
    """
    subscription {
      employee_created {
        id
        email
        name
      }
    }
    """
  end
end
```

To get notifications, the client needs to know how to subscribe. It’s similar
to issuing (and handling) a query, but there is no immediate response. Update
`apps/demo_client/lib/demo_server_ql_api/client.ex`:

```
defmodule DemoServerQLApi.Client do
  use CommonGraphQLClient.Client,
    otp_app: :demo_client,
    mod: DemoServerQLApi

  defp handle(:list, :employees) do
    do_post(
      :employees,
      DemoServerQLApi.Schema.Employee,
      DemoServerQLApi.Query.Employee.list()
    )
  end

  defp handle(:get, :employee, id), do: handle(:get_by, :employee, %{id: id})

  defp handle(:get_by, :employee, variables) do
    do_post(
      :employee,
      DemoServerQLApi.Schema.Employee,
      DemoServerQLApi.Query.Employee.get_by(variables),
      variables
    )
  end

  defp handle_subscribe_to(subscription_name, mod) when subscription_name in [:employee_created] do
    do_subscribe(
      mod,
      subscription_name,
      DemoServerQLApi.Schema.Employee,
      apply(DemoServerQLApi.Subscription.Employee, subscription_name, [])
    )
  end
end
```

Each received notification will call receive/1 on the mod (likely your context)
with the `subscription_name` and the schema.

With this setup done we need to initiate the subscription and handle the
responses. Both of those actions will happen in the context. Update 
`apps/demo_client/lib/demo_server_ql_api.ex`:

```
defmodule DemoServerQLApi do
  @moduledoc """
  Documentation for DemoServerQLApi.

  DemoServerQLApi.list(:employees)
  DemoServerQLApi.get(:employee, 1)
  DemoServerQLApi.get_by(:employee, %{email: "some.one@some-domain.com"})

  DemoServerQLApi.list!(:employees)
  DemoServerQLApi.get!(:employee, 1)
  DemoServerQLApi.get_by!(:employee, %{email: "some.one@some-domain.com"})

  employee = DemoServer.Cache.get_employee!(1)
  Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)
  """

  use CommonGraphQLClient.Context, otp_app: :demo_client

  def subscribe do
    client().subscribe_to(:employee_created, __MODULE__)

    list!(:employees)
    |> sync_employees()
  end

  def receive(subscription_name, %{id: id, email: email}) when subscription_name in [:employee_created] do
    import Ecto.Query, warn: false
    alias DemoClient.{Cache.Timesheet, Repo}

    query = from t in Timesheet, where: t.employee_email == ^email and is_nil(t.employee_id)

    Repo.all(query)
    |> Enum.each(fn(timesheet) ->
      timesheet
      |> Ecto.Changeset.change(employee_id: id)
      |> Repo.update!()
    end)
  end

  def sync_employees(employees) do
    IO.puts "Beginning Re-connection Sync"

    employees
    |> Enum.each(fn(employee) -> receive(:employee_created, employee) end)

    IO.puts "Completed Re-connection Sync"
  end
end
```

You can now test it by running:

`Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)`

To test it through the UI, you can update the employee controller
`apps/demo_server/lib/demo_server_web/controllers/employee_controller.ex`:

```
defmodule DemoServerWeb.EmployeeController do
  use DemoServerWeb, :controller

  alias DemoServer.Cache
  alias DemoServer.Cache.Employee

  def index(conn, _params) do
    employees = Cache.list_employees()
    render(conn, "index.html", employees: employees)
  end

  def new(conn, _params) do
    changeset = Cache.change_employee(%Employee{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"employee" => employee_params}) do
    case Cache.create_employee(employee_params) do
      {:ok, employee} ->
        Absinthe.Subscription.publish(DemoServerWeb.Endpoint, employee, employee_created: true)

        conn
        |> put_flash(:info, "Employee created successfully.")
        |> redirect(to: Routes.employee_path(conn, :show, employee))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    employee = Cache.get_employee!(id)
    render(conn, "show.html", employee: employee)
  end

  def edit(conn, %{"id" => id}) do
    employee = Cache.get_employee!(id)
    changeset = Cache.change_employee(employee)
    render(conn, "edit.html", employee: employee, changeset: changeset)
  end

  def update(conn, %{"id" => id, "employee" => employee_params}) do
    employee = Cache.get_employee!(id)

    case Cache.update_employee(employee, employee_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:info, "Employee updated successfully.")
        |> redirect(to: Routes.employee_path(conn, :show, employee))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", employee: employee, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    employee = Cache.get_employee!(id)
    {:ok, _employee} = Cache.delete_employee(employee)

    conn
    |> put_flash(:info, "Employee deleted successfully.")
    |> redirect(to: Routes.employee_path(conn, :index))
  end
end
```

Discussion

While this article started with a caveat, I’d like to repeat that you probably
don’t want to run this in production yet. We are, and it is a perfect fit for
the type of data and volume we’re dealing with. We also really liked that our
regular API and our events use the same GraphQL technology. And although our
front-end UI is not javascript heavy, using the same API proved appealing
enough that we ultimately went with this approach.

There are some rough edges in the code (for instance, it’s not documented). It
also doesn’t handle failure scenarios as well as I’d like. That said, we built
our applications assuming they would synchronize nightly. Adding subscriptions
made it more likely for the data to be up-to-date sooner. We still sync nightly
and on reconnect, so it’s eventually consistent either way.

There are certainly alternative pub-sub systems to GraphQL, and JSON is just
not great for high-throughput situations. There are scenarios where it excels
though, and we wanted to help push that boundary slightly beyond javascript
front ends. Thanks again to the Absinthe Team for their amazing work
implementing GraphQL in Elixir.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 1 June 2020 by Oleg G.Kapranov

[1]: https://www.annkissam.com/elixir/alembic/posts/2018/07/13/graphql-subscriptions-connecting-phoenix-applications-with-absinthe-and-websockets.html
[2]: https://hexdocs.pm/absinthe/subscriptions.html
[3]: https://github.com/annkissam/common_graphql_client
[4]: https://github.com/annkissam/absinthe_websocket
