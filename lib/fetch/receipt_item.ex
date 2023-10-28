defmodule Fetch.ReceiptItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias Fetch.Receipt

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "receipt_item" do
    belongs_to :receipt, Receipt
    field :short_description, :string
    field :price, :decimal
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [:short_description, :price])
    |> validate_required([:short_description, :price])
  end
end
