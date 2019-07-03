defmodule Mechanizex.QueryTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Request, Response, Page, Query}
  alias Mechanizex.Page.Element
  doctest Mechanizex.Query

  @html """
    <html>
    <head>
    <title id="elem_1">Test</title>
    <meta id="elem_2" name="description" content="Test webpage"/>
    </head>
    <body>
      <div id="elem_3" class="container" data-method="get">
        <a id="elem_4" href="http://google.com.br" rel="nofollow" class="company js-google js-cool">Google Brazil</a>
      </div>
      <div id="elem_5" class="content">
        <a id="elem_6" href="http://google.com" class="company js-google js-cool">Google</a>
        <a id="elem_7" href="http://elixir-lang.org" class="js-elixir js-cool">Elixir lang</a>
        <a id="elem_8" href="http://java.com" class="js-java">Java</a>
      </div>
    </body>
    </html>
  """

  setup_all do
    {:ok,
     page: %Page{
       agent: Mechanizex.new(),
       request: %Request{},
       parser: Mechanizex.HTMLParser.Floki,
       response: %Response{
         body: @html
       }
     }}
  end

  describe ".with_elements" do
    test "invalid string criteria", %{page: page} do
      assert page
             |> Query.with_elements([:a], foo: "bar")
             |> Enum.map(&Element.name/1) == []
    end

    test "invalid regexp criteria", %{page: page} do
      assert page
             |> Query.with_elements([:title], foo: ~r/bar/)
             |> Enum.map(&Element.name/1) == []
    end

    test "one element returned", %{page: page} do
      assert(
        page
        |> Query.with_elements([:title])
        |> Enum.map(&Element.name/1) == [:title]
      )
    end

    test "css criteria", %{page: page} do
      assert page
             |> Query.with_elements([:a], css: ".js-google")
             |> Enum.map(&Element.attr(&1, :id)) == [
               "elem_4",
               "elem_6"
             ]
    end

    test "broad match with regex", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a], href: ~r/google.com.br/)
        |> Enum.map(&Element.attr(&1, :id)) == ["elem_4"]
      )
    end

    test "broad match with string won't work", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a], href: "google.com.br")
        |> Enum.map(&Element.attr(&1, :id)) == []
      )
    end

    test "exact match with string in criteria", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a], href: "http://google.com.br")
        |> Enum.map(&Element.attr(&1, :id)) == [
          "elem_4"
        ]
      )
    end

    test "accepts many attributes in criteria", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a],
          class: ~r/js-google /,
          rel: ~r/nofollow/
        )
        |> Enum.map(&Element.attr(&1, :id)) == ["elem_4"]
      )
    end

    test "broad match text with regexp", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a], text: ~r/Google/)
        |> Enum.map(&Element.attr(&1, :id)) == [
          "elem_4",
          "elem_6"
        ]
      )
    end

    test "exact match text with string", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a], text: "Google")
        |> Enum.map(&Element.attr(&1, :id)) == ["elem_6"]
      )
    end

    test "text and many attributes criteria", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a],
          text: ~r/Google Brazil/,
          class: ~r/js-google /
        )
        |> Enum.map(&Element.attr(&1, :id)) == ["elem_4"]
      )
    end

    test "css, text and many attributes criteria", %{page: page} do
      assert(
        page
        |> Query.with_elements([:a],
          text: ~r/Google/,
          class: ~r/js-google/,
          rel: "nofollow"
        )
        |> Enum.map(&Element.attr(&1, :id)) == ["elem_4"]
      )
    end
  end
end
