defmodule RestApiTest.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias RestApi.Repo

      import Ecto
      import Ecto.Query
      import RestApiTest.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(RestApi.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(RestApi.Repo, {:shared, self()})
    end

    :ok
  end
end
