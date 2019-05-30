defmodule Mechanizex.Query do

  alias Mechanizex.Queryable

  def with_elements(queryable, element_names, criterias \\ [])

  def with_elements(queryable, element_names, criterias) do
    queryable
    |> maybe_filter_by_selector(criterias)
    |> filter_by_element_names(element_names)
    |> filter_by_criteria(criterias)
  end

  defp maybe_filter_by_selector(queryable, css: selector) do
    search(queryable, selector)
  end

  defp maybe_filter_by_selector(queryable, _) do
    queryable
  end

  defp filter_by_element_names(queryables, names) when is_list(queryables) do
    Enum.filter(queryables, fn queryable -> Queryable.tag_name(queryable) in names end)
  end

  defp filter_by_element_names(queryable, names) when is_map(queryable) do
    names = Enum.map(names, &to_string/1)
    Enum.flat_map(names, fn name -> search(queryable, name) end)
  end

  defp filter_by_criteria(queryables, criterias) do
    criterias = Keyword.delete(criterias, :css)
    Enum.filter(queryables, &all_criterias_meet?(&1, criterias))
  end

  defp all_criterias_meet?(queryable, [h | t]) do
    criteria_meet?(queryable, h) and all_criterias_meet?(queryable, t)
  end

  defp all_criterias_meet?(_, []) do
    true
  end

  defp criteria_meet?(queryable, {:text, value}) when is_binary(value) do
    text(queryable) == value
  end

  defp criteria_meet?(queryable, {:text, value}) do
    text(queryable) =~ value
  end

  defp criteria_meet?(queryable, {attr_name, value}) when is_binary(value) do
    attribute(queryable, attr_name) == value
  end

  defp criteria_meet?(queryable, {attr_name, value}) do
    attr_value = attribute(queryable, attr_name)
    attr_value != nil and attr_value =~ value
  end

  def search(queryable, selector), do: parser(queryable).search(queryable, selector)

  def attributes(queryable, attr_name) when not is_list(queryable), do: attributes([queryable], attr_name)
  def attributes(queryable, attr_name), do: parser(queryable).attributes(queryable, attr_name)
  def attributes(queryable, selector, attr_name), do: parser(queryable).attributes(queryable, selector, attr_name)

  def attribute(queryable, attr_name) when not is_list(queryable), do: attribute([queryable], attr_name)
  def attribute(queryable, attr_name), do: parser(queryable).attributes(queryable, attr_name) |> List.first()
  def attribute(queryable, selector, attr_name), do: parser(queryable).attributes(queryable, selector, attr_name) |> List.first()

  def text(queryable) when not is_list(queryable), do: parser(queryable).text([queryable])
  def text(queryable), do: parser(queryable).text(queryable)

  def parser(queryable) when is_list(queryable), do: queryable |> List.first() |> Queryable.parser()
  def parser(queryable), do: Queryable.parser(queryable)
end

defprotocol Mechanizex.Queryable do
  def data(queryable)
  def parser(queryable)
  def tag_name(queryable)
end


