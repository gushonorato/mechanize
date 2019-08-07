defmodule Mechanizex.Page do
  alias Mechanizex.{Request, Response, Query, Form}
  alias Mechanizex.Page.{Link, Element}
  import Mechanizex.Query

  @enforce_keys [:request, :response, :agent]
  defstruct request: nil, response: nil, agent: nil, parser: nil

  @type t :: %__MODULE__{
          request: Request.t(),
          response: Response.t(),
          agent: pid(),
          parser: module()
        }

  def response_code(page), do: page.response.code
  def body(page), do: page.response.body
  def agent(page), do: page.agent

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

  defdelegate links(page, criterias), to: __MODULE__, as: :links_with

  def links_with(page, criterias \\ [])

  def links_with(page, criterias) do
    page
    |> search("a, area")
    |> Enum.filter(query(criterias))
    |> Element.to_links()
  end

  def link_with(page, criterias \\ [])

  def link_with(page, criterias) do
    page
    |> links_with(criterias)
    |> List.first()
  end

  def url(page) do
    page.response.url
  end

  defdelegate form(page), to: __MODULE__, as: :form_with

  def form_with(page, criterias \\ [])

  def form_with(page, criterias) do
    page
    |> Query.search("form")
    |> Enum.filter(query(criterias))
    |> List.first()
    |> Form.new()
  end
end

defimpl Mechanizex.HTMLParser.Parseable, for: Mechanizex.Page do
  def parser(page), do: page.parser
  def parser_data(page), do: page.response.body
  def page(page), do: page
end
