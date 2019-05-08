defmodule Mechanize.HTTPAdapter.Httpoison do
  use Mechanize.HTTPAdapter

  @impl Mechanize.HTTPAdapter
  @spec request!(any(), Mechanize.Request.t()) :: Mechanize.Response.t()
  def request!(mech, req) do
    HTTPoison.request!(req.method, req.url, req.body, req.headers)
    |> create_mechanize_page(req, mech)
  end

  defp create_mechanize_page(res, req, mech) do
    %Mechanize.Page{
      response: %Mechanize.Response{
        body: res.body,
        headers: res.headers,
        status_code: res.status_code
      },
      request: req,
      body: res.body,
      mechanize: mech
    }
  end
end
