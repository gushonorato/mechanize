defmodule Mechanizex.Form.TextInput do
  alias Mechanizex.Page.Element

  @derive [Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, value: nil, disabled: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          value: String.t(),
          disabled: boolean()
        }
end
