defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.Element
  alias Mechanizex.Page

  @derive [Mechanizex.Page.Elementable]
  defstruct element: nil

  @type t :: %__MODULE__{
          element: Element.t()
        }

  def click(%Mechanizex.Page.Link{} = link) do
    url = Element.attr(link, :href)
    base_url = link |> Element.page() |> Page.url()

    link
    |> Element.page()
    |> Page.agent()
    |> Mechanizex.Agent.get!(URI.merge(base_url, url))
  end
end
