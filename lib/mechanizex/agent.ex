defmodule Mechanizex.Agent do
  use Agent
  alias Mechanizex.{HTTPAdapter, HTMLParser, Page}
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
    {:ok, mech} = Mechanizex.Agent.start_link(options)
    mech
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

  def option(mechanizex, option) do
    Agent.get(mechanizex, fn state -> state.options[option] end)
  end

  def http_adapter(mechanizex) do
    Agent.get(mechanizex, fn state -> state.http_adapter end)
  end

  def set_http_adapter(mechanizex, adapter) do
    Agent.update(mechanizex, &Map.put(&1, :http_adapter, adapter))
    mechanizex
  end

  def html_parser(mechanizex) do
    Agent.get(mechanizex, fn state -> state.html_parser end)
  end

  def set_html_parser(mechanizex, parser) do
    Agent.update(mechanizex, &Map.put(&1, :html_parser, parser))
    mechanizex
  end

  defp deleg_http(method, params) do
    params
    |> List.first()
    |> http_adapter
    |> apply(method, params)
  end

  def get!(mech, url), do: deleg_http(:get!, [mech, url])
  def request!(mech, req), do: deleg_http(:request!, [mech, req])
end
