defmodule Mechanize.HTMLParser.FlokiParser do
  use Mechanize.HTMLParser
  alias Mechanize.Page
  alias Mechanize.Page.Element

  @impl Mechanize.HTMLParser
  def find(page, selector) do
    page
    |> Page.body()
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, page))
  end

  defp create_element({name, attrs, children} = el, page) do
    %Element{
      name: name,
      attributes: attrs,
      children: children,
      text: Floki.text(el),
      mechanize: Page.mechanize(page),
      parser: __MODULE__
    }
  end

  @impl Mechanize.HTMLParser
  def attribute(el, attr_name) when is_atom(attr_name) do
    attribute(el, Atom.to_string(attr_name))
  end

  @impl Mechanize.HTMLParser
  def attribute(%{name: name, attributes: attrs, children: children}, attr_name) do
    Floki.attribute([{name, attrs, children}], attr_name)
  end

  @impl Mechanize.HTMLParser
  def text(%Page{} = page) do
    page
    |> Page.body()
    |> Floki.text()
  end

  @impl Mechanize.HTMLParser
  def text(%{name: name, attributes: attrs, children: children}) do
    Floki.text([{name, attrs, children}])
  end
end
