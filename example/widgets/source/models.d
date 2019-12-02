module models;

import std.typecons : Nullable;
import std.json : JSONValue, JSONType, parseJSON;
import std.format;
import std.algorithm : map;
import std.array : array;
import std.traits;
import std.meta : Filter, staticMap;

enum AlignContent: string {
    flexStart = "flex-start",
    flexEnd = "flex-end",
    center = "center",
    spaceBetween = "space-between",
    spaceAround = "space-around",
    spaceEvenly = "space-evenly",
    stretch = "stretch",
    inherit = "inherit",
    initial = "initial",
    unset = "unset"
}

enum AlignItems: string {
    flexStart = "flex-start",
    flexEnd = "flex-end",
    center = "center",
    baseline = "baseline",
    stretch = "stretch",
    inherit = "inherit",
    initial = "initial",
    unset = "unset"
}

enum AlignSelf: string {
    auto_ = "auto",
    flexStart = "flex-start",
    flexEnd = "flex-end",
    center = "center",
    baseline = "baseline",
    stretch = "stretch",
    inherit = "inherit",
    initial = "initial",
    unset = "unset"
}

enum JustifyContent: string {
    flexStart = "flex-start",
    flexEnd = "flex-end",
    center = "center",
    spaceBetween = "space-between",
    spaceAround = "space-around",
    inherit = "inherit",
    initial = "initial",
    unset = "unset"
}

enum Overflow: string {
    visible = "visible",
    hidden = "hidden",
    scroll = "scroll",
    auto_ = "auto",
    inherit = "inherit",
    initial = "initial",
    unset = "unset"
}

enum Visibility: string {
    visible = "visible",
    hidden = "hidden",
    inherit = "inherit",
    initial = "initial",
    unset = "unset"
}

enum BoxStyle: string {
    success = "success",
    info = "info",
    warning = "warning",
    danger = "danger",
    none = ""
}

enum ButtonStyle: string {
    primary = "primary",
    success = "success",
    info = "info",
    warning = "warning",
    danger = "danger",
    none = ""
}

enum Orientation : string {
    horizontal = "horizontal",
    vertical = "vertical"
}
// NOTE: the enums above aren't used in the models below. Instead plain strings are used.
// This is because of https://issues.dlang.org/show_bug.cgi?id=20410
// Effectively sumtype (by use of ReplaceTypeUnless) decays them into string, causing errors

// Models can reference to another Widget. The reference is a prepended string to a Widget's commId
auto makeReference(string commId) @safe {
    return "IPY_MODEL_"~commId;
}

struct Reference(T) {
    string value;
    alias value this;
}

alias typeOf(alias T) = typeof(T);
// To instantiate a Widget!Model we need to also instantiate a Widget!T for each model that is referenced.
// This template exposed Names and Types which contain the name and type of each Referenced model for a given Model.
template getReferenceModels(T) {
    enum isReference(string name) = is(typeof(__traits(getMember, T, name)) : Reference!R, R);
    alias getSymbol(string name) = __traits(getMember, T, name);
    alias extractModelType(T) = TemplateArgsOf!(T)[0];
    alias Names = Filter!(isReference, __traits(allMembers, T));
    alias Types = staticMap!(extractModelType, staticMap!(typeOf,staticMap!(getSymbol,  Names)));
}

alias BarStyle = BoxStyle;

struct LayoutModel {
    enum _model_module = "@jupyter-widgets/base"; // The namespace for the model.
    enum _model_module_version = "1.0.0"; // A semver requirement for namespace version containing the model.
    enum _model_name = "LayoutModel";
    enum _view_module = "@jupyter-widgets/base";
    enum _view_module_version = "1.0.0";
    enum _view_name = "LayoutView";
    Nullable!(string) align_content; // The align-content CSS attribute.
    Nullable!(string) align_items; // The align-items CSS attribute.
    Nullable!(string) align_self; // The align-self CSS attribute.
    Nullable!(string) border; // The border CSS attribute.
    Nullable!(string) bottom; // The bottom CSS attribute.
    Nullable!(string) display; // The display CSS attribute.
    Nullable!(string) flex; // The flex CSS attribute.
    Nullable!(string) flex_flow; // The flex-flow CSS attribute.
    Nullable!(string) height; // The height CSS attribute.
    Nullable!(string) justify_content; // The justify-content CSS attribute.
    Nullable!(string) left; // The left CSS attribute.
    Nullable!(string) margin; // The margin CSS attribute.
    Nullable!(string) max_height; // The max-height CSS attribute.
    Nullable!(string) max_width; // The max-width CSS attribute.
    Nullable!(string) min_height; // The min-height CSS attribute.
    Nullable!(string) min_width; // The min-width CSS attribute.
    Nullable!(string) order; // The order CSS attribute.
    Nullable!(string) overflow; // The overflow CSS attribute.
    Nullable!(string) overflow_x; // The overflow-x CSS attribute.
    Nullable!(string) overflow_y; // The overflow-y CSS attribute.
    Nullable!(string) padding; // The padding CSS attribute.
    Nullable!(string) right; // The right CSS attribute.
    Nullable!(string) top; // The top CSS attribute.
    Nullable!(string) visibility; // The visibility CSS attribute.
    Nullable!(string) width; // The width CSS attribute.
}

