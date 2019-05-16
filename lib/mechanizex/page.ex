defmodule Mechanizex.Page do
  alias Mechanizex.{Request, Response}
  alias Mechanizex.Page.Link
  defstruct request: nil, response: nil, agent: nil, links: nil

  @type t :: %__MODULE__{
          request: Request.t(),
          response: Response.t(),
          agent: pid()
        }

  def body(page) do
    page.response.body
  end

  def agent(page) do
    page.agent
  end

  def html_parser(page) do
    page
    |> agent
    |> Mechanizex.html_parser()
  end

  def links(page) do
    page
    |> find("a")
    |> Enum.into(find(page, "area"))
    |> Enum.map(&Link.create/1)
  end

  defp delegate_parser(method, params) do
    params
    |> List.first()
    |> html_parser
    |> apply(method, params)
  end

  def find(page, selector), do: delegate_parser(:find, [page, selector])
end
