defmodule Mechanize.Page.Element do
  @moduledoc """
  The HMTL element.

  This module provides functions to manipulate and extract information from HMTL element nodes.

  ## Public fields

    * `name` - name of the HTML tag.
    * `attrs` - List of the element attributes.
    * `text` - Inner text of the element.
    * `page` - page where this element was extracted.

  ## Private fields
    Fields reserved for interal use of the library and it is not recommended to access it directly.

    * `parser_node` - internal data used by the parser.
    * `parser` - parser used to parse this element.

  """
  alias Mechanize.Page.Elementable

  defstruct [:name, :attrs, :parser_node, :text, :parser, :page]

  @type attributes :: [{String.t(), String.t()}]
  @typedoc """
  The HTML Element struct.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          attrs: attributes(),
          parser_node: Mechanize.HTMLParser.parser_node(),
          text: String.t(),
          parser: module(),
          page: Page.t()
        }

  @doc """
  Returns the page where this element was extracted.

  Element may be any struct implementing `Mechanize.Page.Elementable` protocol.
  """
  @spec get_page(any()) :: Page.t()
  def get_page(elementable), do: Elementable.element(elementable).page

  @doc """
  Returns the inner text from the HTML element.

  Text from elements without inner text are extracted as empty strings by the parser. It means that
  this function will return an empty string in case of the element does not have inner text.

  Element may be any struct implementing `Mechanize.Page.Elementable` protocol.
  """
  @spec text(any()) :: String.t()
  def text(elementable), do: Elementable.element(elementable).text

  @doc """
  Returns the HTML tag name of the element.

  For instance, it will return "a" and "area" for hyperlinks, "img" for images, etc.

  Element may be any struct implementing `Mechanize.Page.Elementable` protocol.

  ## Example

  ```
  iex> Element.name(image)
  "img"
  ```
  """
  @spec name(any) :: String.t()
  def name(elementable) do
    elementable
    |> Elementable.element()
    |> Map.get(:name)
    |> normalize_value()
  end

  @doc """
  Returns a list containing all attributes from a HMTL element and its values.

  In case element doest have any attributes, an empty list is returned.

  Element may be any struct implementing `Mechanize.Page.Elementable` protocol.

  ## Example
  ```
  iex> Element.attrs(element)
  [{"href", "/home"}, {"rel", "nofollow"}]
  ```
  """
  @spec attrs(any) :: attributes()
  def attrs(el), do: Elementable.element(el).attrs

  @doc """
  Returns true if attribute is present, otherwise false.

  Element may be any struct implementing `Mechanize.Page.Elementable` protocol.

  ## Example
  ```
  iex> Element.attr_present?(checkbox, :selected)
  true
  ```
  """
  @spec attr_present?(any, atom()) :: boolean()
  def attr_present?(element, attr_name), do: attr(element, attr_name) != nil

  @doc """
  Returns attribute value of a given element.

  This functions accepts opts:

  * `default` - Returns a default value in case of an attribute is not present. Default: `nil`.
  * `normalize` - Returns the value of the attribute downcased and without dangling spaces.

  ## Examples

  ```
  iex> Element.attr(element, :href)
  "/home"
  ```
  """
  @spec attr(any, atom) :: any
  def attr(element, attr_name, opts \\ []) do
    opts =
      [default: nil, normalize: false]
      |> Keyword.merge(opts)

    element
    |> attrs()
    |> List.keyfind(Atom.to_string(attr_name), 0, {nil, opts[:default]})
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
