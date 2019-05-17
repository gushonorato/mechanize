defmodule Mechanizex.Page.Element do
  defstruct dom_id: nil, name: nil, attributes: nil, tree: nil, text: nil, page: nil, parser: nil

  @type t :: %__MODULE__{
          dom_id: String.t(),
          name: String.t(),
          attributes: list(),
          tree: list(),
          text: String.t(),
          page: Page.t(),
          parser: module()
        }

  def tree(%Mechanizex.Page.Element{ tree: tree }), do: tree

  def agent(%Mechanizex.Page.Element{ page: page }), do: page.agent

  def page(%Mechanizex.Page.Element{ page: page }), do: page
end
