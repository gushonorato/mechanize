defmodule Mechanizex.PageTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Page.{Element, Link}
  alias Mechanizex.{Page, Request, Response, Browser}
  import Mox
  import TestHelper

  describe ".form_with" do
    setup do
      stub_requests("/test/htdocs/two_forms.html")
    end

    test "return only the first form", %{page: page} do
      form = Page.form_with(page)

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

    test "select form by its attributes", %{page: page} do
      form = Page.form_with(page, name: "form-name-2")

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
    setup do
      stub_requests("/test/htdocs/page_with_links.html")
    end

    test "returns list of %Link struct", %{page: page} do
      [%Link{}] = Page.links_with(page, href: ~r/google.com/)
    end

    test "with one attribute criteria", %{page: page} do
      assert(
        page
        |> Page.links_with(href: ~r/google.com/)
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "with many attributes criteria", %{page: page} do
      assert(
        page
        |> Page.links_with(class: ~r/great-company/, rel: "search")
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "with text criteria", %{page: page} do
      assert(
        page
        |> Page.links_with(text: "Google")
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "multiple links with same text", %{page: page} do
      assert(
        page
        |> Page.links_with(text: ~r/Google/)
        |> Enum.map(&Element.attr(&1, :href)) == [
          "http://www.google.com",
          "http://www.android.com"
        ]
      )
    end

    test "multiple links with same attribute", %{page: page} do
      assert(
        page
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

    test "image area links" do
      {:ok, %{page: page}} = stub_requests("/test/htdocs/page_with_image_area_links.html")

      assert(
        page
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
    setup do
      stub_requests("/test/htdocs/page_with_links.html")
    end

    test "returns list of %Link struct", %{page: page} do
      %Link{} =
        page
        |> Page.link_with(href: ~r/google.com/)
    end

    test "with one attribute criteria", %{page: page} do
      assert(
        page
        |> Page.link_with(href: ~r/google.com/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "with many attributes criteria", %{page: page} do
      assert(
        page
        |> Page.link_with(class: ~r/great-company/, rel: "search")
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "with text criteria", %{page: page} do
      assert(
        page
        |> Page.link_with(text: "Google")
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "multiple links with same text return the first", %{page: page} do
      assert(
        page
        |> Page.link_with(text: ~r/Google/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "multiple links with same attribute return the first", %{page: page} do
      assert(
        page
        |> Page.link_with(class: ~r/great-company/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "image area links" do
      {:ok, %{page: page}} = stub_requests("/test/htdocs/page_with_image_area_links.html")

      assert(
        page
        |> Page.link_with()
        |> Element.attr(:alt) == "Sun"
      )
    end
  end

  describe ".click_link" do
    setup :verify_on_exit!

    setup %{mock_request: path} do
      expect(Mechanizex.HTTPAdapter.Mock, :request!, fn %Request{url: ^path} ->
        %Response{
          body: File.read(path) |> elem(1),
          headers: [],
          code: 200,
          url: "http://example.com/#{path}"
        }
      end)

      :ok
    end

    setup do
      {:ok, browser: Mechanizex.Browser.new(http_adapter: :mock)}
    end

    @tag mock_request: "test/htdocs/page_with_links.html"
    test "click on first matched link", %{browser: browser} do
      expect(Mechanizex.HTTPAdapter.Mock, :request!, fn %Request{url: "http://www.google.com"} ->
        %Response{}
      end)

      browser
      |> Browser.get!("test/htdocs/page_with_links.html")
      |> Page.click_link(class: ~r/great-company/)
    end

    @tag mock_request: "test/htdocs/page_with_links.html"
    test "click on first matched link by text", %{browser: browser} do
      expect(Mechanizex.HTTPAdapter.Mock, :request!, fn %Request{url: "http://www.seomaster.com.br"} ->
        %Response{}
      end)

      browser
      |> Browser.get!("test/htdocs/page_with_links.html")
      |> Page.click_link("SEO Master")
    end

    @tag mock_request: "test/htdocs/page_with_links.html"
    test "relative link", %{browser: browser} do
      expect(Mechanizex.HTTPAdapter.Mock, :request!, fn %Request{url: "http://example.com/test"} ->
        %Response{}
      end)

      browser
      |> Browser.get!("test/htdocs/page_with_links.html")
      |> Page.click_link("Back")
    end

    @tag mock_request: "test/htdocs/page_with_image_area_links.html"
    test "image area links", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request!, fn %Request{url: "http://example.com/test/htdocs/sun.html"} ->
        %Response{}
      end)

      browser
      |> Browser.get!("test/htdocs/page_with_image_area_links.html")
      |> Page.click_link(alt: "Sun")
    end
  end
end
