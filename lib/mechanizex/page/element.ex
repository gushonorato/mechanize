defmodule Mechanizex.Page.Element do
  alias Mechanizex.Page.Elementable
  alias Mechanizex.Page.Link

  defstruct name: nil,
            attrs: nil,
            parser_data: nil,
            text: nil,
            page: nil

  @type t :: %__MODULE__{
          name: atom(),
          attrs: list(),
          parser_data: list(),
          text: String.t(),
          page: Page.t()
        }

  def page(el), do: el(el).page
  def text(el), do: el(el).text
  def name(el), do: maybe_normalize_value(el(el).name, true)
  def attrs(el), do: el(el).attrs
  def attr_present?(el, attr_name), do: attr(el, attr_name) != nil

  def attr(el, attr_name, opts \\ []) do
    default_opts = [default: nil, normalize: false]
    opts = Keyword.merge(default_opts, opts)

    el
    |> attrs()
    |> List.keyfind(to_string(attr_name), 0, {nil, opts[:default]})
    |> elem(1)
    |> maybe_normalize_value(opts[:normalize])
  end

  defp maybe_normalize_value(value, false) do
    value
  end

  defp maybe_normalize_value(nil, _) do
    nil
  end

  defp maybe_normalize_value(value, _) do
    value
    |> String.downcase()
    |> String.trim()
  end

  defp el(elementable), do: Elementable.element(elementable)

  def to_links(elements) when is_list(elements) do
    Enum.map(elements, &to_link/1)
  end

  def to_link(%Mechanizex.Page.Element{name: "a"} = element) do
    %Link{element: element}
  end

  def to_link(%Mechanizex.Page.Element{name: "area"} = element) do
    %Link{element: element}
  end
end

defimpl Mechanizex.Page.Elementable, for: Mechanizex.Page.Element do
  def element(elementable), do: elementable
end

defimpl Mechanizex.HTMLParser.Parseable, for: Mechanizex.Page.Element do
  alias Mechanizex.Page.Elementable
  alias Mechanizex.HTMLParser.Parseable
  def parser(element), do: Parseable.parser(Elementable.element(element).page)
  def parser_data(element), do: Elementable.element(element).parser_data
  def page(element), do: Elementable.element(element).page
end
