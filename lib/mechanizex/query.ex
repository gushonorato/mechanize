defmodule Mechanize.Query do
  alias Mechanize.HTMLParser.Parseable
  alias Mechanize.Queryable

  defmodule BadCriteriaError do
    defexception [:message]
  end

  def search(nil, _selector), do: raise(ArgumentError, "parseable is nil")

  def search(_parseable, nil), do: raise(ArgumentError, "selector is nil")

  def search(parseable, selector), do: parser(parseable).search(parseable, selector)

  def filter(nil, _selector), do: raise(ArgumentError, "parseable is nil")

  def filter(_parseable, nil), do: raise(ArgumentError, "selector is nil")

  def filter(parseable, selector), do: parser(parseable).filter(parseable, selector)

  def matches(nil, _criteria) do
    raise ArgumentError, "queryable is nil"
  end

  def matches(queryable, criteria) do
    Enum.filter(queryable, &match_criteria?(&1, criteria))
  end

  def search_matches(parseable, selector, criteria \\ []) do
    parseable
    |> search(selector)
    |> matches(criteria)
  end

  def match_criteria?(_element, []), do: true

  def match_criteria?(element, [{:tag, tag} | criterias]) do
    match_criteria?(element, [{:tags, [tag]} | criterias])
  end

  def match_criteria?(element, [{:tags, tags} | criterias]) do
    String.to_atom(Queryable.name(element)) in tags and match_criteria?(element, criterias)
  end

  def match_criteria?(element, [{:text, text} | criterias]) do
    match_text?(element, text) and match_criteria?(element, criterias)
  end

  def match_criteria?(element, [attributes | criterias]) do
    match_attribute?(element, attributes) and match_criteria?(element, criterias)
  end

  defp match_attribute?(element, {attr_name, value}) when value == nil or value == false do
    attr(element, attr_name) == nil
  end

  defp match_attribute?(element, {attr_name, true}) do
    attr(element, attr_name) != nil
  end

  defp match_attribute?(element, {attr_name, value}) when is_binary(value) or is_integer(value) do
    attr(element, attr_name) == value
  end

  defp match_attribute?(element, {attr_name, value}) do
    attr_value = attr(element, attr_name)
    attr_value != nil and attr_value =~ value
  end

  defp match_text?(element, nil) do
    Queryable.text(element) == nil
  end

  defp match_text?(element, text) when is_binary(text) do
    Queryable.text(element) == text
  end

  defp match_text?(element, text) do
    Queryable.text(element) != nil and Queryable.text(element) =~ text
  end

  defp parser(elements) when is_list(elements),
    do: elements |> List.first() |> Parseable.parser()

  defp parser(element), do: Parseable.parser(element)

  defp attr(queryable, attr_name) do
    queryable
    |> Queryable.attrs()
    |> List.keyfind(Atom.to_string(attr_name), 0, {nil, nil})
    |> elem(1)
  end
end
