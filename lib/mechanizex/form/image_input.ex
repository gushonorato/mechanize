defmodule Mechanizex.Form.ImageInput do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.{Form, Queryable}
  alias Mechanizex.Form.{ClickError}

  @derive [Elementable, Queryable]
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
      use Mechanizex.Form.FieldMatcher, for: unquote(__MODULE__)
      use Mechanizex.Form.FieldUpdater, for: unquote(__MODULE__)
    end
  end

  def click(form, %__MODULE__{} = image) do
    Form.submit(form, image)
  end

  def click(form, criteria) do
    {x, criteria} = Keyword.pop(criteria, :x, 0)
    {y, criteria} = Keyword.pop(criteria, :y, 0)

    form
    |> Form.image_inputs_with(criteria)
    |> maybe_click_on_image(form, x, y)
  end

  defp maybe_click_on_image(images, form, x, y) do
    case images do
      [] ->
        raise ClickError, message: "Can't click on image because it was not found"

      [image] ->
        click(form, %__MODULE__{image | x: x, y: y})

      images ->
        raise ClickError,
          message: "Can't decide which image to click because #{length(images)} images were found"
    end
  end
end

defimpl Mechanizex.Form.ParameterizableField, for: Mechanizex.Form.ImageInput do
  def to_param(image) do
    [{"#{image.name}.x", image.x}, {"#{image.name}.y", image.y}]
  end
end
