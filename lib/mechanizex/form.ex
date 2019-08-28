defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element

  alias Mechanizex.Form.{
    TextInput,
    DetachedField,
    Checkbox,
    ParameterizableField,
    RadioButton,
    SubmitButton,
    Checkbox,
    ImageInput,
    SelectList
  }

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

  defmodule InconsistentFormError do
    defexception [:message]
  end

  defmodule ClickError do
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

  def update_fields(form, fun) do
    %__MODULE__{form | fields: Enum.map(form.fields, fun)}
  end

  def update_fields(form, type, fun) when is_atom(type) do
    update_fields(form, [type], fun)
  end

  def update_fields(form, types, fun) do
    update_fields(form, fn field ->
      if field.__struct__ in types do
        fun.(field)
      else
        field
      end
    end)
  end

  def update_fields(form, types, criteria, fun) do
    update_fields(form, types, fn field ->
      if Query.match?(field, criteria) do
        fun.(field)
      else
        field
      end
    end)
  end

  def remove_fields(form, fun) do
    %__MODULE__{form | fields: Enum.reject(form.fields, fun)}
  end

  def fields(form) do
    form.fields
  end

  def fields_with(form, type, fun) when is_function(fun) do
    form.fields
    |> Stream.filter(&(type == &1.__struct__))
    |> Enum.filter(fun)
  end

  def fields_with(form, type, criteria) do
    form.fields
    |> Stream.filter(&(type == &1.__struct__))
    |> Enum.filter(&Query.match?(&1, criteria))
  end

  defdelegate checkboxes(form), to: Checkbox
  defdelegate checkboxes_with(form, criteria), to: Checkbox
  defdelegate update_checkboxes(form, fun), to: Checkbox
  defdelegate update_checkboxes_with(form, criteria, fun), to: Checkbox
  defdelegate check_checkbox(form, criteria), to: Checkbox, as: :check
  defdelegate uncheck_checkbox(form, criteria), to: Checkbox, as: :uncheck

  defdelegate image_inputs(form), to: ImageInput
  defdelegate image_inputs_with(form, criteria), to: ImageInput
  defdelegate update_image_inputs(form, fun), to: ImageInput
  defdelegate update_image_inputs_with(form, criteria, fun), to: ImageInput
  defdelegate click_image(form, criteria), to: ImageInput, as: :click

  defdelegate radio_buttons(form), to: RadioButton
  defdelegate radio_buttons_with(form, criteria), to: RadioButton
  defdelegate update_radio_buttons(form, fun), to: RadioButton
  defdelegate update_radio_buttons_with(form, criteria, fun), to: RadioButton
  defdelegate check_radio_button(form, criteria), to: RadioButton, as: :check
  defdelegate uncheck_radio_button(form, criteria), to: RadioButton, as: :uncheck

  defdelegate select_lists(form), to: SelectList
  defdelegate select_lists_with(form, criteria), to: SelectList
  defdelegate update_select_lists(form, fun), to: SelectList
  defdelegate update_select_lists_with(form, criteria, fun), to: SelectList
  defdelegate select(form, criteria), to: SelectList
  defdelegate unselect(form, criteria), to: SelectList

  defdelegate submit_buttons(form), to: SubmitButton
  defdelegate submit_buttons_with(form, criteria), to: SubmitButton
  defdelegate update_submit_buttons(form, fun), to: SubmitButton
  defdelegate update_submit_buttons_with(form, criteria, fun), to: SubmitButton
  defdelegate click_button(form, criteria), to: SubmitButton, as: :click

  def submit(form, button \\ nil) do
    Mechanizex.Agent.request!(agent(form), %Request{
      method: method(form),
      url: action_url(form),
      params: params(form.fields, button)
    })
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
    |> Enum.reject(&is_submit?/1)
    |> maybe_add_clicked_button(button)
    |> Enum.reject(fn f -> Element.attr_present?(f, :disabled) or f.name == nil end)
    |> Enum.flat_map(&ParameterizableField.to_param/1)
  end

  defp is_submit?(field) do
    match?(%SubmitButton{}, field) or match?(%ImageInput{}, field)
  end

  defp maybe_add_clicked_button(params, nil), do: params
  defp maybe_add_clicked_button(params, button), do: [button | params]

  defp agent(form) do
    form.element.page.agent
  end

  defp parse_fields(element) do
    element
    |> Query.search("input, textarea, button, select")
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

      name == "input" and type == "radio" ->
        RadioButton.new(el)

      name == "input" and type == "checkbox" ->
        Checkbox.new(el)

      name == "input" and type == "submit" ->
        SubmitButton.new(el)

      name == "input" and type == "image" ->
        ImageInput.new(el)

      name == "textarea" or name == "input" ->
        TextInput.new(el)

      name == "select" ->
        SelectList.new(el)

      true ->
        nil
    end
  end
end
