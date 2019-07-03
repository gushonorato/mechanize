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
    fields =
      if field_present?(form, field) do
        update_field(form.fields, field, value)
      else
        [DetachedField.new(field, value) | form.fields]
      end

    %Mechanizex.Form{form | fields: fields}
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
    Enum.reduce(form.fields, %{}, fn field, params ->
      Map.put_new(params, field.name, field.value)
    end)
  end

  defp agent(form) do
    form.element.page.agent
  end

  defp field_present?(%Mechanizex.Form{fields: fields}, field) do
    Enum.find(fields, fn %{label: label, name: name} ->
      label == field or name == field
    end)
  end

  defp update_field(fields, field, value) do
    Enum.map(fields, fn f ->
      if f.label == field or f.name == field do
        Map.put(f, :value, value)
      else
        f
      end
    end)
  end

  defp parse_fields(element) do
    element
    |> Query.with_elements([:input])
    |> Enum.reject(fn el -> Element.attr(el, :name) == nil end)
    |> Enum.map(&create_field/1)
  end

  defp create_field(%Element{name: :input} = element) do
    TextInput.new(element)
  end
end
