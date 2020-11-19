defmodule Mechanize.Form do
  @moduledoc """
  Encapsulates all functionalities related to form handling and submission.

  You can fetch a form from a page using `Mechanize.Page` module:
  ```
  form = Page.form_with(page, name: "login")
  ```
  """

  alias Mechanize.Page.Element

  alias Mechanize.Form.{
    TextInput,
    ArbitraryField,
    Checkbox,
    ParameterizableField,
    RadioButton,
    SubmitButton,
    Checkbox,
    ImageInput,
    SelectList
  }

  alias Mechanize.Query

  @derive [Mechanize.Page.Elementable]
  @enforce_keys [:element]
  defstruct element: nil,
            fields: []

  @typedoc """
  The HTML Form struct.
  """
  @type t :: %__MODULE__{
          element: Element.t(),
          fields: list()
        }

  @doc false
  def new(page, element) do
    %Mechanize.Form{element: element, fields: parse_fields(page, element)}
  end

  @doc false
  def put_field(form, field, value) do
    put_field(form, ArbitraryField.new(field, value))
  end

  def put_field(form, field) do
    %__MODULE__{form | fields: [field | form.fields]}
  end

  @doc """
  Returns all fields from the given form.
  """
  @spec fields(t()) :: list()
  def fields(nil) do
    raise ArgumentError, "form is nil"
  end

  def fields(form) do
    form.fields
  end

  @doc """
  Returns a list of text inputs or an empty list if no text inputs are found.

  See related `fill_text/2`.
  """
  @spec text_inputs(t()) :: [TextInput.t()]
  defdelegate text_inputs(form), to: TextInput, as: :text_inputs_with

  @doc """
  Returns a list of text inputs matching the given `query`.

  An empty list is returned in case no text input is matched by the given `query`.

  See related `fill_text/2`.

  ## Example
  Returns all text inputs with name "download".
  ```
  Form.text_inputs(form, name: "download")
  ```
  """
  @spec text_inputs_with(t(), Query.t()) :: [TextInput.t()]
  defdelegate text_inputs_with(form, query), to: TextInput

  @doc """
  Fill a text input with a given value.

  Text inputs are all inputs that can store text, not just limited to inputs of the `type="text"`.
  Mechanize treats color, date, datetime, email, hidden, month, number, password, range, search,
  tel, text, time, url, week and textarea as text inputs.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  You can fill a login form like this:
  ```
  form
  |> Form.fill_text(name: "username", with: "me@example.com")
  |> Form.fill_text(name: "password", with: "123456")
  |> Form.submit!()
  ```
  """
  @spec fill_text(t(), Query.t()) :: t()
  defdelegate fill_text(form, query), to: TextInput

  @doc """
  Returns a list of checkboxes or an empty list if no checkboxes are found.

  See related `check_checkbox/2` and `uncheck_checkbox/2`.
  """
  @spec checkboxes(t()) :: [Checkbox.t()]
  defdelegate checkboxes(form), to: Checkbox, as: :checkboxes_with

  @doc """
  Returns a list of checkboxes matching the given `query`.

  An empty list is returned in case no checkbox is matched by the given `query`.

  See related `check_checkbox/2` and `uncheck_checkbox/2`.

  ## Example
  Returns all checkboxes with name "download".
  ```
  Form.text_inputs(form, name: "download")
  ```
  """
  @spec checkboxes_with(t(), Query.t()) :: [Checkbox.t()]
  defdelegate checkboxes_with(form, query), to: Checkbox

  @doc """
  Check all checkboxes matching the given query.

  Raises `Mechanize.Query.BadQueryError` if no checkbox is matched by the query.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  You can check a checkbox and submit the for after:
  ```
  form
  |> Form.check_checkbox(name: "subscribe", value: "yes")
  |> Form.submit!()
  ```
  """
  @spec check_checkbox(t(), Query.t()) :: t()
  defdelegate check_checkbox(form, query), to: Checkbox

  @doc """
  Uncheck all checkboxes matching the given query.

  Raises `Mechanize.Query.BadQueryError` if no checkbox is matched by the query.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  You can uncheck a checkbox and submit the for after:
  ```
  form
  |> Form.uncheck_checkbox(name: "subscribe", value: "yes")
  |> Form.submit!()
  ```
  """
  @spec uncheck_checkbox(t(), Query.t()) :: t()
  defdelegate uncheck_checkbox(form, query), to: Checkbox

  @doc """
  Returns a list of image inputs or an empty list if no image input are found.

  See related `click_image!/2`.
  """
  @spec image_inputs(t()) :: [ImageInput.t()]
  defdelegate image_inputs(form), to: ImageInput, as: :image_inputs_with

  @doc """
  Returns a list of image inputs matching the given `query`.

  An empty list is returned in case no image input is matched by the given `query`.

  See related `click_image!/2`.

  ## Example
  Returns all image inputs with name "america".
  ```
  Form.image_inputs_with(form, name: "america")
  ```
  """
  @spec image_inputs_with(t(), Query.t()) :: [ImageInput.t()]
  defdelegate image_inputs_with(form, query), to: ImageInput

  @doc """
  Clicks on a image input matching the given query.

  Mechanize submits the form when an image input is clicked and a `Mechanize.Page` struct is
  returned as the result.

  Raises `Mechanize.Query.BadQueryError` if none or more than one image input is matched by query.

  Raises additional exceptions from `Mechanize.Browser.request!/5`.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  You can click on an image input:
  ```
  Form.click_image!(form, name: "america")
  ```

  You can also send x,y coordinates of the click:
  ```
  Form.click_image!(form, name: "america", x: 120, y: 120)
  ```
  """
  @spec click_image!(t(), Query.t()) :: Page.t()
  defdelegate click_image!(form, query), to: ImageInput

  @doc """
  Returns a list of radio buttons or an empty list if no radio buttons are found.

  See related `check_radio_button/2` and `uncheck_radio_button/2`.
  """
  @spec radio_buttons(t()) :: [RadioButton.t()]
  defdelegate radio_buttons(form), to: RadioButton, as: :radio_buttons_with

  @doc """
  Returns a list of radio buttons matching the given `query`.

  An empty list is returned in case no radio button is matched by the given `query`.

  See related `check_radio_button/2` and `uncheck_radio_button/2`.

  ## Example
  Returns all radio buttons with name "subscribe".
  ```
  Form.radio_buttons_with(form, name: "subscribe")
  ```
  """
  @spec radio_buttons_with(t(), Query.t()) :: [RadioButton.t()]
  defdelegate radio_buttons_with(form, query), to: RadioButton

  @doc """
  Checks a radio button matching the given query.

  When you check a radio button, Mechanize does the job to uncheck all radios from the same radio
  group (i.e. same name attribute) before check the radio button in the query.

  Raises `Mechanize.Query.BadQueryError` if no radio button is matched by query. Also raises if
  two or more radio buttons from the same radio group are checked by the query.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  Checks a radio button and submit the form:
  ```
  form
  |> Form.check_checkbox(name: "subscribe", value: "yes")
  |> Form.submit!()
  ```
  """
  @spec check_radio_button(t(), Query.t()) :: t()
  defdelegate check_radio_button(form, query), to: RadioButton

  @doc """
  Unchecks a radio button matching the given query.

  Raises `Mechanize.Query.BadQueryError` if no radio button is matched by query.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  Unchecks a radio button and submit the form:
  ```
  form
  |> Form.uncheck_checkbox(name: "subscribe", value: "yes")
  |> Form.submit!()
  ```
  """
  @spec uncheck_radio_button(t(), Query.t()) :: t()
  defdelegate uncheck_radio_button(form, query), to: RadioButton

  @doc """
  Returns a list of selects or an empty list if no selects are found.

  See related `select/2` and `unselect/2`.
  """
  @spec select_lists(t()) :: [SelectList.t()]
  defdelegate select_lists(form), to: SelectList, as: :select_lists_with

  @doc """
  Returns a list of selects matching the given `query`.

  An empty list is returned in case no selects is matched by the given `query`.

  See related `select/2` and `unselect/2`.

  ## Example
  Returns all selects with name "category".
  ```
  Form.select_lists_with(form, name: "category")
  ```
  """
  @spec select_lists_with(t(), Query.t()) :: [SelectList.t()]
  defdelegate select_lists_with(form, query), to: SelectList

  @doc """
  Selects an option from select list matching the given query.

  In case of selects without `multiple` attribute, Mechanize does the job to unselect all
  options from the same select list before it selects the given option.

  Raises `Mechanize.Query.BadQueryError` if no select or option is matched by query. Also raises
  when two or more options from the same select list are selected by the query and `multiple`
  attribute is not present.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Examples

  Selects an `option` with text "Option 1" on a `select` with `name="select1"`.

  ```elixir
  Form.select(form, name: "select1", option: "Option 1")
  ```

  Select by `value` attribute:

  ```elixir
  Form.select(form, name: "select1", option: [value: "1"])
  ```

  Or select the third option of a `select` (note that Mechanize uses a zero-based index):

  ```elixir
  Form.select(form, name: "select1", option: 2)
  ```
  """
  @spec select(t(), Query.t()) :: t()
  defdelegate select(form, query), to: SelectList

  @doc """
  Unselects an option from select list matching the given query.

  Raises `Mechanize.Query.BadQueryError` if no select or option is matched by query.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Examples

  By `option` with text "Option 1" on a `select` with `name="select1"`.

  ```elixir
  Form.select(form, name: "select1", option: "Option 1")
  ```

  By `value` attribute:

  ```elixir
  Form.select(form, name: "select1", option: [value: "1"])
  ```

  Or unselect the third option of a `select` (note that Mechanize uses a zero-based index):

  ```elixir
  Form.select(form, name: "select1", option: 2)
  ```
  """
  @spec unselect(t(), Query.t()) :: t()
  defdelegate unselect(form, query), to: SelectList

  @doc """
  Returns a list of submit buttons or an empty list if no submit buttons are found.

  See related `select/2` and `unselect/2`.
  """
  @spec submit_buttons(t()) :: [SubmitButton.t()]
  defdelegate submit_buttons(form), to: SubmitButton, as: :submit_buttons_with

  @doc """
  Returns a list of submit buttons matching the given `query`.

  An empty list is returned in case no submit button is matched by the given `query`.

  See related `click_button!/2`.

  ## Example
  Returns all submit buttons with name "send".
  ```
  Form.submit_buttons_with(form, name: "send")
  ```
  """
  @spec submit_buttons_with(t(), Query.t()) :: [SubmitButton.t()]
  defdelegate submit_buttons_with(form, query), to: SubmitButton

  @doc """
  Clicks on a submit button matching the given query.

  Mechanize submits the form when an submit button is clicked and a `Mechanize.Page` struct is
  returned as the result.

  Raises `Mechanize.Query.BadQueryError` if none or more than one submit button is matched by
  query.

  Raises additional exceptions from `Mechanize.Browser.request!/5`.

  See `Mechanize.Query` module documentation to know all query capabilities in depth.

  ## Example

  You can click on an submit button by its visible text:
  ```
  SubmitButton.click_button!(form, "OK")
  ```

  You can also click by attribute name:
  ```
  SubmitButton.click_button!(form, name: "submit1")
  ```

  Fill a login form and submit by clicking in "OK" submit button:
  ```
  form
  |> Form.fill_text(name: "username", with: "me@example.com")
  |> Form.fill_text(name: "password", with: "123456")
  |> Form.click_button!("OK")
  ```
  """
  @spec click_button!(t(), Query.t()) :: Page.t()
  defdelegate click_button!(form, query), to: SubmitButton

  @doc """
  Submits the given form.

  Mechanize submits the form and a `Mechanize.Page` struct is returned as the result.

  To simulate a form submited by a button click, pass the button as the second parameter
  or use any of our helper functions `click_button!/2` or
  `click_image!/2`. To simulate a form submited by enter key press, ignore the
  second parameter.

  Raises additional exceptions from `Mechanize.Browser.request!/5`.

  ## Example

  Simulate a login form submission by pressing "enter":
  ```
  form
  |> Form.fill_text(name: "username", with: "me@example.com")
  |> Form.fill_text(name: "password", with: "123456")
  |> Form.submit!()
  ```

  Simulate a login form submission by clicking the submit button:
  ```
  button =
    form
    |> Form.submit_buttons()
    |> List.first()

  form
  |> Form.fill_text(name: "username", with: "me@example.com")
  |> Form.fill_text(name: "password", with: "123456")
  |> Form.submit!(button)
  ```
  See `click_button!/2` for a simpler way to do this.
  """
  @spec submit!(t(), SubmitButton.t() | ImageInput.t(), keyword()) :: Page.t()
  def submit!(form, button \\ nil, opts \\ []) do
    {options, _opts} = Keyword.pop(opts, :options, [])

    case method(form) do
      :post ->
        Mechanize.Browser.request!(
          browser(form),
          :post,
          action_url(form),
          {:form, params(form.fields, button)},
          opts
        )

      :get ->
        Mechanize.Browser.request!(
          browser(form),
          :get,
          action_url(form),
          "",
          params: params(form.fields, button), options: options
        )
    end
  end

  defp method(form) do
    method =
      form
      |> Element.attr(:method)
      |> Kernel.||("")
      |> String.trim()
      |> String.downcase()

    if method == "post", do: :post, else: :get
  end

  defp action_url(form) do
    form
    |> Element.attr(:action)
    |> Kernel.||("")
    |> String.trim()
    |> (&URI.merge(form.element.page.url, &1)).()
    |> URI.to_string()
  end

  defp params(fields, button) do
    fields
    |> Enum.reject(&is_submit?/1)
    |> maybe_add_clicked_button(button)
    |> Enum.reject(fn f -> Element.attr_present?(f, :disabled) or f.name == nil end)
    |> Enum.flat_map(&ParameterizableField.to_param/1)
  end

  defp is_submit?(field) do
    match?(%SubmitButton{}, field) or match?(%ImageInput{}, field)
  end

  defp maybe_add_clicked_button(params, nil), do: params
  defp maybe_add_clicked_button(params, button), do: [button | params]

  defp browser(form) do
    form.element.page.browser
  end

  defp parse_fields(page, element) do
    element
    |> parse_inner_fields()
    |> parse_outer_fields(page, element)
    |> Enum.map(&create_field/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_inner_fields(element) do
    Query.search(element, "input, textarea, button, select")
  end

  defp parse_outer_fields(fields, page, element) do
    case Element.attr(element, :id) do
      nil ->
        fields

      form_id ->
        page
        |> Query.filter_out(~s(form[id="#{form_id}"]))
        |> Query.search(~s([form="#{form_id}"]))
        |> Kernel.++(fields)
    end
  end

  defp create_field(el) do
    tag = Element.name(el)
    type = Element.attr(el, :type, normalize: true)

    cond do
      type == "reset" ->
        nil

      tag == "button" and (type == "submit" or type == nil or type == "") ->
        SubmitButton.new(el)

      tag == "input" and type == "radio" ->
        RadioButton.new(el)

      tag == "input" and type == "checkbox" ->
        Checkbox.new(el)

      tag == "input" and type == "submit" ->
        SubmitButton.new(el)

      tag == "input" and type == "image" ->
        ImageInput.new(el)

      tag == "textarea" or tag == "input" ->
        TextInput.new(el)

      tag == "select" ->
        SelectList.new(el)

      true ->
        nil
    end
  end
end
