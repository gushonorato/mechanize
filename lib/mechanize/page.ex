defmodule Mechanize.Page do
  alias Mechanize.{Response, Query, Form}
  alias Mechanize.Page.{Link, Element}

  defstruct response_chain: nil, status_code: nil, content: nil, url: nil, browser: nil, parser: nil

  @type t :: %__MODULE__{
          response_chain: [Response.t()],
          status_code: integer(),
          content: String.t(),
          url: String.t(),
          browser: pid(),
          parser: module()
        }

  defmodule ClickError do
    defexception [:message]
  end

  defmodule InvalidMetaRefreshError do
    defexception [:message]
  end

  def browser(page), do: page.browser
  def url(page), do: page.url
  def content(page), do: page.content

  def meta_refresh(nil), do: raise(ArgumentError, "page is nil")

  def meta_refresh(page) do
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

  def headers(page) do
    page
    |> last_response()
    |> Response.headers()
  end

  def last_response(page), do: List.first(page.response_chain)

  def click_link(page, criterias) when is_list(criterias) do
    page
    |> link_with(criterias)
    |> Link.click()
  end

  def click_link(page, text) when is_binary(text) do
    page
    |> link_with(text: text)
    |> Link.click()
  end

  defdelegate links(page), to: __MODULE__, as: :links_with

  def link_with(page, criteria \\ []) do
    page
    |> links_with(criteria)
    |> List.first()
  end

  def links_with(page, criteria \\ []) do
    page
    |> elements_with("a, area", criteria)
    |> Enum.map(&Link.new/1)
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
  defdelegate filter(page, selector), to: Query
  defdelegate elements_with(page, selector, criteria \\ []), to: Query, as: :search_matches
end

defimpl Mechanize.HTMLParser.Parseable, for: Mechanize.Page do
  def parser(page), do: page.parser
  def parser_data(page), do: page.content
  def page(page), do: page
end
