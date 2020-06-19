defmodule Mechanize.Page do
  @moduledoc """
  The HTML Page.

  This module defines `Mechanize.Page` and the main functions for working with Pages.

  The Page is created as a result of a successful HTTP request.
  ```
  alias Mechanize.{Browser, Page}

  browser = Browser.new()
  page = Browser.get!(browser, "https://www.example.com")
  ```
  """
  alias Mechanize.{Response, Query, Form}
  alias Mechanize.Query.BadQueryError
  alias Mechanize.Page.{Link, Element}

  defstruct [:response_chain, :status_code, :content, :url, :browser, :parser]

  @typedoc """
  The HTML Page struct.
  """
  @type t :: %__MODULE__{
          response_chain: [Response.t()],
          status_code: integer(),
          content: String.t(),
          url: String.t(),
          browser: Browser.t(),
          parser: module()
        }

  @typedoc """
  A fragment of a page. It is an array of `Mechanize.Page.Element` struct in most of the cases,
  but it could be any struct that implements `Mechanize.Page.Elementable` protocol.
  """
  @type fragment :: [any]

  defmodule ClickError do
    @moduledoc """
    Raised when an error occurs on a click action.
    """
    defexception [:message]
  end

  defmodule InvalidMetaRefreshError do
    @moduledoc """
    Raised when Mechanize cannot parse the `content` attribute of a
    `<meta http-equiv="refresh" ...>` element inside the page content.
    """
    defexception [:message]
  end

  @doc """
  Returns the browser that fetched the `page`.
  """
  @spec get_browser(t()) :: Browser.t()
  def get_browser(nil), do: raise(ArgumentError, "page is nil")
  def get_browser(%__MODULE__{} = page), do: page.browser

  @doc """
  Returns the `page` url.
  """
  @spec get_url(t()) :: String.t()
  def get_url(nil), do: raise(ArgumentError, "page is nil")
  def get_url(%__MODULE__{} = page), do: page.url

  @doc """
  Returns the page content.
  """
  @spec get_content(t()) :: String.t()
  def get_content(%__MODULE__{} = page), do: page.content

  @doc """
  Extracts meta-refresh data from a `page`.

  A two element tuple with a integer representing the delay in the first position and
  the a string representing the URL in the second position will be returned if a
  `<meta http-equiv="refresh" ...>` is found, otherwise `nil` will be returned.

  Raises `Mechanize.Page.InvalidMetaRefreshError` if Mechanize cannot parse the `content` attribute
  of the meta-refresh.

  ## Example
  ```
  # <meta http-equiv="refresh" content="10; url=https://www.example.com">
  {delay, url} = Page.meta_refresh(page)

  delay # => 10
  url # => https://www.example.com
  ```
  """
  @spec meta_refresh(t()) :: {integer(), String.t()}
  def meta_refresh(nil), do: raise(ArgumentError, "page is nil")

  def meta_refresh(%__MODULE__{} = page) do
    page
    |> search("meta[http-equiv=refresh]")
    |> List.first()
    |> case do
      nil ->
        nil

      meta ->
        meta
        |> Element.attr(:content)
        |> parse_meta_refresh_content(page)
    end
  end

  defp parse_meta_refresh_content(content, page) do
    content =
      content
      |> String.split(";")
      |> Enum.map(&String.trim/1)
      |> Enum.join(";")

    case Regex.scan(~r/^(\d+)(?:;url\s*=\s*(.*))?$/, content) do
      [[_, delay, url]] -> {String.to_integer(delay), url}
      [[_, delay]] -> {String.to_integer(delay), nil}
      _ -> raise InvalidMetaRefreshError, "can't parse meta-refresh content of #{page.url}"
    end
  end

  @doc """
  Returns the response headers of a `page`.

  In case of Mechanize Browser has followed one or more redirects when `page` was fetched,
  the headers returned corresponds to the headers of the last response.
  """
  @spec get_headers(t()) :: Header.headers()
  def get_headers(%__MODULE__{} = page) do
    page
    |> get_response()
    |> Response.headers()
  end

  @doc """
  Return the response of a `page`.

  In case of Mechanize Browser has followed one or more redirects when `page` was fetched,
  the response returned correspond to the last respose.
  """
  @spec get_response(t()) :: Response.t()
  def get_response(%__MODULE__{} = page), do: List.first(page.response_chain)

  @doc """
  Clicks on a link that matches `query`.

  Links are all elements defined by `a` and `area` html tags.

  If the request does not fail, a Page struct is returned, otherwise, it raises
  `Mechanize.HTTPAdapter.NetworkError`. In case of more than one link matches the query,
  Mechanize will click on the first matched link.

  Raises `Mechanize.Page.ClickError` if the matched link has no href attribute.

  Raises `Mechanize.Page.BadQueryError` if no link matches with given `query`.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.
  ## Examples

  Click on the first link with text equals to "Back":
  ```
    Page.click_link!(page, "Back")
  ```

  Click on the first link by its "href" attribute:
  ```
    Page.click_link!(page, href: "sun.html")
  ```
  """
  @dialyzer :no_return
  @spec click_link!(t() | fragment(), Query.t()) :: t()
  def click_link!(page_or_fragment, query) do
    page_or_fragment
    |> link_with!(query)
    |> Link.click!()
  end

  @doc """
  Returns a list containing all links from a page or fragment of a page, or an empty list in
  case it has no links.
  """
  @spec links(t() | fragment()) :: [Link.t()]
  defdelegate links(page_or_fragment), to: __MODULE__, as: :links_with

  @doc """
  Return the first link matched by `query`.

  Nil is returned if no link was matched.

  See `Mechanize.Page.links_with/2` for more details about how to query links.
  """
  @spec link_with(t() | fragment(), Query.t()) :: Link.t() | nil
  def link_with(page_or_fragment, query \\ []) do
    page_or_fragment
    |> links_with(query)
    |> List.first()
  end

  @doc """
  Return the first link matched by `query`.

  Raise `Mechanize.Query.BadQueryError` if no link was matched.

  See `Mechanize.Page.links_with/2` for more details about how to query links.
  """
  @spec link_with!(t() | fragment(), Query.t()) :: Link.t() | nil
  def link_with!(page_or_fragment, query \\ []) do
    case link_with(page_or_fragment, query) do
      nil -> raise BadQueryError, "no link found with given query"
      link -> link
    end
  end

  @doc """
  Return all links matched by `query`.

  An empty list is returned if no link was matched.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Examples
  Retrieving all links containing "Back" text of `page`:
  ```
  Page.links_with(page, "Back")
  ```

  Retrieving all links by attribute:
  ```
    Page.links_with(page, href: "sun.html")
  ```
  """
  @spec links_with(t() | fragment(), Query.t()) :: [Link.t()]
  def links_with(page_or_fragment, query \\ []) do
    page_or_fragment
    |> elements_with("a, area", query)
    |> Enum.map(&Link.new/1)
  end

  @doc """
  Return all links matched by `query`.

  Raise `Mechanize.Query.BadQueryError` if no link was matched.

  See `Mechanize.Page.links_with/2` for more details about how to query links.
  """
  @spec links_with!(t() | fragment(), Query.t()) :: [Link.t()]
  def links_with!(page_or_fragment, query \\ []) do
    case links_with(page_or_fragment, query) do
      [] -> raise BadQueryError, "no link found with given query"
      link -> link
    end
  end

  @doc """
  Returns the first form in a given page or fragment or nil in case of the given page or fragment
  does not have a form.
  """
  @spec form(t() | fragment()) :: Form.t() | nil
  def form(page_or_fragment) do
    page_or_fragment
    |> forms()
    |> List.first()
  end

  @doc """
  Returns a list containing all forms of a given page or fragment.

  In case of a page or fragment does not have a form, returns a empty list.
  """
  @spec forms(t() | fragment()) :: [Form.t()]
  defdelegate forms(page_or_fragment), to: __MODULE__, as: :forms_with

  @doc """
  Returns the first form that matches the `query` for the given page or fragment.

  In case of no form matches, returns nil instead.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Examples
  Fetch the first form which name is equal to "login".
  ```
  %Form{} = Page.form_with(page, name: "login")
  ```
  """
  @spec form_with(t() | fragment(), Query.t()) :: Form.t() | nil
  def form_with(page_or_fragment, query \\ []) do
    page_or_fragment
    |> forms_with(query)
    |> List.first()
  end

  @doc """
  Returns a list containing all forms matching `query` for the given page or fragment.

  In case of no form matches, returns an empty list instead.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Examples
  Fetch all forms which name is equal to "login".
  ```
  list = Page.forms_with(page, name: "login")
  ```
  """
  @spec forms_with(t() | fragment(), Query.t()) :: [Form.t()]
  def forms_with(page_or_fragment, query \\ []) do
    page_or_fragment
    |> elements_with("form", query)
    |> Enum.map(&Form.new(page_or_fragment, &1))
  end

  @doc """
  Search for elements on a given page or fragment using a CSS selector.

  A list of `Mechanize.Page.Element` matching the selector will be return. In case of no element
  matches the selector, an empty list will be returned instead.


  See also `Mechanize.Page.elements_with/3`.
  ## Example

  Printing in console todos of a todo html unordered list:
  ```
  page
  |> Page.search("ul.todo > li")
  |> Enum.map(&Element.text/1)
  |> Enum.each(&IO.puts/1)
  ```
  """
  @spec search(t() | fragment(), String.t()) :: [Element.t()]
  defdelegate search(page, selector), to: Query

  @doc """
  Returns all elements not matching the selector.

  A list of `Mechanize.Page.Element` matching the selector will be return. In case of all elements
  match the selector, and empty list will be returned instead.

  ## Example

  Removing a unordered list with "todo" class from the content of a page.

  ```
  Page.filter_out(page, "ul.todo > li")
  ```
  """
  @spec filter_out(t() | fragment(), String.t()) :: [Element.t()]
  defdelegate filter_out(page, selector), to: Query

  @doc """
  Search for elements on a given page or fragment both using a CSS selector and queries.

  This function is similar to `Mechanize.Page.search/2`, but you can also use the power of
  queries combined. First, the function will match the page or the fragments against the
  CSS selector, after it will perform a match of the remaining elements to the query. A list of
  `Mechanize.Page.Element` will be return. In case of no element both matches the selector and
  the query, an empty list will be returned instead.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example
  Printing in console todos of a todo html unordered list starting with "A":
  ```
  page
  |> Page.elements_with("ul.todo > li", text: ~r/^A/i)
  |> Enum.map(&Element.text/1)
  |> Enum.each(&IO.puts/1)
  ```
  """
  @spec elements_with(t() | fragment(), String.t(), Query.t()) :: [Element.t()]
  defdelegate elements_with(page_or_fragment, selector, query \\ []), to: Query
end
