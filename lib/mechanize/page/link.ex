defmodule Mechanize.Page.Link do
  alias Mechanize.Page.Element
  alias Mechanize.Browser

  @derive [Mechanize.Page.Elementable]
  defstruct [:element, :url]

  @type t :: %__MODULE__{
          element: Element.t(),
          url: String.t()
        }

  def click(%__MODULE__{} = link) do
    Browser.click_link(link.element.page.browser, link)
  end

  def new(%Element{name: name} = el) when name == "a" or name == "area" do
    %__MODULE__{
      element: el,
      url: resolve_url(el)
    }
  end

  defp resolve_url(el) do
    Browser.resolve_url(Element.page(el), Element.attr(el, :href))
  end
end
