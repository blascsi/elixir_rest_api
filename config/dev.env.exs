import Config

config :rest_api,
  port: 8000

config :rest_api, RestApi.Repo,
  database: "rest_api_dev",
  username: "elixir",
  password: "asdQWE123",
  hostname: "localhost"
