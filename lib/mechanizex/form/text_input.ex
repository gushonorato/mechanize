defmodule Mechanizex.Form.TextInput do
  alias Mechanizex.Page.Element

  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, value: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          value: String.t()
        }

  def new(element) do
    %Mechanizex.Form.TextInput{
      element: element,
      name: element.attributes[:name],
      value: element.attributes[:value]
    }
  end
end
