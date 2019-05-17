defmodule Mechanizex.Page do
  alias Mechanizex.{Request, Response}
  alias Mechanizex.Page.Link
  defstruct request: nil, response: nil, agent: nil, links: nil

  @type t :: %__MODULE__{
          request: Request.t(),
          response: Response.t(),
          agent: pid(),
          links: list(Link.t())
        }

  def body(page) do
    page.response.body
  end

  def agent(page) do
    page.agent
  end

  def html_parser(page) do
    page
    |> agent
    |> Mechanizex.Agent.html_parser()
  end

  defdelegate links(page), to: __MODULE__, as: :with_links

  def with_links(page, criterias \\ []), do: with_elements(page, [:a, :area], criterias)

  def with_elements(page, element_names, criterias \\ [])
  def with_elements(page, element_names, criterias) do
    page
    |> maybe_filter_by_selector(criterias)
    |> filter_by_element_names(element_names)
    |> filter_by_criteria(criterias)
  end

  defp maybe_filter_by_selector(page, css: selector) do
    search(page, selector)
  end

  defp maybe_filter_by_selector(page, _) do
    page
  end

  defp filter_by_element_names(%Mechanizex.Page{} = page, names) do
    names = Enum.map(names, &normalize/1)
    Enum.flat_map(names, fn name -> search(page, name) end)
  end

  defp filter_by_element_names(elements, names) do
    names = Enum.map(names, &normalize/1)
    Enum.filter(elements, fn e -> e.name in names end)
  end

  defp filter_by_criteria(elements, criterias) do
    criterias = Keyword.delete(criterias, :css)
    Enum.filter(elements, &all_criterias_meet?(&1, criterias))
  end

  defp all_criterias_meet?(element, [h | t]) do
    criteria_meet?(element, h) and all_criterias_meet?(element, t)
  end

  defp all_criterias_meet?(element, []) do
    true
  end

  defp criteria_meet?(element, {attr, value}) when is_atom(attr) do
    criteria_meet?(element, {normalize(attr), value})
  end

  defp criteria_meet?(element, {"text", value}) when is_binary(value) do
    element.text == value
  end

  defp criteria_meet?(element, {"text", value}) do
    element.text =~ value
  end

  defp criteria_meet?(element, {attr_name, value}) when is_binary(value) do
    element.attributes[attr_name] == value
  end

  defp criteria_meet?(element, {attr_name, value}) do
    attr_value = element.attributes[attr_name]
    attr_value != nil and attr_value =~ value
  end

  defp normalize(name) do
    if is_atom(name), do: Atom.to_string(name), else: name
  end

  defp delegate_parser(method, params) do
    params
    |> List.first()
    |> html_parser
    |> apply(method, params)
  end

  def search(page, selector), do: delegate_parser(:search, [page, selector])
end
