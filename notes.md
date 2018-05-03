# ToDo

- write about no backlog limit
- restart on crashes
- connection FIXME
- one writter per connection?
- Using async_stream for processing is slower
- active: false gives a little boost but not a constant throughput
- gen_tcp.recv was slower
- try regex and it was slower than checking length and convert to string
- gonna try sharding and removing trailing zeros. It made no difference

# Perf

## Just receive

Each connection 2_000_000

time = {client, server}

- Receive packets 1 connection nothing more, active once, packet 0:
  1. One connection:
    {6978, 6974}, {6878, 6878}, {6668, 6666}, {6798, 6800}
  2. 5 connections: 17174, 17321, 17365, 16935
    clients: 10611 11989 12756 15267 15322
    servers: 10900 11991 12757 15269 15323

    clients: 11768 11824 12401 15409 15438
    servers: 11827 11827 12404 15398 15440

    clients: 11393 11534 12113 15216 15360
    servers: 11385 11523 12099 15207 15351

- Receive packets 1 connection nothing more, active once, packet line:
  1. One connection: 6238, 6154, 6176, 5967
  2. 5 connections: 18598, 19731, 19095, 19402
    clients~server: 15720 16148 17647 22517 22641
    clients~server: 15094 16643 16706 22168 22784

- Using recv gave similar stats than active once raw


# Receive and write to ets raw mode
- active once
  clients: 22556 22804 25703 26164 27175
  servers: 26631 26745 27719 27796 28272

  clients: 21144 21461 25139 27625 28382
  servers: 24702 26420 27750 28752 29394

  clients: 30400 30448 30541 35717 35820
  servers: 32739 32887 33007 36574 36661

- recv
  clients: 20579 21351 21836 27046 27547
  servers: 23719 23770 23810 28409 28701

  clients: 23279 23291 23461 30086 30609
  servers: 26047 26112 26339 31340 31618

  clients: 19989 20613 20658 26529 26990
  servers: 22758 22853 22933 27849 27908


# Test noregex

23467
23643
23743
28559

14:56:34.936 [warn]  FINISHED in 23150
14:56:36.545 [warn]  FINISHED in 24758
14:56:37.407 [warn]  FINISHED in 25621
14:56:38.203 [warn]  FINISHED in 26416
14:56:39.994 [warn]  FINISHED in 28208

