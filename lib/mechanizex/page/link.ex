defmodule Mechanizex.Page.Link do
  alias Mechanizex.Page.Element
  alias Mechanizex.Page

  def click(%Element{attrs: %{href: url}, page: page}) do
    page
    |> Page.agent()
    |> Mechanizex.Agent.get!(URI.merge(page.response.url, url))
  end
end
