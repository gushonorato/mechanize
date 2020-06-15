defmodule Mechanize.Form.CheckboxTest do
  use ExUnit.Case, async: true
  alias Mechanize.{Page, Form}
  alias Mechanize.Form.Checkbox
  alias Mechanize.Query.BadCriteriaError
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/checkbox_test.html")
    {:ok, Map.put(vars, :form, Page.form(page))}
  end

  describe ".checkboxes" do
    test "retrieve checkboxes and only checkboxes", %{form: form} do
      checkboxes =
        form
        |> Checkbox.checkboxes_with()
        |> Enum.map(&{&1.name, &1.value, &1.checked})

      assert checkboxes == [
               {"male", nil, true},
               {"female", nil, false},
               {"green", nil, false},
               {"green", nil, false},
               {"red", "", true},
               {"blue", nil, false},
               {"yellow", nil, false},
               {"brown", nil, false},
               {"purple", nil, false},
               {"download", "yes", true},
               {"download", "no", false}
             ]
    end
  end

  describe ".check" do
    test "returns a form", %{form: form} do
      assert match?(%Form{}, Checkbox.check_checkbox(form, name: "female"))
    end

    test "error when checkbox doesnt exist", %{form: form} do
      assert_raise BadCriteriaError, ~r/Can't check checkbox with criteria \[name: "lero"\]/, fn ->
        Checkbox.check_checkbox(form, name: "lero")
      end
    end

    test "check by criteria with name", %{form: form} do
      checked =
        form
        |> Checkbox.check_checkbox(name: "female")
        |> Checkbox.checkboxes_with()
        |> Enum.filter(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["male", "female", "red", "download"]
    end

    test "check by criteria with name and value", %{form: form} do
      checked =
        form
        |> Checkbox.check_checkbox(name: "download", value: "no")
        |> Checkbox.checkboxes_with()
        |> Enum.filter(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["male", "red", "download", "download"]
    end
  end

  describe ".uncheck" do
    test "correct uncheck", %{form: form} do
      assert match?(%Form{}, Checkbox.uncheck_checkbox(form, name: "download", value: "yes"))
    end

    test "uncheck by criteria with name", %{form: form} do
      checked =
        form
        |> Checkbox.uncheck_checkbox(name: "male")
        |> Checkbox.checkboxes_with()
        |> Enum.filter(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["red", "download"]
    end

    test "uncheck by criteria with name and value", %{form: form} do
      checked =
        form
        |> Checkbox.uncheck_checkbox(name: "download", value: "yes")
        |> Checkbox.checkboxes_with()
        |> Enum.filter(& &1.checked)
        |> Enum.map(& &1.name)

      assert checked == ["male", "red"]
    end

    test "error when checkbox doesnt exist", %{form: form} do
      assert_raise BadCriteriaError,
                   ~r/Can't uncheck checkbox with criteria \[name: "lero"\]/,
                   fn ->
                     Form.uncheck_checkbox(form, name: "lero")
                   end
    end
  end

  describe ".submit" do
    test "submit only checked checkboxes", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "male=on&red=&download=yes", conn} = Plug.Conn.read_body(conn)

        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with()
      |> Form.submit()
    end
  end
end
