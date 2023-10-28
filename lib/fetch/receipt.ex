defmodule Fetch.Receipt do
  use Ecto.Schema
  require Integer
  import Ecto.Changeset
  alias __MODULE__
  alias Fetch.ReceiptItem
  alias Decimal, as: D

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "receipt" do
    field :retailer, :string
    field :purchase_date, :date
    field :purchase_time, :time
    field :total, :decimal

    has_many :items, ReceiptItem
  end

  def changeset(attrs) do
    changeset(%Receipt{}, attrs)
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [:retailer, :purchase_date, :purchase_time, :total])
    |> validate_required([:retailer, :purchase_date, :purchase_time, :total])
    |> cast_assoc(:items, with: &ReceiptItem.changeset/2)
  end

  def points(%Receipt{} = receipt) do
    [
      &retailer_name_length_points/1,
      &total_round_dollar_points/1,
      &even_quarter_points/1,
      &item_pairs_points/1,
      &item_desc_multiple_of_three_points/1,
      &odd_date_points/1,
      &between_2pm_and_4pm_points/1
    ]
    |> Enum.reduce(d(0), fn point_calculator, points_acc ->
      points_from_calc = point_calculator.(receipt) |> d()
      D.add(points_acc, points_from_calc)
    end)
  end

  defp retailer_name_length_points(receipt) do
    receipt.retailer
    |> String.graphemes()
    |> Enum.filter(&Regex.match?(~r/[a-zA-Z0-9]/, &1))
    |> Enum.count()
  end

  defp total_round_dollar_points(receipt) do
    if D.integer?(receipt.total), do: 50, else: 0
  end

  defp even_quarter_points(receipt) do
    remainder = D.rem(receipt.total, d("0.25"))
    if D.eq?(remainder, 0), do: 25, else: 0
  end

  defp item_pairs_points(receipt) do
    num_pairs = Enum.count(receipt.items) |> div(2)
    num_pairs * 5
  end

  defp item_desc_multiple_of_three_points(receipt) do
    receipt.items
    |> Enum.map(fn item ->
      length =
        item.short_description
        |> String.trim()
        |> String.graphemes()
        |> Enum.count()

      if rem(length, 3) == 0 do
        D.mult(item.price, d("0.2"))
        |> D.round(0, :up)
        |> D.to_integer()
      else
        0
      end
    end)
    |> Enum.sum()
  end

  defp odd_date_points(receipt) do
    purchase_day_odd = Integer.is_odd(receipt.purchase_date.day)
    if purchase_day_odd, do: 6, else: 0
  end

  defp between_2pm_and_4pm_points(receipt) do
    time = receipt.purchase_time
    # invert before? and after? because they are exclusive
    between_2pm_4pm? = !Time.before?(time, ~T[14:00:00]) and !Time.after?(time, ~T[16:00:00])
    if between_2pm_4pm?, do: 10, else: 0
  end

  defp d(number), do: Decimal.new(number)
end
