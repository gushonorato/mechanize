defmodule Mechanize.Form.Checkbox do
  @moduledoc false

  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Query.BadCriteriaError

  use Mechanize.Form.FieldMatcher, suffix: "es"
  use Mechanize.Form.FieldUpdater, suffix: "es"

  @derive [Elementable]
  @enforce_keys [:element]
  defstruct element: nil, name: nil, value: nil, checked: false

  @type t :: %__MODULE__{
          element: Element.t(),
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
    assert_checkbox_found(
      form,
      criteria,
      "Can't check checkbox with criteria #{inspect(criteria)} because it was not found"
    )

    update_checkboxes_with(form, criteria, fn checkbox ->
      %__MODULE__{checkbox | checked: true}
    end)
  end

  def uncheck(form, criteria) do
    assert_checkbox_found(
      form,
      criteria,
      "Can't uncheck checkbox with criteria #{inspect(criteria)} because it was not found"
    )

    update_checkboxes_with(form, criteria, fn checkbox ->
      %__MODULE__{checkbox | checked: false}
    end)
  end

  defp assert_checkbox_found(form, criteria, error_msg) do
    if checkboxes_with(form, criteria) == [], do: raise(BadCriteriaError, error_msg)
  end
end

defimpl Mechanize.Form.ParameterizableField, for: Mechanize.Form.Checkbox do
  def to_param(field) do
    if field.checked, do: [{field.name, field.value || "on"}], else: []
  end
end
