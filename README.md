# Nine Digits

**To view this document and the code documentation in html format open
`./doc/index.html`**

TCP server for receiving nine digits numbers

## Installation and Running

This project requires Elixir 1.6 and Erlang 20 to run (It could work with
Erlang >= 18 but it has only been tested with 20). In case you don't have any of
those installed the project has a Docker image and a Makefile to execute
`mix` tasks with Docker:

- **build**: creates the Docker image.
- **clean**: deletes the docker images.
- **run** - `mix do clean --only prod, run --no-halt`: executes the program.
- **tests** - `mix test`: runs the tests.
- **lint** - `mix do credo, format --check-formatted`: runs code checks with
credo and the elixir formatter.
- **coverage** - `mix coveralls`: runs the tests and displays the code coverage.
- **coverage-html** - `mix coveralls.html`: generates the html page with detail
coverage in the `./cover` directory.
- **type-check** - `mix dialyzer`: runs the type check with `dialyzer`. The
- first time it is run it takes a couple of minutes to build the Persistent
Lookup Table (PLT), but they should be already included in the `_build` directory.
- **docs** - `mix docs`: generates the html documentation.
- **load-test**: runs a load test using `docker-compose`, it creates two
containers, one that runs the server listening on port 4000, and
another that creates 5 connections and starts sending random data to the server.

## Design an implementation

Let's start with the supervision tree:

![alt supervision tree](./supervision_tree.png)

Each box represents a process that runs on the Erlang VM (BEAM), this processes
are very light-weight and the BEAM has it's own process schedulers which can move
processes around different cores for maximum concurrency.

There are two kind of processes, the ones that implement a part of the
application logic, and the `Supervisor`s, which keep track of the state of its
children processes and implement the restart logic in case one of them fails.
Although the diagram doesn't display the correct order, `Supervisor`s start
their children in order depth first and shut them off in the reverse order,
in this case it will be:

`Repo` ->

`Stats` ->

`Writer.Supervisor` -> `Writer` 1..n ->

`Server.Supervisor` -> `Server` -> `Connection.Supervisor` -> `Connection` 1..n ->

A basic overview of the application goes like this. On start `Repo` will
remove the existing `numbers.log` file, and starts two `ETS` tables
([Erlang Term Storage](http://erlang.org/doc/man/ets.html)), one that stores
the unique numbers and another with the duplicates counter, `ETS` tables
provide a set of atomic operations suitable for concurrent writes; to further
increase performance both tables are started with the `:write_concurrency`
flag, which increases memory consumption over write speed.

The `Stats` process times-out every 10 seconds and asks `Repo` for the
duplicate counter and the total unique numbers stored, computes the difference
between the current and last timeout and prints it to stdout.

Each `Writer` maintains an open reference to the file,
[Erlang IO](http://erlang.org/doc/apps/stdlib/io_protocol.html) is handle
through a separate process, the IO reference of a `Writer` process is
optimize for writes with the `:delayed_write` option, this means that the
process will buffer writes until they reach 64 KB or a 2 seconds timeout
is triggered.

For the TCP connections part we spawn a `Server` process that opens the
TCP socket and binds the port creating a listening socket. Each `Connection`
process retrieves the listening socket from `Sever` to start listening for new
client connections. Once a connection is established the client can start
sending data, `Connection` will receive the raw data parse it and update the
corresponding `ETS` table, if the number is a duplicate it will only increase
the duplicates counter, but if it receives a new number, it will add it to the
numbers table and send an asynchronous requests to a `Writter` to append the
new number to the file.

## Assumptions

This application was made assuming that it's purpose is to process as many
requests as possible, that clients will maintain and open connection and send
burst of messages taking advantage of Nagle's algorithm (merges small
TCP messages and sends them as one), that way the `Connection` processes
will parse messages in bulk increasing throughput.

If there are no open slots for connections new client will just sit in the
ready for connection queue, in case that the desire behavior would be to
reject incoming connections the backlog value for the listening socket could
be set to decrease the number of users that could wait in the queue.

There will never be idle connections, that way it doesn't make sense to load
balance the `Writter`s processes, because the load will always be the same
for every `Connection` process.

## Things I tried, some worked some didn't.

- Using `Task.async_stream` to parse items in parallel, mostly, I think,
because the numbers of items that come in a single packet is not that big.
- Sharding the `ETS` table, instead of a global unique numbers table, I tried
creating a table per digit 0-9, because the numbers are padded with zero the
numbers will be distributed evenly across the tables, but this didn't make
a difference.
- At first I parsed items with a regex, but performance was poor, changing the
parsing algorithm to check length and `Integer.parse` reduce the processing
time.
- In the first implementation I tried with a single process for writing to
the file, the problem was that it received more messages than it processed. To
remove the bottleneck I created one `Writer` for each `Connection`, tried
with synchronous messages but performance was poor, so I left it with
asynchronous messages. With async there is a risk that the message queue gets
fill quicker than it's emptied but the tests I performed this not seems to
be the case.
- To reduce memory consumption I tried with `DETS` instead of `ETS`, the latter
is kept in memory while the former writes to disks, but write speed was really
poor.

## Difficulties

- I think that since college I've never worked directly with TCP.
- I'm fairly new working with Elixir/Erlang, I must say that it's an amazing
language and ecosystem. I choose it because it fits perfectly for this kind of
problems of networking and concurrency. It's not the fastest language for data
processing, but given all its attributes you get constant throughput,
predictability and fault tolerance.
- Withstanding attacks from this -> ![alt text](./danger.jpeg)
