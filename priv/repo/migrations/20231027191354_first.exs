defmodule Fetch.Repo.Migrations.First do
  use Ecto.Migration

  def change do
    create table(:receipt) do
      add :retailer, :string, null: false
      add :purchase_date, :date, null: false
      add :purchase_time, :time, null: false
      add :total, :decimal, null: false
    end

    create table(:receipt_item) do
      add :receipt_id, references(:receipt, on_delete: :delete_all)
      add :short_description, :string, null: false
      add :price, :decimal, null: false
    end

    create index(:receipt_item, [:receipt_id])
  end
end
