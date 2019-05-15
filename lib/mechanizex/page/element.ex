defmodule Mechanizex.Page.Element do
  defstruct name: nil, attributes: nil, children: nil, text: nil, mechanizex: nil, parser: nil

  @type t :: %__MODULE__{
          name: String.t(),
          attributes: list(),
          children: list(),
          text: String.t(),
          mechanizex: pid(),
          parser: module()
        }

  def attribute(%Mechanizex.Page.Element{} = el, attr_name) do
    el.parser.attribute(el, attr_name)
  end
end
