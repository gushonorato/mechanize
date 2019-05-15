defmodule Mechanizex.Page do
  alias Mechanizex.{Request, Response}
  alias Mechanizex.Page.Link
  defstruct request: nil, response: nil, mechanizex: nil, links: nil

  @type t :: %__MODULE__{
          request: Request.t(),
          response: Response.t(),
          mechanizex: pid()
        }

  def body(page) do
    page.response.body
  end

  def mechanizex(page) do
    page.mechanizex
  end

  def html_parser(page) do
    page
    |> mechanizex
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
