defmodule Mechanize.Request do
  defstruct method: :get, url: nil, headers: [], body: []

  @type t :: %__MODULE__{
          method: atom(),
          url: String.t(),
          headers: list(),
          body: term()
        }
end
