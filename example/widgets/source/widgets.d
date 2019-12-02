module widgets;

import models;

import jupyter.wire.kernel;
import jupyter.wire.message;
import std.json : JSONValue, parseJSON;
import std.meta;

interface IWidget {
    void close(scope IoPubMessageSender sender) @safe;
    void update(scope IoPubMessageSender sender, JSONValue newState) @safe; // process change from the backend (will send change to frontend as well)
    void onUpdate(in JSONValue newState, in JSONValue buffer_paths) @safe; // process change from the frontend
    void onCustomMessage(scope IoPubMessageSender sender, in JSONValue content) @safe;
    void onRequestState(scope IoPubMessageSender sender) @safe;
    void onRemove(scope IoPubMessageSender sender, in JSONValue data) @safe;
    void display(scope IoPubMessageSender sender) @safe;
    string getCommId() @safe;
}

enum WidgetProtocolMetadata = parseJSON(`{"version":"2.0.0"}`);

// Each Widget is templatized on a model. A model may contain reference to other models, which each need an instantiated widget.
// This helper struct initializes all referenced widgets.
// e.g. many models reference a LayoutModel or a StyleModel
struct ReferenceWidgets(T) {
    alias makeWidget(T) = Widget!T;
    alias Models = getReferenceModels!T.Types;
    alias Names = getReferenceModels!T.Names;
    alias Widgets = staticMap!(makeWidget, Models);
    static foreach(idx, W; Widgets) {
        mixin("W "~Names[idx]~";");
    }
    void initialize(ref T state, scope IoPubMessageSender sender) @safe {
        static foreach (idx, Widget; Widgets) {{
                auto widget = new Widget(sender);
                mixin(Names[idx]~" = widget;");
                __traits(getMember, state, Names[idx]) = widget.commId.makeReference();
            }}
    }
}

class Widget(T) : IWidget {
    private string commId;
    private ReferenceWidgets!T referenceWidgets;
    T state;

    this(scope IoPubMessageSender sender) @safe {
        import std.uuid: randomUUID;
        this(sender, randomUUID.toString);
    }

    this(scope IoPubMessageSender sender, string commId) @safe {
        this(sender, commId, T());
        sender(commOpenMessage(commId, "jupyter.widget", this.state.serialize(), WidgetProtocolMetadata));
    }

    this(scope IoPubMessageSender sender, string commId, T state) @safe {
        this.commId = commId;
        this.state = state;
        referenceWidgets.initialize(this.state, sender);
    }

    override void close(scope IoPubMessageSender sender) @safe {
        sender(commCloseMessage(commId));
    }

    override void update(scope IoPubMessageSender sender, JSONValue newState) @safe {
        this.state.update(newState, JSONValue());
        JSONValue data;
        data["state"] = newState;
        sender(commMessage(commId, data, WidgetProtocolMetadata));
    }

    override void onUpdate(in JSONValue newState, in JSONValue buffer_paths) @safe {
        this.state.update(newState, buffer_paths);
    }

    override void onRequestState(scope IoPubMessageSender sender) @safe {
        auto data = this.state.serialize();
        data["method"] = "update";
        sender(commMessage(commId, data, WidgetProtocolMetadata));
    }

    override void onCustomMessage(scope IoPubMessageSender sender, in JSONValue content) @safe {
    }

    override void onRemove(scope IoPubMessageSender sender, in JSONValue data) @safe {
    }

    override void display(scope IoPubMessageSender sender) @safe {
        JSONValue widgetView;
        widgetView["model_id"] = commId;
        widgetView["version_major"] = 2;
        widgetView["version_minor"] = 0;
        JSONValue data;
        data["application/vnd.jupyter.widget-view+json"] = widgetView;
        sender(displayDataMessage(data));
    }

    override string getCommId() @safe {
        return commId;
    }
}

@safe unittest {
    import models : FloatSliderModel;
    import std.algorithm : startsWith;
    auto w = new Widget!FloatSliderModel((Message){});
    assert(w.state.style.startsWith("IPY_MODEL_"));
    assert(w.state.layout.startsWith("IPY_MODEL_"));
}

IWidget constructWidget(in string commId, in JSONValue data, scope IoPubMessageSender sender) @safe {
    import models : AllModels;
    import std.format : format;

    const modelModule = data["_model_module"].str;
    const modelName = data["_model_name"].str;
    const viewModule = data["_view_module"].str;
    const viewName = data["_view_name"].str;

    static foreach(Model; AllModels) {
        if (Model._model_module == modelModule &&
            Model._model_name == modelName &&
            Model._view_module == viewModule &&
            Model._view_name == viewName) {
            Model model;
            model.update(data, JSONValue());
            return new Widget!(Model)(sender, commId, model);
        }
    }

    throw new Exception("Cannot construct widget module %s:%s with view %s:%s".format(modelModule, modelName, viewModule, viewName));
}

@safe unittest {
    import std.json : parseJSON;
    bool isCalled = false;

    auto widget = constructWidget("abcd", parseJSON(`{"_model_module":"@jupyter-widgets/controls","_model_name":"FloatSliderModel","_view_module":"@jupyter-widgets/controls","_view_name":"FloatSliderView","max":250.0}`), (Message msg){});

    assert(widget !is null);
    widget.onRequestState((Message msg){
            if (msg.content["comm_id"].str == "abcd") {
                isCalled = true;
                assert(msg.content["data"]["state"]["max"].floating == 250.0);
            }
        });
    assert(isCalled == true);
}

@safe unittest {
    import std.json : parseJSON;
    bool isCalled = false;

    auto widget = constructWidget("abcd", parseJSON(`{"_model_module":"@jupyter-widgets/controls","_model_name":"FloatSliderModel","_view_module":"@jupyter-widgets/controls","_view_name":"FloatSliderView","max":250.0}`), (Message msg){});

    assert(widget !is null);
    widget.update((Message msg){
            if (msg.content["comm_id"].str == "abcd") {
                isCalled = true;
                assert(msg.content["data"]["state"]["max"].floating == 260.0);
            }
        }, parseJSON(`{"max": 260.0}`));
    assert(isCalled == true);
}

