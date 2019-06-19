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

  def body(page) do
    page.response.body
  end

  def agent(page) do
    page.agent
  end

  def click_link(page, criterias) when is_list(criterias) do
    page
    |> with_links(criterias)
    |> List.first()
    |> Link.click()
  end

  def click_link(page, text) when is_binary(text) do
    page
    |> with_links(text: text)
    |> List.first()
    |> Link.click()
  end

  defdelegate links(page), to: __MODULE__, as: :with_links

  def with_links(page, criterias \\ []), do: Query.with_elements(page, [:a, :area], criterias)
  def with_form(page, criterias \\ [])

  def with_form(page, criterias) do
    page
    |> Query.with_elements([:form], criterias)
    |> List.first()
    |> Form.new()
  end

  defimpl Mechanizex.Queryable, for: Mechanizex.Page do
    alias Mechanizex.{Page, Agent}

    def data(page), do: Page.body(page)
    def parser(page), do: page |> Page.agent() |> Agent.html_parser()
    def tag_name(_), do: raise(ArgumentError, "%Page{} struct does not have a tag name.")
  end
end
