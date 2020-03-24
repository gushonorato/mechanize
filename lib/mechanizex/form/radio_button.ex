defmodule Mechanizex.Form.RadioButton do
  alias Mechanizex.{Query, Queryable}
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Form.InconsistentFormError
  alias Mechanizex.Query.BadCriteriaError

  use Mechanizex.Form.{FieldMatcher, FieldUpdater}

  @derive [Queryable, Elementable]
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
    assert_radio_found(
      form,
      criteria,
      "Can't check radio with criteria #{inspect(criteria)} because it was not found"
    )

    radio_groups =
      form
      |> radio_buttons_with(criteria)
      |> Stream.map(& &1.name)
      |> Enum.uniq()

    form
    |> update_radio_buttons(fn field ->
      cond do
        Query.match_criteria?(field, criteria) ->
          %__MODULE__{field | checked: true}

        field.name in radio_groups ->
          %__MODULE__{field | checked: false}

        true ->
          field
      end
    end)
    |> assert_single_radio_in_group_checked
  end

  def uncheck(form, criteria) do
    assert_radio_found(
      form,
      criteria,
      "Can't uncheck radio with criteria #{inspect(criteria)} because it was not found"
    )

    update_radio_buttons_with(form, criteria, &%__MODULE__{&1 | checked: false})
  end

  defp assert_radio_found(form, criteria, error_msg) do
    if radio_buttons_with(form, criteria) == [], do: raise(BadCriteriaError, message: error_msg)
  end

  defp assert_single_radio_in_group_checked(form) do
    form
    |> radio_buttons_with(fn radio -> radio.checked end)
    |> Enum.group_by(&Element.attr(&1, :name))
    |> Stream.filter(fn {_, radios_checked} -> length(radios_checked) > 1 end)
    |> Enum.map(fn {group_name, _} -> group_name end)
    |> case do
      [] ->
        form

      group_names ->
        raise InconsistentFormError,
          message: "Multiple radio buttons with same name (#{Enum.join(group_names, ", ")}) are checked"
    end
  end
end

defimpl Mechanizex.Form.ParameterizableField, for: Mechanizex.Form.RadioButton do
  def to_param(field) do
    if field.checked, do: [{field.name, field.value}], else: []
  end
end
