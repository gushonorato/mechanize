defmodule Mechanize.Form.Checkbox do
  @moduledoc false

  alias Mechanize.Query
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Query.BadQueryError

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

  def checkboxes_with(form, query \\ []) do
    get_in(form, [Access.key(:fields), Access.filter(&Query.match?(&1, __MODULE__, query))])
  end

  def update_checkbox(form, checked, query) do
    put_in(
      form,
      [
        Access.key(:fields),
        Access.filter(&Query.match?(&1, __MODULE__, query)),
        Access.key(:checked)
      ],
      checked
    )
  end

  def check_checkbox(form, query) do
    assert_checkbox_found(
      form,
      query,
      "Can't check checkbox with query #{inspect(query)} because it was not found"
    )

    update_checkbox(form, true, query)
  end

  def uncheck_checkbox(form, query) do
    assert_checkbox_found(
      form,
      query,
      "Can't uncheck checkbox with query #{inspect(query)} because it was not found"
    )

    update_checkbox(form, false, query)
  end

  defp assert_checkbox_found(form, query, error_msg) do
    if checkboxes_with(form, query) == [], do: raise(BadQueryError, error_msg)
  end
end

defimpl Mechanize.Form.ParameterizableField, for: Mechanize.Form.Checkbox do
  def to_param(field) do
    if field.checked, do: [{field.name, field.value || "on"}], else: []
  end
end
