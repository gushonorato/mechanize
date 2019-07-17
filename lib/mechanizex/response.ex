defmodule Mechanizex.Response do
  defstruct body: nil, headers: nil, code: nil, url: nil

  @type t :: %__MODULE__{
          body: term(),
          headers: list(),
          code: integer(),
          url: binary()
        }
end
