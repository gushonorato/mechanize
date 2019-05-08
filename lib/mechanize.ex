defmodule Mechanize do
  use Agent
  alias Mechanize.HTTPAdapter

  @default_options [adapter: :httpoison]

  defstruct options: []

  @type t :: %__MODULE__{
    options: list()
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
      @default_options
      |> Keyword.merge(Application.get_all_env(:mechanize))
      |> Keyword.merge(options)

    %Mechanize{options: opts}
  end

  def get_option(mechanize, option) do
    Agent.get(mechanize, fn state -> state.options[option] end)
  end

  defdelegate get!(mechanize, url), to: HTTPAdapter
  defdelegate request!(mechanize, request), to: HTTPAdapter
end
