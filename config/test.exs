import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :model_name_talk, ModelNameTalkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Rg468FPXZLn0WA7urn1Z1c34WeMzuc4ZESIOojAJkFuvlCi2p6nxm6mSugwgmRlp",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# A scratch log, so a test run never writes into priv/rounds.
config :model_name_talk, ledger_path: "/tmp/model_name_talk_test_ledger.log"
