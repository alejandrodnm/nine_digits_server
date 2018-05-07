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
- Slow tests because we need to make sure that the process wrote to the file
and there are some async processes
test supervisor tree
