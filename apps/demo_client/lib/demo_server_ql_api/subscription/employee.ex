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
