defmodule Mechanizex.Form.SelectList do
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.SelectListOptions
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
    |> Enum.map(&SelectListOptions.new(&1))
  end

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)
      use Mechanizex.Form.FieldMatcher, for: unquote(__MODULE__)
      use Mechanizex.Form.FieldUpdater, for: unquote(__MODULE__)
    end
  end
end

defimpl Mechanizex.Page.Elementable, for: Mechanizex.Form.SelectList do
  defdelegate page(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate name(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate text(e), to: Mechanizex.Page.Elementable.LabeledElementable
  defdelegate attrs(e), to: Mechanizex.Page.Elementable.LabeledElementable
end
