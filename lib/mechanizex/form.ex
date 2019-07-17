defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{TextInput, DetachedField, Submit}
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

  def fill_field(form, field, with: value) do
    updated_form = update_field(form, field, value)
    if updated_form == form, do: add_field(form, field, value), else: updated_form
  end

  def update_field(form, field, value) do
    Map.put(form, :fields, do_update_field(form.fields, field, value))
  end

  defp do_update_field([], _, _) do
    []
  end

  defp do_update_field([field | t], field_key, value) do
    if field.name == field_key do
      [%{field | value: value} | t]
    else
      [field | do_update_field(t, field_key, value)]
    end
  end

  def add_field(form, field, value) do
    Map.put(form, :fields, [DetachedField.new(field, value) | form.fields])
  end

  def delete_field(form, field_name) do
    Map.put(form, :fields, Enum.reject(form.fields, fn field -> field.name == field_name end))
  end

  def fields(form) do
    form.fields
  end

  def submit_buttons(form), do: Enum.filter(form.fields, &Submit.is_submit?/1)

  def submit(form, button \\ nil) do
    Mechanizex.Agent.request!(agent(form), %Request{
      method: method(form),
      url: action_url(form),
      params: params(form.fields, button)
    })
  end

  def click_button(form, locator) do
    button =
      form
      |> submit_buttons()
      |> Enum.filter(fn %Submit{text: text, id: id, name: name} ->
        locator == text or locator == id or locator == name
      end)
      |> List.first()

    case button do
      nil ->
        raise Mechanizex.Form.ButtonNotFound,
          message: "Unable to click on button with id, name or text equal to \"#{locator}\"."

      _ ->
        submit(form, button)
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
    |> Enum.reject(&Submit.is_submit?/1)
    |> maybe_add_submit_button(button)
    |> Enum.reject(fn f -> f.disabled == true or f.name == nil end)
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
        Submit.new(el)

      name == "input" and (type == "submit" or type == "image") ->
        Submit.new(el)

      name == "textarea" or name == "input" ->
        TextInput.new(el)

      true ->
        nil
    end
  end
end

defmodule Mechanizex.Form.ButtonNotFound do
  defexception [:message]
end
