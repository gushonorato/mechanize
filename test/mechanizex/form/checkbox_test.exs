defmodule Mechanizex.Form.CheckboxTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Form.Checkbox
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/checkbox_test.html")
    {:ok, Map.put(vars, :form, Page.form(page))}
  end

  describe ".checkboxes" do
    test "retrieve checkboxes and only checkboxes", %{form: form} do
      checkboxes =
        form
        |> Form.checkboxes()
        |> Enum.map(&{&1.label, &1.name, &1.value, &1.checked})

      assert checkboxes == [
               {nil, "male", nil, true},
               {nil, "female", nil, false},
               {nil, "green", nil, false},
               {nil, "green", nil, false},
               {nil, "red", nil, false},
               {nil, "blue", nil, false},
               {nil, "yellow", nil, false},
               {nil, "brown", nil, false},
               {nil, "purple", nil, false},
               {nil, "download", "yes", true},
               {nil, "download", "no", false}
             ]
    end
  end

  describe ".check" do
    test "check by criteria with name", %{form: form} do
      checked =
        form
        |> Checkbox.check(name: "female")
        |> Form.checkboxes_with(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["male", "female", "download"]
    end

    test "check by criteria with name and value", %{form: form} do
      checked =
        form
        |> Checkbox.check(name: "download", value: "no")
        |> Form.checkboxes_with(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["male", "download", "download"]
    end
  end

  describe ".uncheck" do
    test "uncheck by criteria with name", %{form: form} do
      checked =
        form
        |> Checkbox.uncheck(name: "male")
        |> Form.checkboxes_with(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["download"]
    end

    test "uncheck by criteria with name and value", %{form: form} do
      checked =
        form
        |> Checkbox.uncheck(name: "download", value: "yes")
        |> Form.checkboxes_with(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["male"]
    end
  end
end
