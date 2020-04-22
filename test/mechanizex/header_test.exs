defmodule Mechanizex.HeaderTest do
  use ExUnit.Case, async: true
  alias Mechanizex.Header

  doctest Mechanizex.Header

  @subject [{"content-type", "text/html"}, {"location", "https://example.com"}]

  describe ".merge" do
    test "raise if any headers1 is nil" do
      assert_raise(ArgumentError, "headers1 is nil", fn ->
        Header.merge(nil, [])
      end)
    end

    test "ignore if headers2 is nil" do
      assert Header.merge(@subject, nil) == @subject
    end

    test "merges empty header with non-empty" do
      assert Header.merge(@subject, []) == @subject
      assert Header.merge([], @subject) == @subject
    end

    test "merges non-empty headers" do
      assert Header.merge(@subject, [{"header", "value"}]) == [
               {"header", "value"},
               {"content-type", "text/html"},
               {"location", "https://example.com"}
             ]
    end

    test "updates headers1 value on key clash" do
      assert Header.merge(@subject, [{"content-type", "application/json"}]) == [
               {"content-type", "application/json"},
               {"location", "https://example.com"}
             ]
    end
  end

  describe ".prepend/2" do
    test "raises if headers are nil" do
      assert_raise(ArgumentError, "headers is nil", fn ->
        Header.prepend(nil, {"content-type", "text/html"})
      end)
    end

    test "ignore if prepended header is nil" do
      assert Header.prepend(@subject, nil) == @subject
    end
  end

  describe ".prepend/3" do
    test "raises if headers are nil" do
      assert_raise(ArgumentError, "headers is nil", fn ->
        Header.prepend(nil, "content-type", "text/html")
      end)
    end

    test "raises if key is nil" do
      assert_raise(ArgumentError, "key is nil", fn ->
        Header.prepend(@subject, nil, "text/html")
      end)
    end

    test "raises if value is nil" do
      assert_raise(ArgumentError, "value is nil", fn ->
        Header.prepend(@subject, "content-type", nil)
      end)
    end

    test "downcase header key on prepend" do
      assert Header.prepend(@subject, "Connection", "Keep-alive") == [
               {"connection", "Keep-alive"},
               {"content-type", "text/html"},
               {"location", "https://example.com"}
             ]
    end

    test "prepends duplicated header key" do
      assert Header.prepend(@subject, "location", "https://example2.com") == [
               {"location", "https://example2.com"},
               {"content-type", "text/html"},
               {"location", "https://example.com"}
             ]
    end
  end

  describe ".delete" do
    test "raises if headers are nil" do
      assert_raise ArgumentError, "headers is nil", fn ->
        Header.delete(nil, "content-type")
      end
    end

    test "ignores if key is nil" do
      assert Header.delete(@subject, nil) == @subject
    end

    test "delete header by key" do
      assert Header.delete(@subject, "content-type") == [
               {"location", "https://example.com"}
             ]
    end

    test "delete key case insensitive" do
      assert Header.delete(@subject, "Location") == [
               {"content-type", "text/html"}
             ]
    end
  end

  describe ".put/2" do
    test "raises if headers are nil" do
      assert_raise ArgumentError, "headers is nil", fn ->
        assert Header.put(nil, {"content-type", "text/html"})
      end
    end

    test "ignore if put header is nil" do
      assert Header.put(@subject, nil) == @subject
    end
  end

  describe ".put/3" do
    test "raises if headers are nil" do
      assert_raise ArgumentError, "headers is nil", fn ->
        Header.put(nil, "content-type", "text/html")
      end
    end

    test "raises if key is nil" do
      assert_raise ArgumentError, "key is nil", fn ->
        Header.put(@subject, nil, "text/html")
      end
    end

    test "raises if value is nil" do
      assert_raise ArgumentError, "value is nil", fn ->
        Header.put(@subject, "content-type", nil)
      end
    end

    test "downcase header key and adds to the end of the headers list" do
      assert Header.put(@subject, "Connection", "Keep-alive") == [
               {"content-type", "text/html"},
               {"location", "https://example.com"},
               {"connection", "Keep-alive"}
             ]
    end

    test "updates if key already exits" do
      assert Header.put(@subject, "content-type", "text/html") == [
               {"content-type", "text/html"},
               {"location", "https://example.com"}
             ]
    end
  end

  describe ".take" do
    test "raises if headers are nil" do
      assert_raise ArgumentError, "headers is nil", fn ->
        Header.take(nil, "connection")
      end
    end

    test "returns nil key is nil" do
      assert Header.take(@subject, nil) == nil
    end

    test "retuns nil if header key is not present" do
      assert Header.take(@subject, "connection") == nil
    end

    test "returns tuple {header taken, headers without header taken} ignoring case" do
      assert Header.take(@subject, "Content-type") ==
               {{"content-type", "text/html"}, [{"location", "https://example.com"}]}
    end
  end

  describe ".get_value" do
    test "raises if headers are nil" do
      assert_raise ArgumentError, "headers is nil", fn ->
        Header.get_value(nil, "content-type")
      end
    end

    test "return nil if key is nil" do
      assert Header.get_value(@subject, nil) == nil
    end

    test "return header value of the first matched header by key" do
      subject = [{"content-type", "text/html"}, {"content-type", "application/json"}]
      assert Header.get_value(subject, "content-type") == "text/html"
    end

    test "return header value from case insensitive key" do
      assert Header.get_value(@subject, "Content-Type") == "text/html"
    end

    test "retuns nil if header key is not present" do
      assert Header.get_value(@subject, "connection") == nil
    end
  end

  describe ".get_all" do
    test "raises if headers is nil" do
      assert_raise ArgumentError, "headers is nil", fn ->
        Header.get_all(nil, "content-type")
      end
    end

    test "return empty list if key is nil" do
      assert Header.get_all(@subject, nil) == []
    end

    test "return all headers matched by case insensitive key" do
      subject = [
        {"content-type", "text/html"},
        {"content-type", "application/json"},
        {"location", "https://example.com"}
      ]

      assert Header.get_all(subject, "Content-Type") == [
               {"content-type", "text/html"},
               {"content-type", "application/json"}
             ]
    end

    test "retuns empty list if header key is not present" do
      assert Header.get_all(@subject, "connection") == []
    end
  end
end
