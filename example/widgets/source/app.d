import jupyter.wire.kernel;
import jupyter.wire.message : CompleteResult;

import std.json : JSONValue;
import std.uni : toLower;
import std.array : replace;

import widgets;
import repl;
import models;

version (unittest) {} else mixin Main!ExampleBackend;

enum getWidgetCreateName(string name) = (toLower(name[0..1]) ~ name[1 .. $]).replace("Model","");

mixin template genWidgetCreateFun(T) if (is(T : Widget!M, M)) {
    import std.traits : TemplateArgsOf;
    mixin(`T `~getWidgetCreateName!(__traits(identifier, TemplateArgsOf!(T)[0]))~`(scope IoPubMessageSender sender) {
        auto widget = new T(sender);
        widgetMap[widget.getCommId()] = widget;
        return widget;
    }`);
}

struct WidgetFactory {
    private IWidget[string] widgetMap;
    mixin genWidgetCreateFun!(Widget!FloatSliderModel);
    mixin genWidgetCreateFun!(Widget!IntSliderModel);
    mixin genWidgetCreateFun!(Widget!ButtonModel);
    mixin genWidgetCreateFun!(Widget!CheckboxModel);
}

struct ExampleBackend {

    enum languageInfo = LanguageInfo("foo", "0.0.1", ".foo");
    Repl!WidgetFactory repl;
    WidgetFactory widgetFactory;

    void initialize() @safe {
        repl.addGlobal("widgets", &widgetFactory);
    }

    ExecutionResult execute(in string code, scope IoPubMessageSender sender) @safe {
        import std.conv: text;

        auto result = (() @trusted => repl.run(code, sender))();

        if (result.error)
            throw new Exception(result.message);

        return textResult((() @trusted => result.value.text())());
    }

    CompleteResult complete(string code, long cursorPos) @safe {
        import std.algorithm : map, canFind;
        import std.array : array;

        scope IoPubMessageSender sender = (Message){};
        CompleteResult ret;
        auto complete = (() @trusted => repl.complete(code, cursorPos, sender))();
        ret.matches = complete.matches;
        ret.cursorStart = complete.start;
        ret.cursorEnd = complete.end;
        ret.status = "ok";
        return ret;
    }

    // NOTE: not used in this example, but it can be called from the frontend when it constructs a Widget
    bool commOpen(in string commId, in string targetName, in JSONValue metadata, in JSONValue data, scope IoPubMessageSender sender) @safe {
        if (targetName != "jupyter.widget")
            return false;

        widgetFactory.widgetMap[commId] = constructWidget(commId, data, sender);
        return true;
    }

    void commClose(in string commId, in JSONValue data, scope IoPubMessageSender sender) @safe {
        if (auto p = commId in widgetFactory.widgetMap) {
            (*p).onRemove(sender, data);
        }
        widgetFactory.widgetMap.remove(commId);
    }

    void commMessage(in string commId, in JSONValue data, scope IoPubMessageSender sender) @safe {
        import jupyter.wire.log: log;
        log("received comm msg ", commId);
        if (auto p = commId in widgetFactory.widgetMap) {
            switch (data["method"].str) {
            case "update":
                return (*p).onUpdate(data["state"], data["buffer_paths"]);
            case "request_state":
                return (*p).onRequestState(sender);
            case "custom":
                return (*p).onCustomMessage(sender, data["content"]);
            default: return;
            }
        } else
            log("cannot find widget ", commId);
    }
}
