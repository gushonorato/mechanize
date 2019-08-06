defmodule Mechanizex.Form.RadioButton do
  use Mechanizex.Form.FieldMatchHelper
  alias Mechanizex.Page.{Element, Elementable}

  @derive [Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, value: nil, checked: false

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          value: String.t(),
          checked: boolean()
        }

  def new(%Element{} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      checked: Element.attr_present?(el, :checked)
    }
  end

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)

      field_match_helper_for(unquote(__MODULE__))
    end
  end
end
