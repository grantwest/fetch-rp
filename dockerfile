FROM elixir:1.15.6

COPY . /app
WORKDIR /app
ENV MIX_ENV=dev
RUN mix deps.get && \
    mix compile && \
    mix ecto.setup

EXPOSE 4001

CMD mix phx.server
