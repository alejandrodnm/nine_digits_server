use Mix.Config

config :nine_digits,
  ip: {127, 0, 0, 1},
  port: 4000,
  concurrency: 2,
  file_path: "numbers.log",
  # if tcp_response is true the connections will send a response to the
  # clients after procesing an item
  tcp_response: true,
  # time to wait for binding the socket before stopping the process init
  # callback
  server_timeout: 200,
  # time to wait for receiving client messages before closing the connection.
  idle_timeout: 100
