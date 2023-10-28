defmodule FetchWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(FetchWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, %Ecto.Changeset{errors: errors}}) do
    encoded_errors =
      errors
      |> Enum.map(fn {field, {reason, _}} ->
        {field, reason}
      end)
      |> Map.new()

    conn
    |> put_status(400)
    |> json(%{errors: encoded_errors})
  end
end
