use Mix.Config

config :nine_digits,
  ip: {127, 0, 0, 1},
  port: 4000,
  concurrency: 2,
  file_path: "numbers.log",
  # if tcp_response is true the connections will send a response to the
  # clients after procesing an item
  tcp_response: true
