defmodule Mechanizex.Page.Element do
  alias Mechanizex.Page.Elementable

  defstruct name: nil,
            attrs: nil,
            parser_data: nil,
            text: nil,
            page: nil

  @type t :: %__MODULE__{
          name: atom(),
          attrs: list(),
          parser_data: list(),
          text: String.t(),
          page: Page.t()
        }

  def page(el), do: el(el).page
  def text(el), do: el(el).text
  def name(el), do: el(el).name
  def attrs(el), do: el(el).attrs
  def attr_present?(el, attr_name), do: attr(el, attr_name) != nil
  def attr(el, attr_name), do: el(el).attrs[attr_name]
  defp el(elementable), do: Elementable.element(elementable)
end

defprotocol Mechanizex.Page.Elementable do
  def element(elementable)
end

defimpl Mechanizex.Page.Elementable, for: Mechanizex.Page.Element do
  def element(elementable), do: elementable
end

defimpl Mechanizex.Page.Elementable, for: Any do
  def element(elementable), do: elementable.element
end

defimpl Parseable, for: Mechanizex.Page.Element do
  alias Mechanizex.Page.Elementable
  def parser(element), do: Parseable.parser(Elementable.element(element).page)
  def parser_data(element), do: Elementable.element(element).parser_data
  def page(element), do: Elementable.element(element).page
end
