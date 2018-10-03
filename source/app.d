import jupyter.wire.kernel;

mixin Main!();


// int main(string[] args) {
//     try {
//         const connectionFileName = args[1];
//         runKernel(connectionFileName);
//         return 0;
//     } catch(Exception e) {
//         import std.stdio: stderr;
//         stderr.writeln("Error: ", e.msg);
//         import std.stdio: File;
//         auto f = File("/tmp/oops.txt", "w");
//         f.writeln("Error: ", e);
//         return 1;
//     } catch(Error e) {
//         import std.stdio: stderr;
//         stderr.writeln("FATAL ERROR: ", e);
//         import std.stdio: File;
//         auto f = File("/tmp/oops.txt", "w");
//         f.writeln("FATAL ERROR: ", e.msg);

//         return 2;
//     }
// }


// void runKernel(in string connectionFileName) @safe {
//     import jupyter.wire.connection: fileNameToConnectionInfo, Sockets, recvStrings, sendStrings;
//     import jupyter.wire.message: Message, statusMessage;
//     import std.stdio;

//     const connectionInfo = fileNameToConnectionInfo(connectionFileName);
//     auto sockets = Sockets(connectionInfo);

//     ubyte[1024] buf;

//     for(;;) {

//         auto f = File("/tmp/foo.txt", "a");

//         const requestStrings = sockets.shell.recvStrings;
//         if(requestStrings is null) continue;

//         auto requestMsg = Message(requestStrings);
//         f.writeln(requestMsg);

//         auto busyMsg = statusMessage(requestMsg.header, "busy");
//         sockets.ioPub.sendStrings(busyMsg.toStrings(connectionInfo.key));

//         auto idleMsg = statusMessage(requestMsg.header, "idle");
//         sockets.ioPub.sendStrings(idleMsg.toStrings(connectionInfo.key));
//     }
// }
