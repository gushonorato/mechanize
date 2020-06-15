defmodule Mechanize.Form do
  alias Mechanize.Page.Element

  alias Mechanize.Form.{
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

  alias Mechanize.Query

  @derive [Mechanize.Page.Elementable]
  @enforce_keys [:element]
  defstruct element: nil,
            fields: []

  @type t :: %__MODULE__{
          element: Element.t(),
          fields: list()
        }

  defmodule InconsistentFormError do
    defexception [:message]
  end

  @spec new(Page.t(), Element.t()) :: Form.t()
  def new(page, element) do
    %Mechanize.Form{element: element, fields: parse_fields(page, element)}
  end

  defdelegate fetch(term, key), to: Map
  defdelegate get_and_update(data, key, function), to: Map
  defdelegate pop(data, key), to: Map

  def put_field(form, field, value) do
    put_field(form, DetachedField.new(field, value))
  end

  def put_field(form, field) do
    %__MODULE__{form | fields: [field | form.fields]}
  end

  def fields(nil) do
    raise ArgumentError, "form is nil"
  end

  def fields(form) do
    form.fields
  end

  defdelegate text_inputs(form), to: TextInput, as: :text_inputs_with
  defdelegate text_inputs_with(form, criteria), to: TextInput
  defdelegate fill_text(form, criteria), to: TextInput

  defdelegate checkboxes(form), to: Checkbox, as: :checkboxes_with
  defdelegate checkboxes_with(form, criteria), to: Checkbox
  defdelegate check_checkbox(form, criteria), to: Checkbox
  defdelegate uncheck_checkbox(form, criteria), to: Checkbox

  defdelegate image_inputs(form), to: ImageInput, as: :image_inputs_with
  defdelegate image_inputs_with(form, criteria), to: ImageInput
  defdelegate click_image(form, criteria), to: ImageInput

  defdelegate radio_buttons(form), to: RadioButton, as: :radio_buttons_with
  defdelegate radio_buttons_with(form, criteria), to: RadioButton
  defdelegate check_radio_button(form, criteria), to: RadioButton
  defdelegate uncheck_radio_button(form, criteria), to: RadioButton

  defdelegate select_lists(form), to: SelectList, as: :select_lists_with
  defdelegate select_lists_with(form, criteria), to: SelectList
  defdelegate select(form, criteria), to: SelectList
  defdelegate unselect(form, criteria), to: SelectList

  defdelegate submit_buttons(form), to: SubmitButton, as: :submit_buttons_with
  defdelegate submit_buttons_with(form, criteria), to: SubmitButton
  defdelegate click_button(form, criteria), to: SubmitButton

  def submit(form, button \\ nil) do
    case method(form) do
      :post ->
        Mechanize.Browser.request!(
          browser(form),
          :post,
          action_url(form),
          {:form, params(form.fields, button)}
        )

      :get ->
        Mechanize.Browser.request!(
          browser(form),
          :get,
          action_url(form),
          "",
          params: params(form.fields, button)
        )
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
