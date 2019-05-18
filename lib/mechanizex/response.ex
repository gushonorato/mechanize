defmodule Mechanizex.Response do
  defstruct body: nil, headers: nil, status_code: nil, url: nil

  @type t :: %__MODULE__{
          body: term(),
          headers: list(),
          status_code: integer(),
          url: binary()
        }
end
