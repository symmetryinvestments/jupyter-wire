int main(string[] args) {
    try {
        const connectionFileName = args[1];
        runKernel(connectionFileName);
        return 0;
    } catch(Exception e) {
        import std.stdio: stderr;
        stderr.writeln("Error: ", e.msg);
        import std.stdio: File;
        auto f = File("/tmp/oops.txt", "w");
        f.writeln("Error: ", e);
        return 1;
    } catch(Error e) {
        import std.stdio: stderr;
        stderr.writeln("FATAL ERROR: ", e);
        import std.stdio: File;
        auto f = File("/tmp/oops.txt", "w");
        f.writeln("FATAL ERROR: ", e.msg);

        return 2;
    }
}


void runKernel(in string connectionFileName) @safe {
    import jupyter.wire.connection: fileNameToConnectionInfo, Sockets, recvStrings, sendStrings;
    import jupyter.wire.message: Message, statusMessage;
    import std.stdio;

    const connectionInfo = fileNameToConnectionInfo(connectionFileName);

    // import zmqd: Socket, SocketType;
    // auto shell = Socket(SocketType.router);
    // f.writeln("connection uri: ", connectionInfo.uri(connectionInfo.shellPort));
    // shell.bind(connectionInfo.uri(connectionInfo.shellPort));

    auto sockets = Sockets(connectionInfo);

    ubyte[1024] buf;

    for(;;) {

        auto f = File("/tmp/foo.txt", "a");
        // const shellBytes = sockets.shell.receive(buf);
        // f.writeln("# of bytes on shell: ", shellBytes);
        // f.writeln("Data on shell:\n", buf[0 .. shellBytes]);

        // import zmqd: Frame;
        // int i;
        // do {
        //     auto frame = Frame();
        //     sockets.shell.receive(frame);
        //     () @trusted { f.writeln(i++, " : ", cast(string)frame.data); }();
        // } while(sockets.shell.more);

        // const controlBytes = sockets.control.receive(buf);
        // f.writeln("# of bytes on control: ", controlBytes);
        // f.writeln("Data on control:\n", buf[0 .. controlBytes]);

        auto requestMsg = Message(sockets.shell.recvStrings);
        f.writeln(requestMsg);

        auto busyMsg = statusMessage(requestMsg.header, "busy");
        sockets.ioPub.sendStrings(busyMsg.toStrings(connectionInfo.key));

        auto idleMsg = statusMessage(requestMsg.header, "idle");
        sockets.ioPub.sendStrings(idleMsg.toStrings(connectionInfo.key));
    }
}
