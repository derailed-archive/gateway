FROM elixir:latest as release

WORKDIR /
COPY . .

# required for mix release deps
RUN mix local.hex --force
RUN mix local.rebar --force
# release a production version
ENV MIX_ENV=prod
ENV RELEASE_COOKIE=derailed-gateway-cookie
ENV GUILD_NODES=guilds@127.0.0.1
ENV READY_NODES=ready@127.0.0.1
ENV SESSION_NODES=sessions@127.0.0.1
RUN mix deps.get
RUN mix deps.compile
RUN mix release

# recopy to open new build files
FROM elixir:latest

COPY --from=release /_build/prod/rel/derailed .

CMD [ "/bin/derailed", "start" ]
