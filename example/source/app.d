import jupyter.wire.kernel;


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
            return ExecutionResult("99 bottles of beer on the wall");

        case "inc":
            return ExecutionResult(text(++value));

        case "dec":
            return ExecutionResult(text(--value));

        case "print":
            return ExecutionResult("", text(value));

        case "hello":
            return ExecutionResult("", "Hello world!");
        }
    }
}
