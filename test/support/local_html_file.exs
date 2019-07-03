defmodule Mechanizex.HTTPAdapter.LocalHtmlFile do
  use Mechanizex.HTTPAdapter
  alias Mechanizex.{Request, Response, Page, Agent}

  @impl Mechanizex.HTTPAdapter
  @spec request!(pid(), Request.t()) :: Page.t()
  def request!(agent, req) do
    %Page{
      response: %Response{
        body: read_html_file(req),
        headers: [],
        status_code: 200,
        url: req.url
      },
      request: req,
      agent: agent,
      parser: Agent.html_parser(agent)
    }
  end

  defp read_html_file(req) do
    req.url
    |> String.replace_prefix("https://htdocs.local/", "")
    |> File.read()
    |> elem(1)
  end
end

import Mox

defmock(Mechanizex.HTTPAdapter.LocalHtmlFileMock, for: Mechanizex.HTTPAdapter)
