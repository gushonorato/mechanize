defmodule Mechanize.Form.RadioButton do
  @moduledoc false

  alias Mechanize.Query
  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Form.InconsistentFormError
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

  def radio_buttons_with(form, query \\ []) do
    get_in(form, [
      Access.key(:fields),
      Access.filter(&Query.match?(&1, __MODULE__, query))
    ])
  end

  def clear_radios(form, radio_names) do
    update_radio_button(form, false, name: radio_names)
  end

  def update_radio_button(form, checked, query) do
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

  def check_radio_button(form, query) do
    assert_radio_found(
      form,
      query,
      "Can't check radio with query #{inspect(query)} because it was not found"
    )

    radio_names =
      form
      |> radio_buttons_with(query)
      |> Stream.map(& &1.name)
      |> Enum.uniq()

    form
    |> clear_radios(radio_names)
    |> update_radio_button(true, query)
    |> assert_single_radio_in_group_checked()
  end

  def uncheck_radio_button(form, query) do
    assert_radio_found(
      form,
      query,
      "Can't uncheck radio with query #{inspect(query)} because it was not found"
    )

    update_radio_button(form, false, query)
  end

  defp assert_radio_found(form, query, error_msg) do
    if radio_buttons_with(form, query) == [], do: raise(BadQueryError, message: error_msg)
  end

  defp assert_single_radio_in_group_checked(form) do
    form
    |> radio_buttons_with()
    |> Enum.filter(& &1.checked)
    |> Enum.reduce(%{}, fn radio, acc -> Map.update(acc, radio.name, 0, &(&1 + 1)) end)
    |> Enum.filter(fn {_radio_name, count} -> count > 1 end)
    |> Enum.map(fn {radio_name, _count} -> radio_name end)
    |> case do
      [] ->
        form

      radio_names ->
        raise InconsistentFormError,
          message:
            "Cannot check multiple radio buttons with same name (#{Enum.join(radio_names, ", ")})"
    end
  end
end

defimpl Mechanize.Form.ParameterizableField, for: Mechanize.Form.RadioButton do
  def to_param(field) do
    if field.checked, do: [{field.name, field.value}], else: []
  end
end
