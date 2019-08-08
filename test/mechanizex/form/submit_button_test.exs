defmodule Mechanizex.Form.SubmitButtonTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{ClickError, SubmitButton}
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/submit_button_test.html")
    {:ok, Map.put(vars, :form, Page.form_with(page))}
  end

  describe ".submit_buttons" do
    test "get all submit buttons", %{form: form} do
      expectation = [
        {"button1", "button1_value", "button1_value", nil, false},
        {"button2", "button2_value", "button2_value", nil, false},
        {nil, "button3_value", "button3_value", nil, false},
        {"button4", "button4_value", nil, nil, false},
        {"button5", "button5_value", "Button 5", nil, false},
        {nil, "button6_value", "Button 6", nil, false},
        {"button7", "button7_value", "Button 7", nil, false},
        {"button8", "button8_value", "Button 8", nil, false},
        {nil, nil, "Button 9", "button9", true},
        {"button10", "button10_value", "Button 10", nil, false},
        {"button14", "button14_value", "Button 14", nil, false},
        {"button15", "button15_value", "Button 15", nil, false},
        {"button16", "button16_value", "Button 16", nil, false},
        {"button17", "button17_value", "Button 17", nil, false},
        {"button18", "button18_value", "Button 18", nil, false},
        {"button19", "button19_value", "Button 19", nil, false},
        {"BUTTON20", "button20_value", "Button 20", nil, false}
      ]

      result =
        form
        |> Form.submit_buttons()
        |> Enum.map(fn f = %{name: name, value: value, label: label} ->
          {name, value, label, Element.attr(f, :id), Element.attr_present?(f, :disabled)}
        end)

      assert result == expectation
    end
  end

  describe ".click_button" do
    test "label not match", %{form: form} do
      {:error, error} =
        form
        |> SubmitButton.click("Button 1")

      assert %ClickError{} = error
      assert error.message =~ ~r/not found/i
    end

    test "criteria not match", %{form: form} do
      {:error, error} =
        form
        |> SubmitButton.click(name: "lero")

      assert %ClickError{} = error
      assert error.message =~ ~r/not found/i
    end

    test "multiple labels match", %{form: form} do
      {:error, error} =
        form
        |> SubmitButton.click(~r/Button/i)

      assert %ClickError{} = error
      assert error.message =~ ~r/16 buttons were found./i
    end

    test "multiple criteria match", %{form: form} do
      {:error, error} =
        form
        |> SubmitButton.click(name: ~r/button/)

      assert %ClickError{} = error
      assert error.message =~ ~r/13 buttons were found./i
    end

    test "a nil button", %{form: form} do
      {:error, error} =
        form
        |> SubmitButton.click(nil)

      assert %ArgumentError{} = error
      assert error.message =~ ~r/button is nil./i
    end

    test "button click success with label", %{form: form, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/submit"
        Plug.Conn.resp(conn, 200, "Lero lero")
      end)

      {:ok, page} =
        form
        |> SubmitButton.click("Button 6")

      assert Page.body(page) == "Lero lero"
    end

    test "button click success with name", %{form: form, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/submit"
        Plug.Conn.resp(conn, 200, "Lero lero")
      end)

      {:ok, page} =
        form
        |> SubmitButton.click(name: "button1")

      assert Page.body(page) == "Lero lero"
    end
  end
end
