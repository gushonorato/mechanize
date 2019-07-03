defmodule Mechanizex.Query do
  alias Mechanizex.Page.Element

  def with_elements(elements, element_names, criterias \\ [])

  def with_elements(elements, element_names, criterias) do
    elements
    |> maybe_filter_by_selector(criterias)
    |> filter_by_element_names(element_names)
    |> filter_by_criteria(criterias)
  end

  defp maybe_filter_by_selector(elements, css: selector) do
    search(elements, selector)
  end

  defp maybe_filter_by_selector(elements, _) do
    elements
  end

  defp filter_by_element_names(elements, names) when is_list(elements) do
    Enum.filter(elements, fn element -> Element.name(element) in names end)
  end

  defp filter_by_element_names(elements, names) when is_map(elements) do
    names = Enum.map(names, &to_string/1)
    Enum.flat_map(names, fn name -> search(elements, name) end)
  end

  defp filter_by_criteria(elements, criterias) do
    criterias = Keyword.delete(criterias, :css)
    Enum.filter(elements, &all_criterias_meet?(&1, criterias))
  end

  defp all_criterias_meet?(elements, [h | t]) do
    criteria_meet?(elements, h) and all_criterias_meet?(elements, t)
  end

  defp all_criterias_meet?(_, []) do
    true
  end

  defp criteria_meet?(element, {:text, value}) when is_binary(value) do
    Element.text(element) == value
  end

  defp criteria_meet?(element, {:text, value}) do
    Element.text(element) =~ value
  end

  defp criteria_meet?(element, {attr_name, value}) when is_binary(value) do
    Element.attr(element, attr_name) == value
  end

  defp criteria_meet?(element, {attr_name, value}) do
    attr_value = Element.attr(element, attr_name)
    attr_value != nil and attr_value =~ value
  end

  def search(elements, selector), do: parser(elements).search(elements, selector)

  def parser(elements) when is_list(elements),
    do: elements |> List.first() |> Parseable.parser()

  def parser(element), do: Parseable.parser(element)
end
