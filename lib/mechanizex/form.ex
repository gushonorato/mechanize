defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{TextInput, DetachedField, SubmitButton}
  alias Mechanizex.{Query, Request}

  @derive [Mechanizex.Page.Elementable]
  @enforce_keys [:element]
  defstruct element: nil,
            fields: []

  @type t :: %__MODULE__{
          element: Element.t(),
          fields: list()
        }

  @spec new(Element.t()) :: Form.t()
  def new(element) do
    %Mechanizex.Form{
      element: element,
      fields: parse_fields(element)
    }
  end

  defmodule ButtonNotFound do
    defexception [:message]
  end

  def fill_field(form, field, with: value) do
    updated_form = update_field(form, field, value)
    if updated_form == form, do: add_field(form, field, value), else: updated_form
  end

  def update_field(form, field_name, value) do
    update_fields(form, fn field ->
      if field.name == field_name, do: %{field | value: value}, else: field
    end)
  end

  def add_field(form, field, value) do
    create_field(form, DetachedField.new(field, value))
  end

  def delete_field(form, field_name) do
    remove_fields(form, fn field -> field.name == field_name end)
  end

  def create_field(form, field) do
    Map.put(form, :fields, [field | form.fields])
  end

  def retrieve_fields(form, fun) do
    Enum.filter(form.fields, fun)
  end

  def update_fields(form, fun) do
    %__MODULE__{form | fields: Enum.map(form.fields, fun)}
  end

  def remove_fields(form, fun) do
    %__MODULE__{form | fields: Enum.reject(form.fields, fun)}
  end

  def fields(form) do
    form.fields
  end

  def submit_buttons(form), do: Enum.filter(form.fields, &SubmitButton.is_submit_button?/1)

  def submit(form, button \\ nil) do
    Mechanizex.Agent.request(agent(form), %Request{
      method: method(form),
      url: action_url(form),
      params: params(form.fields, button)
    })
  end

  def click_button(_form, nil) do
    {:error, %ArgumentError{message: "Can't click on button because button is nil."}}
  end

  def click_button(form, criteria) when is_list(criteria) do
    form
    |> submit_buttons(criteria)
    |> maybe_click_on_button(form)
  end

  def click_button(form, label) when is_binary(label) do
    form
    |> submit_buttons(fn button -> button.label == label end)
    |> maybe_click_on_button(form)
  end

  def click_button(form, %SubmitButton{} = button) do
    submit(form, button)
  end

  def click_button(form, label) do
    form
    |> submit_buttons_with(fn button -> button.label != nil and button.label =~ label end)
    |> maybe_click_on_button(form)
  end

  defp maybe_click_on_button(buttons, form) do
    case buttons do
      [] ->
        {:error,
         %FormComponentNotFound{
           message: "Can't click on button because it was not found."
         }}

      [button] ->
        click_button(form, button)

      buttons ->
        {:error,
         %MultipleFormComponentsFound{
           message: "Can't click on button because #{length(buttons)} buttons were found."
         }}
    end
  end

  defp method(form) do
    method =
      form
      |> Element.attr(:method)
      |> Kernel.||("")
      |> String.trim()
      |> String.downcase()

    if method == "post", do: :post, else: :get
  end

  defp action_url(form) do
    form
    |> Element.attr(:action)
    |> Kernel.||("")
    |> String.trim()
    |> (&URI.merge(form.element.page.request.url, &1)).()
    |> URI.to_string()
  end

  defp params(fields, button) do
    fields
    |> Enum.reject(&SubmitButton.is_submit_button?/1)
    |> maybe_add_submit_button(button)
    |> Enum.reject(fn f -> Element.attr_present?(f, :disabled) or f.name == nil end)
    |> Enum.map(fn f -> {f.name, f.value} end)
  end

  defp maybe_add_submit_button(params, nil), do: params
  defp maybe_add_submit_button(params, button), do: [button | params]

  defp agent(form) do
    form.element.page.agent
  end

  defp parse_fields(element) do
    element
    |> Query.search("input, textarea, button")
    |> Enum.map(&create_field/1)
    |> Enum.reject(&is_nil/1)
  end

  defp create_field(el) do
    name = Element.name(el)
    type = Element.attr(el, :type, normalize: true)

    cond do
      type == "reset" ->
        nil

      name == "button" and (type == "submit" or type == nil or type == "") ->
        SubmitButton.new(el)

      # name == "input" and type == "radio" ->
      # RadioButton.new(el)

      name == "input" and (type == "submit" or type == "image") ->
        SubmitButton.new(el)

      name == "textarea" or name == "input" ->
        TextInput.new(el)

      true ->
        nil
    end
  end
end
