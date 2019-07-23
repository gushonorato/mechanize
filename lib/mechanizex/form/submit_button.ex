defmodule Mechanizex.Form.SubmitButton do
  alias Mechanizex.Page.Element

  @derive [Mechanizex.Page.Elementable]
  defstruct element: nil, name: nil, value: nil, text: nil, id: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          value: String.t(),
          text: String.t()
        }

  def new(%Element{name: "button"} = el) do
    %Mechanizex.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      text: Element.text(el)
    }
  end

  def new(%Element{name: "input", attrs: [{"type", "image"} | _]} = el) do
    %Mechanizex.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      text: nil
    }
  end

  def new(%Element{name: "input"} = el) do
    %Mechanizex.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      text: Element.attr(el, :value)
    }
  end

  def is_submit_button?(field) do
    match?(%__MODULE__{}, field)
  end
end
