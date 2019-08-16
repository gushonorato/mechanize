defmodule Mechanizex.Page do
  alias Mechanizex.{Request, Response, Query, Form}
  alias Mechanizex.Page.Link

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

  defdelegate links(page), to: __MODULE__, as: :links_with

  def link_with(page, criteria \\ []) do
    page
    |> links_with(criteria)
    |> List.first()
  end

  def links_with(page, criteria \\ []), do: elements_with(page, "a, area", criteria, &Link.new/1)

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

  def forms_with(page, criteria \\ []), do: elements_with(page, "form", criteria, &Form.new/1)

  def elements_with(page, selector, criteria \\ [], construct_fun \\ fn x -> x end)

  def elements_with(page, selector, criteria, construct_fun) do
    page
    |> Query.search(selector)
    |> Enum.filter(&Query.match?(&1, criteria))
    |> Enum.map(construct_fun)
  end

  def url(page) do
    page.response.url
  end
end

defimpl Mechanizex.HTMLParser.Parseable, for: Mechanizex.Page do
  def parser(page), do: page.parser
  def parser_data(page), do: page.response.body
  def page(page), do: page
end
