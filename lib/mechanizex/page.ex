defmodule Mechanizex.Page do
  alias Mechanizex.{Request, Response, Query, Form}
  alias Mechanizex.Page.{Link, Element}

  @enforce_keys [:request, :response, :agent]
  defstruct request: nil, response: nil, agent: nil, parser: nil

  @type t :: %__MODULE__{
          request: Request.t(),
          response: Response.t(),
          agent: pid(),
          parser: module()
        }

  def body(page) do
    page.response.body
  end

  def agent(page) do
    page.agent
  end

  def click_link(page, criterias) when is_list(criterias) do
    page
    |> with_link(criterias)
    |> Link.click()
  end

  def click_link(page, text) when is_binary(text) do
    page
    |> with_link(text: text)
    |> Link.click()
  end

  defdelegate links(page), to: __MODULE__, as: :with_links

  def with_links(page, criterias \\ []) do
    page
    |> Query.search("a, area")
    |> Query.select(:all, criterias)
    |> Element.to_links()
  end

  def with_link(page, criterias \\ []) do
    page
    |> with_links(criterias)
    |> List.first()
  end

  def url(page) do
    page.response.url
  end

  def with_form(page, criterias \\ [])

  def with_form(page, criterias) do
    page
    |> Query.search("form")
    |> Query.select(:all, criterias)
    |> List.first()
    |> Form.new()
  end
end

defimpl Mechanizex.HTMLParser.Parseable, for: Mechanizex.Page do
  def parser(page), do: page.parser
  def parser_data(page), do: page.response.body
  def page(page), do: page
end
