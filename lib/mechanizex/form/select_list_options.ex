defmodule Mechanizex.Form.SelectListOptions do
  alias Mechanizex.Page.{Element, Elementable}

  @derive [Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, value: nil, selected: false

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          value: String.t(),
          value: boolean()
        }

  def new(%Element{} = el) do
    %__MODULE__{
      element: el,
      value: Element.attr(el, :value) || Element.text(el),
      label: Element.attr(el, :label) || Element.text(el),
      selected: Element.attr_present?(el, :selected)
    }
  end
end
