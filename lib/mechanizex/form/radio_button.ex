defmodule Mechanizex.Form.RadioButton do
  alias Mechanizex.Page.Element

  @derive [Mechanizex.Page.Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, value: nil, checked: false

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          value: String.t(),
          checked: boolean()
        }
end
