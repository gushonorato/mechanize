defmodule Mechanizex.Form.SelectTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Form.SelectList
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
             |> Enum.map(& &1.name) == ["list1", "list2"]
    end
  end

  describe ".select_lists_with" do
    test "not found returns empty list", %{form: form} do
      assert Form.select_lists_with(form, name: "lero") == []
    end

    test "select list found by name", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "list1")
             |> Enum.map(& &1.name) == ["list1"]
    end
  end

  describe ".options" do
    test "get option from a list with just one SelectList", %{form: form} do
      assert form
             |> Form.select_lists_with(name: "list1")
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 1", "1", "Option 1", false},
               {"Option 2", "2", "Option 2", true},
               {"Label 3", "3", "Option 3", false},
               {"Option 4", "Option 4", "Option 4", false}
             ]
    end

    test "get options from all SelectLists inside a list", %{form: form} do
      assert form
             |> Form.select_lists_with(name: ~r/list/)
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
             |> Form.select_lists_with(name: "list2")
             |> List.first()
             |> SelectList.options()
             |> Enum.map(&{&1.label, &1.value, Element.text(&1), &1.selected}) == [
               {"Option 5", "5", "Option 5", false}
             ]
    end
  end

  describe ".update_select_lists_with" do
    test "by criteria with name"
    test "update more than one select list at once"
  end

  describe ".select_options" do
    test "raise when option not found"
    test "raise when select list not found"
    test "raise when many options selected on single selection select list"
    test "on success return form"
    test "select by option index"
  end

  describe ".unselect_options" do
    test "raise when option not found"
    test "raise when select list not found"
    test "on success return form"
    test "select by option index"
  end
end
