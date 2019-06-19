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

  def fill_field(form, field, with: value) do
    fields =
      if field_present?(form, field) do
        update_field(form.fields, field, value)
      else
        [DetachedField.new(field, value) | form.fields]
      end

    %Mechanizex.Form{form | fields: fields}
  end

  defp field_present?(%Mechanizex.Form{fields: fields}, field) do
    Enum.find(fields, fn %{label: label, name: name} ->
      label == field or name == field
    end)
  end

  defp update_field(fields, field, value) do
    Enum.map(fields, fn f ->
      if f.label == field or f.name == field do
        Map.put(f, :value, value)
      else
        f
      end
    end)
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
