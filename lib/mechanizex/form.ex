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

  @spec new(Page.t(), Element.t()) :: Form.t()
  def new(page, element) do
    %Mechanizex.Form{element: element, fields: parse_fields(page, element)}
  end

  defmodule InconsistentFormError do
    defexception [:message]
  end

  def put_field(form, field, value) do
    put_field(form, DetachedField.new(field, value))
  end

  def put_field(form, field) do
    %__MODULE__{form | fields: [field | form.fields]}
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
      if Query.match_criteria?(field, criteria) do
        fun.(field)
      else
        field
      end
    end)
  end

  def delete_fields(form, fun) when is_function(fun) do
    %__MODULE__{form | fields: Enum.reject(form.fields, fun)}
  end

  def delete_fields_with(form, criteria) do
    delete_fields(form, &Query.match_criteria?(&1, criteria))
  end

  def fields(nil) do
    raise ArgumentError, "form is nil"
  end

  def fields(form) do
    form.fields
  end

  def fields_with(form, type, fun) when is_function(fun) do
    form
    |> fields()
    |> Stream.filter(&(type == &1.__struct__))
    |> Enum.filter(fun)
  end

  def fields_with(form, type, criteria) do
    form
    |> fields()
    |> Stream.filter(&(type == &1.__struct__))
    |> Enum.filter(&Query.match_criteria?(&1, criteria))
  end

  defdelegate text_inputs(form), to: TextInput
  defdelegate text_inputs_with(form, criteria), to: TextInput
  defdelegate update_text_inputs(form, fun), to: TextInput
  defdelegate update_text_inputs_with(form, criteria, fun), to: TextInput
  defdelegate fill_text(form, criteria), to: TextInput

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
    req =
      case method(form) do
        :post ->
          %Request{
            method: method(form),
            url: action_url(form),
            body: {:form, params(form.fields, button)}
          }

        :get ->
          %Request{
            method: method(form),
            url: action_url(form),
            params: params(form.fields, button)
          }
      end

    Mechanizex.Browser.request!(browser(form), req)
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
    |> (&URI.merge(form.element.page.url, &1)).()
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

  defp browser(form) do
    form.element.page.browser
  end

  defp parse_fields(page, element) do
    element
    |> parse_inner_fields()
    |> parse_outer_fields(page, element)
    |> Enum.map(&create_field/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_inner_fields(element) do
    Query.search(element, "input, textarea, button, select")
  end

  defp parse_outer_fields(fields, page, element) do
    case Element.attr(element, :id) do
      nil ->
        fields

      form_id ->
        page
        |> Query.filter(~s(form[id="#{form_id}"]))
        |> Query.search(~s([form="#{form_id}"]))
        |> Kernel.++(fields)
    end
  end

  defp create_field(el) do
    tag = Element.name(el)
    type = Element.attr(el, :type, normalize: true)

    cond do
      type == "reset" ->
        nil

      tag == "button" and (type == "submit" or type == nil or type == "") ->
        SubmitButton.new(el)

      tag == "input" and type == "radio" ->
        RadioButton.new(el)

      tag == "input" and type == "checkbox" ->
        Checkbox.new(el)

      tag == "input" and type == "submit" ->
        SubmitButton.new(el)

      tag == "input" and type == "image" ->
        ImageInput.new(el)

      tag == "textarea" or tag == "input" ->
        TextInput.new(el)

      tag == "select" ->
        SelectList.new(el)

      true ->
        nil
    end
  end
end
