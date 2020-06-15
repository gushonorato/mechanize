defmodule Mechanize.HTMLParser.FlokiTest do
  use ExUnit.Case, async: true
  alias Mechanize.Page.Element
  import TestHelper

  setup_all do
    {:ok, %{page: page}} = stub_requests("/test/htdocs/html_parser_test.html")
    {:ok, %{page: page, parser: Mechanize.HTMLParser.Floki}}
  end

  describe ".search" do
    test "raises if page_or_element is nil", %{parser: parser} do
      assert_raise ArgumentError, "page_or_element is nil", fn ->
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

    test "search page with single element found", %{parser: parser, page: page} do
      assert page
             |> parser.search(".america .portuguese")
             |> Enum.map(&Element.text/1) == ["Brazil"]
    end

    test "search page with multiple elements found", %{parser: parser, page: page} do
      assert page
             |> parser.search(".portuguese")
             |> Enum.map(&Element.text/1) == ["Portugal", "Brazil"]
    end

    test "search element with single element found", %{parser: parser, page: page} do
      [element] = parser.search(page, ".america")

      assert element
             |> parser.search(".portuguese")
             |> Enum.map(&Element.text/1) == ["Brazil"]
    end

    test "search element with multiple elements found", %{parser: parser, page: page} do
      [element] = parser.search(page, ".america")

      assert element
             |> parser.search(".spanish")
             |> Enum.map(&Element.text/1) == ["Chile", "Argentina"]
    end
  end

  describe ".filter_out" do
    test "raise when page_or_elements is nil", %{parser: parser} do
      assert_raise ArgumentError, "page_or_elements is nil", fn ->
        parser.filter_out(nil, "a")
      end
    end

    test "raise when selector is nil", %{page: page, parser: parser} do
      assert_raise ArgumentError, "selector is nil", fn ->
        parser.filter_out(page, nil)
      end
    end

    test "returns an element", %{page: page, parser: parser} do
      [%Element{}] = parser.filter_out(page, "a")
    end

    test "remove child elements from a page", %{page: page, parser: parser} do
      [result] = parser.filter_out(page, "div")

      node =
        """
         <!DOCTYPE html>
         <html lang="en">
           <head>
             <meta charset="UTF-8">
             <meta name="viewport" content="width=device-width, initial-scale=1.0">
           </head>
           <body>
           </body>
         </html>
        """
        |> parser.parse_document()
        |> List.first()

      assert result.parser_node == node
    end

    test "remove child elements from parent element", %{page: page, parser: parser} do
      [element] = parser.search(page, ".america")
      [element] = parser.filter_out(element, ".portuguese")

      assert Element.text(element) == "ChileArgentina"
    end

    test "remove all elements", %{page: page, parser: parser} do
      assert parser.filter_out(page, "html") == []
    end
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
