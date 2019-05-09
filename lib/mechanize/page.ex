defmodule Mechanize.Page do
  alias Mechanize.{Request, Response}
  alias Mechanize.Page.Link
  defstruct request: nil, response: nil, mechanize: nil, links: nil

  @type t :: %__MODULE__{
          request: Request.t(),
          response: Response.t(),
          mechanize: pid()
        }

  def body(page) do
    page.response.body
  end

  def mechanize(page) do
    page.mechanize
  end

  def html_parser(page) do
    page
    |> mechanize
    |> Mechanize.html_parser()
  end

  def links(page) do
    find(page, "a")
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
