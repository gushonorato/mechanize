defmodule Mechanize.Page do

  alias Mechanize.{Request, Response, HTMLParser}
  defstruct request: nil, response: nil, mechanize: nil

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

  defdelegate find(page, selector), to: HTMLParser
end
