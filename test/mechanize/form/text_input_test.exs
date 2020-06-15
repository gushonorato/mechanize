defmodule Mechanize.Form.TextInputTest do
  use ExUnit.Case, async: true
  alias Mechanize
  alias Mechanize.{Page, Form}
  alias Mechanize.Form.TextInput
  alias Mechanize.Query.BadCriteriaError
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/text_input_test.html")
    {:ok, Map.put(vars, :form, Page.form_with(page))}
  end

  describe ".text_inputs" do
    test "get all text inputs", %{form: form} do
      assert form
             |> TextInput.text_inputs_with()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"color1", "color1 value"},
               {"date1", "date1 value"},
               {"datetime1", "datetime1 value"},
               {"email1", "email1 value"},
               {"hidden1", "hidden1 value"},
               {"month1", "month1 value"},
               {"number1", "number1 value"},
               {"password1", "password1 value"},
               {"range1", "range1 value"},
               {"search1", "search1 value"},
               {"tel1", "tel1 value"},
               {"text1", "text1 value"},
               {"time1", "time1 value"},
               {"url1", "url1 value"},
               {"week1", "week1 value"},
               {"textarea1", "textarea1 value"}
             ]
    end
  end

  describe ".with_text_inputs" do
    test "get all text inputs which matches query", %{form: form} do
      assert form
             |> TextInput.text_inputs_with(name: ~r/^te/)
             |> Enum.map(&{&1.name, &1.value}) == [
               {"tel1", "tel1 value"},
               {"text1", "text1 value"},
               {"textarea1", "textarea1 value"}
             ]
    end
  end

  describe ".fill_text" do
    test "return form", %{form: form} do
      assert match?(%Form{}, TextInput.fill_text(form, name: "text1", with: "new text value"))
    end

    test "raise when without with clause", %{form: form} do
      assert_raise ArgumentError, ~r/No "with" clause given with text input value/, fn ->
        TextInput.fill_text(form, name: "text1")
      end
    end

    test "fill existent text field", %{form: form} do
      assert form
             |> TextInput.fill_text(name: "text1", with: "new text1 value")
             |> TextInput.text_inputs_with()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"color1", "color1 value"},
               {"date1", "date1 value"},
               {"datetime1", "datetime1 value"},
               {"email1", "email1 value"},
               {"hidden1", "hidden1 value"},
               {"month1", "month1 value"},
               {"number1", "number1 value"},
               {"password1", "password1 value"},
               {"range1", "range1 value"},
               {"search1", "search1 value"},
               {"tel1", "tel1 value"},
               {"text1", "new text1 value"},
               {"time1", "time1 value"},
               {"url1", "url1 value"},
               {"week1", "week1 value"},
               {"textarea1", "textarea1 value"}
             ]
    end

    test "raise when field does not exist", %{form: form} do
      assert_raise BadCriteriaError, ~r/it was not found/, fn ->
        TextInput.fill_text(form, name: "lero", with: "lero")
      end
    end
  end
end
