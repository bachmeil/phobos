Ddoc

$(SPEC_S Modules,

$(GRAMMAR
$(I Module):
	$(I ModuleDeclaration) $(GLINK DeclDefs)
	$(GLINK DeclDefs)

$(GNAME DeclDefs):
	$(I DeclDef)
	$(I DeclDef) $(I DeclDefs)

$(GNAME DeclDef):
	$(LINK2 attribute.html#AttributeSpecifier, $(I AttributeSpecifier))
	$(GLINK ImportDeclaration)
	$(I EnumDeclaration)
	$(I ClassDeclaration)
	$(I InterfaceDeclaration)
	$(I AggregateDeclaration)
	$(I Declaration)
	$(I Constructor)
	$(I Destructor)
	$(I Invariant)
	$(I UnitTest)
	$(I StaticConstructor)
	$(I StaticDestructor)
	$(LINK2 version.html#DebugSpecification, $(I DebugSpecification))
	$(LINK2 version.html#VersionSpecification, $(I VersionSpecification))
	$(GLINK MixinDeclaration)
	$(B ;)
)


	$(P Modules have a one-to-one correspondence with source files.
	The module name is the file name with the path and extension
	stripped off.
	)

	$(P Modules automatically provide a namespace scope for their contents.
	Modules superficially resemble classes, but differ in that:
	)

	$(UL 
	$(LI There's only one instance of each module, and it is
	statically allocated.)

	$(LI There is no virtual table.)

	$(LI Modules do not inherit, they have no super modules, etc.)

	$(LI Only one module per file.)

	$(LI Module symbols can be imported.)

	$(LI Modules are always compiled at global scope, and are unaffected
	by surrounding attributes or other modifiers.)
	)

	$(P Modules can be grouped together in hierarchies called $(I packages).
	)

	$(P Modules offer several guarantees:)

	$(UL

	$(LI The order in which modules are imported does not affect the
	semantics.)

	$(LI The semantics of a module are not affected by what imports
	it.)

	$(LI If a module C imports modules A and B, any modifications to B
	will not silently change code in C that is dependent on A.)

	)

<h3>Module Declaration</h3>

	$(P The $(I ModuleDeclaration) sets the name of the module and what
	package it belongs to. If absent, the module name is taken to be the
	same name (stripped of path and extension) of the source file name.
	)

$(GRAMMAR
$(I ModuleDeclaration):
	$(B module) $(I ModuleName) $(B ;)

$(I ModuleName):
	$(I Identifier)
	$(I ModuleName) $(B .) $(I Identifier)
)

	$(P The $(I Identifier) preceding the rightmost are the $(I packages)
	that the module is in. The packages correspond to directory names in
	the source file path.
	)

	$(P If present, the $(I ModuleDeclaration) appears syntactically first
	in the source file, and there can be only one per source file.
	)

	$(P Example:)

---------
module c.stdio;    // this is module $(B stdio) in the $(B c) package
---------

	$(P By convention, package and module names are all lower case. This is
	because those names have a one-to-one correspondence with the operating
	system's directory and file names, and many file systems
	are not case sensitive. All lower case package and module names will
	minimize problems moving projects between dissimilar file systems.
	)

<h2><a name="ImportDeclaration">Import Declaration</a></h2>

	$(P
	Symbols from one module are made available in another module
	by using the $(I ImportDeclaration):
	)

$(GRAMMAR
$(I ImportDeclaration):
	$(B import) $(I ImportList) $(B ;)
	$(B static import) $(I ImportList) $(B ;)

$(I ImportList):
	$(I Import)
	$(I ImportBindings)
	$(I Import) $(B ,) $(I ImportList)

$(I Import):
	$(I ModuleName)
	$(I ModuleAliasIdentifier) $(B =) $(I ModuleName)

$(I ImportBindings):
	$(I Import) $(B :) $(I ImportBindList)

$(I ImportBindList):
	$(I ImportBind)
	$(I ImportBind) $(B ,) $(I ImportBindList)

$(I ImportBind):
	$(I Identifier)
	$(I Identifier) = $(I Identifier)
)

	$(P There are several forms of the $(I ImportDeclaration),
	from generalized to fine-grained importing.)

	$(P The order in which $(I ImportDeclarations) occur has no
	significance.)

	$(P $(I ModuleName)s in the $(I ImportDeclaration) must be fully
	qualified
	with whatever packages they are in. They are not considered to
	be relative to the module that imports them.)

<h3>Basic Imports</h3>

	$(P The simplest form of importing is to just list the
	modules being imported:)

---------
import std.stdio;  // import module $(B stdio) from the $(B std) package
import foo, bar;   // import modules $(B foo) and $(B bar)

void main()
{
    writefln("hello!\n");  // calls std.stdio.writefln
}
---------

	$(P How basic imports work is that first a name is searched for in the
	current namespace. If it is not found, then it is looked for in the
	imports.
	If it is found uniquely among the imports, then that is used. If it is
	in more than one import, an error occurs.
	)

---
module A;
void foo();
void bar();
---

---
module B;
void foo();
void bar();
---

---
module C;
import A;
void foo();
void test()
{ foo(); // C.foo() is called, it is found before imports are searched
  bar(); // A.bar() is called, since imports are searched
}
---

---
module D;
import A;
import B;
void test()
{ foo();   // error, A.foo() or B.foo() ?
  A.foo(); // ok, call A.foo()
  B.foo(); // ok, call B.foo()
}
---

---
module E;
import A;
import B;
alias B.foo foo;
void test()
{ foo();   // call B.foo()
  A.foo(); // call A.foo()
  B.foo(); // call B.foo()
} 
---

<h3>Public Imports</h3>

	$(P By default, imports are $(I private). This means that
	if module A imports module B, and module B imports module
	C, then C's names are not searched for. An import can
	be specifically declared $(I public), when it will be
	treated as if any imports of the module with the $(I ImportDeclaration)
	also import the public imported modules.
	)

---
module A;
void foo() { }
---

---
module B;
void bar() { }
---

---
module C;
import A;
public import B;
...
foo();	// call  A.foo()
bar();	// calls B.bar()
---

---
module D;
import C;
...
foo();	// error, foo() is undefined
bar();	// ok, calls B.bar()
---

<h3>Static Imports</h3>

	$(P Basic imports work well for programs with relatively few modules
	and imports. If there are a lot of imports, name collisions
	can start occurring between the names in the various imported modules.
	One way to stop this is by using static imports.
	A static import requires one to use a fully qualified name
	to reference the module's names:
	)

---
static import std.stdio;

void main()
{
    writefln("hello!");            // error, writefln is undefined
    std.stdio.writefln("hello!");  // ok, writefln is fully qualified
}
---


<h3>Renamed Imports</h3>

	$(P A local name for an import can be given, through which
	all references to the module's symbols must be qualified
	with:)

---
import io = std.stdio;

void main()
{
    io.writefln("hello!");         // ok, calls std.stdio.writefln
    std.stdio.writefln("hello!");  // error, std is undefined
    writefln("hello!");            // error, writefln is undefined
}
---

	$(P Renamed imports are handy when dealing with
	very long import names.)

<h3>Selective Imports</h3>

	$(P Specific symbols can be exclusively imported from
	a module and bound into the current namespace:)

---
import std.stdio : writefln, foo = writef;

void main()
{
    std.stdio.writefln("hello!");  // error, std is undefined
    writefln("hello!");            // ok, writefln bound into current namespace
    writef("world");               // error, writef is undefined
    foo("world");                  // ok, calls std.stdio.writef()
    fwritefln(stdout, "abc");      // error, fwritefln undefined
}
---

	$(P $(B static) cannot be used with selective imports.)

<h3>Renamed and Selective Imports</h3>

	$(P When renaming and selective importing are combined:)

------------
import io = std.stdio : foo = writefln;

void main()
{
    writefln("bar");           // error, writefln is undefined
    std.stdio.foo("bar");      // error, foo is bound into current namespace
    std.stdio.writefln("bar"); // error, std is undefined
    foo("bar");                // ok, foo is bound into current namespace,
                               // FQN not required
    io.writefln("bar");        // ok, io=std.stdio bound the name io in
                               // the current namespace to refer to the entire module
    io.foo("bar");             // error, foo is bound into current namespace,
                               // foo is not a member of io
--------------

<h3>Module Scope Operator</h3>

	Sometimes, it's necessary to override the usual lexical scoping rules
	to access a name hidden by a local name. This is done with the
	global scope operator, which is a leading '.':

---------
int x;

int foo(int x)
{
    if (y)
	return x;		// returns foo.x, not global x
    else
	return .x;		// returns global x
}
---------

	The leading '.' means look up the name at the module scope level.

<a name="staticorder"><h2>Static Construction and Destruction</h2></a>

	$(P Static constructors are code that gets executed to initialize
	a module or a class before the main() function gets called.
	Static destructors are code that gets executed after the main()
	function returns, and are normally used for releasing
	system resources.)

	$(P There can be multiple static constructors and static destructors
	within one module. The static constructors are run in lexical order,
	the static destructors are run in reverse lexical order.)

<h3>Order of Static Construction</h3>

	The order of static initialization is implicitly determined by
	the $(I import) declarations in each module. Each module is
	assumed to depend on any imported modules being statically
	constructed first.
	Other than following that rule, there is no imposed order
	on executing the module static constructors.
	<p>

	Cycles (circular dependencies) in the import declarations are
	allowed as long as not both of the modules contain static constructors
	or static destructors. Violation of this rule will result
	in a runtime exception.

<h3>Order of Static Construction within a Module</h3>

	Within a module, the static construction occurs in the lexical
	order in which they appear.

<h3>Order of Static Destruction</h3>

	It is defined to be exactly the reverse order that static
	construction was performed in. Static destructors for individual
	modules will only be run if the corresponding static constructor
	successfully completed.

<h3>Order of Unit tests</h3>

	Unit tests are run in the lexical order in which they appear
	within a module.

<h2>$(LNAME2 MixinDeclaration, Mixin Declaration)</h2>

$(GRAMMAR
$(I MixinDeclaration):
    $(B mixin) $(B $(LPAREN)) $(ASSIGNEXPRESSION) $(B $(RPAREN)) $(B ;)
)

	$(P The $(ASSIGNEXPRESSION)
	must evaluate at compile time
	to a constant string.
	The text contents of the string must be compilable as a valid
	$(GLINK DeclDefs), and is compiled as such.
	)

)

Macros:
	TITLE=Modules
	WIKI=Module
	GLINK=$(LINK2 #$0, $(I $0))
	GNAME=$(LNAME2 $0, $0)
	FOO=

