defmodule Mechanizex.Response do
  alias Mechanizex.Header
  defstruct body: nil, headers: [], code: nil, url: nil, location: nil

  @type t :: %__MODULE__{
          body: term(),
          headers: list(),
          code: integer(),
          url: String.t(),
          location: String.t()
        }

  # TODO: Add tests
  def new(attrs \\ []) do
    %__MODULE__{}
    |> struct(attrs)
    |> normalize()
  end

  def normalize(%__MODULE__{} = res) do
    res
    |> normalize_headers()
    |> fetch_location()
  end

  def headers(%__MODULE__{} = res) do
    res.headers
  end

  def location(%__MODULE__{} = res), do: Header.get(res.headers, "location")

  defp normalize_headers(%__MODULE__{} = res) do
    %__MODULE__{res | headers: Header.normalize(res.headers)}
  end

  defp fetch_location(%__MODULE__{} = res), do: Map.put(res, :location, location(res))
end
