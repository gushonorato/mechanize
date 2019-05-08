defmodule Mechanize.HTMLParser do
  use Introspection
  alias Mechanize.Page

  defmacro __using__(_) do
    quote do
      @behaviour Mechanize.HTMLParser
    end
  end

  @callback find(Page.t(), String.t()) :: list()

  @spec find(Page.t(), String.t()) :: list()
  def find(page, selector) do
    parser(page).find(page,selector)
  end

  @spec parser(Page.t()) :: term()
  def parser(page) do
    page
    |> Page.mechanize
    |> Mechanize.get_option(:parser)
    |> submodule("_parser")
  end
end
