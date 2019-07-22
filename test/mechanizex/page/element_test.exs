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
      assert Element.attr(@subject, :type, default: "") == " TExT   "
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

  describe ".put_attr" do
    test "creates a new attribute if doesn't exists" do
      assert Element.put_attr(@subject, "value", "lero") == %Element{
               name: "input",
               attrs: [{"value", "lero"}, {"type", " TExT   "}]
             }
    end

    test "updates attribute if already exists" do
      assert Element.put_attr(@subject, "type", "lero") == %Element{
               name: "input",
               attrs: [{"type", "lero"}]
             }
    end
  end

  describe ".add_attr" do
    test "add new attribute even if exists" do
      assert Element.add_attr(@subject, "type", "lero") == %Element{
               name: "input",
               attrs: [{"type", "lero"}, {"type", " TExT   "}]
             }
    end
  end

  describe ".update_attr" do
    test "does nothing if attr name doesn't exists" do
      assert Element.update_attr(@subject, "value", "lero") == %Element{
               name: "input",
               attrs: [{"type", " TExT   "}]
             }
    end

    test "update attr if attr name exists" do
      assert Element.update_attr(@subject, "type", "lero") == %Element{
               name: "input",
               attrs: [{"type", "lero"}]
             }
    end
  end
end
