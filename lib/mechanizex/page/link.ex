defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.Element
  alias Mechanizex.{Page, Browser}

  @derive [Mechanizex.Page.Elementable]
  defstruct element: nil

  @type t :: %__MODULE__{
          element: Element.t()
        }

  def click(%Mechanizex.Page.Link{} = link) do
    url =
      link
      |> Element.page()
      |> Page.url()
      |> URI.merge(Element.attr(link, :href))
      |> URI.to_string()

    link
    |> Element.page()
    |> Page.browser()
    |> Browser.get!(url)
  end

  def new(el) do
    %__MODULE__{element: el}
  end
end
