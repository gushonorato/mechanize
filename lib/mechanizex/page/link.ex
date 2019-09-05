defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.Element
  alias Mechanizex.{Page, Browser}

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
    |> Page.browser()
    |> Browser.get!(URI.merge(base_url, url))
  end

  def new(el) do
    %__MODULE__{element: el}
  end
end
