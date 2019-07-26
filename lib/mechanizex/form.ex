defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{TextInput, DetachedField, SubmitButton, RadioButton, Checkbox}
  alias Mechanizex.{Query, Request}
  import Mechanizex.Query, only: [query: 1]

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

  defmodule MultipleFormComponentsFound do
    defexception [:message]
  end

  defmodule FormComponentNotFound do
    defexception [:message]
  end

  defmodule InconsistentForm do
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

  def remove_fields(form, fun) do
    %__MODULE__{form | fields: Enum.reject(form.fields, fun)}
  end

  def fields(form) do
    form.fields
  end

  def submit_buttons(form, criteria \\ [])
  def submit_buttons(form, criteria), do: submit_buttons_with(form, criteria)
  def submit_buttons_with(form, criteria), do: fields_with(form, SubmitButton, criteria)

  def radio_buttons(form, criteria \\ [])
  def radio_buttons(form, criteria), do: radio_buttons_with(form, criteria)
  def radio_buttons_with(form, criteria), do: fields_with(form, RadioButton, criteria)

  def fields_with(form, type, fun) when is_function(fun) do
    form.fields
    |> Stream.filter(&type.is_type?/1)
    |> Enum.filter(fun)
  end

  def fields_with(form, type, criteria) do
    form.fields
    |> Stream.filter(&type.is_type?/1)
    |> Enum.filter(query(attrs: criteria))
  end

  def check_radio_button!(form, criteria) do
    case check_radio_button(form, criteria) do
      {:error, error} -> raise error
      {:ok, form} -> {:ok, form}
    end
  end

  def check_radio_button(form, criteria) do
    update_radio_buttons_with(form, criteria, fn field, matched_fields ->
      group_name =
        matched_fields
        |> List.first()
        |> Element.attr(:name)

      cond do
        field in matched_fields ->
          %RadioButton{field | checked: true}

        field.name == group_name ->
          %RadioButton{field | checked: false}

        true ->
          field
      end
    end)
  end

  def uncheck_radio_button!(form, criteria) do
    case uncheck_radio_button(form, criteria) do
      {:error, error} -> raise error
      {:ok, form} -> {:ok, form}
    end
  end

  def uncheck_radio_button(form, criteria) do
    update_radio_buttons_with(form, criteria, fn field, matched_fields ->
      if field in matched_fields do
        %RadioButton{field | checked: false}
      else
        field
      end
    end)
  end

  def update_radio_buttons_with(form, criteria, fun) do
    form
    |> radio_buttons(criteria)
    |> case do
      [] ->
        {:error, %FormComponentNotFound{message: "Radio button with criteria #{inspect(criteria)} not found"}}

      radios ->
        form
        |> update_fields(fn field -> if RadioButton.is_type?(field), do: fun.(field, radios), else: field end)
        |> assert_single_radio_in_group_checked()
    end
  end

  defp assert_single_radio_in_group_checked(form) do
    radio_names =
      form
      |> radio_buttons(fn radio -> radio.checked end)
      |> Enum.group_by(&Element.attr(&1, :name))
      |> Enum.filter(fn {_, v} -> length(v) > 1 end)
      |> Enum.map(fn {k, _} -> k end)

    if Enum.empty?(radio_names) do
      {:ok, form}
    else
      radio_names = Enum.join(radio_names, ",")

      {:error,
       %InconsistentForm{
         message: "Multiple radio buttons with same name (#{radio_names}) are checked"
       }}
    end
  end

  def check_radio_button!(form, criteria) do
    case check_radio_button(form, criteria) do
      {:error, error} -> raise error
      {:ok, form} -> form
    end
  end

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
    |> Enum.reject(&SubmitButton.is_type?/1)
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

      name == "input" and type == "radio" ->
        RadioButton.new(el)

      name == "input" and type == "checkbox" ->
        Checkbox.new(el)

      name == "input" and (type == "submit" or type == "image") ->
        SubmitButton.new(el)

      name == "textarea" or name == "input" ->
        TextInput.new(el)

      true ->
        nil
    end
  end
end
