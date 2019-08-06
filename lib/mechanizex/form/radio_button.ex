defmodule Mechanizex.Form.RadioButton do
  use Mechanizex.Form.FieldMatchHelper
  alias Mechanizex.{Form, Query}
  alias Mechanizex.Form.InconsistentFormError
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

  def check(form, criteria) do
    radio_groups =
      form
      |> Form.radio_buttons_with(criteria)
      |> Stream.map(& &1.name)
      |> Enum.uniq()

    form
    |> Form.update_radio_buttons(fn field ->
      cond do
        Query.match?(field, criteria) ->
          %__MODULE__{field | checked: true}

        field.name in radio_groups ->
          %__MODULE__{field | checked: false}

        true ->
          field
      end
    end)
  end

  def uncheck(form, criteria) do
    Form.update_radio_buttons_with(form, criteria, &%__MODULE__{&1 | checked: false})
  end
end

defimpl Mechanizex.Form.ParameterizableField, for: Mechanizex.Form.RadioButton do
  def to_param(field) do
    if field.checked, do: [{field.name, field.value}], else: []
  end
end
