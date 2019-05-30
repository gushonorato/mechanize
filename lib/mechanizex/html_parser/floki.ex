defmodule Mechanizex.HTMLParser.Floki do
  alias Mechanizex.{HTMLParser, Page, Queryable}
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
  def search([], _), do: []

  @impl HTMLParser
  def search([h | _] = elements, selector) do
    check_elements_from_same_page(elements)

    elements
    |> Enum.map(&Queryable.data/1)
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, h.page))
  end

  @impl HTMLParser
  def attributes(elements, attribute_name) do
    elements
    |> Enum.map(&Queryable.data/1)
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
    |> Enum.map(&Queryable.data/1)
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
      dom_id: dom_id(tree),
      tag_name: String.to_atom(name),
      attributes: create_attributes_map(attributes),
      tree: tree,
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
