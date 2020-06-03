defmodule DemoServerQL.Schema.Types do
  use Absinthe.Schema.Notation

  object :employee do
    field :id, :id
    field :name, :string
    field :email, :string
  end
end
