defmodule Mechanizex.Query do
  alias Mechanizex.Page.Element
  alias Mechanizex.HTMLParser.Parseable

  defmacro query(criteria) do
    quote do
      &Mechanizex.Query.match?(&1, unquote(criteria))
    end
  end

  def match?(_element, []), do: true

  def match?(element, [{:tag, tag} | criterias]) do
    __MODULE__.match?(element, [{:tags, [tag]} | criterias])
  end

  def match?(element, [{:tags, tags} | criterias]) do
    String.to_atom(Element.name(element)) in tags and __MODULE__.match?(element, criterias)
  end

  def match?(element, [{:text, text} | criterias]) do
    text_match?(element, text) and __MODULE__.match?(element, criterias)
  end

  def match?(element, [attributes | criterias]) do
    attribute_match?(element, attributes) and __MODULE__.match?(element, criterias)
  end

  def attribute_match?(element, {attr_name, nil}) do
    Element.attr(element, attr_name) == nil
  end

  def attribute_match?(element, {attr_name, value}) when is_binary(value) do
    Element.attr(element, attr_name) == value
  end

  def attribute_match?(element, {attr_name, value}) do
    attr_value = Element.attr(element, attr_name)
    attr_value != nil and attr_value =~ value
  end

  defp text_match?(element, nil) do
    Element.text(element) == nil
  end

  defp text_match?(element, text) when is_binary(text) do
    Element.text(element) == text
  end

  defp text_match?(element, text) do
    Element.text(element) =~ text
  end

  def search(elements, selector), do: parser(elements).search(elements, selector)

  def parser(elements) when is_list(elements),
    do: elements |> List.first() |> Parseable.parser()

  def parser(element), do: Parseable.parser(element)
end

#
