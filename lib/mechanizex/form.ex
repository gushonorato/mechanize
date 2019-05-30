defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element

  @enforce_keys [:element]
  defstruct element: nil,
            fields: %{}

  @type t :: %__MODULE__{
          element: Element.t(),
          fields: map()
        }

end
