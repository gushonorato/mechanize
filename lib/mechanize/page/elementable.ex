defprotocol Mechanize.Page.Elementable do
  @moduledoc """
  Protocol used to extract element data using `Mechanize.Page.Element` module.

  To implement this protocol you have to implement a single function
  `Mechanize.Page.Elementable.element/1`.

  ## Example

  Implementation of Elementable for a `Mechanize.Form`:

  ```
  defmodule Mechanize.Form do
    defstruct element: nil,
              fields: []
  end

  defimpl Mechanize.Page.Elementable, for: Mechanize.Form do
    def element(e), do: e.element
  end
  ```
  """

  @doc """
  Returns an `Mechanize.Page.Element` struct from elementable data.
  """
  @spec element(any) :: Element.t()
  def element(elementable)
end

defimpl Mechanize.Page.Elementable, for: Any do
  def element(elementable), do: elementable.element
end
