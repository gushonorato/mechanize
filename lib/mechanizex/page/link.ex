defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.Element
  alias Mechanizex.Page

  @derive [Mechanizex.Page.Elementable]
  defstruct element: nil

  @type t :: %__MODULE__{
          element: Element.t()
        }

  def click(%Mechanizex.Page.Link{element: %{attrs: %{href: url}, page: page}}) do
    page
    |> Page.agent()
    |> Mechanizex.Agent.get!(URI.merge(Page.url(page), url))
  end
end
