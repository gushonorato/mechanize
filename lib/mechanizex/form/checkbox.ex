defmodule Mechanizex.Form.Checkbox do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.{Form, Queryable}

  use Mechanizex.Form.FieldMatcher, suffix: "es"
  use Mechanizex.Form.FieldUpdater, suffix: "es"

  @derive [Queryable, Elementable]
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

  def check(form, criteria) do
    Form.update_checkboxes_with(form, criteria, fn checkbox ->
      %__MODULE__{checkbox | checked: true}
    end)
  end

  def uncheck(form, criteria) do
    Form.update_checkboxes_with(form, criteria, fn checkbox ->
      %__MODULE__{checkbox | checked: false}
    end)
  end
end

defimpl Mechanizex.Form.ParameterizableField, for: Mechanizex.Form.Checkbox do
  def to_param(field) do
    if field.checked, do: [{field.name, field.value || "on"}], else: []
  end
end
