defmodule Mechanizex.Form.RadioButtonTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
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

  describe ".check_radio_button!" do
    test "check multiple radios with same name", %{form: form} do
      assert_raise Mechanizex.Form.InconsistentFormError, fn ->
        form
        |> Form.check_radio_button!(name: "download")
      end
    end

    test "check inexistent radio button", %{form: form} do
      assert_raise Mechanizex.Form.FormNotUpdatedError, fn ->
        form
        |> Form.check_radio_button!(name: "lero")
      end
    end
  end

  describe ".check_radio_button" do
    test "check by name and value", %{form: form} do
      {:ok, form} =
        form
        |> Form.check_radio_button(name: "download", value: "yes")

      fields =
        form
        |> Form.radio_buttons_with(fn f -> f.checked end)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}, {"download", "yes", true}]

      fields =
        form
        |> Form.check_radio_button(name: "download", value: "no")
        |> (fn {:ok, form} -> form end).()
        |> Form.radio_buttons_with(fn f -> f.checked end)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}, {"download", "no", true}]
    end

    test "check multiple radios with same name", %{form: form} do
      {:error, error} =
        form
        |> Form.check_radio_button(name: "download")

      assert %Mechanizex.Form.InconsistentFormError{} = error
      assert error.message =~ ~r/same name \(download\)/
    end

    test "check inexistent radio button", %{form: form} do
      {:error, error} =
        form
        |> Form.check_radio_button(name: "lero")

      assert %Mechanizex.Form.FormNotUpdatedError{} = error
      assert error.message =~ ~r/Can't check radio/
    end
  end

  describe ".uncheck_radio_button!" do
    test "uncheck radio by name and value", %{form: form} do
      assert_raise Mechanizex.Form.FormNotUpdatedError, fn ->
        form
        |> Form.uncheck_radio_button!(name: "lero")
      end
    end
  end

  describe ".uncheck_radio_button" do
    test "uncheck radio by name and value", %{form: form} do
      fields =
        form
        |> Form.radio_buttons_with(fn f -> f.checked end)
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert fields == [{"color", "orange", true}]

      fields =
        form
        |> Form.uncheck_radio_button(name: "color")
        |> (fn {:ok, form} -> form end).()
        |> Form.radio_buttons_with(fn f -> f.checked end)

      assert fields == []
    end
  end
end
