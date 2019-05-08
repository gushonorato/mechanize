defmodule FlokiParser do
  use Mechanize.HTMLParser
  alias Mechanize.Page

  @spec find(Page.t(), String.t()) :: [any()]
  def find(page, selector) do
    page
    |> Page.body
    |> Floki.find(selector)
  end
end
