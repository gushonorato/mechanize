defmodule Mechanizex.Query do
  alias Mechanizex.Page.Element
  alias Mechanizex.HTMLParser.Parseable

  defmacro query(criteria) do
    quote do
      &Mechanizex.Query.query(&1, unquote(criteria))
    end
  end

  def query(_element, []), do: true

  def query(element, [{:tag, tag} | criterias]) do
    query(element, [{:tags, [tag]} | criterias])
  end

  def query(element, [{:tags, tags} | criterias]) do
    String.to_atom(Element.name(element)) in tags and query(element, criterias)
  end

  def query(element, [{:attr, attributes} | criterias]) do
    query(element, [{:attrs, attributes} | criterias])
  end

  def query(element, [{:attrs, attributes} | criterias]) do
    attributes_match?(element, attributes) and query(element, criterias)
  end

  def query(element, [{:text, text} | criterias]) do
    text_match?(element, text) and query(element, criterias)
  end

  def attributes_match?(_element, []), do: true

  def attributes_match?(element, [{attr_name, nil} | t]) do
    Element.attr(element, attr_name) == nil and attributes_match?(element, t)
  end

  def attributes_match?(element, [{attr_name, value} | t]) when is_binary(value) do
    Element.attr(element, attr_name) == value and attributes_match?(element, t)
  end

  def attributes_match?(element, [{attr_name, value} | t]) do
    attr_value = Element.attr(element, attr_name)
    attr_value != nil and attr_value =~ value and attributes_match?(element, t)
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
