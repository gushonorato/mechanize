defmodule Mechanizex.Form.DetachedField do
  alias Mechanizex.Form.ParameterizableField

  @derive [ParameterizableField]
  @enforce_keys [:name, :value]
  defstruct label: nil, name: nil, value: nil

  @type t :: %__MODULE__{
          label: String.t(),
          name: String.t(),
          value: String.t()
        }

  def new(name, value) do
    %Mechanizex.Form.DetachedField{label: nil, name: name, value: value}
  end
end
