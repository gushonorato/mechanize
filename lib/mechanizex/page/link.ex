defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.{Element, ClickError}
  alias Mechanizex.{Page, Browser}

  @derive [Mechanizex.Page.Elementable]
  defstruct element: nil

  @type t :: %__MODULE__{
          element: Element.t()
        }

  def click(%Mechanizex.Page.Link{} = link) do
    href = Element.attr(link, :href)

    unless href, do: raise(ClickError, "href attribute is missing")

    url =
      link
      |> Element.page()
      |> Page.url()
      |> URI.merge(href)
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
