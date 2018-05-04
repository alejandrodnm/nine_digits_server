use Mix.Config

config :logger, level: :info, compile_time_purge_level: :info

config :nine_digits,
  ip: {0, 0, 0, 0},
  port: 4000,
  concurrency: 5,
  file_path: "numbers.log"
