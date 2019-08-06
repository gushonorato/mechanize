defmodule Mechanizex.Form.SubmitButton do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Form.{ParameterizableField}

  @derive [Elementable, ParameterizableField]
  defstruct element: nil, name: nil, value: nil, label: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          value: String.t(),
          label: String.t()
        }

  def new(%Element{name: "button"} = el) do
    %Mechanizex.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      label: Element.text(el)
    }
  end

  def new(%Element{name: "input", attrs: [{"type", "image"} | _]} = el) do
    %Mechanizex.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      label: nil
    }
  end

  def new(%Element{name: "input"} = el) do
    %Mechanizex.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      label: Element.attr(el, :value)
    }
  end
end
