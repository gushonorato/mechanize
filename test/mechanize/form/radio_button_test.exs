defmodule Mechanize.Form.RadioButtonTest do
  use ExUnit.Case, async: true
  alias Mechanize.{Page, Form}
  alias Mechanize.Form.{RadioButton, InconsistentFormError}
  alias Mechanize.Query.BadCriteriaError
  alias Mechanize.Page.Element
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
  end

  describe ".radio_buttons_with" do
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
    test "returns form", %{form: form} do
      assert match?(%Form{}, RadioButton.uncheck(form, name: "download", value: "no"))
    end

    test "check by name and value", %{form: form} do
      form = RadioButton.check(form, name: "download", value: "yes")

      fields =
        form
        |> RadioButton.radio_buttons_with()
        |> Enum.filter(& &1.checked)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}, {"download", "yes", true}]

      fields =
        form
        |> RadioButton.check(name: "download", value: "no")
        |> RadioButton.radio_buttons_with()
        |> Enum.filter(& &1.checked)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}, {"download", "no", true}]
    end

    test "check multiple radios with same name", %{form: form} do
      assert_raise InconsistentFormError, ~r/same name \(color\)/, fn ->
        RadioButton.check(form, name: "color")
      end
    end

    test "check inexistent radio button", %{form: form} do
      assert_raise BadCriteriaError, ~r/it was not found/, fn ->
        Form.check_radio_button(form, name: "lero")
      end
    end
  end

  describe ".uncheck" do
    test "returns form", %{form: form} do
      assert match?(%Form{}, RadioButton.uncheck(form, name: "color"))
    end

    test "uncheck radio by name and value", %{form: form} do
      fields =
        form
        |> Form.radio_buttons_with(checked: true)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}]

      fields =
        form
        |> RadioButton.uncheck(name: "color")
        |> Form.radio_buttons()
        |> Enum.filter(& &1.checked)

      assert fields == []
    end

    test "raise when uncheck inexistent radio button", %{form: form} do
      assert_raise BadCriteriaError, ~r/it was not found/, fn ->
        RadioButton.uncheck(form, name: "lero")
      end
    end
  end

  describe ".submit" do
    test "submit only checked radio buttons", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "user=gustavo&passwd=123456&color=red&download=yes", _} =
                 Plug.Conn.read_body(conn)

        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with()
      |> Form.check_radio_button(name: "download", value: "yes")
      |> Form.check_radio_button(name: "color", value: "red")
      |> Form.submit()
    end
  end
end
