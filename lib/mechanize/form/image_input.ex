defmodule Mechanize.Form.ImageInput do
  @moduledoc false

  alias Mechanize.Form
  alias Mechanize.Query
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Query.BadQueryError

  @derive [Elementable]
  defstruct element: nil, name: nil, x: 0, y: 0

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          x: integer(),
          y: integer()
        }

  def new(%Element{name: "input"} = el) do
    %Mechanize.Form.ImageInput{
      element: el,
      name: Element.attr(el, :name)
    }
  end

  def image_inputs_with(form, query \\ []) do
    get_in(form, [Access.key(:fields), Access.filter(&Query.match?(&1, __MODULE__, query))])
  end

  def click_image(form, %__MODULE__{} = image) do
    Form.submit(form, image)
  end

  def click_image(form, query) do
    {x, query} = Keyword.pop(query, :x, 0)
    {y, query} = Keyword.pop(query, :y, 0)

    form
    |> Form.image_inputs_with(query)
    |> maybe_click_on_image(form, x, y)
  end

  defp maybe_click_on_image(images, form, x, y) do
    case images do
      [] ->
        raise BadQueryError, message: "Can't click on image input because it was not found"

      [image] ->
        click_image(form, %__MODULE__{image | x: x, y: y})

      images ->
        raise BadQueryError,
          message: "Can't decide which image input to click because #{length(images)} were found"
    end
  end
end

defimpl Mechanize.Form.ParameterizableField, for: Mechanize.Form.ImageInput do
  def to_param(image) do
    [{"#{image.name}.x", image.x}, {"#{image.name}.y", image.y}]
  end
end
