defmodule Mechanize.Form.SelectTest do
  use ExUnit.Case, async: true
  alias Mechanize.{Page, Form}
  alias Mechanize.Form.SelectList
  alias Mechanize.Page.Element
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/select_list_test.html")
    {:ok, Map.put(vars, :form, Page.form_with(page))}
  end

  describe ".select_lists" do
    test "get all select lists", %{form: form} do
      assert form
             |> Form.select_lists()
             |> Enum.map(& &1.name) == ["select1", "select2", "multiple1"]
    end
  end

  describe ".select_lists_with" do
    test "not found returns empty list", %{form: form} do
      assert Form.select_lists_with(form, name: "lero") == []
    end

    test "select list found by name", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "select1")
             |> Enum.map(& &1.name) == ["select1"]
    end

    test "returns only select lists" do
      {:ok, %{page: page}} = stub_requests("/test/htdocs/form_test.html")

      result =
        page
        |> Page.form_with(name: "form_with_all_field_types")
        |> Form.select_lists_with(name: "input1")

      assert [%SelectList{}] = result
      assert result |> List.first() |> Element.attr(:id) == "select"
    end
  end

  describe ".options" do
    test "get option from a list with just one SelectList", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(
               &{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected, &1.index}
             ) == [
               {"Label 1", "1", "Option 1", false, 0},
               {nil, "2", "Option 2", true, 1},
               {"Label 3", "3", "Option 3", false, 2},
               {nil, "Option 4", "Option 4", false, 3}
             ]
    end

    test "get options from all SelectLists inside a list", %{form: form} do
      assert form
             |> Form.select_lists_with(name: ~r/^select/)
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", false},
               {nil, "2", "Option 2", true},
               {"Label 3", "3", "Option 3", false},
               {nil, "Option 4", "Option 4", false},
               {nil, "5", "Option 5", false}
             ]
    end

    test "get options from a SelectList struct", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "select2")
             |> List.first()
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {nil, "5", "Option 5", false}
             ]
    end
  end

  describe ".select" do
    test "raise when option not found", %{form: form} do
      assert_raise Mechanize.Query.BadQueryError, ~r/No option found/, fn ->
        SelectList.select(form, name: "select1", option: [label: ~r/Lero/])
      end
    end

    test "raise when select list not found", %{form: form} do
      assert_raise Mechanize.Query.BadQueryError, ~r/No select found/, fn ->
        SelectList.select(form, name: "lero", option: [label: ~r/Option/])
      end
    end

    test "raise when many options selected on single selection select list", %{form: form} do
      assert_raise Mechanize.Query.BadQueryError, ~r/Multiple selected/, fn ->
        SelectList.select(form, name: "select1", option: [label: ~r/Label/])
      end
    end

    test "multi select list", %{form: form} do
      assert form
             |> SelectList.select(name: "multiple1", option: [label: ~r/Label/])
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", true},
               {nil, "2", "Option 2", true},
               {"Label 3", "3", "Option 3", true},
               {nil, "Option 4", "Option 4", false}
             ]
    end

    test "on success return form", %{form: form} do
      form = SelectList.select(form, name: "select1", option: [value: "1"])
      assert match?(%Form{}, form)
    end

    test "select option by text", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", option: [text: "Option 3"])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", false},
               {nil, "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {nil, "Option 4", "Option 4", false}
             ]
    end

    test "select option by text with shortcut", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", option: "Option 3")
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", false},
               {nil, "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {nil, "Option 4", "Option 4", false}
             ]
    end

    test "select option by label", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", option: [label: "Label 3"])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", false},
               {nil, "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {nil, "Option 4", "Option 4", false}
             ]
    end

    test "select by query with attributes name and option value", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", option: [value: "1"])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", true},
               {nil, "2", "Option 2", false},
               {"Label 3", "3", "Option 3", false},
               {nil, "Option 4", "Option 4", false}
             ]
    end

    test "select option by 0-based index", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", option: 2)
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.value, Element.text(&1), &1.selected}) == [
               {"Label 1", "1", "Option 1", false},
               {nil, "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {nil, "Option 4", "Option 4", false}
             ]
    end

    test "empty query selects all options", %{form: form} do
      assert form
             |> SelectList.select(name: "multiple1")
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{Element.text(&1), &1.selected}) == [
               {"Option 1", true},
               {"Option 2", true},
               {"Option 3", true},
               {"Option 4", true}
             ]
    end

    test "selects only selects in form" do
      {:ok, %{page: page}} = stub_requests("/test/htdocs/form_test.html")

      page
      |> Page.form_with(name: "form_with_all_field_types")
      |> SelectList.select(name: "input1", option: [text: "Option 1"])
    end

    test "raise if form is nil" do
      assert_raise ArgumentError, "form is nil", fn ->
        SelectList.select(nil, name: "input1", option: [text: "Option 1"])
      end
    end
  end

  describe ".unselect" do
    test "on success return form", %{form: form} do
      match?(%Form{}, SelectList.unselect(form, name: "multiple1", option: 0))
    end

    test "raise when select list not found", %{form: form} do
      assert_raise(Mechanize.Query.BadQueryError, ~r/No select found/, fn ->
        SelectList.unselect(form, name: "lero", option: [name: ~r/Option/])
      end)
    end

    test "raise when option not found", %{form: form} do
      assert_raise Mechanize.Query.BadQueryError, ~r/No option found/, fn ->
        SelectList.unselect(form, name: "multiple1", option: [name: ~r/Lero/])
      end
    end

    test "raise if form is nil" do
      assert_raise ArgumentError, "form is nil", fn ->
        SelectList.unselect(nil, name: "input1", option: [text: "Option 1"])
      end
    end

    test "empty option query selects all option", %{form: form} do
      assert form
             |> SelectList.unselect(name: "multiple1")
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{Element.text(&1), &1.selected}) == [
               {"Option 1", false},
               {"Option 2", false},
               {"Option 3", false},
               {"Option 4", false}
             ]
    end

    test "select option by text", %{form: form} do
      assert form
             |> SelectList.unselect(name: "multiple1", option: [text: "Option 2"])
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{Element.text(&1), &1.selected}) == [
               {"Option 1", false},
               {"Option 2", false},
               {"Option 3", true},
               {"Option 4", false}
             ]
    end

    test "select option by label", %{form: form} do
      assert form
             |> SelectList.unselect(name: "multiple1", option: [label: "Label 3"])
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{Element.attr(&1, :label), &1.selected}) == [
               {"Label 1", false},
               {nil, true},
               {"Label 3", false},
               {nil, false}
             ]
    end

    test "select by query with attributes name and option value", %{form: form} do
      assert form
             |> SelectList.unselect(name: "multiple1", option: [value: "2"])
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{&1.value, &1.selected}) == [
               {"1", false},
               {"2", false},
               {"3", true},
               {"Option 4", false}
             ]
    end

    test "select option by 0-based index", %{form: form} do
      assert form
             |> SelectList.unselect(name: "multiple1", option: 1)
             |> Form.select_lists_with(name: "multiple1")
             |> SelectList.options()
             |> Enum.map(&{&1.index, &1.selected}) == [
               {0, false},
               {1, false},
               {2, true},
               {3, false}
             ]
    end
  end

  describe ".submit" do
    test "submit only selected options buttons", %{form: form, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "select1=2&select2=5&multiple1=2&multiple1=3", conn} =
                 Plug.Conn.read_body(conn)

        Plug.Conn.resp(conn, 200, "OK")
      end)

      form
      |> Form.submit()
    end
  end
end
