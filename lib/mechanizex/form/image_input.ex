defmodule Mechanizex.Form.ImageInput do
  alias Mechanizex.Page.{Element, Elementable}

  @derive [Elementable]
  defstruct element: nil, name: nil, x: 0, y: 0

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          x: integer(),
          y: integer()
        }

  def new(%Element{name: "input"} = el) do
    %Mechanizex.Form.ImageInput{
      element: el,
      name: Element.attr(el, :name)
    }
  end

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)
      use Mechanizex.Form.FieldMatchHelper, for: unquote(__MODULE__)
    end
  end
end
