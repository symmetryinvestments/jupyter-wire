module jupyter.wire.log;


version(Windows) {
    extern(Windows) void OutputDebugStringW(const wchar* fmt) @nogc nothrow;
}


/**
   Polymorphic logging function.
   Prints to the console when unit testing and on Linux,
   otherwise uses the system logger on Windows.
 */
void log(
    string file = __FILE__,
    size_t line = __LINE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__,
     A...
    )
    (
        auto ref A args,
    )
    @trusted
{
    try {
        version(unittest) {
            version(Have_unit_threaded) {
                import unit_threaded: writelnUt;
                writelnUt(args);
            } else {
                import std.stdio: writeln;
                writeln(args);
            }
        } else version(JupyterLogStdout) {
            import std.experimental.logger: trace;
            trace!(line, file, funcName, prettyFuncName, moduleName)(args);

        } else version(JupyterLogFile) {

            import std.experimental.logger.filelogger: FileLogger;

            static FileLogger fileLogger;

            if(fileLogger is null) {
                fileLogger = new FileLogger("/tmp/jupyter.txt");
            }

            fileLogger.log(args);

        } else version(Windows) {
            import std.conv: text, to;
            scope txt = text(args);
            scope wtxt = txt.to!wstring;
            OutputDebugStringW(wtxt.ptr);
        } else {
            import std.experimental.logger: trace;
            trace!(line, file, funcName, prettyFuncName, moduleName)(args);
        }
    } catch(Exception e) {
        import core.stdc.stdio: printf;
        printf("Error - could not log\n");
    }
}
