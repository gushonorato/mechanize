defmodule Mechanizex.HTTPAdapter.Httpoison do
  use Mechanizex.HTTPAdapter
  alias Mechanizex.{Request, Response, Page}

  @impl Mechanizex.HTTPAdapter
  @spec request!(pid(), Request.t()) :: Page.t()
  def request!(mech, req) do
    req.method
    |> HTTPoison.request!(req.url, req.body, req.headers)
    |> create_mechanizex_page(req, mech)
  end

  @spec create_mechanizex_page(HTTPoison.Response.t(), Request.t(), Mechanizex.t()) :: Page.t()
  defp create_mechanizex_page(res, req, mech) do
    %Page{
      response: %Response{
        body: res.body,
        headers: res.headers,
        status_code: res.status_code
      },
      request: req,
      mechanizex: mech
    }
  end
end
