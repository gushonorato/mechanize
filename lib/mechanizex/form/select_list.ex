defmodule Mechanizex.Form.SelectList do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.SelectListOption
  alias Mechanizex.Form
  alias Mechanizex.Criteria

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
    |> Criteria.search("option")
    |> Enum.with_index()
    |> Enum.map(&SelectListOption.new(&1))
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
      if Criteria.match?(option, opts_criteria) do
        %SelectListOption{option | selected: true}
      else
        %SelectListOption{option | selected: false}
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
    if Criteria.match?(select, criteria) do
      fun.(select, option)
    else
      option
    end
  end
end

defimpl Mechanizex.Page.Elementable, for: Mechanizex.Form.SelectList do
  defdelegate page(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate name(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate text(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate attrs(e), to: Mechanizex.Page.Elementable.LabeledElementable
end
