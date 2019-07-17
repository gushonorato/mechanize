defmodule Mechanizex.HTTPAdapter.Httpoison do
  @behaviour Mechanizex.HTTPAdapter
  alias Mechanizex.{Request, Response, Page, Agent}

  @impl Mechanizex.HTTPAdapter
  @spec request!(pid(), Request.t()) :: Page.t()
  def request!(mech, req) do
    req.method
    |> HTTPoison.request!(req.url, req.body, req.headers)
    |> create_mechanizex_page(req, mech)
  end

  @spec create_mechanizex_page(HTTPoison.Response.t(), Request.t(), Mechanizex.t()) :: Page.t()
  defp create_mechanizex_page(res, req, agent) do
    %Page{
      response: %Response{
        body: res.body,
        headers: res.headers,
        code: res.status_code,
        url: req.url
      },
      request: req,
      agent: agent,
      parser: Agent.html_parser(agent)
    }
  end
end
