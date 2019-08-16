defmodule Mechanizex.Form.SelectListOption do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Queryable

  @derive [Elementable, Queryable]
  @enforce_keys [:element, :index]
  defstruct element: nil, label: nil, value: nil, selected: false, index: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          value: String.t(),
          index: integer(),
          selected: boolean()
        }

  def new({%Element{} = el, index}) do
    %__MODULE__{
      element: el,
      value: Element.attr(el, :value) || Element.text(el),
      label: Element.attr(el, :label) || Element.text(el),
      index: index,
      selected: Element.attr_present?(el, :selected)
    }
  end
end
