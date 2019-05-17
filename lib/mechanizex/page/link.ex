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

  def click(%Element{attributes: %{ href: url }}) do

  end
end
