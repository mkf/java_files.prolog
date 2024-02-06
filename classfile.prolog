schema(classfile, [
	   u(4, magic, 0xCAFEBABE) - seek(4, just),
	   u(2, bytes, classfileformat(minor)) - seek(6, just),
	   u(2, bytes, classfileformat(major)) - seek(8, just),
	   u(2, count(constant_pool),_) - seek(10, just),
	   table(constant_pool) - seek(10, cp_size),
	   u(2, accessflags,_) - seek(12, cp_size),
	   u(2, index(constant_pool, class(this))) - seek(14, cp_size),
	   u(2, index(constant_pool, class(super))) - seek(16, cp_size),
	   u(2, count, interfaces) - seek(18, cp_size),
	   table(interfaces) - seek(18, cpi_size),
	   u(2, count, fields) - seek(20, cpi_size),
	   table(fields) - seek(20, cpif_size),
	   u(2, count, methods) - seek(22, cpif_size),
	   table(methods) - seek(22, cpifm_size),
	   u(2, count, attributes) - seek(24, cpifm_size),
	   table(attributes) - seek(24, cpifma_size)
	  ]).
bits(accessflags, [public_ - 0x1, private_ - 0x2, protected_ - 0x4, static_ - 0x8, final_ - 0x10,
		   synchronized_ - 0x20, bridge - 0x40,
		   super_ - 0x20,
		   volatile_ - 0x40, transient_ - 0x80,
		   varargs_ - 0x80, native_ - 0x100, 
		   interface_ - 0x200, abstract_ - 0x400, strict_ - 0x800,
		   synthetic_ - 0x1000, annotation_ - 0x2000,
		   enum_ - 0x4000, module_ - 0x8000]).
tags(constant_pool, [null - 0, utf8 - 1, abandoned_unicode - 2,
		     number1(integer) - 3, number1(float) - 4, number2(long) - 5, number2(double) - 6,
		     class - 7, string - 8,
		     ref(field) - 9, ref(method) - 10, ref(interface_method) - 11,
		     name_and_type - 12, java7(method, handle) - 15, java7(method, type) - 16,
		     dynamic_ref(java11) - 17, dynamic_ref(java7(invoke)) - 18,
		     java9(module) - 19, java9(package) - 20 ]).
struct_by_tag(constant_pool, info/1, u(1, tag(constant_pool)),
	      [class - [u(2, index(constant_pool, utf8, name))],
	       ref(_) - [u(2, index(constant_pool, class)),
			 u(2, index(constant_pool, name_and_type))],
	       string - [u(2, index(constant_pool, utf8))],
	       number1(_) - [u(4, bytes)], number2(_) - [u(4, bytes, high), u(4, bytes, low)],
	       name_and_type - [u(2, index(constant_pool, utf8, name)),
				u(2, index(constant_pool, utf8, descriptor))],
	       utf8 - [u(2, count(bytes)), table(bytes)],
	       java7(method, handle) - [u(1, tag(reference)), u(2, index(constant_pool, ref(_)))],
	       java7(method, type) - [u(2, index(constant_pool, utf8, descriptor))],
	       dynamic_ref(_) - [u(2, index(bootstrap_methods)), u(2, index(constant_pool, name_and_type))],
	       java9(_) - [u(2, index(constant_pool, utf8, name))] ]).
struct(X, [u(2, accessflags), u(2, index(constant_pool, utf8, name)), u(2, index(constant_pool, utf8, descriptor)),
		u(2, count(attributes)), table(attributes)]) :- X = fields ; X = methods.
struct(attributes, [u(2, index(constant_pool, utf8, name)), u(4, count(bytes)), table(bytes)]).
example_classfile(Filepath) :-
    string_concat
    (Home,			   
     "/eclipse-jee/src/eclipse/plugins/com.sun.jna_5.13.0.v20230812-1000/com/sun/jna/WeakMemoryHolder.class",
    Filepath),
    getenv("HOME", Home).
open(Filename, read, _Fd, [alias(example_classfile), bom(false), type(binary)]).
proces :- fill_buffer(example_classfile),
	  read_pending_codes(example_classfile, Chars, Tail),
	  schema(classfile, Entries),
	  proces(Chars, Entries), !.
difference_entry(A, B, A - B).
grab(Taken, Leftover, Given, u(2, _, _)) :- fail.
    
proces(Chars, [ Entry - seek(_, _) | Schema ]) :-
    grab(_, Leftover, Chars, Entry), !,
    proces(Leftover, Schema), !.
