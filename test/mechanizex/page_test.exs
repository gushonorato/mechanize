defmodule Mechanizex.PageTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Test.Support.LocalPageLoader
  alias Mechanizex.Page.{Element, Link}
  alias Mechanizex.{Page, Request, Response}
  import Mox

  setup_all do
    {:ok, browser: Mechanizex.Browser.new(http_adapter: :mock)}
  end

  describe ".form_with" do
    test "return only the first form", %{browser: browser} do
      form =
        browser
        |> LocalPageLoader.get("test/htdocs/two_forms.html")
        |> Page.form_with()

      assert Element.attrs(form) == [
               {"id", "form-id-1"},
               {"action", "/form1"},
               {"method", "get"},
               {"name", "form-name-1"}
             ]

      assert Enum.map(form.fields, &{&1.name, &1.value}) == [
               {"login1", "default user 1"},
               {"passwd1", nil}
             ]
    end

    test "select form by its attributes", %{browser: browser} do
      form =
        browser
        |> LocalPageLoader.get("test/htdocs/two_forms.html")
        |> Page.form_with(name: "form-name-2")

      assert Element.attrs(form) == [
               {"id", "form-id-2"},
               {"action", "/form2"},
               {"method", "post"},
               {"name", "form-name-2"}
             ]

      assert Enum.map(form.fields, &{&1.name, &1.value}) == [
               {"login2", "default user 2"},
               {"passwd2", nil}
             ]
    end
  end

  describe ".links_with" do
    test "returns list of %Link struct", %{browser: browser} do
      [%Link{}] =
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.links_with(href: ~r/google.com/)
    end

    test "with one attribute criteria", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.links_with(href: ~r/google.com/)
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "with many attributes criteria", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.links_with(class: ~r/great-company/, rel: "search")
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "with text criteria", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.links_with(text: "Google")
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "multiple links with same text", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.links_with(text: ~r/Google/)
        |> Enum.map(&Element.attr(&1, :href)) == [
          "http://www.google.com",
          "http://www.android.com"
        ]
      )
    end

    test "multiple links with same attribute", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.links_with(class: ~r/great-company/)
        |> Enum.map(&Element.text/1) == [
          "Google",
          "Google Android",
          "Microsoft",
          "Apple",
          "Back"
        ]
      )
    end

    test "image area links", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_image_area_links.html")
        |> Page.links_with()
        |> Enum.map(&Element.attr(&1, :alt)) == [
          "Sun",
          "Mercury",
          "Venus"
        ]
      )
    end
  end

  describe ".link_with" do
    test "returns list of %Link struct", %{browser: browser} do
      %Link{} =
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.link_with(href: ~r/google.com/)
    end

    test "with one attribute criteria", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.link_with(href: ~r/google.com/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "with many attributes criteria", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.link_with(class: ~r/great-company/, rel: "search")
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "with text criteria", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.link_with(text: "Google")
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "multiple links with same text return the first", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.link_with(text: ~r/Google/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "multiple links with same attribute return the first", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.link_with(class: ~r/great-company/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "image area links", %{browser: browser} do
      assert(
        browser
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_image_area_links.html")
        |> Page.link_with()
        |> Element.attr(:alt) == "Sun"
      )
    end
  end

  describe ".click_link" do
    setup :verify_on_exit!

    test "click on first matched link", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "http://www.google.com"} = req ->
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      browser
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
      |> Page.click_link(class: ~r/great-company/)
    end

    test "click on first matched link by text", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "http://www.seomaster.com.br"} = req ->
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      browser
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
      |> Page.click_link("SEO Master")
    end

    test "relative link", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "https://htdocs.local/test"} = req ->
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      browser
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
      |> Page.click_link("Back")
    end

    test "image area links", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :get,
                               url: "https://htdocs.local/test/htdocs/sun.html"
                             } = req ->
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      browser
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_image_area_links.html")
      |> Page.click_link(alt: "Sun")
    end
  end
end
