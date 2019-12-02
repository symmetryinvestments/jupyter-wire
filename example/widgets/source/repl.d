module repl;

import std.algorithm;
import pegged.grammar;
import sumtype;
import std.format;
import std.conv;
import std.traits;
import std.meta;
import std.typecons;

mixin(grammar(`
ToyLanguage:
    Statements < ((AssignmentExpression / Expression) (EndOfLine?))+ eoi

    AssignmentExpression < Expression "=" (Value / Expression)

    Expression < (Invoke / Identifier / IncompleteIdentifier) ("." (Invoke / Identifier / IncompleteIdentifier))*

    Invoke <- Identifier ("()")

    Whitespace <- :(' ' / '\t')+

    EndOfLine <: ('\r' '\n') / '\n'

    Spacing <- :(Whitespace)*

    Identifier <~ '_'? [A-Za-z] [0-9A-Z_a-z-]*

    IncompleteIdentifier < eps

    Integer <~ '-'? ([1-9] [0-9]*) / ('0' [Xx] [0-9A-Fa-f]+) / ('0' [0-7]*)

    Float <~ '-'? ((([0-9]+ '.' [0-9]*) / ([0-9]* '.' [0-9]+))(('E' / 'e') ('+' / '-')? [0-9]+)?) / ([0-9]+ ('E' / 'e') ('+' / '-')? [0-9]+)

    String <~ "\"" (!("\"" / EndOfLine) .)* "\""

    Value <- String / Float / Integer
`));

auto parseToyLanguage(string code) @trusted {
    return ToyLanguage(code);
}

@safe unittest {
    assert(parseToyLanguage("a").successful);
    assert(parseToyLanguage("a = 4").successful);
    assert(parseToyLanguage(`a = "text"`).successful);
    assert(parseToyLanguage("a = FloatWidget()").successful);
    assert(parseToyLanguage("a.max = 45.3").successful);
    assert(parseToyLanguage("a.display()").successful);
    assert(parseToyLanguage(`a = FloatWidget()
  a.max = 45.3
  a.display()`).successful);
}

version (unittest) {
    struct Foo {
        int a;
        void doStuff() @safe {a = 5; }
        void set(int b) @safe { a = b; }
    }
    struct Inner {
        int b = 1;
        void incr() @safe { b += 1; }
    }
    struct Bar {
        Inner inner;
    }
}

@safe unittest {
    Repl!(Foo) repl;

    repl.run("a");
    repl.run("a = Foo()");
    assert(repl.run("a.a").value == repl.Value(0));
    repl.run("a.doStuff()");
    assert(repl.run("a.a").value == repl.Value(5));
}

@safe unittest {
    Repl!(Bar) repl;

    repl.run(`a = Bar()`);
    assert(repl.run(`a.inner.b`).value == repl.Value(1));
    repl.run(`a.inner.incr()`);
    assert(repl.run(`a.inner.b`).value == repl.Value(2));
    assert(repl.run(`a.inner.b = 4`).value == repl.Value(4));
    repl.run(`a.inner.incr()`);
    assert(repl.run(`a.inner.b`).value == repl.Value(5));
}

@safe unittest {
    Repl!(Foo) repl;

    repl.addGlobal("foo", Foo(4));
    assert(repl.run("foo.a").value == repl.Value(4));
}

@safe unittest {
    Repl!(Foo) repl;

    repl.run("a = Foo()");
    assert(repl.run("a.a = 43.3").error == true);
    assert(repl.run("a.a = 43.3").message == "Error: cannot assign type double to type int in 'a.a = 43.3'");
    assert(repl.run("a.noexist").error == true);
    assert(repl.run("a.noexist").message == "Error: property 'noexist' is not available on type Foo in 'noexist'");
    assert(repl.run("a.noexist()").error == true);
    assert(repl.run("a.noexist()").message == "Error: method 'noexist' is not available on type Foo in 'noexist()'");
    assert(repl.run("Nope()").error == true);
    assert(repl.run("Nope()").message == "Error: type Nope not found in 'Nope()'");
    assert(repl.run("a.a.impossible").error == true);
    assert(repl.run("a.a.impossible").message == "Error: cannot access a property on a int in 'impossible'");
    assert(repl.run("a.a.impossible()").error == true);
    assert(repl.run("a.a.impossible()").message == "Error: cannot call a method on a int in 'impossible()'");
}

