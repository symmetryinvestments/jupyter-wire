import jupyter.wire.kernel;


mixin Main!ExampleBackend;


struct ExampleBackend {

    enum languageInfo = LanguageInfo("foo", "0.0.1", ".foo");
    int value;

    ExecutionResult execute(in string code) @safe {
        import std.conv: text;

        switch(code) {
        default:
            return ExecutionResult("Unknown command '" ~ code ~ "'",
                                   "Oops");
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
