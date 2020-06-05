defmodule Mechanize.Page.Element do
  alias Mechanize.Page.Elementable

  defstruct name: nil,
            attrs: nil,
            parser_data: nil,
            text: nil,
            parser: nil,
            page: nil

  @type t :: %__MODULE__{
          name: atom(),
          attrs: list(),
          parser_data: list(),
          text: String.t(),
          parser: module(),
          page: Page.t()
        }

  def page(el), do: Elementable.element(el).page
  def text(el), do: Elementable.element(el).text

  def name(el) do
    el
    |> Elementable.element()
    |> Map.get(:name)
    |> normalize_value()
  end

  def attrs(el), do: Elementable.element(el).attrs
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

defimpl Mechanize.Page.Elementable, for: Mechanize.Page.Element do
  def element(e), do: e
end
