defmodule Mechanizex.FormTest do
  use ExUnit.Case, async: true
  alias Mechanizex

  setup_all do
    {:ok, agent: Mechanizex.new(http_adapter: :local_html_file)}
  end

  describe ".fill_field" do
    test "update an existent text field by field name", %{agent: agent} do
      form =
        agent
        |> Mechanizex.get!("test/htdocs/two_forms.html")
        |> Mechanizex.with_form()
        |> Mechanizex.fill_field("login1", with: "gustavo")
        |> Mechanizex.fill_field("passwd1", with: "123456")

      assert Enum.map(form.fields, &{&1.name, &1.value}) == [
               {"login1", "gustavo"},
               {"passwd1", "123456"}
             ]
    end

    test "creates a new field", %{agent: agent} do
      form =
        agent
        |> Mechanizex.get!("test/htdocs/two_forms.html")
        |> Mechanizex.with_form()
        |> Mechanizex.fill_field("captcha", with: "checked")

      assert Enum.map(form.fields, &{&1.name, &1.value}) == [
               {"captcha", "checked"},
               {"login1", "default user 1"},
               {"passwd1", nil}
             ]
    end
  end
end
