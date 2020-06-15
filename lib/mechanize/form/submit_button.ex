defmodule Mechanize.Form.SubmitButton do
  @moduledoc false

  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.{Form, Query}
  alias Mechanize.Form.ParameterizableField
  alias Mechanize.Query.BadCriteriaError

  @derive [ParameterizableField, Elementable]
  defstruct [:element, :name, :value, :visible_text]

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          value: String.t(),
          visible_text: String.t()
        }

  def new(%Element{name: "button"} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      visible_text: Element.text(el)
    }
  end

  def new(%Element{name: "input"} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      visible_text: Element.attr(el, :value)
    }
  end

  def submit_buttons_with(form, criteria \\ []) do
    get_in(form, [
      Access.key(:fields),
      Access.filter(&Query.match?(&1, __MODULE__, criteria))
    ])
  end

  def click_button(_form, nil) do
    raise ArgumentError, message: "Can't click on button because button is nil."
  end

  def click_button(form, criteria) when is_list(criteria) do
    form
    |> submit_buttons_with(criteria)
    |> maybe_click_on_button(form)
  end

  def click_button(form, visible_text) when is_binary(visible_text) do
    form
    |> submit_buttons_with()
    |> Enum.filter(&(&1.visible_text == visible_text))
    |> maybe_click_on_button(form)
  end

  def click_button(form, %__MODULE__{} = button) do
    Form.submit(form, button)
  end

  def click_button(form, visible_text) do
    form
    |> submit_buttons_with()
    |> Enum.filter(&(&1.visible_text != nil and &1.visible_text =~ visible_text))
    |> maybe_click_on_button(form)
  end

  defp maybe_click_on_button(buttons, form) do
    case buttons do
      [] ->
        raise BadCriteriaError,
          message: "Can't click on submit button because no button was found for given criteria"

      [button] ->
        click_button(form, button)

      buttons ->
        raise BadCriteriaError,
          message:
            "Can't decide which submit button to click because #{length(buttons)} buttons were found for given criteria"
    end
  end
end
