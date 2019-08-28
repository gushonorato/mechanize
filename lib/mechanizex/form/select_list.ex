defmodule Mechanizex.Form.SelectList do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Form.{Option, InconsistentFormError}
  alias Mechanizex.Query
  alias Mechanizex.Query.BadCriteriaError
  alias Mechanizex.{Form, Query, Queryable}

  use Mechanizex.Form.FieldMatcher
  use Mechanizex.Form.FieldUpdater

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

  def options(%__MODULE__{} = select), do: options([select])
  def options(selects), do: Enum.flat_map(selects, & &1.options)

  def selected_options(selects) do
    selects
    |> options()
    |> Enum.filter(fn opt -> opt.selected end)
  end

  defp fetch_options(el) do
    el
    |> Query.search("option")
    |> Enum.with_index()
    |> Enum.map(&Option.new(&1))
  end

  def update_options_with(form, criteria, opts_criteria, fun) do
    Form.update_select_lists_with(form, criteria, fn select ->
      assert_options_found(select.options, opts_criteria)
      %__MODULE__{select | options: Enum.map(select.options, &fun.(select, &1))}
    end)
  end

  def select(form, criteria) do
    {opts_criteria, criteria} = Keyword.pop(criteria, :options, [])
    assert_select_found(form, criteria)

    form
    |> update_options_with(criteria, opts_criteria, fn select, opt ->
      cond do
        Query.match?(opt, opts_criteria) ->
          %Option{opt | selected: true}

        Element.attr_present?(select, :multiple) ->
          opt

        true ->
          %Option{opt | selected: false}
      end
    end)
    |> assert_single_option_selected
  end

  def unselect(form, criteria) do
    {opts_criteria, criteria} = Keyword.pop(criteria, :options, [])
    assert_select_found(form, criteria)

    update_options_with(form, criteria, opts_criteria, fn _select, opt ->
      if Query.match?(opt, opts_criteria) do
        %Option{opt | selected: false}
      else
        opt
      end
    end)
  end

  defp assert_select_found(form, criteria) do
    if Form.select_lists_with(form, criteria) == [],
      do: raise(BadCriteriaError, "No select found with criteria #{inspect(criteria)}")
  end

  defp assert_options_found(options, criteria) do
    if Enum.filter(options, &Query.match?(&1, criteria)) == [],
      do: raise(BadCriteriaError, "No option found with criteria #{inspect(criteria)} in select")
  end

  defp assert_single_option_selected(form) do
    form
    |> Form.select_lists_with(multiple: false)
    |> Stream.map(fn select -> {select.name, length(selected_options(select))} end)
    |> Stream.filter(fn {_, selected} -> selected > 1 end)
    |> Enum.map(fn {name, _} -> name end)
    |> case do
      [] ->
        form

      names ->
        raise InconsistentFormError, "Multiple selected options on single select list with name(s) #{names}"
    end
  end
end

defimpl Mechanizex.Form.ParameterizableField, for: Mechanizex.Form.SelectList do
  alias Mechanizex.Form.SelectList

  def to_param(select) do
    case SelectList.selected_options(select) do
      [] ->
        option =
          select
          |> SelectList.options()
          |> List.first()

        [{select.name, option.value}]

      options ->
        options
        |> Enum.map(&{select.name, &1.value})
    end
  end
end
