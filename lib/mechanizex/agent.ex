defmodule Mechanizex.Agent do
  use Agent
  alias Mechanizex.{HTTPAdapter, HTMLParser, Page, Request}
  alias Mechanizex.Page.Link

  defstruct options: [http_adapter: :httpoison, html_parser: :floki],
            http_adapter: nil,
            html_parser: nil

  @type t :: %__MODULE__{
          options: list(),
          http_adapter: any(),
          html_parser: any()
        }

  @spec start_link(list()) :: {:error, any()} | {:ok, pid()}
  def start_link(options \\ []) do
    Agent.start_link(fn -> init(options) end)
  end

  @spec new(list()) :: pid()
  def new(options \\ []) do
    {:ok, agent} = Mechanizex.Agent.start_link(options)
    agent
  end

  @spec init(list()) :: Mechanizex.Agent.t()
  defp init(options) do
    opts =
      %Mechanizex.Agent{}
      |> Map.get(:options)
      |> Keyword.merge(Application.get_all_env(:mechanizex))
      |> Keyword.merge(options)

    %Mechanizex.Agent{options: opts}
    |> inject_dependencies
  end

  defp inject_dependencies(state) do
    state
    |> Map.put(:http_adapter, HTTPAdapter.adapter(state.options[:http_adapter]))
    |> Map.put(:html_parser, HTMLParser.parser(state.options[:html_parser]))
  end

  def option(agent, option) do
    Agent.get(agent, fn state -> state.options[option] end)
  end

  def http_adapter(agent) do
    Agent.get(agent, fn state -> state.http_adapter end)
  end

  def set_http_adapter(agent, adapter) do
    Agent.update(agent, &Map.put(&1, :http_adapter, adapter))
    agent
  end

  def html_parser(agent) do
    Agent.get(agent, fn state -> state.html_parser end)
  end

  def set_html_parser(agent, parser) do
    Agent.update(agent, &Map.put(&1, :html_parser, parser))
    agent
  end

  def get!(agent, %URI{} = uri) do
    get!(agent, URI.to_string(uri))
  end

  def get!(agent, url) do
    request!(agent, %Request{method: :get, url: url})
  end

  def request!(agent, request) do
    http_adapter(agent).request!(agent, request)
  end
end
