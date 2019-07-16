defmodule Mechanizex.FormTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Test.Support.LocalPageLoader
  alias Mechanizex.{Form, Request}
  alias Mechanizex.Form.{TextInput}
  import Mox

  setup_all do
    {:ok, agent: Mechanizex.new(http_adapter: :mock)}
  end

  describe ".fill_field" do
    test "update a first field by name", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Mechanizex.with_form()
        |> Form.fill_field("username", with: "gustavo")
        |> Form.fill_field("passwd", with: "123456")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [
          {"username", "gustavo"},
          {"passwd", "123456"}
        ]
      )
    end

    test "creates a new field", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Mechanizex.with_form()
        |> Mechanizex.fill_field("captcha", with: "checked")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value})

      assert fields == [
               {"captcha", "checked"},
               {"username", nil},
               {"passwd", "12345"}
             ]
    end
  end

  describe ".update_field" do
    test "updates first field when duplicated" do
      assert(
        %Form{
          element: :fake,
          fields: [
            %TextInput{element: :fake, name: "article[categories][]", value: "1"},
            %TextInput{element: :fake, name: "article[categories][]", value: "2"}
          ]
        }
        |> Form.update_field("article[categories][]", "3")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [
          {"article[categories][]", "3"},
          {"article[categories][]", "2"}
        ]
      )
    end
  end

  describe ".add_field" do
    test "adds a field even if already exists" do
      assert(
        %Form{element: :fake}
        |> Form.add_field("user[codes][]", "1")
        |> Form.add_field("user[codes][]", "2")
        |> Form.add_field("user[codes][]", "3")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [
          {"user[codes][]", "3"},
          {"user[codes][]", "2"},
          {"user[codes][]", "1"}
        ]
      )
    end
  end

  describe ".delete_field" do
    test "removes all fields with the given name" do
      assert(
        %Form{
          element: :fake,
          fields: [
            %TextInput{element: :fake, name: "article[categories][]", value: "1"},
            %TextInput{element: :fake, name: "article[categories][]", value: "2"},
            %TextInput{element: :fake, name: "username", value: "gustavo"}
          ]
        }
        |> Form.delete_field("article[categories][]")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [{"username", "gustavo"}]
      )
    end
  end

  describe ".parse_fields" do
    test "parse all generic text input", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get(
          "https://htdocs.local/test/htdocs/form_with_all_generic_text_inputs.html"
        )
        |> Mechanizex.with_form()
        |> Form.fields()
        |> Enum.map(fn %TextInput{name: name, value: value} -> {name, value} end)

      assert fields == [
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

    test "parse disabled fields", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get(
          "https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html"
        )
        |> Mechanizex.with_form()
        |> Form.fields()
        |> Enum.map(fn %TextInput{name: name, disabled: disabled} -> {name, disabled} end)

      assert fields == [
               {"color1", false},
               {"date1", true},
               {"datetime1", true},
               {"email1", true},
               {"textarea1", true}
             ]
    end

    test "parse elements without name", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get(
          "https://htdocs.local/test/htdocs/form_with_inputs_without_name.html"
        )
        |> Mechanizex.with_form()
        |> Form.fields()
        |> Enum.map(fn %TextInput{name: name, value: value} -> {name, value} end)

      assert fields == [
               {nil, "gustavo"},
               {nil, "123456"}
             ]
    end

    test "parse all submit buttons", %{agent: agent} do
      assert agent
             |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_buttons.html")
             |> Mechanizex.with_form()
             |> Form.fields()
             |> Enum.map(fn %{
                              name: name,
                              value: value,
                              text: text,
                              id: id,
                              disabled: disabled
                            } ->
               {name, value, text, id, disabled}
             end) == [
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
    end
  end

  describe ".submit" do
    setup :verify_on_exit!

    test "method is get when method attribute missing", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _, %Request{method: :get, url: "https://htdocs.local/login"} ->
        :ok
      end)

      agent
      |> LocalPageLoader.get(
        "https://htdocs.local/test/htdocs/form_method_attribute_missing.html"
      )
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "method is get when method attribute is blank", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _, %Request{method: :get, url: "https://htdocs.local/login"} ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_method_attribute_blank.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "method post", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _, %Request{method: :post, url: "https://htdocs.local/login"} ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_method_attribute_post.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "absent action attribute", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url:
                                  "https://htdocs.local/test/htdocs/form_with_absent_action.html"
                              } ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absent_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "empty action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url:
                                  "https://htdocs.local/test/htdocs/form_with_blank_action.html"
                              } ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_blank_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "relative action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _,
                              %Request{method: :post, url: "https://htdocs.local/test/login"} ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_relative_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "absolute action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _, %Request{method: :post, url: "https://www.foo.com/login"} ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "input fields submission", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url: "https://www.foo.com/login",
                                params: [{"username", "gustavo"}, {"passwd", "gu123456"}]
                              } ->
        :ok
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.fill_field("username", with: "gustavo")
      |> Mechanizex.fill_field("passwd", with: "gu123456")
      |> Mechanizex.submit()
    end

    test "doest not submit disabled fields", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url:
                                  "https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html",
                                params: [{"color1", "color1 value"}]
                              } ->
        :ok
      end)

      agent
      |> LocalPageLoader.get(
        "https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html"
      )
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end
  end

  describe ".click_button" do
    setup :verify_on_exit!
  end
end
