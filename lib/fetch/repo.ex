defmodule Fetch.Repo do
  use Ecto.Repo,
    otp_app: :fetch,
    adapter: Ecto.Adapters.SQLite3
end
