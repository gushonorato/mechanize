defmodule Mechanizex.Form.ImageInputTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Page.Element
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/image_input_test.html")
    {:ok, Map.put(vars, :form, Page.form_with(page))}
  end

  describe ".image_inputs" do
    test "retreve all image buttons", %{form: form} do
      inputs = Form.image_inputs(form)

      assert Enum.map(inputs, &{&1.name, &1.x, &1.y}) == [
               {"map1", 0, 0},
               {"map2", 0, 0}
             ]
    end

    test "elements loaded", %{form: form} do
      inputs = Form.image_inputs(form)

      refute Enum.empty?(inputs)
      Enum.each(inputs, fn image -> assert %Element{} = image.element end)
    end
  end
end
