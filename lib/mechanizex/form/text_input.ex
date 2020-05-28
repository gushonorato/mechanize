defmodule Mechanize.Form.TextInput do
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Form.ParameterizableField
  alias Mechanize.Queryable
  alias Mechanize.Query.BadCriteriaError

  use Mechanize.Form.{FieldMatcher, FieldUpdater}

  @derive [ParameterizableField, Queryable, Elementable]
  @enforce_keys [:element]
  defstruct element: nil, name: nil, value: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          value: String.t()
        }

  def new(%Element{name: "input"} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value)
    }
  end

  def new(%Element{name: "textarea"} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      value: Element.text(el)
    }
  end

  def fill_text(form, criteria) do
    {value, criteria} = Keyword.pop(criteria, :with)

    assert_value_present(value)
    assert_text_input_found(form, criteria)

    update_text_inputs_with(form, criteria, fn input ->
      %__MODULE__{input | value: value}
    end)
  end

  defp assert_value_present(value) do
    if value == nil, do: raise(ArgumentError, "No \"with\" clause given with text input value")
  end

  defp assert_text_input_found(form, criteria) do
    if text_inputs_with(form, criteria) == [],
      do:
        raise(BadCriteriaError,
          message: "Can't fill text input with criteria #{inspect(criteria)} because it was not found"
        )
  end
end
