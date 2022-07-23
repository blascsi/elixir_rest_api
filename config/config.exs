import Config

config :rest_api, ecto_repos: [RestApi.Repo]

import_config "#{config_env()}.env.exs"
