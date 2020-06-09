defmodule Mechanize.Query do
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Page

  defmodule BadCriteriaError do
    defexception [:message]
  end

  def search(nil, _selector), do: raise(ArgumentError, "page_or_elements is nil")
  def search(_page_or_elements, nil), do: raise(ArgumentError, "selector is nil")

  def search(%Page{} = page, selector), do: page.parser.search(page, selector)

  def search(elementables, selector) when is_list(elementables) do
    elementables
    |> Enum.map(&Elementable.element/1)
    |> Enum.flat_map(fn el -> el.parser.search(el, selector) end)
  end

  def search(elementable, selector) do
    search([elementable], selector)
  end

  def filter(nil, _selector), do: raise(ArgumentError, "page_or_elements is nil")
  def filter(_page_or_elements, nil), do: raise(ArgumentError, "selector is nil")

  def filter(%Page{} = page, selector), do: page.parser.filter(page, selector)

  def filter(elementables, selector) when is_list(elementables) do
    elementables
    |> Enum.map(&Elementable.element/1)
    |> Enum.flat_map(fn el -> el.parser.filter(el, selector) end)
  end

  def filter(elementable, selector), do: filter([elementable], selector)

  def elements_with(page_or_elements, selector, criteria \\ []) do
    page_or_elements
    |> search(selector)
    |> Enum.filter(&match_criteria?(&1, criteria))
  end

  def match?(nil, _types, _criteria) do
    raise ArgumentError, "element is nil"
  end

  def match?(_element, nil, _criteria) do
    raise ArgumentError, "types is nil"
  end

  def match?(_element, _types, nil) do
    raise ArgumentError, "criteria is nil"
  end

  def match?(element, types, criteria) do
    match_type?(element, types) and match_criteria?(element, criteria)
  end

  def match_type?(element, types) when is_list(types) do
    element.__struct__ in types
  end

  def match_type?(element, type) do
    match_type?(element, [type])
  end

  def match_criteria?(nil, _criteria), do: raise(ArgumentError, "element is nil")
  def match_criteria?(_element, nil), do: raise(ArgumentError, "criteria is nil")

  def match_criteria?(_element, []), do: true

  # TODO: Add tests
  def match_criteria?(element, index) when is_integer(index) do
    case element.index do
      nil ->
        raise ArgumentError, "element is not indexed"

      ^index ->
        true

      _ ->
        false
    end
  end

  def match_criteria?(element, [attributes | criterias]) do
    match_attribute?(element, attributes) and match_criteria?(element, criterias)
  end

  defp match_attribute?(_element, {:text, nil}) do
    raise ArgumentError, "criteria :text is nil"
  end

  defp match_attribute?(element, {:text, value}) when is_binary(value) do
    Element.text(element) == value
  end

  defp match_attribute?(element, {:text, value}) do
    Element.text(element) =~ value
  end

  defp match_attribute?(_element, {attr_name, nil}) do
    raise ArgumentError, "criteria :#{attr_name} is nil"
  end

  defp match_attribute?(element, {attr_name, boolean}) when is_boolean(boolean) do
    Element.attr_present?(element, attr_name) == boolean
  end

  defp match_attribute?(element, {attr_name, value}) when is_binary(value) do
    Element.attr(element, attr_name) == value
  end

  defp match_attribute?(element, {attr_name, value}) do
    case Element.attr(element, attr_name) do
      nil -> false
      attr_value -> attr_value =~ value
    end
  end
end
