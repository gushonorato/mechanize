defmodule Mechanizex.PageTest do
  use ExUnit.Case, async: true
  alias Mechanizex

  setup_all do
    {:ok, agent: Mechanizex.new(http_adapter: :local_html_file) }
  end

  describe ".with_form" do
    test "return only the first form", %{agent: agent} do
      form =
        agent
        |> Mechanizex.get!("test/htdocs/two_forms.html")
        |> Mechanizex.with_form()

        assert Enum.map(form.element.attributes, &(&1)) == [action: "/form1", id: "form-id-1", method: "get", name: "form-name-1"]
        assert Enum.map(form.fields, &({&1.name, &1.value})) == [{"login1", "default user 1"}, {"passwd1", nil}]
    end

    test "select form by its attributes", %{agent: agent} do
        form =
          agent
          |> Mechanizex.get!("test/htdocs/two_forms.html")
          |> Mechanizex.with_form(name: "form-name-2")

        assert Enum.map(form.element.attributes, &(&1)) == [action: "/form2", id: "form-id-2", method: "post", name: "form-name-2"]
        assert Enum.map(form.fields, &({&1.name, &1.value})) == [{"login2", "default user 2"}, {"passwd2", nil}]
    end
  end
end
