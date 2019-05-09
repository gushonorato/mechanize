defmodule Mechanize.Page.Element do
  defstruct name: nil, attributes: nil, children: nil, text: nil, mechanize: nil, parser: nil

  @type t :: %__MODULE__{
          name: String.t(),
          attributes: list(),
          children: list(),
          text: String.t(),
          mechanize: pid(),
          parser: module()
        }

  def attribute(%Mechanize.Page.Element{} = el, attr_name) do
    el.parser.attribute(el, attr_name)
  end
end