// TODO: WidgetModel[] is not implemented. Probably could be a IWidget[]
// struct AccordionModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "AccordionModel";
//     JSONValue _titles = {}; // Titles of the pages
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "AccordionView";
//     string box_style = BoxStyle.none; // Use a predefined styling for the box.
//     WidgetModel[] children; // List of widget children
//     Reference!LayoutModel layout;
//     Nullable!(int) selected_index = 0; // The index of the selected page. This is either an integer selecting a particular sub-widget, or None to have no widgets selected.
// }

struct BoundedFloatTextModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "BoundedFloatTextModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "FloatTextView";
    bool continuous_update = false; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    double max = 100.0; // Max value
    double min = 0.0; // Min value
    Nullable!(double) step; // Minimum step to increment the value
    Reference!DescriptionStyleModel style; // Styling customizations
    double value = 0.0; // Float value
}

struct BoundedIntTextModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "BoundedIntTextModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "IntTextView";
    bool continuous_update = false; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    int max = 100; // Max value
    int min = 0; // Min value
    int step = 1; // Minimum step to increment the value
    Reference!DescriptionStyleModel style; // Styling customizations
    int value = 0; // Int value
}

// TODO: WidgetModel[] is not implemented. Probably could be a IWidget[]
// struct BoxModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "BoxModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "BoxView";
//     string box_style = BoxStyle.none; // Use a predefined styling for the box.
//     WidgetModel[] children; // List of widget children
//     Reference!LayoutModel layout;
// }

struct ButtonModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ButtonModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ButtonView";
    string button_style = ButtonStyle.none; // Use a predefined styling for the button.
    string description; // Button label.
    bool disabled = false; // Enable or disable user changes.
    string icon; // Font-awesome icon name, without the 'fa-' prefix.
    Reference!LayoutModel layout;
    Reference!ButtonStyleModel style;
    string tooltip; // Tooltip caption of the button.
}

struct ButtonStyleModel {
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ButtonStyleModel";
    enum _view_module = "@jupyter-widgets/base";
    enum _view_module_version = "1.0.0";
    enum _view_name = "StyleView";
    Nullable!(string) button_color; // Color of the button
    string font_weight; // Button text font weight.
}

struct CheckboxModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "CheckboxModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "CheckboxView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes.
    bool indent = true; // Indent the control to align with other controls with a description.
    Reference!LayoutModel layout;
    Reference!DescriptionStyleModel style; // Styling customizations
    bool value = false; // Bool value
}

struct ColorPickerModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ColorPickerModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ColorPickerView";
    bool concise = false; // Display short version with just a color selector.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes.
    Reference!LayoutModel layout;
    Reference!DescriptionStyleModel style; // Styling customizations
    string value = "black"; // The color value.
}

struct ControllerAxisModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ControllerAxisModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ControllerAxisView";
    Reference!LayoutModel layout;
    double value = 0.0; // The value of the axis.
}

struct ControllerButtonModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ControllerButtonModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ControllerButtonView";
    Reference!LayoutModel layout;
    bool pressed = false; // Whether the button is pressed.
    double value = 0.0; // The value of the button.
}

// struct ControllerModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "ControllerModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "ControllerView";
//     AxisModel[] axes; // The axes on the gamepad.
//     ButtonModel[] buttons; // The buttons on the gamepad.
//     bool connected = false; // Whether the gamepad is connected.
//     int index = 0; // The id number of the controller.
//     Reference!LayoutModel layout;
//     string mapping; // The name of the control mapping.
//     string name; // The name of the controller.
//     double timestamp = 0.0; // The last time the data from this gamepad was updated.
// }

