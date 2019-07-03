defmodule Mechanizex.HTMLParser.Floki do
  alias Mechanizex.{HTMLParser, Page, Element}
  alias Mechanizex.Page.Element

  @behaviour Mechanizex.HTMLParser

  @impl HTMLParser
  def search(%Page{} = page, selector) do
    page
    |> Page.body()
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, page))
  end

  @impl HTMLParser
  def search(%Element{} = element, selector) do
    search([element], selector)
  end

  @impl HTMLParser
  def search([], _), do: []

  @impl HTMLParser
  def search([h | _] = elements, selector) do
    check_elements_from_same_page(elements)

    elements
    |> Enum.map(&Parseable.parser_data/1)
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, h.page))
  end

  @impl HTMLParser
  def attributes(elements, attribute_name) do
    elements
    |> Enum.map(&Parseable.parser_data/1)
    |> Floki.attribute(to_string(attribute_name))
  end

  @impl HTMLParser
  def attributes(page, selector, attribute_name) do
    page
    |> Page.body()
    |> Floki.attribute(selector, to_string(attribute_name))
  end

  @impl HTMLParser
  def text(%Page{} = page) do
    page
    |> Page.body()
    |> Floki.text()
  end

  @impl HTMLParser
  def text(elements) do
    elements
    |> Enum.map(&Parseable.parser_data/1)
    |> Floki.text()
  end

  defp check_elements_from_same_page(elements) do
    num_pages =
      elements
      |> Enum.map(&Element.page/1)
      |> Enum.uniq()
      |> Enum.count()

    if num_pages > 1, do: raise(ArgumentError, "Elements are not from the same page")
  end

  defp create_element({name, attributes, _} = tree, page) do
    %Element{
      name: String.to_atom(name),
      attrs: create_attributes_map(attributes),
      parser_data: tree,
      text: Floki.text(tree),
      page: page
    }
  end

  defp dom_id(tree) do
    tree
    |> Floki.attribute("id")
    |> List.first()
  end

  defp create_attributes_map(attributes) do
    attributes
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end
end
