use Mix.Config

config :logger, level: :info

config :nine_digits,
  ip: {127, 0, 0, 1},
  port: 4000,
  concurrency: 5,
  file_path: "numbers.log"
