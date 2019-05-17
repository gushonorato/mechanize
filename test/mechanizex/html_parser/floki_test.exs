defmodule Mechanizex.HTMLParser.FlokiTest do
  use ExUnit.Case, async: true
  alias Mechanizex.HTMLParser
  alias Mechanizex.{Response, Page}
  alias Mechanizex.Page.Element

  doctest Mechanizex.HTMLParser.Floki

  @html """
    <html>
    <head>
    <title>Test</title>
    <meta name="description" content="Test webpage"/>
    </head>
    <body>
      <div class="container" data-method="get">
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
      <div class="container" data-method="get">
      </div>
      <div class="content">
      </div>
    </body>
    </html>
  """

  @page %Page {
    agent: :fake_mechanize_pid,
    response: %Response{
      body: @html
    }
  }

  @page_without_text %Page {
    agent: :fake_mechanize_pid,
    response: %Response{
      body: @html_without_text
    }
  }

  @google %Element{
    name: "a",
    attributes: %{"href" => "http://google.com", "class" => "company js-google js-cool"},
    text: "Google",
    tree: {
      "a",
      [{"href", "http://google.com"}, {"class", "company js-google js-cool"}],
      ["Google"]
    },
    page: @page,
    parser: HTMLParser.Floki
  }

  describe ".search" do
    test "element not found" do
      assert HTMLParser.Floki.search(@page, ".unknown") == []
    end

    test "one element with children found" do
      element = %Element{
        name: "div",
        attributes: %{"class" => "container", "data-method" => "get"},
        text: "Google",
        tree: {
          "div",
          [{"class", "container"}, {"data-method", "get"}],
          [
            {"a",
              [
                {"href", "http://google.com"},
                {"class", "company js-google js-cool"}
              ], ["Google"]}
          ]
        },
        page: @page,
        parser: HTMLParser.Floki
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
        HTMLParser.Floki.search([%Element{page: @page}, %Element{page: @page_without_text}], ".js-google")
      end
    end
  end

  describe ".attribute" do

    test "attribute not found" do
      assert HTMLParser.Floki.attribute([@google], "data-remote") == []
    end

    test "attribute found" do
      assert HTMLParser.Floki.attribute([@google], "href") == ["http://google.com"]
    end

    test "multiple elements" do
      assert HTMLParser.Floki.attribute([@google, @google], "href") == ["http://google.com", "http://google.com"]
    end

    test "multiple attributes found within a page" do
      assert HTMLParser.Floki.attribute(@page, ".js-cool", "href") == ["http://google.com", "http://google.com", "http://elixir-lang.org"]
    end
  end

  describe ".text" do

    test "within a page" do
      assert HTMLParser.Floki.text(@page) == "TestGoogleGoogleElixir langJava"
    end

    test "within one element" do
      assert HTMLParser.Floki.text([@google]) == "Google"
    end

    test "within many elements" do
      assert HTMLParser.Floki.text([@google, @google]) == "GoogleGoogle"
    end

    test "element without text" do
      text =
        @page
        |> HTMLParser.Floki.search("meta")
        |> HTMLParser.Floki.text

        assert text == ""
    end

    test "page doesn't have text" do
      text =
        @page_without_text
        |> HTMLParser.Floki.text

        assert text == ""
    end
  end

end
