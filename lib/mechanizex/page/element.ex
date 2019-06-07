defmodule Mechanizex.Page.Element do
  defstruct dom_id: nil,
            tag_name: nil,
            attributes: nil,
            tree: nil,
            text: nil,
            page: nil

  @type t :: %__MODULE__{
          dom_id: String.t(),
          tag_name: atom(),
          attributes: list(),
          tree: list(),
          text: String.t(),
          page: Page.t()
        }

  def page(element) do
    element.page
  end

  defimpl Mechanizex.Queryable, for: Mechanizex.Page.Element do
    alias Mechanizex.Queryable
    def data(element), do: element.tree
    def parser(element), do: Queryable.parser(element.page)
    def tag_name(element), do: element.tag_name
  end
end