@safe unittest {
    Repl!(Foo) repl;
    int b = 88;
    repl.run("a = Foo()");
    repl.run("a.set()", b);
    assert(repl.run("a.a").value == repl.Value(88));
}

@safe unittest {
    Repl!(Bar) repl;

    repl.addGlobal("widgets", 4);
    assert(repl.complete("", 0) == CompleteResult(["widgets"], 0, 0));
    assert(repl.complete("w", 0) == CompleteResult(["widgets"], 0, 1));
}

@safe unittest {
    Repl!(Bar) repl;

    repl.addGlobal("bar", Bar());
    assert(repl.complete("b",1) == CompleteResult(["bar"], 0, 1));
    assert(repl.complete("bar.",4) == CompleteResult(["inner"], 4, 4));
    assert(repl.complete("bar.in",5) == CompleteResult(["inner"], 4, 6));
}

@safe unittest {
    Repl!(Bar) repl;

    assert(repl.complete("b = Bar()
b. = 4
c = Bar()",13) == CompleteResult(["inner"], 13, 13));
    assert(repl.complete("b = Bar()
b.inner. = 4
c = Bar()",15) == CompleteResult(["b", "incr"], 19, 19));
    assert(repl.complete("b = Bar()
b.inn = 4
c = Bar()",14) == CompleteResult(["inner"], 12, 16));
}

struct CompleteResult {
    string[] matches;
    ulong start;
    ulong end;
}

struct Repl(Ts...) if (Ts.length > 0) {
    alias makePointerType(T) = T*;
    alias InnerTypes = discoverTypes!(Ts, double, int, string);
    alias InnerTypesPtrs = staticMap!(makePointerType, AliasSeq!(InnerTypes, Ts));
    alias Value = SumType!(Ts, InnerTypes, InnerTypesPtrs, Void);

    struct Void {
    }

    class Var {
        Value value;
        ParseTree tree;
        bool error;
        bool valid;
        string message;

        this(ParseTree tree) @safe {
            this.tree = tree;
            value = Void();
        }

        this(Value value) @safe {
            this.value = value;
            valid = true;
        }

        this(ParseTree tree, Value value) @safe {
            this(tree);
            this.replaceValue(value);
            valid = true;
        }

        void toString(scope void delegate(const(char)[]) sink) const @trusted {
            sink("tree: ");
            if (tree.input.length > 0)
                sink(tree.text());
            else
                sink("\n");
            sink("value: ");
            sink(value.text());
            sink("\nerror: ");
            sink(error.text());
            sink("\nvalid: ");
            sink(valid.text());
            sink("\nmessage: ");
            sink(message);
            sink("\n");
        }

        Var call(Ps...)(ParseTree tree, Ps ps) {
            assert(tree.name == "ToyLanguage.Invoke");
            auto name = tree.matches[0];
            if (!valid)
                return this;
            try {
                return new Var(tree, value.match!((ref t) => callIt(t, name, ps)));
            } catch (Exception e) {
                return Var.createError(tree, e);
            }
        }

        Var access(ParseTree tree) @safe {
            assert(tree.name == "ToyLanguage.Identifier");
            auto name = tree.matches[0];
            if (!valid)
                return this;
            try {
                return new Var(tree, value.match!((ref t) => accessIt(t, name)));
            } catch (Exception e) {
                return new Var(tree, value).addError(tree, e);
            }
        }

        Var assign(ParseTree tree, Var other) @safe {
            assert(tree.name == "ToyLanguage.AssignmentExpression");
            if (!valid) {
                replaceValue(other.value);
                valid = true;
                return this;
            }
            try {
                return replaceValue(value.match!((ref t) => assignIt(t, other)));
            } catch (Exception e) {
                return this.addError(tree, e);
            }
        }

        static Var createError(ParseTree tree, Exception e) @trusted {
            return Var.createError(tree, cast(string)e.message);
        }

        static Var createError(ParseTree tree, string message) @safe {
            return new Var(tree).addError(tree, message);
        }

        Var addError(ParseTree tree, string message) @safe {
            this.message = "Error: %s in '%s'".format(message, tree.input[tree.begin .. tree.end]);
            this.error = true;
            return this;
        }

        Var addError(ParseTree tree, Exception e) @trusted {
            return this.addError(tree, cast(string)e.message);
        }

        Var replaceValue(Value v) @trusted {
            this.value = v;
            return this;
        }

        string source() @safe {
            return tree.input[tree.begin .. tree.end];
        }
    }
    Var[string] symbols;

    void addGlobal(T)(string name, T v) {
        auto var = new Var(Value(v));
        symbols[name] = var;
    }

    Var run(Ps...)(string code, Ps ps) {
        auto result = parseToyLanguage(code);
        if (!result.successful)
            throw new Exception(result.matches.joiner("\n").text());

        return result.children.map!(child => executeStatements(child, ps)).joiner().reduce!((a,b) => a.error ? a : b);
    }

    CompleteResult complete(Ps...)(string code, ulong cursorPos, Ps ps) {
        import std.array : array;

        auto result = parseToyLanguage(code);
        auto statements = result.children.map!(child => executeStatements(child, ps)).joiner().array();
        auto s = statements.filter!(s => s.tree.begin <= cursorPos && s.tree.end >= cursorPos);

        if (s.empty)
            return CompleteResult(getAllValidSymbols(), 0, code.length);

        auto statement = s.front;

        if (!statement.valid) {
            return CompleteResult(getAllValidSymbols(), statement.tree.begin, statement.tree.end);
        }

        auto deepest = getLastChild(statement.tree);
        auto matches = statement.value.match!((ref t) => getFieldsAndFunctions(t));

        return CompleteResult(matches, deepest.begin, deepest.end);
    }

private:
    string[] getAllValidSymbols() @safe {
        import std.array : array;
        return symbols.byKeyValue.filter!(pair => pair.value.valid).map!(pair => pair.key).array();
    }

    Var assignToVar(Ps...)(ParseTree tree, Var lhs, Var rhs, Ps ps) {
        if (lhs.error)
            return lhs;
        if (rhs.error)
            return rhs;
        if (!rhs.valid)
            return rhs.addError(tree, "%s is unitialized".format(rhs.source));
        return lhs.assign(tree, rhs);
    }

    auto executeStatements(Ps...)(ParseTree tree, Ps ps) {
        assert(tree.name == "ToyLanguage.Statements");
        return tree.children.map!(child => executeStatement(child, ps));
    }

    Var dereference(Ps...)(Var var, Ps ps) {
        return var.replaceValue(var.value.match!((ref t){
                    static if (isPointer!(typeof(t))) {
                        return Value(*t);
                    } else
                        return Value(t);
                }));
    }

    Var executeStatement(Ps...)(ParseTree tree, Ps ps) {
        if (!tree.successful)
            return Var.createError(tree, tree.name);
        switch (tree.name) {
        case "ToyLanguage.AssignmentExpression": return dereference(executeAssignment(tree, ps));
        case "ToyLanguage.Expression": return dereference(evaluateExpression(tree, ps));
        default: assert(0);
        }
    }

    Var executeAssignment(Ps...)(ParseTree tree, Ps ps) {
        assert(tree.name == "ToyLanguage.AssignmentExpression");
        return assignToVar(tree, getVar(tree.children[0], ps), getVar(tree.children[1], ps));
    }

    Var getVar(Ps...)(ParseTree tree, Ps ps) {
        assert(tree.name == "ToyLanguage.Expression" || tree.name == "ToyLanguage.Value");
        if (tree.name == "ToyLanguage.Value")
            return getValueVar(tree, ps);
        return evaluateExpression(tree, ps);
    }

    Var getValueVar(Ps...)(ParseTree tree, Ps ps) {
        assert(tree.name == "ToyLanguage.Value");
        switch (tree.children[0].name) {
        case "ToyLanguage.Integer": return new Var(tree, Value(tree.matches[0].to!int));
        case "ToyLanguage.Float": return new Var(tree, Value(tree.matches[0].to!double));
        case "ToyLanguage.String": return new Var(tree, Value(tree.matches[0][1..$-1]));
        default: assert(0);
        }
    }

    Var evaluateExpression(Ps...)(ParseTree tree, Ps ps) {
        assert(tree.name == "ToyLanguage.Expression");
        Var object = evaluateGlobal(tree.children[0], ps);
        foreach (child; tree.children[1 .. $]) {
            if (child.name == "ToyLanguage.Invoke")
                object = object.call(child, ps);
            else if (child.name == "ToyLanguage.Identifier")
                object = object.access(child);
            else {
                auto o = new Var(tree,object.value);
                return o.addError(tree, "Invalid");
            }
        }
        return object;
    }

    Var evaluateGlobal(Ps...)(ParseTree tree, Ps ps) {
        assert(tree.name == "ToyLanguage.Invoke" || tree.name == "ToyLanguage.Identifier");
        if (tree.name == "ToyLanguage.Invoke") {
            static foreach(T; Ts) {
                static if (isAggregateType!T) {
                    if (__traits(identifier, T) == tree.matches[0])
                        return new Var(Value(T.init));
                }
            }
            return Var.createError(tree, "type %s not found".format(tree.matches[0]));
        }
        if (auto p = tree.matches[0] in symbols)
            return (*p);
        auto object = new Var(tree);
        symbols[tree.matches[0]] = object;
        return object;
    }

    static auto callIt(T, Ps...)(ref T t, string name, Ps ps) {
        alias BaseType = getBaseType!T;
        static if (isAggregateType!BaseType || is(BaseType == class)) {
            static foreach(fun; getFunctions!(BaseType)) {{
                    enum funName = __traits(identifier, fun);
                    if (name == funName) {
                        alias returnType = ReturnType!(__traits(getMember, t, funName));
                        static if (is(returnType == void)) {
                            callFunction!(T, void, funName, Ps)(t, ps);
                            return Value(Void());
                        } else {
                            return Value(callFunction!(T, returnType, funName, Ps)(t, ps));
                        }
                    }
                }}
            throw new Exception("method '%s' is not available on type %s".format(name, __traits(identifier, BaseType)));
        } else
            throw new Exception("cannot call a method on a %s".format(BaseType.stringof));
        return Value(Void()); // needed for inference
    }

    static auto accessIt(T)(ref T t, string name) {
        alias BaseType = getBaseType!(T);
        static if (isAggregateType!BaseType && !is(BaseType : Nullable!P, P)) {
            static foreach(member; getFields!BaseType) {
                if (name == member) {
                    return Value(&__traits(getMember, t, member));
                }
            }
            throw new Exception("property '%s' is not available on type %s".format(name, __traits(identifier, BaseType)));
        } else
            throw new Exception("cannot access a property on a %s".format(BaseType.stringof));
        return Value(Void()); // needed for inference
    }

    static auto assignIt(T)(ref T t, Var other) {
        static if (isPointer!T) {
            other.value.match!((T otherT){
                    *t = *otherT;
                },(ref PointerTarget!T otherT){
                    *t = otherT;
                },(ref incompatible){
                    throw new Exception("cannot assign type %s to type %s".format(typeof(incompatible).stringof, PointerTarget!(T).stringof));
                });
            return Value(t);
        } else
            return other.value;
    }

    static string[] getFieldsAndFunctions(T)(ref T t) {
        static if (is(T == Void))
            return [];
        else static if (isAggregateType!T || is(T == class)) {
            alias Fields = getFields!T;
            alias FunctionSymbols = getFunctions!T;
            alias Functions = staticMap!(getIdentifier, FunctionSymbols);
            static if (Fields.length == 0 && Functions.length == 0)
                return [];
            else static if (Fields.length == 0) {
                enum string[Functions.length] fieldsAndFunctions = [Functions];
            } else static if (Functions.length == 0) {
                enum string[Fields.length] fieldsAndFunctions = [Fields];
            } else
                enum string[Fields.length + Functions.length] fieldsAndFunctions = [Fields, Functions];
            return fieldsAndFunctions[];
        } else {
            return [];
        }
    }

    static R callFunction(T, R, string name, Ps...)(auto ref T t, Ps ps) {
        alias fun = __traits(getMember, t, name);
        alias parameters = Parameters!(fun);
        alias ResultType = ReturnType!(fun);
        static if (parameters.length > 0) {
            static if (__traits(compiles, __traits(getMember, t, name)(ps))) {
                return __traits(getMember, t, name)(ps);
            }
            throw new Exception("cannot call method '%s' on type %s".format(name, T.stringof));
        } else {
            return __traits(getMember, t, name)();
        }
    }
}

@safe unittest {
    Foo foo = Foo();
    Repl!(Foo).callIt(foo, "doStuff");
    assert(foo.a == 5);
}

// get the most deepest, last child of the tree
ParseTree getLastChild(ref ParseTree p) @safe {
    if (p.children.length == 0)
        return p;
    return getLastChild(p.children[$-1]);
}

// strips the pointer
template getBaseType(T) {
    static if (isPointer!T)
        alias getBaseType = PointerTarget!T;
    else
        alias getBaseType = T;
}

enum getIdentifier(alias T) = __traits(identifier, T);

// gets all functions from T as symbols
template getFunctions(T) {
    alias getSymbol(string name) = AliasSeq!(__traits(getMember, T, name))[0];
    enum canAlias(string name) = __traits(compiles, getSymbol!name);
    alias members = __traits(allMembers, T);
    alias hasTSymbol = ApplyLeft!(hasMember, T);
    alias symbols = staticMap!(getSymbol, Filter!(canAlias, Filter!(hasTSymbol, AliasSeq!(members))));
    alias getFunctions = Filter!(isFunction, symbols);
}

// returns all public fields of T
template getFields(T) {
    alias hasField(string name) = hasMember!(T, name);
    enum isPublic(string name) = __traits(getProtection, __traits(getMember, T, name)) == "public";
    alias getFields = Filter!(isPublic, Filter!(hasField, FieldNameTuple!(T)));
}

// Recursively get all types of the fields and return values of each function of each item in Ts
template discoverTypes(Ts...) {
    enum isNotVoid(T) = !is(T == void);
    static if (Ts.length == 0) {
        alias discoverTypes = AliasSeq!();
    } else static if (Ts.length == 1) {
        alias T = Ts[0];
        static if (!isAggregateType!T && !(is(T == class))) {
            alias discoverTypes = AliasSeq!T;
        } else static if(is(T : Nullable!P, P)) {
            alias discoverTypes = AliasSeq!(Nullable!P, discoverTypes!P);
        } else {
            alias typeOfField(string name) = typeof(__traits(getMember, T, name));
            alias hasField(string name) = hasMember!(T, name);
            enum isNoT(Other) = !is(T == Other);
            alias fieldTypes = Filter!(isNoT, staticMap!(typeOfField, getFields!T));
            alias functionReturnTypes = Filter!(isNoT, staticMap!(ReturnType, getFunctions!(T)));
            alias Types = AliasSeq!(fieldTypes, discoverTypes!fieldTypes, functionReturnTypes, discoverTypes!(functionReturnTypes));
            alias discoverTypes = Filter!(isNotVoid, NoDuplicates!(Types));
        }
    } else {
        alias discoverTypes = Filter!(isNotVoid, NoDuplicates!(AliasSeq!(discoverTypes!(Ts[0]), discoverTypes!(Ts[1 .. $]))));
    }
}

