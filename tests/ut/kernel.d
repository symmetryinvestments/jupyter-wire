module ut.kernel;


import unit_threaded;
import jupyter.wire.kernel;

private struct DummyBackend {
    enum languageInfo = LanguageInfo();
    ExecutionResult execute(in string, scope IoPubMessageSender sender) @safe {
        return ExecutionResult.init;
    }
}

@("usage")
unittest {
    run!DummyBackend([]).shouldThrowWithMessage("Usage: <exeName> <connectionFileName>");
    run!DummyBackend(["foobin"]).shouldThrowWithMessage("Usage: foobin <connectionFileName>");
}
