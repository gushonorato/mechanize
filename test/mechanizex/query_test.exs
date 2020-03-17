defmodule Mechanizex.QueryTest do
  use ExUnit.Case, async: true
  alias Mechanizex.Page.Element
  alias Mechanizex.Query
  doctest Mechanizex.Query

  @subject [
    %Element{
      name: "a",
      attrs: [{"href", "www.google.com"}, {"rel", "follow"}, {"disabled", "disabled"}],
      text: "Google"
    },
    %Element{
      name: "a",
      attrs: [{"href", "www.microsoft.com"}, {"rel", "nofollow"}],
      text: "Microsoft"
    },
    %Element{name: "area", attrs: [{"href", "www.amazon.com"}, {"rel", "follow"}, {"alt", "Amazon"}]}
  ]

  describe ".match?" do
    test "only one selected by element name" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tags: [:area]))
             |> Enum.map(&Element.attr(&1, :alt)) == ["Amazon"]
    end

    test "more than one selected by element name" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tag: :a))
             |> Enum.map(&Element.text/1) == ["Google", "Microsoft"]
    end

    test "only one selected by attribute" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, rel: "nofollow"))
             |> Enum.map(&Element.text/1) == ["Microsoft"]
    end

    test "more than one selected by attribute" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, rel: "follow"))
             |> Enum.map(&Element.attr(&1, :href)) == ["www.google.com", "www.amazon.com"]
    end

    test "select without attributes" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, disabled: nil))
             |> Enum.map(&Element.attr(&1, :href)) == ["www.microsoft.com", "www.amazon.com"]
    end

    test "select without attributes using boolean criteria" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, disabled: false))
             |> Enum.map(&Element.attr(&1, :href)) == ["www.microsoft.com", "www.amazon.com"]
    end

    test "select elements if attribute is present using boolean criteria" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, disabled: true))
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and element name" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tag: :a, rel: "follow"))
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and text" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tag: :a, text: "Google"))
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "select by string only text is a exact match" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, text: "Googl"))
             |> Enum.map(&Element.text/1) == []
    end

    test "select by string only attribute is a exact match" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, href: "google"))
             |> Enum.map(&Element.text/1) == []
    end

    test "select all using multiple element names" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tags: [:a, :area]))
             |> Enum.map(&Element.attr(&1, :href)) == ["www.google.com", "www.microsoft.com", "www.amazon.com"]
    end

    test "none selected" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, rel: "strange"))
             |> Enum.map(&Element.text/1) == []
    end

    test "only one selected by attribute with regex" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, rel: ~r/no/))
             |> Enum.map(&Element.text/1) == ["Microsoft"]
    end

    test "more than one selected by attribute with regex" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, href: ~r/www\.am|www\.goo/))
             |> Enum.map(&Element.attr(&1, :href)) == ["www.google.com", "www.amazon.com"]
    end

    test "both by attributes and element name with regex" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tag: :a, href: ~r/google/))
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and text with regex" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, tag: :a, href: ~r/google/))
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "by text with regex" do
      assert @subject
             |> Enum.filter(&Query.match?(&1, text: ~r/Googl/))
             |> Enum.map(&Element.text/1) == ["Google"]
    end
  end
end
