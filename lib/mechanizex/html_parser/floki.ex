defmodule Mechanizex.HTMLParser.Floki do
  alias Mechanizex.HTMLParser
  alias Mechanizex.Page.Element
  alias Mechanizex.HTMLParser.Parseable

  @behaviour Mechanizex.HTMLParser

  @impl HTMLParser
  def search([], _), do: []

  @impl HTMLParser
  def search([h | _] = elements, selector) do
    check_elements_from_same_page(elements)

    elements
    |> Enum.map(&Parseable.parser_data/1)
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, Parseable.page(h)))
  end

  @impl HTMLParser
  def search(parseable, selector) do
    parseable
    |> Parseable.parser_data()
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, Parseable.page(parseable)))
  end

  defp check_elements_from_same_page(elements) do
    num_pages =
      elements
      |> Enum.map(&Parseable.page/1)
      |> Enum.uniq()
      |> Enum.count()

    if num_pages > 1, do: raise(ArgumentError, "Elements are not from the same page")
  end

  defp create_element({name, attributes, _} = tree, page) do
    %Element{
      name: name,
      attrs: attributes,
      parser_data: tree,
      text: Floki.text(tree),
      page: page
    }
  end
end
