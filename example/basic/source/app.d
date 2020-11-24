import jupyter.wire.kernel;
import jupyter.wire.message : CompleteResult;
import jupyter.wire.magic: magic_runner;
import std.stdio;

mixin Main!ExampleBackend;


class ExampleException: Exception {
    import std.exception: basicExceptionCtors;
    mixin basicExceptionCtors;
}

static this() {
  magic_runner.register_line_magic("echo",
				   function ExecutionResult(string x) {
				     return textResult(x);
				       });
  magic_runner.register_cell_magic("echo",
				   function ExecutionResult(string x,
							    string y) {
				     return textResult(y);
				       });
}

struct ExampleBackend {

    enum languageInfo = LanguageInfo("foo", "0.0.1", ".foo");
    int value;

    ExecutionResult execute(in string code, scope IoPubMessageSender sender) @safe {
        import std.conv: text;

	auto c = magic_runner.run(code);
	if (c[0] == 1) {
	  return c[1];
	}
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

    CompleteResult complete(string code, long cursorPos) {
        import std.algorithm : map, canFind;
        import std.array : array;

        CompleteResult ret;
        ret.matches = ["1", "2", "3"].map!(x => code ~ "_" ~ x).array;
        ret.cursorStart = cursorPos - code.length;
        ret.cursorEnd = cursorPos;
        ret.status = code.canFind("@err") ? "error" : "ok";
        return ret;
    }
}
