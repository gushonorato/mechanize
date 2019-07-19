defmodule Mechanizex.Response do
  defstruct body: [], headers: [], code: nil, url: nil

  @type t :: %__MODULE__{
          body: term(),
          headers: list(),
          code: integer(),
          url: binary()
        }
end
