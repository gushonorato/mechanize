defmodule Mechanize.QueryTest do
  use ExUnit.Case, async: true
  alias Mechanize.Page.Element
  alias Mechanize.{Page, Query}
  alias Mechanize.HTMLParser.Parseable
  doctest Mechanize.Query

  @page %Page{
    parser: Mechanize.HTMLParser.Floki,
    content: File.read!("./test/htdocs/query_test.html")
  }

  describe ".search" do
    test "return element list" do
      result = Query.search(@page, ".spanish")

      assert is_list(result)
      Enum.each(result, fn e -> %Element{} = e end)
    end

    test "raise if page or element list is nil" do
      assert_raise ArgumentError, "parseable is nil", fn ->
        Query.search(nil, ".spanish")
      end
    end

    test "raise if selector is nil" do
      assert_raise ArgumentError, "selector is nil", fn ->
        Query.search(@page, nil)
      end
    end

    test "if none matched return empty list" do
      assert Query.search(@page, ".english") == []
    end

    test "match elements of a page by css selector" do
      assert @page
             |> Query.search(".spanish")
             |> Enum.map(&Element.text/1) == ["Spain", "Chile", "Argentina"]
    end

    test "match sub-elements by css selector" do
      assert @page
             |> Query.search(".america")
             |> Query.search(".spanish")
             |> Enum.map(&Element.text/1) == ["Chile", "Argentina"]
    end

    test "search elements returned by filter" do
      assert @page
             |> Query.filter(".america")
             |> Query.search(".spanish")
             |> Enum.map(&Element.text/1) == ["Spain"]
    end
  end

  describe ".filter" do
    test "return element list" do
      assert is_list(Query.filter(@page, ".europe"))
    end

    test "raise if parseable is nill" do
      assert_raise ArgumentError, "parseable is nil", fn ->
        Query.filter(nil, ".spanish")
      end
    end

    test "raise if selector is nil" do
      assert_raise ArgumentError, "selector is nil", fn ->
        Query.filter(@page, nil)
      end
    end

    test "if all matched return empty list" do
      assert Query.filter(@page, "*") == []
    end

    test "return elements of a page unmatched by css selector" do
      assert @page
             |> Query.filter(".spanish")
             |> Enum.map(fn parseable -> Parseable.parser(parseable).raw_html(parseable) end) ==
               [
                 ~s(<body><div class="europe continent"><div class="portuguese">Portugal</div></div><div class="america continent"><div class="portuguese">Brazil</div></div></body>)
               ]
    end

    test "filter element returned by .search" do
      assert @page
             |> Query.search(".continent")
             |> Query.filter(".spanish")
             |> Enum.map(fn parseable -> Parseable.parser(parseable).raw_html(parseable) end) ==
               [
                 ~s(<div class="europe continent"><div class="portuguese">Portugal</div></div>),
                 ~s(<div class="america continent"><div class="portuguese">Brazil</div></div>)
               ]
    end
  end

  describe ".matches" do
    @subject [
      %Element{
        name: "a",
        attrs: [{"href", "www.google.com"}, {"rel", "follow"}, {"disabled", "disabled"}],
        text: "Google"
      },
      %Element{
        name: "a",
        attrs: [{"href", "www.microsoft.com"}, {"rel", "nofollow"}],
        text: "Microsoft"
      },
      %Element{
        name: "area",
        attrs: [{"href", "www.amazon.com"}, {"rel", "follow"}, {"alt", "Amazon"}]
      }
    ]

    test "raise if queryable is nil" do
      assert_raise ArgumentError, "queryable is nil", fn ->
        assert Query.matches(nil, tags: [:area])
      end
    end

    test "only one selected by element name" do
      assert @subject
             |> Query.matches(tags: [:area])
             |> Enum.map(&Element.attr(&1, :alt)) == ["Amazon"]
    end

    test "more than one selected by element name" do
      assert @subject
             |> Query.matches(tag: :a)
             |> Enum.map(&Element.text/1) == ["Google", "Microsoft"]
    end

    test "only one selected by attribute" do
      assert @subject
             |> Query.matches(rel: "nofollow")
             |> Enum.map(&Element.text/1) == ["Microsoft"]
    end

    test "more than one selected by attribute" do
      assert @subject
             |> Query.matches(rel: "follow")
             |> Enum.map(&Element.attr(&1, :href)) == ["www.google.com", "www.amazon.com"]
    end

    test "select without attributes" do
      assert @subject
             |> Query.matches(disabled: nil)
             |> Enum.map(&Element.attr(&1, :href)) == ["www.microsoft.com", "www.amazon.com"]
    end

    test "select without attributes using boolean criteria" do
      assert @subject
             |> Query.matches(disabled: false)
             |> Enum.map(&Element.attr(&1, :href)) == ["www.microsoft.com", "www.amazon.com"]
    end

    test "select elements if attribute is present using boolean criteria" do
      assert @subject
             |> Query.matches(disabled: true)
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and element name" do
      assert @subject
             |> Query.matches(tag: :a, rel: "follow")
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and text" do
      assert @subject
             |> Query.matches(tag: :a, text: "Google")
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "select by string only text is a exact match" do
      assert @subject
             |> Query.matches(text: "Googl")
             |> Enum.map(&Element.text/1) == []
    end

    test "select by string only attribute is a exact match" do
      assert @subject
             |> Query.matches(href: "google")
             |> Enum.map(&Element.text/1) == []
    end

    test "select all using multiple element names" do
      assert @subject
             |> Query.matches(tags: [:a, :area])
             |> Enum.map(&Element.attr(&1, :href)) == [
               "www.google.com",
               "www.microsoft.com",
               "www.amazon.com"
             ]
    end

    test "none selected" do
      assert @subject
             |> Query.matches(rel: "strange")
             |> Enum.map(&Element.text/1) == []
    end

    test "only one selected by attribute with regex" do
      assert @subject
             |> Query.matches(rel: ~r/no/)
             |> Enum.map(&Element.text/1) == ["Microsoft"]
    end

    test "more than one selected by attribute with regex" do
      assert @subject
             |> Query.matches(href: ~r/www\.am|www\.goo/)
             |> Enum.map(&Element.attr(&1, :href)) == ["www.google.com", "www.amazon.com"]
    end

    test "both by attributes and element name with regex" do
      assert @subject
             |> Query.matches(tag: :a, href: ~r/google/)
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and text with regex" do
      assert @subject
             |> Query.matches(tag: :a, href: ~r/google/)
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "by text with regex" do
      assert @subject
             |> Query.matches(text: ~r/Googl/)
             |> Enum.map(&Element.text/1) == ["Google"]
    end
  end

  describe ".search_matches" do
    test "raise if parseable is nil" do
      assert_raise ArgumentError, "parseable is nil", fn ->
        Query.search_matches(nil, "div")
      end
    end

    test "raise if selector is nil" do
      assert_raise ArgumentError, "selector is nil", fn ->
        Query.search_matches(@page, nil)
      end
    end

    test "select none by selector" do
      assert Query.search_matches(@page, ".asia", class: "spanish") == []
    end

    test "select none by criteria" do
      assert Query.search_matches(@page, ".spanish", class: "english") == []
    end

    test "select by css and criteria" do
      assert @page
             |> Query.search_matches(".continent > *", class: "portuguese")
             |> Enum.map(&Element.text/1) == ["Portugal", "Brazil"]
    end
  end
end
