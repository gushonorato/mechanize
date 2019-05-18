defmodule Mechanizex.Request do
  defstruct method: :get, url: nil, headers: [], body: []

  @type t :: %__MODULE__{
          method: atom(),
          url: binary(),
          headers: list(),
          body: term()
        }
end
