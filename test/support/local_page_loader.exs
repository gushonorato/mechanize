defmodule Mechanizex.Test.Support.LocalPageLoader do
  alias Mechanizex.{Request, Response, Page, Agent}

  def get(agent, url) do
    %Page{
      response: %Response{
        body: read_html_file(url),
        headers: [],
        code: 200,
        url: url
      },
      request: %Request{
        method: :get,
        url: url
      },
      agent: agent,
      parser: Agent.html_parser(agent)
    }
  end

  defp read_html_file(url) do
    url
    |> String.replace_prefix("https://htdocs.local/", "")
    |> File.read()
    |> elem(1)
  end
end
