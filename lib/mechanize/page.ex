defmodule Mechanize.Page do

  alias Mechanize.{Request, Response, HTMLParser}
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

  def links(page) do
    find(page, "a area")
    |> Enum.map(&Link.create/1)
  end

  defdelegate find(page, selector), to: HTMLParser
end
