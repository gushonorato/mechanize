defmodule Mechanizex.Form.SelectTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Form.{SelectList, Option}
  alias Mechanizex.Page.Element
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
  end

  describe ".options" do
    test "get option from a list with just one SelectList", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected, &1.index}) == [
               {"Option 1", "1", "Option 1", false, 0},
               {"Option 2", "2", "Option 2", true, 1},
               {"Label 3", "3", "Option 3", false, 2},
               {"Option 4", "Option 4", "Option 4", false, 3}
             ]
    end

    test "get options from all SelectLists inside a list", %{form: form} do
      assert form
             |> Form.select_lists_with(name: ~r/^select/)
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", true},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false},
               {"Option 5", "5", "Option 5", false}
             ]
    end

    test "get options from a SelectList struct", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "select2")
             |> List.first()
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 5", "5", "Option 5", false}
             ]
    end
  end

  describe ".update_select_lists" do
    test "on success return form", %{form: form} do
      assert match?(%Form{}, Form.update_select_lists(form, fn _select, option -> option end))
    end

    test "select by list name and option value", %{form: form} do
      assert form
             |> Form.update_select_lists(fn select, option ->
               cond do
                 select.name == "select1" and option.value == "3" ->
                   %Option{option | selected: true}

                 select.name == "select1" ->
                   %Option{option | selected: false}

                 true ->
                   option
               end
             end)
             |> Form.select_lists()
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false},
               {"Option 5", "5", "Option 5", false},
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", true},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "select first element of select1 by index", %{form: form} do
      assert form
             |> Form.update_select_lists(fn select, option ->
               cond do
                 select.name == "select1" and option.index == 0 ->
                   %Option{option | selected: true}

                 select.name == "select1" ->
                   %Option{option | selected: false}

                 true ->
                   option
               end
             end)
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", true},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "no select list in form", %{page: page} do
      page
      |> Page.form_with(name: "empty_form")
      |> Form.update_select_lists(fn -> raise "Should not be called." end)
    end

    test "select third option of all selects", %{form: form} do
      assert form
             |> Form.update_select_lists(fn _select, option ->
               if option.index == 2 do
                 %Option{option | selected: true}
               else
                 %Option{option | selected: false}
               end
             end)
             |> Form.select_lists()
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false},
               {"Option 5", "5", "Option 5", false},
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end
  end

  describe ".update_select_lists_with" do
    test "select by list name and option value", %{form: form} do
      assert form
             |> Form.update_select_lists_with([name: "select1"], fn _select, option ->
               if option.value == "3" do
                 %Option{option | selected: true}
               else
                 %Option{option | selected: false}
               end
             end)
             |> Form.select_lists()
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false},
               {"Option 5", "5", "Option 5", false},
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", true},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "select first element of select1 by index", %{form: form} do
      assert form
             |> Form.update_select_lists_with([name: "select1"], fn _select, option ->
               if option.index == 0 do
                 %Option{option | selected: true}
               else
                 %Option{option | selected: false}
               end
             end)
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", true},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end
  end

  describe ".select_options" do
    test "raise when option not found"
    test "raise when select list not found"
    test "raise when many options selected on single selection select list"

    test "on success return form", %{form: form} do
      form = SelectList.select(form, name: "select1", options: [value: "1"])
      assert match?(%Form{}, form)
    end

    test "select option by text", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", options: [text: "Option 3"])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "select option by label", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", options: [label: "Label 3"])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "select by criteria with attributes name and option value", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", options: [value: "1"])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", true},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "select option by 0-based index", %{form: form} do
      assert form
             |> SelectList.select(name: "select1", options: [index: 2])
             |> Form.select_lists_with(name: "select1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", false},
               {"Label 3", "3", "Option 3", true},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end
  end

  describe ".unselect_options" do
    test "raise when option not found"
    test "raise when select list not found"
    test "on success return form"
    test "select by option index"
    test "nil"
    test "empty"
  end
end
