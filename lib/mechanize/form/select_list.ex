defmodule Mechanize.Form.SelectList do
  @moduledoc false

  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Form.Option
  alias Mechanize.Query
  alias Mechanize.Query.BadQueryError

  @derive [Elementable]
  @enforce_keys [:element]
  defstruct element: nil, name: nil, options: []

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          options: list()
        }

  def new(%Element{} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      options: fetch_options(el)
    }
  end

  def select_lists_with(form, query \\ []) do
    get_in(form, [
      Access.key(:fields),
      Access.filter(&Query.match?(&1, __MODULE__, query))
    ])
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

  defp assert_select_found(form, query) do
    selects =
      get_in(form, [Access.key(:fields), Access.filter(&Query.match?(&1, __MODULE__, query))])

    if selects == [] do
      raise(BadQueryError, "No select found with query #{inspect(query)}")
    end

    form
  end

  defp assert_options_found(form, query, opts_query) do
    options =
      get_in(form, [
        Access.key(:fields),
        Access.filter(&Query.match?(&1, __MODULE__, query)),
        Access.key(:options),
        Access.filter(&Query.match_query?(&1, opts_query))
      ])

    if options == [[]] do
      raise(BadQueryError, "No option found with query #{inspect(query)} in select")
    end

    form
  end

  def select(form, query \\ [])

  def select(nil, _query), do: raise(ArgumentError, "form is nil")

  def select(form, query) do
    {opts_query, query} = Keyword.pop(query, :option, [])

    form
    |> assert_select_found(query)
    |> assert_options_found(query, opts_query)
    |> ensure_single_selected(query)
    |> update_select(query, opts_query, true)
    |> assert_single_option_selected()
  end

  defp ensure_single_selected(form, query) do
    query = Keyword.put(query, :multiple, false)

    put_in(
      form,
      [
        Access.key(:fields),
        Access.filter(&Query.match?(&1, __MODULE__, query)),
        Access.key(:options),
        Access.all(),
        Access.key(:selected)
      ],
      false
    )
  end

  defp update_select(form, query, opts_query, selected) do
    put_in(
      form,
      [
        Access.key(:fields),
        Access.filter(&Query.match?(&1, __MODULE__, query)),
        Access.key(:options),
        Access.filter(&Query.match_query?(&1, opts_query)),
        Access.key(:selected)
      ],
      selected
    )
  end

  def unselect(form, query \\ [])
  def unselect(nil, _query), do: raise(ArgumentError, "form is nil")

  def unselect(form, query) do
    {opts_query, query} = Keyword.pop(query, :option, [])

    form
    |> assert_select_found(query)
    |> assert_options_found(query, opts_query)
    |> update_select(query, opts_query, false)
  end

  defp assert_single_option_selected(form) do
    form
    |> select_lists_with(multiple: false)
    |> Stream.map(fn select -> {select.name, length(selected_options(select))} end)
    |> Stream.filter(fn {_, selected} -> selected > 1 end)
    |> Enum.map(fn {name, _} -> name end)
    |> case do
      [] ->
        form

      names ->
        raise BadQueryError,
              "Multiple selected options on single select list with name(s) #{names}"
    end
  end
end

defimpl Mechanize.Form.ParameterizableField, for: Mechanize.Form.SelectList do
  alias Mechanize.Form.SelectList

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
