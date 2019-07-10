defmodule Mechanizex.Query do
  alias Mechanizex.Page.Element
  alias Mechanizex.HTMLParser.Parseable

  def select(elements, names, criterias \\ [])

  def select(elements, :all, criterias) do
    elements
    |> Enum.filter(&all_criterias_meet?(&1, criterias))
  end

  def select(elements, names, criterias) do
    elements
    |> Enum.filter(fn element -> String.to_atom(Element.name(element)) in names end)
    |> Enum.filter(&all_criterias_meet?(&1, criterias))
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

  defp criteria_meet?(element, {attr_name, nil}) do
    Element.attr(element, attr_name) == nil
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
