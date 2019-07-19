defmodule Mechanizex.PageTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Test.Support.LocalPageLoader
  alias Mechanizex.Page.{Element, Link}
  alias Mechanizex.{Page, Request, Response}
  import Mox

  setup_all do
    {:ok, agent: Mechanizex.new(http_adapter: :mock)}
  end

  describe ".with_form" do
    test "return only the first form", %{agent: agent} do
      form =
        agent
        |> LocalPageLoader.get("test/htdocs/two_forms.html")
        |> Mechanizex.with_form()

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

    test "select form by its attributes", %{agent: agent} do
      form =
        agent
        |> LocalPageLoader.get("test/htdocs/two_forms.html")
        |> Mechanizex.with_form(name: "form-name-2")

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

  describe ".with_links" do
    test "returns list of %Link struct", %{agent: agent} do
      [%Link{}] =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_links(href: ~r/google.com/)
    end

    test "with one attribute criteria", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_links(href: ~r/google.com/)
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "with many attributes criteria", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_links(class: ~r/great-company/, rel: "search")
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "with text criteria", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_links(text: "Google")
        |> Enum.map(&Element.attr(&1, :href)) == ["http://www.google.com"]
      )
    end

    test "multiple links with same text", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_links(text: ~r/Google/)
        |> Enum.map(&Element.attr(&1, :href)) == [
          "http://www.google.com",
          "http://www.android.com"
        ]
      )
    end

    test "multiple links with same attribute", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_links(class: ~r/great-company/)
        |> Enum.map(&Element.text/1) == [
          "Google",
          "Google Android",
          "Microsoft",
          "Apple",
          "Back"
        ]
      )
    end

    test "image area links", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_image_area_links.html")
        |> Page.with_links()
        |> Enum.map(&Element.attr(&1, :alt)) == [
          "Sun",
          "Mercury",
          "Venus"
        ]
      )
    end
  end

  describe ".with_link" do
    test "returns list of %Link struct", %{agent: agent} do
      %Link{} =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_link(href: ~r/google.com/)
    end

    test "with one attribute criteria", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_link(href: ~r/google.com/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "with many attributes criteria", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_link(class: ~r/great-company/, rel: "search")
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "with text criteria", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_link(text: "Google")
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "multiple links with same text return the first", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_link(text: ~r/Google/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "multiple links with same attribute return the first", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
        |> Page.with_link(class: ~r/great-company/)
        |> Element.attr(:href) == "http://www.google.com"
      )
    end

    test "image area links", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_image_area_links.html")
        |> Page.with_link()
        |> Element.attr(:alt) == "Sun"
      )
    end
  end

  describe ".click_link" do
    setup :verify_on_exit!

    test "click on first matched link", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "http://www.google.com"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
      |> Page.click_link(class: ~r/great-company/)
    end

    test "click on first matched link by text", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "http://www.seomaster.com.br"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
      |> Page.click_link("SEO Master")
    end

    test "relative link", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "https://htdocs.local/test"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_links.html")
      |> Page.click_link("Back")
    end

    test "image area links", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :get,
                               url: "https://htdocs.local/test/htdocs/sun.html"
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/page_with_image_area_links.html")
      |> Page.click_link(alt: "Sun")
    end
  end
end
