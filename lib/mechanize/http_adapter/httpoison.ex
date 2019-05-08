defmodule Mechanize.HTTPAdapter.Httpoison do
  use Mechanize.HTTPAdapter
  alias Mechanize.{Request, Response, Page}

  @impl Mechanize.HTTPAdapter

  @spec request!(pid(), Request.t()) :: Page.t()
  def request!(mech, req) do
    HTTPoison.request!(req.method, req.url, req.body, req.headers)
    |> create_mechanize_page(req, mech)
  end

  @spec create_mechanize_page(HTTPoison.Response.t(), Request.t(), Mechanize.t()) :: Page.t()
  defp create_mechanize_page(res, req, mech) do
    %Page{
      response: %Response{
        body: res.body,
        headers: res.headers,
        status_code: res.status_code
      },
      request: req,
      mechanize: mech
    }
  end
end
