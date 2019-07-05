defmodule Mechanizex.QueryTest do
  use ExUnit.Case, async: true
  alias Mechanizex.Query
  alias Mechanizex.Page.Element
  doctest Mechanizex.Query

  @subject [
    %Element{
      name: :a,
      attrs: %{href: "www.google.com", rel: "follow", disabled: "disabled"},
      text: "Google"
    },
    %Element{name: :a, attrs: %{href: "www.microsoft.com", rel: "nofollow"}, text: "Microsoft"},
    %Element{name: :area, attrs: %{href: "www.amazon.com", rel: "follow"}, text: "Amazon"}
  ]

  describe ".select" do
    test "only one selected by element name" do
      assert @subject
             |> Query.select([:area])
             |> Enum.map(&Element.text/1) == ["Amazon"]
    end

    test "more than one selected by element name" do
      assert @subject
             |> Query.select([:a])
             |> Enum.map(&Element.text/1) == ["Google", "Microsoft"]
    end

    test "only one selected by attribute" do
      assert @subject
             |> Query.select(:all, rel: "nofollow")
             |> Enum.map(&Element.text/1) == ["Microsoft"]
    end

    test "select without attributes" do
      assert @subject
             |> Query.select(:all, disabled: nil)
             |> Enum.map(&Element.text/1) == ["Microsoft", "Amazon"]
    end

    test "more than one selected by attribute" do
      assert @subject
             |> Query.select(:all, rel: "follow")
             |> Enum.map(&Element.text/1) == ["Google", "Amazon"]
    end

    test "both by attributes and element name" do
      assert @subject
             |> Query.select([:a], rel: "follow")
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and text" do
      assert @subject
             |> Query.select([:a], text: "Google")
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "select by string only text is a exact match" do
      assert @subject
             |> Query.select(:all, text: "Googl")
             |> Enum.map(&Element.text/1) == []
    end

    test "select by string only attribute is a exact match" do
      assert @subject
             |> Query.select(:all, href: "google")
             |> Enum.map(&Element.text/1) == []
    end

    test "select all using :all keyword" do
      assert @subject
             |> Query.select(:all)
             |> Enum.map(&Element.text/1) == ["Google", "Microsoft", "Amazon"]
    end

    test "select all using multiple element names" do
      assert @subject
             |> Query.select([:a, :area])
             |> Enum.map(&Element.text/1) == ["Google", "Microsoft", "Amazon"]
    end

    test "none selected" do
      assert @subject
             |> Query.select(:all, rel: "strange")
             |> Enum.map(&Element.text/1) == []
    end

    test "only one selected by attribute with regex " do
      assert @subject
             |> Query.select(:all, rel: ~r/no/)
             |> Enum.map(&Element.text/1) == ["Microsoft"]
    end

    test "more than one selected by attribute with regex" do
      assert @subject
             |> Query.select(:all, href: ~r/www\.am|www\.goo/)
             |> Enum.map(&Element.text/1) == ["Google", "Amazon"]
    end

    test "both by attributes and element name with regex" do
      assert @subject
             |> Query.select([:a], href: ~r/google/)
             |> Enum.map(&Element.text/1) == ["Google"]
    end

    test "both by attributes and text with regex" do
      assert @subject
             |> Query.select([:a], text: ~r/google/i)
             |> Enum.map(&Element.text/1) == ["Google"]
    end
  end
end
