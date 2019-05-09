defmodule Mechanize do
  use Agent
  alias Mechanize.{HTTPAdapter, HTMLParser, Page}
  alias Mechanize.Page.Link

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
    {:ok, mech} = Mechanize.start_link(options)
    mech
  end

  @spec init(list()) :: Mechanize.t()
  defp init(options) do
    opts =
      %Mechanize{}
      |> Map.get(:options)
      |> Keyword.merge(Application.get_all_env(:mechanize))
      |> Keyword.merge(options)

    %Mechanize{options: opts}
    |> inject_dependencies
  end

  defp inject_dependencies(state) do
    state
    |> Map.put(:http_adapter, HTTPAdapter.adapter(state.options[:http_adapter]))
    |> Map.put(:html_parser, HTMLParser.parser(state.options[:html_parser]))
  end

  def get_option(mechanize, option) do
    Agent.get(mechanize, fn state -> state.options[option] end)
  end

  def http_adapter(mechanize) do
    Agent.get(mechanize, fn state -> state.http_adapter end)
  end

  def html_parser(mechanize) do
    Agent.get(mechanize, fn state -> state.html_parser end)
  end

  defp deleg_http(method, params) do
    params
    |> List.first()
    |> http_adapter
    |> apply(method, params)
  end

  def get!(mech, url), do: deleg_http(:get!, [mech, url])
  def request!(mech, req), do: deleg_http(:request!, [mech, req])

  @spec click(Mechanize.Page.Link.t()) :: Mechanize.Page.t()
  def click(%Link{href: url, mechanize: mech}) do
    get!(mech, url)
  end
end
