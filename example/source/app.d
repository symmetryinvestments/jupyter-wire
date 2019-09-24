import jupyter.wire.kernel;
import jupyter.wire.message : CompleteResult;


mixin Main!ExampleBackend;


class ExampleException: Exception {
    import std.exception: basicExceptionCtors;
    mixin basicExceptionCtors;
}


struct ExampleBackend {

    enum languageInfo = LanguageInfo("foo", "0.0.1", ".foo");
    int value;

    ExecutionResult execute(in string code) @safe {
        import std.conv: text;

        switch(code) {
        default:
            throw new ExampleException("Unkown command '" ~ code ~ "'");

        case "99":
            return textResult("99 bottles of beer on the wall");

        case "inc":
            return textResult(text(++value));

        case "dec":
            return textResult(text(--value));

        case "print":
            return textResult("", Stdout(text(value)));

        case "hello":
            return textResult("", Stdout("Hello world!"));

        case "markup":
            return markdownResult(`# Big header`);
        }
    }

    CompleteResult complete(string code, int cursorPos)
    {
        import std.algorithm : map , canFind;
        import std.array : array;
        import std.experimental.logger: infof;
        import std.conv : to;

        version(TraceCompletion) infof("complete request %s %s",code,cursorPos);
        CompleteResult ret;
        ret.matches = ["1","2","3"].map!(x => code ~ "_" ~ x).array;
        ret.cursorStart = cursorPos - code.length.to!int;
        ret.cursorEnd = cursorPos;
        ret.status = code.canFind("@err") ? "error" : "ok";
        version(TraceCompletion) infof("complete response %s",ret);
        return ret;
    }
}
