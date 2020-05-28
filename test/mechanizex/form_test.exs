defmodule Mechanize.FormTest do
  use ExUnit.Case, async: true
  alias Mechanize
  alias Mechanize.Page.Element
  alias Mechanize.{Form, Page}
  alias Mechanize.Form.DetachedField
  import TestHelper

  setup do
    stub_requests("/test/htdocs/form_test.html")
  end

  describe ".put_field" do
    test "returns form", %{page: page} do
      form = Page.form_with(page, name: "login_form")
      assert match?(%Form{}, Form.put_field(form, %DetachedField{name: "remember", value: "remember"}))
    end

    test "put a new field on form", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.put_field(%DetachedField{name: "remember", value: "remember"})
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"remember", "remember"},
               {"username", "gustavo"},
               {"pass", "123456"},
               {"send", "Send"}
             ]
    end

    test "put a new field on form by name and value", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.put_field("remember", "remember")
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"remember", "remember"},
               {"username", "gustavo"},
               {"pass", "123456"},
               {"send", "Send"}
             ]
    end

    test "put a new field with same name", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.put_field("remember", "remember")
             |> Form.put_field("remember", "remember")
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"remember", "remember"},
               {"remember", "remember"},
               {"username", "gustavo"},
               {"pass", "123456"},
               {"send", "Send"}
             ]
    end
  end

  describe ".delete_fields" do
    test "returns a form", %{page: page} do
      form = Page.form_with(page, name: "login_form")
      assert match?(%Form{}, Form.delete_fields(form, fn field -> field.name == "username" end))
    end

    test "remove all fields that function return true", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.delete_fields(&(&1.name == "username"))
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"pass", "123456"},
               {"send", "Send"}
             ]
    end

    test "empty list if all fields deleted", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.delete_fields(fn _ -> true end)
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == []
    end
  end

  describe ".delete_fields_with" do
    test "returns a form", %{page: page} do
      form = Page.form_with(page, name: "login_form")
      assert match?(%Form{}, Form.delete_fields_with(form, name: "username"))
    end

    test "remove all field with matching name", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.delete_fields_with(name: "username")
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"pass", "123456"},
               {"send", "Send"}
             ]
    end

    test "remove all field with matching value", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.delete_fields_with(value: "123456")
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"username", "gustavo"},
               {"send", "Send"}
             ]
    end

    test "empty list if all fields deleted", %{page: page} do
      assert page
             |> Page.form_with(name: "login_form")
             |> Form.delete_fields_with(name: ~r/./)
             |> Form.fields()
             |> Enum.map(&{&1.name, &1.value}) == []
    end
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
             |> Form.text_inputs()
             |> Enum.map(&{&1.name, &1.value}) == [
               {nil, "gustavo"},
               {nil, "123456"}
             ]
    end

    test "parse outer elements with form attribute", %{page: page} do
      assert page
             |> Page.form_with(name: "form_with_outer_inputs")
             |> Form.text_inputs()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"firstname", "gustavo"},
               {"lastname", "honorato"}
             ]
    end

    test "parse inner element with form attribute without duplicating it", %{page: page} do
      assert page
             |> Page.form_with(id: "form_with_inner_element_with_form_attribute")
             |> Form.text_inputs()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"firstname", "gustavo"}
             ]
    end

    test "parse outer elements case sensitive", %{page: page} do
      assert page
             |> Page.form_with(id: "form_with_case_sensitive")
             |> Form.text_inputs()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"lastname", "honorato"}
             ]
    end

    test "parse outer element with spaces in id", %{page: page} do
      assert page
             |> Page.form_with(id: "form with spaces")
             |> Form.text_inputs()
             |> Enum.map(&{&1.name, &1.value}) == [
               {"firstname", "gustavo"},
               {"lastname", "honorato"}
             ]
    end
  end

  describe ".submit" do
    test "method is GET when method attribute missing", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_missing")
      |> Form.submit()
    end

    test "method is GET when method attribute is blank", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_blank")
      |> Form.submit()
    end

    test "send form fields in URL when GET", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.query_string == "product=gol&manufacturer=vw"
        assert {:ok, "", conn} = Plug.Conn.read_body(conn)
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_get")
      |> Form.submit()
    end

    test "sends form fields in body when POST", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "username=gustavo&pass=123456", conn} = Plug.Conn.read_body(conn)
        assert conn.query_string == ""
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_post")
      |> Form.submit()
    end

    test "content-type header added when POST", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "method_post")
      |> Form.submit()
    end

    test "POST method is case insensitive", %{page: page, bypass: bypass} do
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
        assert assert {:ok, "username=gustavo&pass=123456", conn} = Plug.Conn.read_body(conn)
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "do_not_submit_buttons")
      |> Form.submit()
    end

    test "does not submit disabled fields", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "pass=123456", conn} = Plug.Conn.read_body(conn)
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "with_disabled_fields")
      |> Form.submit()
    end

    test "does not submit input without name", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "username=gustavo", conn} = Plug.Conn.read_body(conn)
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "field_without_name")
      |> Form.submit()
    end

    test "returns a page on success", %{page: page, bypass: bypass} do
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

    test "submit empty value when field has absent value attribute", %{page: page, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert {:ok, "absent_value=", conn} = Plug.Conn.read_body(conn)
        Plug.Conn.resp(conn, 200, "OK")
      end)

      page
      |> Page.form_with(name: "form_with_field_with_absent_value")
      |> Form.submit()
    end
  end
end
