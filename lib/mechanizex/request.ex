defmodule Mechanizex.Request do
  defstruct method: :get, url: nil, headers: [], body: [], params: []

  @type t :: %__MODULE__{
          method: atom(),
          url: binary(),
          params: list(),
          headers: list(),
          body: term()
        }
end