// TODO: Serialisation for Date is not implemented. Could use phobos' DateTime
// struct DatePickerModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "DatePickerModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "DatePickerView";
//     string description; // Description of the control.
//     bool disabled = false; // Enable or disable user changes.
//     Reference!LayoutModel layout;
//     Reference!DescriptionStyleModel style; // Styling customizations
//     Nullable!(Date) value;
// }

struct DescriptionStyleModel {
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "DescriptionStyleModel";
    enum _view_module = "@jupyter-widgets/base";
    enum _view_module_version = "1.0.0";
    enum _view_name = "StyleView";
    string description_width; // Width of the description to the side of the control.
}

// TODO: the source and target fields should probably be a IWidget
// struct DirectionalLinkModel {
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "DirectionalLinkModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     Nullable!(string) _view_name; // Name of the view.
//     array source; // The source (widget, 'trait_name') pair
//     array target; // The target (widget, 'trait_name') pair
// }

struct DropdownModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "DropdownModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "DropdownView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Nullable!(int) index; // Selected index
    Reference!LayoutModel layout;
    Reference!DescriptionStyleModel style; // Styling customizations
}

struct FloatLogSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "FloatLogSliderModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "FloatLogSliderView";
    double base = 10.0; // Base for the logarithm
    bool continuous_update = true; // Update the value of the widget as the user is holding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    double max = 4.0; // Max value for the exponent
    double min = 0.0; // Min value for the exponent
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current value of the slider next to it.
    string readout_format = ".3g"; // Format for the readout
    double step = 0.1; // Minimum step in the exponent to increment the value
    Reference!SliderStyleModel style;
    double value = 1.0; // Float value
}

struct FloatProgressModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "FloatProgressModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ProgressView";
    Nullable!(string) bar_style = Nullable!(string)(BarStyle.none); // Use a predefined styling for the progess bar.
    string description; // Description of the control.
    Reference!LayoutModel layout;
    double max = 100.0; // Max value
    double min = 0.0; // Min value
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    Reference!ProgressStyleModel style;
    double value = 0.0; // Float value
}

struct FloatRangeSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "FloatRangeSliderModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "FloatRangeSliderView";
    bool continuous_update = true; // Update the value of the widget as the user is sliding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    double max = 100.0; // Max value
    double min = 0.0; // Min value
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current value of the slider next to it.
    string readout_format = ".2f"; // Format for the readout
    double step = 0.1; // Minimum step to increment the value
    Reference!SliderStyleModel style;
    double[2] value = [0.0, 1.0]; // Tuple of (lower, upper) bounds
}

struct FloatSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "FloatSliderModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "FloatSliderView";
    bool continuous_update = true; // Update the value of the widget as the user is holding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    double max = 100.0; // Max value
    double min = 0.0; // Min value
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current value of the slider next to it.
    string readout_format = ".2f"; // Format for the readout
    double step = 0.1; // Minimum step to increment the value
    Reference!SliderStyleModel style;
    double value = 0.0; // Float value
}

struct FloatTextModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "FloatTextModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "FloatTextView";
    bool continuous_update = false; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    Nullable!(double) step; // Minimum step to increment the value
    Reference!DescriptionStyleModel style; // Styling customizations
    double value = 0.0; // Float value
}

// TODO: WidgetModel[] is not implemented. Probably could be a IWidget[]
// struct HBoxModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "HBoxModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "HBoxView";
//     string box_style = BoxStyle.none; // Use a predefined styling for the box.
//     WidgetModel[] children; // List of widget children
//     Reference!LayoutModel layout;
// }

struct HTMLMathModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "HTMLMathModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "HTMLMathView";
    string description; // Description of the control.
    Reference!LayoutModel layout;
    string placeholder = "\u200b"; // Placeholder text to display when nothing has been typed
    Reference!DescriptionStyleModel style; // Styling customizations
    string value; // String value
}

struct HTMLModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "HTMLModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "HTMLView";
    string description; // Description of the control.
    Reference!LayoutModel layout;
    string placeholder = "\u200b"; // Placeholder text to display when nothing has been typed
    Reference!DescriptionStyleModel style; // Styling customizations
    string value; // String value
}

