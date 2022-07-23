import Config

config :rest_api, port: 8001

config :rest_api, RestApi.Repo,
  database: "rest_api_test",
  username: "elixir",
  password: "asdQWE123",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
