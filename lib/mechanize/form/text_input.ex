defmodule Mechanize.Form.TextInput do
  @moduledoc false

  alias Mechanize.Query
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Form.ParameterizableField
  alias Mechanize.Query.BadQueryError

  @derive [ParameterizableField, Elementable]
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

  def text_inputs_with(form, query \\ []) do
    get_in(form, [
      Access.key(:fields),
      Access.filter(&Query.match?(&1, __MODULE__, query))
    ])
  end

  def fill_text(form, query) do
    {value, query} = Keyword.pop(query, :with)

    assert_value_present(value)
    assert_text_input_found(form, query)

    update_text_input(form, value, query)
  end

  defp update_text_input(form, value, query) do
    put_in(
      form,
      [
        Access.key(:fields),
        Access.filter(&Query.match?(&1, __MODULE__, query)),
        Access.key(:value)
      ],
      value
    )
  end

  defp assert_value_present(value) do
    if value == nil, do: raise(ArgumentError, "No \"with\" clause given with text input value")
  end

  defp assert_text_input_found(form, query) do
    if text_inputs_with(form, query) == [],
      do:
        raise(BadQueryError,
          message: "Can't fill text input with query #{inspect(query)} because it was not found"
        )
  end
end
