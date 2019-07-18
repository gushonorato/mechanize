defmodule Mechanizex.HTTPAdapter.Httpoison do
  @behaviour Mechanizex.HTTPAdapter
  alias Mechanizex.{Request, Response, Page, Agent}
  alias Mechanizex.Agent.ConnectionError

  @impl Mechanizex.HTTPAdapter
  @spec request(pid(), Request.t()) :: {atom(), Page.t() | ConnectionError.t()}
  def request(agent, req) do
    case HTTPoison.request(req.method, req.url, req.body, req.headers) do
      {:ok, res} ->
        {:ok,
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
         }}

      {:error, error} ->
        {:error, %ConnectionError{error: error}}
    end
  end
end
