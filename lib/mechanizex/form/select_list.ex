defmodule Mechanizex.Form.SelectList do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Form.Option
  alias Mechanizex.{Form, Query, Queryable}

  @derive [Queryable, Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, options: []

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          options: list()
        }

  def new(%Element{} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      label: Element.attr(el, :label),
      options: fetch_options(el)
    }
  end

  def options(%__MODULE__{} = select_list), do: options([select_list])
  def options(list), do: Enum.flat_map(list, & &1.options)

  defp fetch_options(el) do
    el
    |> Query.search("option")
    |> Enum.with_index()
    |> Enum.map(&Option.new(&1))
  end

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)
      use Mechanizex.Form.FieldMatcher, for: unquote(__MODULE__)
    end
  end

  def select(form, criteria) do
    {opts_criteria, criteria} = Keyword.pop(criteria, :options, [])

    update_select_lists_with(form, criteria, fn _select, option ->
      if Query.match?(option, opts_criteria) do
      else
          %Option{option | selected: true}
          %Option{option | selected: false}
      end
    end)
  end

  def update_select_lists(form, fun) do
    update_select_lists_with(form, [], fun)
  end

  def update_select_lists_with(form, criteria, fun) do
    Form.update_fields(form, __MODULE__, fn select ->
      options = Enum.map(select.options, &update_option(&1, select, criteria, fun))
      %__MODULE__{select | options: options}
    end)
  end

  defp update_option(option, select, criteria, fun) do
    if Query.match?(select, criteria) do
      fun.(select, option)
    else
      option
    end
  end
end
