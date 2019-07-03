defmodule Mechanizex.HTMLParser.FlokiTest do
  use ExUnit.Case, async: true
  alias Mechanizex.HTMLParser
  alias Mechanizex.{Response, Page, Request}
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
        <a href="http://google.com" class="company js-google js-cool">Google</a>
      </div>
      <div class="content">
        <a href="http://google.com" class="company js-google js-cool">Google</a>
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
    agent: :fake_mechanize_pid,
    request: %Request{},
    response: %Response{
      body: @html
    }
  }

  @page_without_text %Page{
    agent: :fake_mechanize_pid,
    request: %Request{},
    response: %Response{
      body: @html_without_text
    }
  }

  @google %Element{
    name: :a,
    attrs: %{href: "http://google.com", class: "company js-google js-cool"},
    text: "Google",
    parser_data: {
      "a",
      [{"href", "http://google.com"}, {"class", "company js-google js-cool"}],
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
        name: :div,
        attrs: %{id: "main", class: "container", "data-method": "get"},
        text: "Google",
        parser_data: {
          "div",
          [{"id", "main"}, {"class", "container"}, {"data-method", "get"}],
          [
            {"a",
             [
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
end
