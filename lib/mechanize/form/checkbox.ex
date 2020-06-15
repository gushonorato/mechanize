defmodule Mechanize.Form.Checkbox do
  @moduledoc false

  alias Mechanize.Query
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Query.BadCriteriaError

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

  def checkboxes_with(form, criteria \\ []) do
    get_in(form, [Access.key(:fields), Access.filter(&Query.match?(&1, __MODULE__, criteria))])
  end

  def update_checkbox(form, checked, criteria) do
    put_in(
      form,
      [
        Access.key(:fields),
        Access.filter(&Query.match?(&1, __MODULE__, criteria)),
        Access.key(:checked)
      ],
      checked
    )
  end

  def check_checkbox(form, criteria) do
    assert_checkbox_found(
      form,
      criteria,
      "Can't check checkbox with criteria #{inspect(criteria)} because it was not found"
    )

    update_checkbox(form, true, criteria)
  end

  def uncheck_checkbox(form, criteria) do
    assert_checkbox_found(
      form,
      criteria,
      "Can't uncheck checkbox with criteria #{inspect(criteria)} because it was not found"
    )

    update_checkbox(form, false, criteria)
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
