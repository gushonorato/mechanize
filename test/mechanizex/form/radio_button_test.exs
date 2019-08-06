defmodule Mechanizex.Form.RadioButtonTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Form.RadioButton
  alias Mechanizex.Page.Element
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/radio_button_test.html")
    {:ok, Map.put(vars, :form, Page.form_with(page))}
  end

  describe ".radio_buttons" do
    test "retrive all radios and only radios", %{form: form} do
      assert(
        form
        |> Form.radio_buttons()
        |> Enum.map(fn f = %{name: name, value: value, checked: checked} ->
          {name, value, Element.attr(f, :id), Element.attr_present?(f, :disabled), checked}
        end) == [
          {"color", "blue", "blue", false, false},
          {"color", "brown", nil, false, false},
          {"color", "green", nil, false, false},
          {"color", "red", nil, false, false},
          {"color", "yellow", "a", false, false},
          {"color", "yellow", "b", false, false},
          {"color", "magenta", nil, true, false},
          {"color", "orange", nil, true, true},
          {"download", "yes", nil, false, false},
          {"download", "no", nil, false, false}
        ]
      )
    end

    test "retrieving radios which matches query", %{form: form} do
      assert(
        form
        |> Form.radio_buttons_with(name: "download")
        |> Enum.map(fn f = %{name: name, value: value, checked: checked} ->
          {name, value, Element.attr(f, :id), Element.attr_present?(f, :disabled), checked}
        end) == [
          {"download", "yes", nil, false, false},
          {"download", "no", nil, false, false}
        ]
      )
    end
  end

  describe ".check" do
    test "check by name and value", %{form: form} do
      form = RadioButton.check(form, name: "download", value: "yes")

      fields =
        form
        |> Form.radio_buttons_with(fn f -> f.checked end)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}, {"download", "yes", true}]

      fields =
        form
        |> RadioButton.check(name: "download", value: "no")
        |> Form.radio_buttons_with(fn f -> f.checked end)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}, {"download", "no", true}]
    end
  end

  describe ".uncheck" do
    test "uncheck radio by name and value", %{form: form} do
      fields =
        form
        |> Form.radio_buttons_with(fn f -> f.checked end)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}]

      fields =
        form
        |> RadioButton.uncheck(name: "color")
        |> Form.radio_buttons_with(fn f -> f.checked end)

      assert fields == []
    end
  end

  describe ".submit" do
    test "submit only checked radio buttons", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert(
          Plug.Conn.fetch_query_params(conn).params == %{
            "color" => "red",
            "download" => "yes",
            "passwd" => "123456",
            "user" => "gustavo"
          }
        )

        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with()
      |> Form.check_radio_button!(name: "download", value: "yes")
      |> Form.check_radio_button!(name: "color", value: "red")
      |> Form.submit()
    end
  end
end