// TODO: Bytes is not yet defined. Could be ubyte[]. This also requires to implement the buffer_paths part of the ipywidget widget protocol.
// struct ImageModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "ImageModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "ImageView";
//     string format = "png"; // The format of the image.
//     string height; // Height of the image in pixels.
//     Reference!LayoutModel layout;
//     Bytes value; // The image data as a byte string.
//     string width; // Width of the image in pixels.
// }

struct IntProgressModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "IntProgressModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ProgressView";
    string bar_style = BarStyle.none; // Use a predefined styling for the progess bar.
    string description; // Description of the control.
    Reference!LayoutModel layout;
    int max = 100; // Max value
    int min = 0; // Min value
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    Reference!ProgressStyleModel style;
    int value = 0; // Int value
}

struct IntRangeSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "IntRangeSliderModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "IntRangeSliderView";
    bool continuous_update = true; // Update the value of the widget as the user is sliding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    int max = 100; // Max value
    int min = 0; // Min value
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current value of the slider next to it.
    string readout_format = "d"; // Format for the readout
    int step = 1; // Minimum step that the value can take
    Reference!SliderStyleModel style; // Slider style customizations.
    double[2] value = [0, 1]; // Tuple of (lower, upper) bounds
}

struct IntSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "IntSliderModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "IntSliderView";
    bool continuous_update = true; // Update the value of the widget as the user is holding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    int max = 100; // Max value
    int min = 0; // Min value
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current value of the slider next to it.
    string readout_format = "d"; // Format for the readout
    int step = 1; // Minimum step to increment the value
    Reference!SliderStyleModel style;
    int value = 0; // Int value
}

struct IntTextModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "IntTextModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "IntTextView";
    bool continuous_update = false; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    int step = 1; // Minimum step to increment the value
    Reference!DescriptionStyleModel style; // Styling customizations
    int value = 0; // Int value
}

struct LabelModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "LabelModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "LabelView";
    string description; // Description of the control.
    Reference!LayoutModel layout;
    string placeholder = "\u200b"; // Placeholder text to display when nothing has been typed
    Reference!DescriptionStyleModel style; // Styling customizations
    string value; // String value
}

// TODO: source and target should probably be a simple struct type
// struct LinkModel {
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "LinkModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     Nullable!(string) _view_name; // Name of the view.
//     array source; // The source (widget, 'trait_name') pair
//     array target; // The target (widget, 'trait_name') pair
// }

struct PasswordModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "PasswordModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "PasswordView";
    bool continuous_update = true; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    string placeholder = "\u200b"; // Placeholder text to display when nothing has been typed
    Reference!DescriptionStyleModel style; // Styling customizations
    string value; // String value
}

struct PlayModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "PlayModel";
    bool _playing = false; // Whether the control is currently playing.
    bool _repeat = false; // Whether the control will repeat in a continous loop.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "PlayView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    int interval = 100; // The maximum value for the play control.
    Reference!LayoutModel layout;
    int max = 100; // Max value
    int min = 0; // Min value
    bool show_repeat = true; // Show the repeat toggle button in the widget.
    int step = 1; // Increment step
    Reference!DescriptionStyleModel style; // Styling customizations
    int value = 0; // Int value
}

struct ProgressStyleModel {
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ProgressStyleModel";
    enum _view_module = "@jupyter-widgets/base";
    enum _view_module_version = "1.0.0";
    enum _view_name = "StyleView";
    Nullable!(string) bar_color; // Color of the progress bar.
    string description_width; // Width of the description to the side of the control.
}

struct RadioButtonsModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "RadioButtonsModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "RadioButtonsView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Nullable!(int) index; // Selected index
    Reference!LayoutModel layout;
    Reference!DescriptionStyleModel style; // Styling customizations
}

struct SelectModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "SelectModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "SelectView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Nullable!(int) index; // Selected index
    Reference!LayoutModel layout;
    int rows = 5; // The number of rows to display.
    Reference!DescriptionStyleModel style; // Styling customizations
}

struct SelectMultipleModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "SelectMultipleModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "SelectMultipleView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    int[] index; // Selected indices
    Reference!LayoutModel layout;
    int rows = 5; // The number of rows to display.
    Reference!DescriptionStyleModel style; // Styling customizations
}

struct SelectionRangeSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "SelectionRangeSliderModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "SelectionRangeSliderView";
    bool continuous_update = true; // Update the value of the widget as the user is holding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    int[2] index = [0, 0]; // Min and max selected indices
    Reference!LayoutModel layout;
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current selected label next to the slider
    Reference!DescriptionStyleModel style; // Styling customizations
}

