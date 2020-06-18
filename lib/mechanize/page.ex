defmodule Mechanize.Page do
  @moduledoc """
  The HTML Page.

  This module defines Mechanize.Page and the main functions for working with Pages.

  The Page is created as a result of a successful HTTP request.
  ```
  alias Mechanize.{Browser, Page}

  browser = Browser.new()
  page = Browser.get!(browser, "https://www.example.com")
  ```
  """
  alias Mechanize.{Response, Query, Form}
  alias Mechanize.Query.BadCriteriaError
  alias Mechanize.Page.{Link, Element}

  defstruct [:response_chain, :status_code, :content, :url, :browser, :parser]

  @type t :: %__MODULE__{
          response_chain: [Response.t()],
          status_code: integer(),
          content: String.t(),
          url: String.t(),
          browser: Browser.t(),
          parser: module()
        }

  @type fragment :: [Element.t()]

  defmodule ClickError do
    @moduledoc """
    Raised when an error occurs on a click action.
    """
    defexception [:message]
  end

  defmodule InvalidMetaRefreshError do
    @moduledoc """
    Raised when Mechanize can not parse the `content` attribute of a
    `<meta http-equiv="refresh" ...>` element inside the page content.
    """
    defexception [:message]
  end

  @doc """
  Returns the browser that fetched the `page`.
  """
  @spec get_browser(Page.t()) :: Browser.t()
  def get_browser(nil), do: raise(ArgumentError, "page is nil")
  def get_browser(%__MODULE__{} = page), do: page.browser

  @doc """
  Returns the `page` url.
  """
  @spec get_url(Page.t()) :: String.t()
  def get_url(nil), do: raise(ArgumentError, "page is nil")
  def get_url(%__MODULE__{} = page), do: page.url

  @doc """
  Returns the page content.
  """
  @spec get_content(Page.t()) :: String.t()
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
  @spec meta_refresh(Page.t()) :: {integer(), String.t()}
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
  @spec get_headers(Page.t()) :: Header.headers()
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
  @spec get_response(Page.t()) :: Response.t()
  def get_response(%__MODULE__{} = page), do: List.first(page.response_chain)

  @doc """
  Clicks on a link that matches `criteria`.

  Links are all elements defined by `a` and `area` html tags.

  If the request does not fail, a Page struct is returned, otherwise, it raises
  `Mechanize.HTTPAdapter.NetworkError`. In case of more than one link matches the criteria,
  Mechanize will click on the first matched link.

  Raises `Mechanize.Page.ClickError` if the matched link has no href attribute.

  Raises `Mechanize.Page.BadCriteriaError` if no link matches with given `criteria`.

  ## Examples

  Click on the first link with text equals to "Back":
  ```
    Page.click_link!(page, "Back")
  ```

  Click on the first link by its "href" attribute:
  ```
    Page.click_link!(page, href: "sun.html")
  ```

  You can also click on a link inside a list returned by a `Mechanize.Page.search/2`:
  ```
    page
    |> Page.search("area")
    |> Page.click_link!(alt: "Sun")
  ```

  Or even in a element child:
  ```
    page
    |> Page.search("map[name=planetmap]")
    |> Page.click_link!(alt: "Sun")
  ```
  """
  @dialyzer :no_return
  @spec click_link!(Page.t() | Page.fragment(), Query.t()) :: Page.t()
  def click_link!(page_or_fragment, criterias) do
    page_or_fragment
    |> link_with!(criterias)
    |> Link.click!()
  end

  @doc """
  Returns a list containing all links from `page` or an empty list if `page` has no links.
  """
  @spec links(Page.t()) :: [Link.t()]
  defdelegate links(page), to: __MODULE__, as: :links_with

  @doc """
  Return the first link matched by `criteria`.

  Nil is returned if no link was matched.

  See `Mechanize.Page.links_with/2` for more details about how to query links.
  """
  @spec link_with(Page.t() | Page.fragment(), Query.t()) :: Link.t() | nil
  def link_with(page, criteria \\ []) do
    page
    |> links_with(criteria)
    |> List.first()
  end

  @doc """
  Return the first link matched by `criteria`.

  Raise `Mechanize.Query.BadCriteriaError` if no link was matched.

  See `Mechanize.Page.links_with/2` for more details about how to query links.
  """
  @spec link_with!(Page.t() | Page.fragment(), Query.t()) :: Link.t() | nil
  def link_with!(page, criteria \\ []) do
    case link_with(page, criteria) do
      nil -> raise BadCriteriaError, "no link found with given criteria"
      link -> link
    end
  end

  @doc """
  Return all links matched by `criteria`.

  An empty list is returned if no link was matched.

  ## Examples

  Retrieving all links containing "Back" text of `page`:
  ```
  Page.links_with(page, "Back")
  ```

  Retrieving all links by attribute:
  ```
    Page.links_with(page, href: "sun.html")
  ```

  You can also use regular expressions:
  ```
    Page.links_with(page, href: ~r/sun/)
  ```

  It's possible to chain functions:
  ```
    page
    |> Page.search("map[name=planets]")
    |> Page.links_with("Sun")
  ```
  """
  @spec links_with(Page.t() | Page.fragment(), Query.t()) :: [Link.t()]
  def links_with(page, criteria \\ []) do
    page
    |> elements_with("a, area", criteria)
    |> Enum.map(&Link.new/1)
  end

  @doc """
  Return all links matched by `criteria`.

  Raise `Mechanize.Query.BadCriteriaError` if no link was matched.

  See `Mechanize.Page.links_with/2` for more details about how to query links.
  """
  @spec links_with!(Page.t() | Page.fragment(), Query.t()) :: [Link.t()]
  def links_with!(page, criteria \\ []) do
    case links_with(page, criteria) do
      [] -> raise BadCriteriaError, "no link found with given criteria"
      link -> link
    end
  end

  def form(page) do
    page
    |> forms()
    |> List.first()
  end

  defdelegate forms(page), to: __MODULE__, as: :forms_with

  def form_with(page, criteria \\ []) do
    page
    |> forms_with(criteria)
    |> List.first()
  end

  def forms_with(page, criteria \\ []) do
    page
    |> elements_with("form", criteria)
    |> Enum.map(&Form.new(page, &1))
  end

  defdelegate search(page, selector), to: Query
  defdelegate filter_out(page, selector), to: Query
  defdelegate elements_with(page, selector, criteria \\ []), to: Query
end
