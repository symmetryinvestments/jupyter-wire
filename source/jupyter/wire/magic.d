import jupyter.wire.kernel;
import jupyter.wire.log;
import std.typecons: tuple, Tuple;


struct MagicRunner {
  @safe ExecutionResult function(string)[string] line_magic_map;
  @safe ExecutionResult function(string, string)[string] cell_magic_map;
   Tuple!(int, ExecutionResult) run(string command) @safe {
      import std.string;
      import std.regex;
      import std.array : join;
      auto line_regex = regex(r"^%([a-zA-Z0-9]+)\s*");
      auto cell_regex = regex(r"^%%([a-zA-Z0-9]+)\s*");
      string[] cell_string_array;
      string[] cell_items;
      string[] line_items;
      foreach (string i; splitLines(command)) {
         if(matchFirst(i, line_regex)) {
           line_items ~= i;
	 } else if(matchFirst(i, cell_regex)) {
	   cell_items ~= i;
	 } else {
	   cell_string_array ~= i;
	 }
      }
      auto cell_string = join(cell_string_array, "\n");
      foreach (string i; cell_items) {
	auto c = matchFirst(i, regex(r"^%%([a-zA-Z0-9]+)\s*"));
	version(JupyterLogVerbose) log("cell magic ", c[1]);
	if (c[1] in cell_magic_map) {
	  return tuple(1, cell_magic_map[c[1]](i, cell_string));
	}
      }
      foreach (string i; line_items) {
	auto c = matchFirst(i, regex(r"^%([a-zA-Z0-9]+)\s*"));
	version(JupyterLogVerbose) log("line magic ", c[1]);
	if (c[1] in line_magic_map) {
	  return tuple(1, line_magic_map[c[1]](i));
	}
      }
      return tuple(0,  textResult(""));
   }
  void register_line_magic(string name,
			   ExecutionResult function(string) @safe m) {
    line_magic_map[name] = m;
  }
  void register_cell_magic(string name,
			   ExecutionResult function(string, string) @safe m) {
    cell_magic_map[name] = m;
  }
}

static MagicRunner magic_runner;
