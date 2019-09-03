defmodule Mechanizex.Form.DetachedField do
  alias Mechanizex.Form.ParameterizableField

  @derive [ParameterizableField]
  @enforce_keys [:name, :value]
  defstruct name: nil, value: nil

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t()
        }

  def new(name, value) do
    %Mechanizex.Form.DetachedField{name: name, value: value}
  end
end
