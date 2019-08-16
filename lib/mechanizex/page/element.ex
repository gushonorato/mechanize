defmodule Mechanizex.Page.Element do
  alias Mechanizex.Page.Elementable
  alias Mechanizex.Queryable

  @derive [Queryable]
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

  def page(el), do: Elementable.page(el)
  def text(el), do: Elementable.text(el)

  def name(el) do
    el
    |> Elementable.name()
    |> normalize_value()
  end

  def attrs(el), do: Elementable.attrs(el)
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

  defp maybe_normalize_value(value, true) do
    normalize_value(value)
  end

  defp normalize_value(value) do
    value
    |> String.downcase()
    |> String.trim()
  end
end

defimpl Mechanizex.Page.Elementable, for: Mechanizex.Page.Element do
  def page(e), do: e.page
  def attrs(e), do: e.attrs
  def name(e), do: e.name
  def text(e), do: e.text
end

defimpl Mechanizex.HTMLParser.Parseable, for: Mechanizex.Page.Element do
  alias Mechanizex.HTMLParser.Parseable
  def parser(e), do: Parseable.parser(e.page)
  def parser_data(e), do: e.parser_data
  def page(e), do: e.page
end
