defmodule Mechanize.Response do
  defstruct body: nil, headers: nil, status_code: nil

  @type t :: %__MODULE__{
          body: term(),
          headers: list(),
          status_code: integer()
        }
end
