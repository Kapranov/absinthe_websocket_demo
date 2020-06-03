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
