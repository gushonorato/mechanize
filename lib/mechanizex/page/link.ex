defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.{Element, Link}

  defstruct name: nil,
            attributes: nil,
            href: nil,
            tree: nil,
            text: nil,
            page: nil,
            parser: nil

  @type t :: %__MODULE__{
          name: String.t(),
          attributes: list(),
          tree: list(),
          text: String.t(),
          page: pid(),
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
