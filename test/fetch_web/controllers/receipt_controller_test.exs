defmodule FetchWeb.ReceiptControllerTest do
  use FetchWeb.ConnCase
  alias Fetch.Repo
  alias Fetch.Receipt

  defmacrop d(num) do
    decimal = Decimal.new(num)

    quote do
      unquote(Macro.escape(decimal))
    end
  end

  test "process receipt", %{conn: conn} do
    receipt = %{
      retailer: "Target",
      purchaseDate: "2022-01-01",
      purchaseTime: "13:01",
      items: [
        %{
          shortDescription: "Mountain Dew 12PK",
          price: "6.49"
        },
        %{
          shortDescription: "Emils Cheese Pizza",
          price: "12.25"
        },
        %{
          shortDescription: "Knorr Creamy Chicken",
          price: "1.26"
        },
        %{
          shortDescription: "Doritos Nacho Cheese",
          price: "3.35"
        },
        %{
          shortDescription: "   Klarbrunn 12-PK 12 FL OZ  ",
          price: "12.00"
        }
      ],
      total: "35.35"
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(~p"/receipts/process", Jason.encode!(receipt))

    assert %{"id" => receipt_id} = json_response(conn, 200)

    assert %Fetch.Receipt{
             id: ^receipt_id,
             retailer: "Target",
             purchase_date: ~D[2022-01-01],
             purchase_time: ~T[13:01:00],
             total: d("35.35"),
             items: [
               %Fetch.ReceiptItem{
                 id: _,
                 receipt_id: ^receipt_id,
                 short_description: "Mountain Dew 12PK",
                 price: d("6.49")
               },
               %Fetch.ReceiptItem{
                 id: _,
                 receipt_id: ^receipt_id,
                 short_description: "Emils Cheese Pizza",
                 price: d("12.25")
               },
               %Fetch.ReceiptItem{
                 id: _,
                 receipt_id: ^receipt_id,
                 short_description: "Knorr Creamy Chicken",
                 price: d("1.26")
               },
               %Fetch.ReceiptItem{
                 id: _,
                 receipt_id: ^receipt_id,
                 short_description: "Doritos Nacho Cheese",
                 price: d("3.35")
               },
               %Fetch.ReceiptItem{
                 id: _,
                 receipt_id: ^receipt_id,
                 short_description: "   Klarbrunn 12-PK 12 FL OZ  ",
                 price: d("12")
               }
             ]
           } = Repo.get!(Receipt, receipt_id) |> Repo.preload(:items)
  end

  test "process invalid receipt 400", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(
        ~p"/receipts/process",
        Jason.encode!(%{})
      )

    assert json_response(conn, 400) == %{
             "errors" => %{
               "purchase_date" => "can't be blank",
               "purchase_time" => "can't be blank",
               "retailer" => "can't be blank",
               "total" => "can't be blank"
             }
           }
  end

  test "calculate points - example 1", %{conn: conn} do
    receipt =
      %{
        retailer: "Target",
        purchase_date: "2022-01-01",
        purchase_time: "13:01",
        items: [
          %{
            short_description: "Mountain Dew 12PK",
            price: "6.49"
          },
          %{
            short_description: "Emils Cheese Pizza",
            price: "12.25"
          },
          %{
            short_description: "Knorr Creamy Chicken",
            price: "1.26"
          },
          %{
            short_description: "Doritos Nacho Cheese",
            price: "3.35"
          },
          %{
            short_description: "   Klarbrunn 12-PK 12 FL OZ  ",
            price: "12.00"
          }
        ],
        total: "35.35"
      }
      |> Receipt.changeset()
      |> Repo.insert!()

    conn = get(conn, ~p"/receipts/#{receipt.id}/points")

    assert json_response(conn, 200) == %{"points" => 28}
  end

  test "calculate points - example 2", %{conn: conn} do
    receipt =
      %{
        retailer: "M&M Corner Market",
        purchase_date: "2022-03-20",
        purchase_time: "14:33",
        items: [
          %{
            short_description: "Gatorade",
            price: "2.25"
          },
          %{
            short_description: "Gatorade",
            price: "2.25"
          },
          %{
            short_description: "Gatorade",
            price: "2.25"
          },
          %{
            short_description: "Gatorade",
            price: "2.25"
          }
        ],
        total: "9.00"
      }
      |> Receipt.changeset()
      |> Repo.insert!()

    conn = get(conn, ~p"/receipts/#{receipt.id}/points")

    assert json_response(conn, 200) == %{"points" => 109}
  end

  test "calculate points 404", %{conn: conn} do
    conn = get(conn, ~p"/receipts/#{Ecto.UUID.generate()}/points")
    assert json_response(conn, 404) == %{"errors" => %{"detail" => "Not Found"}}
  end
end
