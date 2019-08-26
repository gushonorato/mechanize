defmodule Mechanizex.Query do
  alias Mechanizex.HTMLParser.Parseable
  alias Mechanizex.Queryable

  def match?(_element, []), do: true

  def match?(element, [{:tag, tag} | criterias]) do
    __MODULE__.match?(element, [{:tags, [tag]} | criterias])
  end

  def match?(element, [{:tags, tags} | criterias]) do
    String.to_atom(Queryable.name(element)) in tags and __MODULE__.match?(element, criterias)
  end

  def match?(element, [{:text, text} | criterias]) do
    text_match?(element, text) and __MODULE__.match?(element, criterias)
  end

  def match?(element, [attributes | criterias]) do
    attribute_match?(element, attributes) and __MODULE__.match?(element, criterias)
  end

  def attribute_match?(element, {attr_name, value}) when value == nil or value == false do
    attr(element, attr_name) == nil
  end

  def attribute_match?(element, {attr_name, true}) do
    attr(element, attr_name) != nil
  end

  def attribute_match?(element, {attr_name, value}) when is_binary(value) or is_integer(value) do
    attr(element, attr_name) == value
  end

  def attribute_match?(element, {attr_name, value}) do
    attr_value = attr(element, attr_name)
    attr_value != nil and attr_value =~ value
  end

  defp text_match?(element, nil) do
    Queryable.text(element) == nil
  end

  defp text_match?(element, text) when is_binary(text) do
    Queryable.text(element) == text
  end

  defp text_match?(element, text) do
    Queryable.text(element) =~ text
  end

  def search(elements, selector), do: parser(elements).search(elements, selector)

  def parser(elements) when is_list(elements),
    do: elements |> List.first() |> Parseable.parser()

  def parser(element), do: Parseable.parser(element)

  defp attr(queryable, attr_name) do
    queryable
    |> Queryable.attrs()
    |> List.keyfind(Atom.to_string(attr_name), 0, {nil, nil})
    |> elem(1)
  end
end
