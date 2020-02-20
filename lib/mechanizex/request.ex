defmodule Mechanizex.Request do
  alias Mechanizex.Header

  defstruct method: :get, url: nil, headers: [], body: [], params: []

  @type t :: %__MODULE__{
          method: atom(),
          url: binary(),
          params: list(),
          headers: list(),
          body: term()
        }

  def normalize_headers(%__MODULE__{} = req) do
    %__MODULE__{req | headers: Header.normalize(req.headers)}
  end
end
