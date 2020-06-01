defmodule Mechanize.PageTest do
  use ExUnit.Case, async: true
  alias Mechanize
  alias Mechanize.Page.{Element, Link, ClickError, InvalidMetaRefreshError}
  alias Mechanize.Page
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
      [%Link{}] = Page.links_with(page, href: ~r/google/)
    end

    test "with one attribute criteria", %{page: page} do
      assert(
        page
        |> Page.links_with(href: ~r/google/)
        |> Enum.map(&Element.attr(&1, :href)) == ["/about/google"]
      )
    end

    test "with many attributes criteria", %{page: page} do
      assert(
        page
        |> Page.links_with(class: ~r/great-company/, rel: "search")
        |> Enum.map(&Element.attr(&1, :href)) == ["/about/google"]
      )
    end

    test "with text criteria", %{page: page} do
      assert(
        page
        |> Page.links_with(text: "Google")
        |> Enum.map(&Element.attr(&1, :href)) == ["/about/google"]
      )
    end

    test "multiple links with same text", %{page: page} do
      assert(
        page
        |> Page.links_with(text: ~r/Google/)
        |> Enum.map(&Element.attr(&1, :href)) == [
          "/about/google",
          "/about/android"
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

    test "image area links", %{page: page} do
      assert(
        page
        |> Page.elements_with("[name=planetmap]")
        |> Page.links_with()
        |> Enum.map(&Element.attr(&1, :alt)) == [
          "Sun",
          "Mercury",
          "Venus",
          "Nibiru"
        ]
      )
    end
  end

  describe ".link_with" do
    setup do
      stub_requests("/test/htdocs/page_with_links.html")
    end

    test "returns list of %Link struct", %{page: page} do
      %Link{} = Page.link_with(page, href: ~r/google/)
    end

    test "with one attribute criteria", %{page: page} do
      assert(
        page
        |> Page.link_with(href: ~r/google/)
        |> Element.attr(:href) == "/about/google"
      )
    end

    test "with many attributes criteria", %{page: page} do
      assert(
        page
        |> Page.link_with(class: ~r/great-company/, rel: "search")
        |> Element.attr(:href) == "/about/google"
      )
    end

    test "with text criteria", %{page: page} do
      assert(
        page
        |> Page.link_with(text: "Google")
        |> Element.attr(:href) == "/about/google"
      )
    end

    test "multiple links with same text return the first", %{page: page} do
      assert(
        page
        |> Page.link_with(text: ~r/Google/)
        |> Element.attr(:href) == "/about/google"
      )
    end

    test "multiple links with same attribute return the first", %{page: page} do
      assert(
        page
        |> Page.link_with(class: ~r/great-company/)
        |> Element.attr(:href) == "/about/google"
      )
    end

    test "image area links", %{page: page} do
      assert(
        page
        |> Page.elements_with("[name=planetmap]")
        |> Page.link_with()
        |> Element.attr(:alt) == "Sun"
      )
    end
  end

  describe ".click_link" do
    setup do
      stub_requests("/test/htdocs/page_with_links.html")
    end

    test "click on first matched link", %{bypass: bypass, page: page} do
      Bypass.expect_once(bypass, "GET", "/about/google", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Page.click_link(page, class: ~r/great-company/)
    end

    test "click on first matched link by text", %{bypass: bypass, page: page} do
      Bypass.expect_once(bypass, "GET", "/about/seomaster", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Page.click_link(page, "SEO Master")
    end

    test "relative link", %{bypass: bypass, page: page} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Page.click_link(page, "Back")
    end

    test "image area links", %{bypass: bypass, page: page} do
      Bypass.expect_once(bypass, "GET", "/test/htdocs/sun.html", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Page.click_link(page, alt: "Sun")
    end

    test "raise if link does't have href attribute", %{page: page} do
      assert_raise ClickError, "href attribute is missing", fn ->
        Page.click_link(page, "Stealth Company")
      end
    end

    test "raise if image area link does't have href attribute", %{page: page} do
      assert_raise ClickError, "href attribute is missing", fn ->
        Page.click_link(page, alt: "Nibiru")
      end
    end
  end

  describe ".meta_refresh" do
    test "page is nil" do
      assert_raise ArgumentError, "page is nil", fn ->
        Page.meta_refresh(nil)
      end
    end

    test "page with meta refresh" do
      content = read_file!("test/htdocs/meta_refresh.html", url: "http://www.google.com.br")
      page = %Page{content: content, parser: Mechanize.HTMLParser.Floki}

      assert Page.meta_refresh(page) == {0, "http://www.google.com.br"}
    end

    test "return the first matched meta refresh if multiple found" do
      {:ok, %{page: page}} = stub_requests("/test/htdocs/multiple_meta_refresh.html")
      assert Page.meta_refresh(page) == {0, "https://seomaster.com.br"}
    end

    test "page without meta refresh" do
      {:ok, %{page: page}} = stub_requests("/test/htdocs/without_meta_refresh.html")
      assert Page.meta_refresh(page) == nil
    end

    test "meta refresh content parsing" do
      [
        {
          "<meta http-equiv=\"refresh\" content=\"10\"/>",
          {10, nil}
        },
        {
          "<meta http-equiv=\"refresh\" content=\"   10    \"/>",
          {10, nil}
        },
        {
          "<meta http-equiv=\"refresh\" content=\"10; url=http://www.google.com.br\"/>",
          {10, "http://www.google.com.br"}
        },
        {
          "<meta http-equiv=\"refresh\" content=\"10 ;   url = http://www.google.com.br\"/>",
          {10, "http://www.google.com.br"}
        },
        {
          "<meta http-equiv=\"refresh\" content=\"10;url=http://www.google.com.br\"/>",
          {10, "http://www.google.com.br"}
        },
        {
          "<meta http-equiv=\"refresh\" content=\"10;url= http://www.google.com.br\"/>",
          {10, "http://www.google.com.br"}
        },
        {
          "<meta http-equiv=\"refresh\" content=\"10;url=     http://www.google.com.br  \"/>",
          {10, "http://www.google.com.br"}
        }
      ]
      |> Stream.with_index(1)
      |> Enum.each(fn {{content, expected_result}, index} ->
        page = %Page{content: content, parser: Mechanize.HTMLParser.Floki, url: index}
        result = Page.meta_refresh(page)

        assert result == expected_result,
               "(test #{index}) expected #{inspect(expected_result)}, " <>
                 "but was #{inspect(result)} on subject #{inspect(content)}"
      end)
    end

    [
      "<meta http-equiv=\"refresh\" content=\"\"/>",
      "<meta http-equiv=\"refresh\" content=\"      \"/>",
      "<meta http-equiv=\"refresh\" content=\";\"/>",
      "<meta http-equiv=\"refresh\" content=\"  ;  \"/>",
      "<meta http-equiv=\"refresh\" content=\"10; lero=http://www.google.com.br\"/>",
      "<meta http-equiv=\"refresh\" content=\"  ; lero=http://www.google.com.br\"/>",
      "<meta http-equiv=\"refresh\" content=\"lero=http://www.google.com.br; 10\"/>",
      "<meta http-equiv=\"refresh\" content=\"lero=http://www.google.com.br\"/>",
      "<meta http-equiv=\"refresh\" content=\"a; lero=http://www.google.com.br\"/>",
      "<meta http-equiv=\"refresh\" content=\"a; url=http://www.google.com.br\"/>"
    ]
    |> Stream.with_index(1)
    |> Enum.each(fn {content, index} ->
      test "#{content} raises exception" do
        page = %Page{
          content: unquote(content),
          parser: Mechanize.HTMLParser.Floki,
          url: unquote(index)
        }

        assert_raise(InvalidMetaRefreshError, fn ->
          Page.meta_refresh(page)
        end)
      end
    end)
  end
end
