defmodule Mechanizex.Response do
  alias Mechanizex.Header
  defstruct body: [], headers: [], code: nil, url: nil

  @type t :: %__MODULE__{
          body: term(),
          headers: list(),
          code: integer(),
          url: binary()
        }

  def normalize(%__MODULE__{} = res) do
    normalize_headers(res)
  end

  defp normalize_headers(%__MODULE__{} = res) do
    %__MODULE__{res | headers: Header.normalize(res.headers)}
  end

  def headers(%__MODULE__{} = res) do
    res.headers
  end
end
