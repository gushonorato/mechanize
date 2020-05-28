defmodule Mechanize.Page.Link do
  alias Mechanize.Page.{Element, ClickError}
  alias Mechanize.Browser

  @derive [Mechanize.Page.Elementable]
  defstruct element: nil

  @type t :: %__MODULE__{
          element: Element.t()
        }

  def click(%Mechanize.Page.Link{} = link) do
    href = Element.attr(link, :href)

    unless href, do: raise(ClickError, "href attribute is missing")

    page = Element.page(link)
    Browser.follow_url(page.browser, page, href)
  end

  def new(el) do
    %__MODULE__{element: el}
  end
end
