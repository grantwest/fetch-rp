defmodule FetchWeb.ReceiptController do
  use FetchWeb, :controller
  alias Fetch.Receipt
  alias Fetch.Repo

  action_fallback FetchWeb.FallbackController

  def process(conn, params) do
    with {:ok, receipt} <- Repo.insert(Receipt.changeset(params)) do
      json(conn, %{id: receipt.id})
    end
  end

  def points(conn, %{"id" => receipt_id}) do
    with %Receipt{} = receipt <- Repo.get(Receipt, receipt_id) || {:error, :not_found} do
      receipt = Repo.preload(receipt, :items)

      points =
        Receipt.points(receipt)
        |> Decimal.round()
        |> Decimal.to_integer()

      json(conn, %{points: points})
    end
  end
end
