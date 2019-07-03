defmodule Mechanizex.FormTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Request
  import Mox

  setup_all do
    {:ok, agent: Mechanizex.new(http_adapter: :local_html_file_mock)}
  end

  setup do
    stub_with(Mechanizex.HTTPAdapter.LocalHtmlFileMock, Mechanizex.HTTPAdapter.LocalHtmlFile)
    :ok
  end

  describe ".fill_field" do
    test "update a text field by name", %{agent: agent} do
      form =
        agent
        |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Mechanizex.with_form()
        |> Mechanizex.fill_field("username", with: "gustavo")
        |> Mechanizex.fill_field("passwd", with: "123456")

      assert Enum.map(form.fields, &{&1.name, &1.value}) == [
               {"username", "gustavo"},
               {"passwd", "123456"}
             ]
    end

    test "creates a new field", %{agent: agent} do
      form =
        agent
        |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Mechanizex.with_form()
        |> Mechanizex.fill_field("captcha", with: "checked")

      assert Enum.map(form.fields, &{&1.name, &1.value}) == [
               {"captcha", "checked"},
               {"username", nil},
               {"passwd", "12345"}
             ]
    end
  end

  describe ".submit" do
    setup :verify_on_exit!

    test "method is get when method attribute missing", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _, %Request{method: :get, url: "https://htdocs.local/login"} ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_method_attribute_missing.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "method is get when method attribute is blank", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _, %Request{method: :get, url: "https://htdocs.local/login"} ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_method_attribute_blank.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "method post", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _, %Request{method: :post, url: "https://htdocs.local/login"} ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_method_attribute_post.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "absent action attribute", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url:
                                  "https://htdocs.local/test/htdocs/form_with_absent_action.html"
                              } ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_absent_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "empty action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url:
                                  "https://htdocs.local/test/htdocs/form_with_blank_action.html"
                              } ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_blank_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "relative action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _,
                              %Request{method: :post, url: "https://htdocs.local/test/login"} ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_relative_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "absolute action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _, %Request{method: :post, url: "https://www.foo.com/login"} ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.submit()
    end

    test "input fields submission", %{agent: agent} do
      Mechanizex.HTTPAdapter.LocalHtmlFileMock
      |> expect(:request!, fn _,
                              %Request{
                                method: :post,
                                url: "https://www.foo.com/login",
                                params: %{"username" => "gustavo", "passwd" => "gu123456"}
                              } ->
        :ok
      end)

      agent
      |> Mechanizex.get!("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
      |> Mechanizex.with_form()
      |> Mechanizex.fill_field("username", with: "gustavo")
      |> Mechanizex.fill_field("passwd", with: "gu123456")
      |> Mechanizex.submit()
    end
  end
end
