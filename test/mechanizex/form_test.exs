defmodule Mechanizex.FormTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Page.Element
  alias Mechanizex.{Form, Page}
  alias Mechanizex.Form.TextInput
  import TestHelper

  setup do
    stub_requests("/test/htdocs/form_test.html")
  end

  describe ".parse_fields" do
    test "parse disabled fields", %{page: page} do
      assert page
             |> Page.form_with(name: "form_with_disabled_generic_inputs")
             |> Form.fields()
             |> Enum.map(fn f -> {f.name, Element.attr_present?(f, :disabled)} end) == [
               {"color1", false},
               {"date1", true},
               {"datetime1", true},
               {"email1", true},
               {"textarea1", true}
             ]
    end

    test "parse elements without name", %{page: page} do
      assert page
             |> Page.form_with(name: "form_with_inputs_without_name")
             |> Form.fields()
             |> Enum.map(fn %TextInput{name: name, value: value} -> {name, value} end) == [
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