struct SelectionSliderModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "SelectionSliderModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "SelectionSliderView";
    bool continuous_update = true; // Update the value of the widget as the user is holding the slider.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    int index = 0; // Selected index
    Reference!LayoutModel layout;
    string orientation = Orientation.horizontal; // Vertical or horizontal.
    bool readout = true; // Display the current selected label next to the slider
    Reference!DescriptionStyleModel style; // Styling customizations
}

struct SliderStyleModel {
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "SliderStyleModel";
    enum _view_module = "@jupyter-widgets/base";
    enum _view_module_version = "1.0.0";
    enum _view_name = "StyleView";
    string description_width; // Width of the description to the side of the control.
    Nullable!(string) handle_color; // Color of the slider handle.
}

// TODO: WidgetModel[] is not implemented. Probably could be a IWidget[]
// struct TabModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "TabModel";
//     JSONValue _titles = {}; // Titles of the pages
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "TabView";
//     string box_style = BoxStyle.none; // Use a predefined styling for the box.
//     WidgetModel[] children; // List of widget children
//     Reference!LayoutModel layout;
//     Nullable!(int) selected_index = 0; // The index of the selected page. This is either an integer selecting a particular sub-widget, or None to have no widgets selected.
// }

struct TextModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "TextModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "TextView";
    bool continuous_update = true; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    string placeholder = "\u200b"; // Placeholder text to display when nothing has been typed
    Reference!DescriptionStyleModel style; // Styling customizations
    string value; // String value
}

struct TextareaModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "TextareaModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "TextareaView";
    bool continuous_update = true; // Update the value as the user types. If False, update on submission, e.g., pressing Enter or navigating away.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    Reference!LayoutModel layout;
    string placeholder = "\u200b"; // Placeholder text to display when nothing has been typed
    Nullable!(int) rows; // The number of rows to display.
    Reference!DescriptionStyleModel style; // Styling customizations
    string value; // String value
}

struct ToggleButtonModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ToggleButtonModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ToggleButtonView";
    string button_style = ButtonStyle.none; // Use a predefined styling for the button.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes.
    string icon; // Font-awesome icon.
    Reference!LayoutModel layout;
    Reference!DescriptionStyleModel style; // Styling customizations
    string tooltip; // Tooltip caption of the toggle button.
    bool value = false; // Bool value
}

struct ToggleButtonsModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ToggleButtonsModel";
    string[] _options_labels; // The labels for the options.
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ToggleButtonsView";
    Nullable!(string) button_style = Nullable!(string)(ButtonStyle.none); // Use a predefined styling for the buttons.
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes
    string[] icons; // Icons names for each button (FontAwesome names without the fa- prefix).
    Nullable!(int) index; // Selected index
    Reference!LayoutModel layout;
    Reference!ToggleButtonsStyleModel style;
    string[] tooltips; // Tooltips for each button.
}

struct ToggleButtonsStyleModel {
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ToggleButtonsStyleModel";
    enum _view_module = "@jupyter-widgets/base";
    enum _view_module_version = "1.0.0";
    enum _view_name = "StyleView";
    string button_width; // The width of each button.
    string description_width; // Width of the description to the side of the control.
    string font_weight; // Text font weight of each button.
}

// TODO: WidgetModel[] is not implemented. Probably could be a IWidget[]
// struct VBoxModel {
//     string[] _dom_classes; // CSS classes applied to widget DOM element
//     enum _model_module = "@jupyter-widgets/controls";
//     enum _model_module_version = "1.2.0";
//     enum _model_name = "VBoxModel";
//     enum _view_module = "@jupyter-widgets/controls";
//     enum _view_module_version = "1.2.0";
//     enum _view_name = "VBoxView";
//     string box_style = BoxStyle.none; // Use a predefined styling for the box.
//     WidgetModel[] children; // List of widget children
//     Reference!LayoutModel layout;
// }

struct ValidModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/controls";
    enum _model_module_version = "1.2.0";
    enum _model_name = "ValidModel";
    enum _view_module = "@jupyter-widgets/controls";
    enum _view_module_version = "1.2.0";
    enum _view_name = "ValidView";
    string description; // Description of the control.
    bool disabled = false; // Enable or disable user changes.
    Reference!LayoutModel layout;
    string readout = "Invalid"; // Message displayed when the value is False
    Reference!DescriptionStyleModel style; // Styling customizations
    bool value = false; // Bool value
}

