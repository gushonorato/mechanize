defmodule Mechanize.Form.Option do
  @moduledoc false

  alias Mechanize.Page.{Element, Elementable}

  @derive [Elementable]
  @enforce_keys [:element, :index]
  defstruct element: nil, visible_text: nil, value: nil, selected: false, index: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          visible_text: String.t(),
          value: String.t(),
          index: integer(),
          selected: boolean()
        }

  def new({%Element{} = el, index}) do
    %__MODULE__{
      element: el,
      value: Element.attr(el, :value) || Element.text(el),
      visible_text: Element.attr(el, :label) || Element.text(el),
      index: index,
      selected: Element.attr_present?(el, :selected)
    }
  end
end
