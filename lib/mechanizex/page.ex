defmodule Mechanizex.Page do
  alias Mechanizex.{Response, Query, Form}
  alias Mechanizex.Page.Link

  defstruct response_chain: nil, status_code: nil, body: nil, url: nil, browser: nil, parser: nil

  @type t :: %__MODULE__{
          response_chain: [Response.t()],
          status_code: integer(),
          body: String.t(),
          url: String.t(),
          browser: pid(),
          parser: module()
        }

  defmodule ClickError do
    defexception [:message]
  end

  def browser(page), do: page.browser
  def url(page), do: page.url
  def body(page), do: page.body

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

defimpl Mechanizex.HTMLParser.Parseable, for: Mechanizex.Page do
  def parser(page), do: page.parser
  def parser_data(page), do: page.body
  def page(page), do: page
end
