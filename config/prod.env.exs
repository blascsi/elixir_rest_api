import Config

config :rest_api, port: 80

config :rest_api, RestApi.Repo,
  database: "rest_api",
  username: "elixir",
  password: "asdQWE123",
  hostname: "localhost"
