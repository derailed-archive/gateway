import Config

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000,
                                 cleanup_interval_ms: 60_000 * 10]}

config :grpc, start_server: true

if Mix.env() == :prod do
  config :logger, level: :info
end
