defmodule Mechanizex.Form do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{TextInput, DetachedField}
  alias Mechanizex.{Query, Request}

  @derive [Elementable]
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

  def submit(form) do
    Mechanizex.Agent.request!(agent(form), %Request{
      method: method(form),
      url: action_url(form),
      params: params(form)
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

  defp params(form) do
    form.fields
    |> Enum.map(fn field -> {field.name, field.value} end)
  end

  defp agent(form) do
    form.element.page.agent
  end

  defp parse_fields(element) do
    element
    |> Query.search("input, textarea")
    |> Enum.reject(fn el -> Element.attr(el, :name) == nil end)
    |> Enum.map(&create_field/1)
  end

  defp create_field(%Element{name: :input} = element) do
    %TextInput{
      element: element,
      name: Element.attr(element, :name),
      value: Element.attr(element, :value)
    }
  end

  defp create_field(%Element{name: :textarea} = element) do
    %TextInput{
      element: element,
      name: Element.attr(element, :name),
      value: Element.text(element)
    }
  end
end
