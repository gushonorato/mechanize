defmodule Mechanizex.HTMLParser.FlokiTest do
  use ExUnit.Case, async: true
  alias Mechanizex.HTMLParser
  alias Mechanizex.HTMLParser.Parseable
  alias Mechanizex.Page
  alias Mechanizex.Page.Element

  doctest Mechanizex.HTMLParser.Floki

  @html """
    <html>
    <head>
    <title>Test</title>
    <meta name="description" content="Test webpage"/>
    </head>
    <body>
      <div id="main" class="container" data-method="get">
        <a disabled href="http://google.com" class="company js-google js-cool">Google</a>
      </div>
      <div class="content">
        <a disabled href="http://google.com" class="company js-google js-cool">Google</a>
        <a href="http://elixir-lang.org" class="js-elixir js-cool">Elixir lang</a>
        <a href="http://java.com" class="js-java">Java</a>
      </div>
    </body>
    </html>
  """

  @html_without_text """
    <html>
    <head>
    <title></title>
    <meta name="description" content="Test webpage"/>
    </head>
    <body>
      <div id="main" class="container" data-method="get">
      </div>
      <div class="content">
      </div>
    </body>
    </html>
  """

  @page %Page{
    browser: :fake_mechanize_pid,
    body: @html
  }

  @page_without_text %Page{
    browser: :fake_mechanize_pid,
    body: @html_without_text
  }

  @google %Element{
    name: "a",
    attrs: [{"disabled", "disabled"}, {"href", "http://google.com"}, {"class", "company js-google js-cool"}],
    text: "Google",
    parser_data: {
      "a",
      [{"disabled", "disabled"}, {"href", "http://google.com"}, {"class", "company js-google js-cool"}],
      ["Google"]
    },
    page: @page
  }

  describe ".search" do
    test "element not found" do
      assert HTMLParser.Floki.search(@page, ".unknown") == []
    end

    test "one element with children found" do
      element = %Element{
        name: "div",
        attrs: [{"id", "main"}, {"class", "container"}, {"data-method", "get"}],
        text: "Google",
        parser_data: {
          "div",
          [{"id", "main"}, {"class", "container"}, {"data-method", "get"}],
          [
            {"a",
             [
               {"disabled", "disabled"},
               {"href", "http://google.com"},
               {"class", "company js-google js-cool"}
             ], ["Google"]}
          ]
        },
        page: @page
      }

      assert HTMLParser.Floki.search(@page, ".container") == [element]
    end

    test "multiple elements found" do
      assert HTMLParser.Floki.search(@page, ".js-google") == [@google, @google]
    end

    test "only element child nodes" do
      result =
        @page
        |> HTMLParser.Floki.search(".container")
        |> HTMLParser.Floki.search(".js-google")

      assert result == [@google]
    end

    test "empty elements list" do
      assert HTMLParser.Floki.search([], ".js-google") == []
    end

    test "elements from different pages" do
      assert_raise ArgumentError, fn ->
        HTMLParser.Floki.search(
          [%Element{page: @page}, %Element{page: @page_without_text}],
          ".js-google"
        )
      end
    end
  end

  describe ".filter" do
    test "raise when parseable is nil" do
      assert_raise ArgumentError, "parseable is nil", fn ->
        HTMLParser.Floki.filter(nil, "a")
      end
    end

    test "raise when selector is nil" do
      assert_raise ArgumentError, "selector is nil", fn ->
        HTMLParser.Floki.filter(@page, nil)
      end
    end

    test "empty element list" do
      assert HTMLParser.Floki.filter([], "form") == []
    end

    test "returns a list of elements" do
      subject = HTMLParser.Floki.filter(@page, "a")

      assert is_list(subject)
      Enum.each(subject, fn e -> assert match?(%Element{}, e) end)
    end

    test "remove selected elements from a page" do
      assert(
        @page
        |> HTMLParser.Floki.filter("a")
        |> List.first()
        |> Parseable.parser_data() ==
          {"html", [],
           [
             {"head", [],
              [
                {"title", [], ["Test"]},
                {"meta", [{"name", "description"}, {"content", "Test webpage"}], []}
              ]},
             {"body", [],
              [
                {"div",
                 [
                   {"id", "main"},
                   {"class", "container"},
                   {"data-method", "get"}
                 ], []},
                {"div", [{"class", "content"}], []}
              ]}
           ]}
      )
    end

    test "remove selected elements from a list of elements" do
      assert(
        @page
        |> HTMLParser.Floki.search("div")
        |> HTMLParser.Floki.filter(".js-cool")
        |> Enum.map(&Parseable.parser_data/1) == [
          {"div", [{"id", "main"}, {"class", "container"}, {"data-method", "get"}], []},
          {"div", [{"class", "content"}], [{"a", [{"href", "http://java.com"}, {"class", "js-java"}], ["Java"]}]}
        ]
      )
    end
  end
end
