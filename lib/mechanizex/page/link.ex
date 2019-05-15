defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.{Element, Link}

  defstruct name: nil,
            attributes: nil,
            href: nil,
            children: nil,
            text: nil,
            mechanizex: nil,
            parser: nil

  @type t :: %__MODULE__{
          name: String.t(),
          attributes: list(),
          children: list(),
          text: String.t(),
          mechanizex: pid(),
          parser: module(),
          href: list()
        }

  @spec create(Element.t()) :: Link.t()
  def create(element) do
    %Link{}
    |> struct(Map.from_struct(element))
    |> Map.put(:href, element.parser.attribute(element, :href))
  end
end
