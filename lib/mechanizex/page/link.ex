defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.{Element, ClickError}
  alias Mechanizex.Browser

  @derive [Mechanizex.Page.Elementable]
  defstruct element: nil

  @type t :: %__MODULE__{
          element: Element.t()
        }

  def click(%Mechanizex.Page.Link{} = link) do
    href = Element.attr(link, :href)

    unless href, do: raise(ClickError, "href attribute is missing")

    page = Element.page(link)
    Browser.follow_url(page.browser, page, href)
  end

  def new(el) do
    %__MODULE__{element: el}
  end
end