struct OutputModel {
    string[] _dom_classes; // CSS classes applied to widget DOM element
    enum _model_module = "@jupyter-widgets/output";
    enum _model_module_version = "1.0.0";
    enum _model_name = "OutputModel";
    enum _view_module = "@jupyter-widgets/output";
    enum _view_module_version = "1.0.0";
    enum _view_name = "OutputView";
    Reference!LayoutModel layout;
    string msg_id; // Parent message id of messages to capture
    JSONValue[] outputs; // The output messages synced from the frontend.
}

enum isModel(alias T) = __traits(compiles, T._model_module);
enum isModel(T) = __traits(compiles, T._model_module);

JSONValue toJSONValue(T)(ref T field) {
    static if (is(T : Reference!P, P))
        return JSONValue(field.value);
    else static if (isModel!T)
        return field.serialize();
    else static if (is(T : Nullable!S, S)) {
        if (field.isNull)
            return JSONValue(null);
        return field.get.toJSONValue();
    } else
        return JSONValue(field);
}

T fromJSONValue(T)(in ref JSONValue value) {
    static if (is (T : int[2])) {
        int[2] range = [cast(int)value[0].integer, cast(int)value[1].integer];
        return range;
    }
    static if (is (T : double[2])) {
        double[2] range = [cast(double)value[0].floating, cast(double)value[1].floating];
        return range;
    }
    static if (is(T : Reference!P, P))
        return Reference!P(value.str);
    static if (is(T == double)) {
        if (value.type == JSONType.integer)
            return cast(float)value.integer();
        return value.floating();
    } else static if (is(T == int))
        return cast(int)value.integer();
    else static if (is(T == immutable(char)[]))
        return value.str();
    else static if (is(T == string))
        return value.str();
    else static if (is(T == bool))
        return value.boolean();
    else static if (is(T == enum))
        return cast(T)value.str();
    else static if (is(T == JSONValue[]))
        return (() @trusted => value.array)().dup;
    else static if (is(T == P[], P))
        return (() @trusted => value.array)().map!(value => value.fromJSONValue!P).array();
    else static if (is(T == Nullable!P, P)) {
        if (value.isNull)
            return Nullable!P();
        return Nullable!P(value.fromJSONValue!P);
    }
    static assert("Don't know how to deserialize "~T.stringof);
}

JSONValue serialize(T)(ref T obj) if (isModel!T) {
    JSONValue data;
    JSONValue state;
    state["_model_module"] = obj._model_module;
    state["_model_module_version"] = obj._model_module_version;
    state["_model_name"] = obj._model_name;
    state["_view_module"] = obj._view_module;
    state["_view_module_version"] = obj._view_module_version;
    state["_view_name"] = obj._view_name;

    foreach (idx, field; obj.tupleof) {
        state[__traits(identifier, obj.tupleof[idx])] = field.toJSONValue();
    }
    data["state"] = state;
    data["buffer_paths"] = parseJSON(`[]`); // NOTE: we need to use buffer_paths whenever we move raw bytes
    return data;
 }

@safe unittest {
    FloatSliderModel slider;
    slider.serialize();
}

void update(T)(ref T state, JSONValue newState, JSONValue buffer_paths) if (isModel!T) {
    if (newState.type != JSONType.object)
        throw new Error("Excepted JSON object");
    const object = (() @trusted => newState.object)();
    foreach (idx, field; state.tupleof) {
        enum FieldName = __traits(identifier, state.tupleof[idx]);
        alias FieldType = typeof(state.tupleof[idx]);
        if (auto p = FieldName in object) {
            static if (isModel!(FieldType)) {
                __traits(getMember, state, FieldName).update(*p, buffer_paths);
            } else
                __traits(getMember, state, FieldName) = (*p).fromJSONValue!(FieldType);
        }
    }
 }

@safe unittest {
    FloatSliderModel slider;
    slider.update(parseJSON(`{"max":300.0}`), parseJSON("{}"));
    assert(slider.max == 300.0);
}

alias getModuleMember(string name) = __traits(getMember, mixin(__MODULE__), name);
enum filterSelf(string name) = name != "AllModels";
alias AllModels = Filter!(isModel, staticMap!(getModuleMember, Filter!(filterSelf,  __traits(allMembers, mixin(__MODULE__)))));
