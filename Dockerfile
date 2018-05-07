FROM elixir:1.6.4
RUN mkdir -p /opt/nine_digits
ENV MIX_ENV prod
WORKDIR /opt/nine_digits
RUN mix local.hex --force
RUN mix local.rebar --force
CMD mix do clean --only prod, deps.get --only prod, compile, run --no-halt
