defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{TextInput, DetachedField}
  alias Mechanizex.Query

  @enforce_keys [:element]
  defstruct element: nil,
            fields: []

  @type t :: %__MODULE__{
          element: Element.t(),
          fields: list()
        }

  @spec new(Element.t()) :: Form.t()
  def new(element) do
    %Mechanizex.Form{
      element: element,
      fields: parse_fields(element)
   }
  end

  defp parse_fields(element) do
    element
    |> Query.with_elements([:input, :text_area, :select])
    |> Enum.map(&create_field/1)
  end

  defp create_field(%Element{tag_name: :input} = element) do
    TextInput.new(element)
  end
end
