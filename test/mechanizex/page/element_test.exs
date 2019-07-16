defmodule Mechanizex.Page.ElementTest do
  use ExUnit.Case, async: true
  alias Mechanizex.Page.Element

  @subject %Element{
    name: "input",
    attrs: [{"type", " TExT   "}]
  }

  describe ".attr" do
    test "value" do
      assert Element.attr(@subject, :type) == " TExT   "
    end

    test "nonexistent attribute" do
      assert Element.attr(@subject, :value) == nil
    end

    test "default value" do
      assert Element.attr(@subject, :value, default: "") == ""
    end

    test "ignore default value if attribute exists" do
      Element.attr(@subject, :type, default: "") == " TExT   "
    end

    test "normalized value" do
      assert Element.attr(@subject, :type, normalize: true) == "text"
    end

    test "normalize a nonexistent attribute" do
      assert Element.attr(@subject, :value, normalize: true) == nil
    end

    test "normalize default value" do
      assert Element.attr(@subject, :value, default: " LERo", normalize: true) == "lero"
    end
  end

end
