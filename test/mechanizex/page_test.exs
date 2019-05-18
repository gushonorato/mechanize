defmodule Mechanizex.PageTest do
  use ExUnit.Case, async: true
  alias Mechanizex.Response
  alias Mechanizex.Page
  doctest Mechanizex.Page

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
       response: %Response{
         body: @html
       }
     }}
  end

  describe ".with_elements" do
    defp with_elements_map(attr_for_map, page, elements, criteria \\ []) do
      page
      |> Page.with_elements(elements, criteria)
      |> Enum.map(&Map.get(&1, attr_for_map))
    end

    test "invalid string criteria", state do
      assert with_elements_map(:name, state.page, [:a], foo: "bar") == []
    end

    test "invalid regexp criteria", state do
      assert with_elements_map(:name, state.page, [:title], foo: ~r/bar/) == []
    end

    test "one element returned", state do
      assert with_elements_map(:name, state.page, [:title]) == [:title]
    end

    test "css criteria", state do
      assert with_elements_map(:dom_id, state.page, [:a], css: ".js-google") == [
               "elem_4",
               "elem_6"
             ]
    end

    test "broad match with regex", state do
      assert with_elements_map(:dom_id, state.page, [:a], href: ~r/google.com.br/) == ["elem_4"]
    end

    test "broad match with string won't work", state do
      assert with_elements_map(:dom_id, state.page, [:a], href: "google.com.br") == []
    end

    test "exact match with string in criteria", state do
      assert with_elements_map(:dom_id, state.page, [:a], href: "http://google.com.br") == [
               "elem_4"
             ]
    end

    test "accepts many attributes in criteria", state do
      assert with_elements_map(:dom_id, state.page, [:a],
               class: ~r/js-google /,
               rel: ~r/nofollow/
             ) == ["elem_4"]
    end

    test "broad match text with regexp", state do
      assert with_elements_map(:dom_id, state.page, [:a], text: ~r/Google/) == [
               "elem_4",
               "elem_6"
             ]
    end

    test "exact match text with string", state do
      assert with_elements_map(:dom_id, state.page, [:a], text: "Google") == ["elem_6"]
    end

    test "text and many attributes criteria", state do
      assert with_elements_map(:dom_id, state.page, [:a],
               text: ~r/Google Brazil/,
               class: ~r/js-google /
             ) == ["elem_4"]
    end

    test "css, text and many attributes criteria", state do
      assert with_elements_map(:dom_id, state.page, [:a],
               text: ~r/Google/,
               class: ~r/js-google/,
               rel: "nofollow"
             ) == ["elem_4"]
    end
  end

  describe ".links" do
    test "return all links of a page", state do
      link_ids =
        state.page
        |> Page.links()
        |> Enum.map(&Map.get(&1, :dom_id))

      assert link_ids == ["elem_4", "elem_6", "elem_7", "elem_8"]
    end
  end
end
