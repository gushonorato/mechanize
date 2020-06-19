defmodule Mechanize.Query do
  @moduledoc """
  Provides an easy support for querying elements in many Mechanize modules.

  This module is not primarily designed to be used by cliente code, instead you should use
  indirectly throught `Mechanize.Page.search/2` and `Mechanize.Page.filter_out/2`. Many other
  functions that accept `Mechanize.Query.t()` criterias also uses this module under the hood.
  Therefore it's important to understand how this module works to unlock all capabilities in
  functions that uses `Mechanize.Query.t()` as criteria.

  ## Examples

  For example, `Mechanize.Page.click_link!/2` is one function of Mechanize API which accepts a
  query as second parameter. You can click in a link based on it's attributes:

  ```
  alias Mechanize.Page

  Page.click_link!(page, href: "/home/about")
  ```

  When you call `Mechanize.Page.click_link!/2`, another call to `Mechanize.Query.elements_with/3` is
  made under the hood to fetch all links with given `[href: "/home/about"]` criteria and then
  Mechanize "clicks" on the first link.

  You can also query elements by its inner text, which is the visible text in case of text links:
  ```
  Page.click_link!(page, text: "About")
  ```

  Or you can use a shorter approach for doing the same:
  ```
  Page.click_link!(page, "About")
  ```

  Query powered functions also accepts regular expressions:
  ```
  Page.click_link!(page, href: ~r/about/)
  ```

  You can combine different types of criterias at once. The following example returns a list of
  links by its href, title attributes and inner text.
  ```
  Page.links_with(page, href: "/home/about", title: "About page", text: "About page")
  ```

  Use boolean criterias to query if an element attribute exists. In example below, we fetch all
  checked and unchecked checkboxes from a given form:
  ```
  alias Mechanize.Form

  Form.checkboxes_with(form, checked: true) # => checkboxes with checked attribute present
  Form.checkboxes_with(form, checked: false) # => checkboxes with checked attribute not present
  ```

  In case of elements that have a logical order, which is the case of select element in a html form,
  you can query it by its index. Note that this index is a zero-based index. In the example below,
  we select the first option from a select list with attribute `name="selectlist1"`:
  ```
  Form.select(form, name: "selectlist1", option: 0)
  ```

  Finally, you can also query elements with different attribute values. In the example below,
  Mechanize "clicks" on the first link found with href equals to "/company" or "/about":
  ```
  Page.click_link!(page, href: ["/company", "/about"])
  ```

  ## Page fragments
  Many queries can work both on `Mechanize.Page` or in page fragments. A page fragment is nothing
  but a list of data which its type implements `Mechanize.Page.Elementable` protocol.

  For example, the function `Mechanize.Page.search/2`, which is also powered by this module,
  returns a page fragment. This mechanism enable client code to chain queries like in the example:

  ```
    page
    |> Page.search(".planetmap")
    |> Page.click_link!("Sun")
  ```

  When you chain functions like that, `Mechanize.Page.click_link!/2` will only work on page fragment
  returned by `Mechanize.Page.search/2` function. That means Mechanize will click on a link with
  attribute `alt="Sun"` only if its child of a `.planetmap`, ignoring all others that are
  not child.

  But there's another use case. You can also click on a link if the link is the page fragment
  itself, like in example below:
  ```
    page
    |> Page.search(".planetmap a")
    |> Page.click_link!("Sun")
  ```
  """
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Page

  defmodule BadCriteriaError do
    @moduledoc """
    Raises when an error occurs when searching an element using a criteria.
    """
    defexception [:message]
  end

  @type t :: keyword() | integer() | String.t()

  @doc """
  See `Mechanize.Page.search/2`.
  """
  def search(nil, _selector), do: raise(ArgumentError, "page_or_fragment is nil")
  def search(_page_or_fragment, nil), do: raise(ArgumentError, "selector is nil")

  def search(%Page{} = page, selector), do: page.parser.search(page, selector)

  def search(fragment, selector) when is_list(fragment) do
    fragment
    |> Enum.map(&Elementable.element/1)
    |> Enum.flat_map(fn el -> el.parser.search(el, selector) end)
  end

  def search(fragment, selector) do
    search([fragment], selector)
  end

  @doc """
  See `Mechanize.Page.filter_out/2`.
  """
  def filter_out(nil, _selector), do: raise(ArgumentError, "page_or_fragment is nil")
  def filter_out(_page_or_fragment, nil), do: raise(ArgumentError, "selector is nil")

  def filter_out(%Page{} = page, selector), do: page.parser.filter_out(page, selector)

  def filter_out(fragments, selector) when is_list(fragments) do
    fragments
    |> Enum.map(&Elementable.element/1)
    |> Enum.flat_map(fn el -> el.parser.filter_out(el, selector) end)
  end

  def filter_out(fragment, selector), do: filter_out([fragment], selector)

  @doc """
  See `Mechanize.Page.elements_with/3`.
  """
  def elements_with(page_or_elements, selector, criteria \\ []) do
    page_or_elements
    |> search(selector)
    |> Enum.filter(&match_criteria?(&1, criteria))
  end

  @doc false
  def match?(nil, _types, _criteria) do
    raise ArgumentError, "element is nil"
  end

  def match?(_element, nil, _criteria) do
    raise ArgumentError, "types is nil"
  end

  def match?(_element, _types, nil) do
    raise ArgumentError, "criteria is nil"
  end

  def match?(element, types, criteria) do
    match_type?(element, types) and match_criteria?(element, criteria)
  end

  @doc false
  def match_type?(element, types) when is_list(types) do
    element.__struct__ in types
  end

  def match_type?(element, type) do
    match_type?(element, [type])
  end

  @doc false
  def match_criteria?(nil, _criteria), do: raise(ArgumentError, "element is nil")
  def match_criteria?(_element, nil), do: raise(ArgumentError, "criteria is nil")

  def match_criteria?(_element, []), do: true

  def match_criteria?(element, text) when is_binary(text) do
    match_criteria?(element, [{:text, text}])
  end

  def match_criteria?(element, index) when is_integer(index) do
    case Map.get(element, :index) do
      ^index ->
        true

      _ ->
        false
    end
  end

  def match_criteria?(element, [attributes | criterias]) do
    match_attribute?(element, attributes) and match_criteria?(element, criterias)
  end

  defp match_attribute?(_element, {:text, nil}) do
    raise ArgumentError, "criteria :text is nil"
  end

  defp match_attribute?(element, {:text, value}) when is_list(value) do
    Element.text(element) in value
  end

  defp match_attribute?(element, {:text, value}) when is_binary(value) do
    Element.text(element) == value
  end

  defp match_attribute?(element, {:text, value}) do
    Element.text(element) =~ value
  end

  defp match_attribute?(_element, {attr_name, nil}) do
    raise ArgumentError, "criteria :#{attr_name} is nil"
  end

  defp match_attribute?(element, {attr_name, value}) when is_list(value) do
    Element.attr(element, attr_name) in value
  end

  defp match_attribute?(element, {attr_name, boolean}) when is_boolean(boolean) do
    Element.attr_present?(element, attr_name) == boolean
  end

  defp match_attribute?(element, {attr_name, value}) when is_binary(value) do
    Element.attr(element, attr_name) == value
  end

  defp match_attribute?(element, {attr_name, value}) do
    case Element.attr(element, attr_name) do
      nil -> false
      attr_value -> attr_value =~ value
    end
  end
end
