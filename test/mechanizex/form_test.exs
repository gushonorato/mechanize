defmodule Mechanizex.FormTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Test.Support.LocalPageLoader
  alias Mechanizex.Page.Element
  alias Mechanizex.{Form, Page}
  alias Mechanizex.Form.TextInput
  import TestHelper

  setup do
    stub_requests("/test/htdocs/form_test.html")
  end

  describe ".fill_field" do
    test "update a first field by name", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Page.form_with()
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
        |> Page.form_with()
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
    test "updates all fields with same name" do
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
          {"article[categories][]", "3"}
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
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_all_generic_text_inputs.html")
        |> Page.form_with()
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
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html")
        |> Page.form_with()
        |> Form.fields()
        |> Enum.map(fn f -> {f.name, Element.attr_present?(f, :disabled)} end)

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
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_inputs_without_name.html")
        |> Page.form_with()
        |> Form.fields()
        |> Enum.map(fn %TextInput{name: name, value: value} -> {name, value} end)

      assert fields == [
               {nil, "gustavo"},
               {nil, "123456"}
             ]
    end
  end

  describe ".submit" do
    test "method is get when method attribute missing", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_missing")
      |> Form.submit()
    end

    test "method is get when method attribute is blank", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_blank")
      |> Form.submit()
    end

    test "method post", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_post")
      |> Form.submit()
    end

    test "method post is case insensitive", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_post_case_insensitive")
      |> Form.submit()
    end

    test "absent action attribute must send request to current page path", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.request_path == "/test/htdocs/form_test.html"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "absent_action")
      |> Form.submit()
    end

    test "empty action url must send request to current page path", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.request_path == "/test/htdocs/form_test.html"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "empty_action")
      |> Form.submit()
    end

    test "relative action url", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.request_path == "/test/login"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "relative_action_url")
      |> Form.submit()
    end

    test "does not submit buttons", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.query_string == "username=gustavo&pass=123456"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "do_not_submit_buttons")
      |> Form.submit()
    end

    test "does not submit disabled fields", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.query_string == "pass=123456"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "with_disabled_fields")
      |> Form.submit()
    end

    test "does not submit input without name", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.query_string == "username=gustavo"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "field_without_name")
      |> Form.submit()
    end

    test "returns a page", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      assert(
        page
        |> Page.form_with(name: "login_form")
        |> Form.submit()
        |> Page.body() == "OK"
      )
    end
  end
end
