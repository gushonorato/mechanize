defmodule Mechanizex.Form.Checkbox do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form

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
      use Mechanizex.Form.FieldMatcher, for: unquote(__MODULE__), suffix: "es"
      use Mechanizex.Form.FieldUpdater, for: unquote(__MODULE__), suffix: "es"
    end
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

defimpl Mechanizex.Page.Elementable, for: Mechanizex.Form.Checkbox do
  defdelegate page(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate name(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate text(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate attrs(e), to: Mechanizex.Page.Elementable.LabeledElementable
end
