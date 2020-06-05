defmodule Mechanize.HTMLParser.FlokiTest do
  use ExUnit.Case, async: true
  alias Mechanize.HTMLParser
  alias Mechanize.Page.Element
  import TestHelper

  setup_all do
    {:ok, %{page: page}} = stub_requests("/test/htdocs/html_parser_test.html")
    {:ok, %{page: page, parser: Mechanize.HTMLParser.Floki}}
  end

  describe ".search" do
    test "raises if page_or_elements is nil", %{parser: parser} do
      assert_raise ArgumentError, "page_or_elements is nil", fn ->
        parser.search(nil, ".continent")
      end
    end

    test "raises if selector is nil", %{parser: parser, page: page} do
      assert_raise ArgumentError, "selector is nil", fn ->
        parser.search(page, nil)
      end
    end

    test "returns empty list when nothing found", %{parser: parser, page: page} do
      assert parser.search(page, ".unknown") == []
    end

    test "returns empty list on search empty list" do
      assert HTMLParser.Floki.search([], ".portuguese") == []
    end

    test "multiple elements found", %{parser: parser, page: page} do
      assert page
             |> parser.search(".portuguese")
             |> Enum.map(&Element.text/1) == ["Portugal", "Brazil"]
    end

    test "search chained siblings", %{parser: parser, page: page} do
      assert page
             |> parser.search(".continent")
             |> parser.search(".portuguese")
             |> Enum.map(&Element.text/1) == ["Portugal", "Brazil"]
    end

    test "search nested parents", %{parser: parser, page: page} do
      assert page
             |> parser.search(".world")
             |> parser.search(".america")
             |> parser.search(".portuguese")
             |> Enum.map(&Element.text/1) == ["Brazil"]
    end
  end

  describe ".filter" do
    test "raise when page_or_elements is nil", %{page: page, parser: parser} do
      assert_raise ArgumentError, "page_or_elements is nil", fn ->
        parser.filter(nil, "a")
      end
    end

    test "raise when selector is nil", %{page: page, parser: parser} do
      assert_raise ArgumentError, "selector is nil", fn ->
        parser.filter(page, nil)
      end
    end

    test "empty element list", %{parser: parser} do
      assert parser.filter([], "form") == []
    end

    test "returns a list of elements", %{page: page, parser: parser} do
      subject = parser.filter(page, "a")

      assert is_list(subject)
      Enum.each(subject, fn e -> assert match?(%Element{}, e) end)
    end

    test "remove selected elements from a page"

    test "remove selected elements from a list of elements"
  end

  describe ".raw_html" do
    test "parseable is nil", %{parser: parser} do
      assert_raise ArgumentError, "page_or_elements is nil", fn ->
        parser.raw_html(nil)
      end
    end

    test "returns raw contents of a page", %{page: page, parser: parser} do
      assert parser.raw_html(page) == page.content
    end

    test "returns a raw content of single element", %{page: page, parser: parser} do
      assert page
             |> parser.search(".europe .portuguese")
             |> List.first()
             |> parser.raw_html() ==
               ~s(<div class="portuguese">Portugal</div>)
    end
  end

  describe "element parsing" do
    setup %{page: page, parser: parser, selector: selector} do
      {:ok,
       %{
         element:
           page
           |> parser.search(selector)
           |> List.first()
       }}
    end

    @tag selector: "#attribute_without_value"
    test "attribute without value", %{element: element} do
      assert element.attrs == [{"id", "attribute_without_value"}, {"value", "value"}]
    end

    @tag selector: "#attribute_with_empty_value"
    test "attribute with empty value", %{element: element} do
      assert element.attrs == [{"id", "attribute_with_empty_value"}, {"value", ""}]
    end

    @tag selector: "#attribute_with_value"
    test "attribute with value", %{element: element} do
      assert element.attrs == [{"id", "attribute_with_value"}, {"value", "10"}]
    end

    @tag selector: "#attribute_with_untrimmed_value"
    test "attribute with untrimmed value", %{element: element} do
      assert element.attrs == [{"id", "attribute_with_untrimmed_value"}, {"value", "  10   "}]
    end

    @tag selector: "#attribute_absent"
    test "attribute absent", %{element: element} do
      assert element.attrs == [{"id", "attribute_absent"}]
    end

    @tag selector: "#text_empty"
    test "text empty", %{element: element} do
      assert element.text == ""
    end

    @tag selector: "#text_absent"
    test "text absent", %{element: element} do
      assert element.text == ""
    end

    @tag selector: "#text_present"
    test "text present", %{element: element} do
      assert element.text == "Lero"
    end

    @tag selector: "#text_untrimmed"
    test "text untrimmed", %{element: element} do
      assert element.text == "   Lero   "
    end
  end
end
