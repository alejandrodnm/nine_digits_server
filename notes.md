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
- Write from multiple processes
- Rely on Nagle's algorithm for buffering writes after processing

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


# Test write to disk

## No writes
23467
23643
23743
28559


2018-05-03 12:56:17.739714 - Received 1730874 unique numbers, 0 duplicates. Unique total 1730874
2018-05-03 12:56:27.762096 - Received 3657045 unique numbers, 0 duplicates. Unique total 5387919
2018-05-03 12:56:37.764998 - Received 3898133 unique numbers, 0 duplicates. Unique total 9286052
2018-05-03 12:56:47.766058 - Received 713948 unique numbers, 0 duplicates. Unique total 10000000

14:56:34.936 [warn]  FINISHED in 23150
14:56:36.545 [warn]  FINISHED in 24758
14:56:37.407 [warn]  FINISHED in 25621
14:56:38.203 [warn]  FINISHED in 26416
14:56:39.994 [warn]  FINISHED in 28208

## One file per writter no buffer

1.
2018-05-03 13:27:53.762881 - Received 1619741 unique numbers, 0 duplicates. Unique total 1619741
2018-05-03 13:28:03.798626 - Received 2256463 unique numbers, 0 duplicates. Unique total 3876204
2018-05-03 13:28:13.800167 - Received 1624084 unique numbers, 0 duplicates. Unique total 5500288
2018-05-03 13:28:23.805844 - Received 1652956 unique numbers, 0 duplicates. Unique total 7153244
2018-05-03 13:28:33.813247 - Received 1824932 unique numbers, 0 duplicates. Unique total 8978176

15:28:31.806 [warn]  FINISHED in 46522
15:28:33.631 [warn]  FINISHED in 48345
15:28:38.413 [warn]  FINISHED in 53129
15:28:39.335 [warn]  FINISHED in 54051
15:28:40.327 [warn]  FINISHED in 55043


2.

2018-05-03 13:32:47.571216 - Received 1622963 unique numbers, 0 duplicates. Unique total 1622963
2018-05-03 13:32:57.584150 - Received 2464948 unique numbers, 0 duplicates. Unique total 4087911
2018-05-03 13:33:07.585361 - Received 1991042 unique numbers, 0 duplicates. Unique total 6078953
2018-05-03 13:33:17.586201 - Received 1813840 unique numbers, 0 duplicates. Unique total 7892793
2018-05-03 13:33:27.587223 - Received 1736489 unique numbers, 0 duplicates. Unique total 9629282
2018-05-03 13:33:37.613650 - Received 370718 unique numbers, 0 duplicates. Unique total 10000000

15:33:20.202 [warn]  FINISHED in 40544
15:33:24.565 [warn]  FINISHED in 44907
15:33:27.476 [warn]  FINISHED in 47807
15:33:30.029 [warn]  FINISHED in 50371
15:33:30.400 [warn]  FINISHED in 50742


## One file per writter with buffer
