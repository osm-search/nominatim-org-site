---
layout: post
title: "Increasing code quality: Static typing for Python Code"
author: Sarah Hoffmann (lonvia)
---

When porting the Nominatim's data importer to Python last year, code quality
played an important role. There are unit tests for every function and a linting tool
runs regularly as part of the continuous integration to find the little code
smells that are the first sign of bigger issues with the code. Now we have
added an additional level of quality checks: static type checking.

Python is a dynamically typed programming language. Variables in Python do
have types but they are implicit and can be changed with a simple assignment.
This gives Python a great degree of flexibility and makes it so useful as a
quick prototyping language.  Problem is that as the code base grows it can also get
in the way of efficient programming. Whenever you define a function, you usually
make implicit assumptions about the type of the parameters and return values.
Say, your function takes the ID of an OSM node as a parameter. As you know it
is a number, you might expect that the ID has a type `int` because it would be
inefficient if the function itself tries to convert the input parameter into
a number every time. These kind of assumptions are made all the time. As the
code base grows, it gets harder to remember these assumptions. The result is
that you need to keep re-reading your own code to remember what you did. This
is tedious and error prone.

To solve the problem, Python has come up with the concept of
[type annotations](https://docs.python.org/3/library/typing.html), They allow
the programmer to add hints about the expected type of a parameter, variable
or return parameter of a function. These annotations don't make a statically
typed language out of Python. In fact, the annotations are completely ignored
at runtime. Instead they can be used with static type checkers like
[mypy](http://www.mypy-lang.org/). They analyse the code without executing it
and highlight places where functions are used without the expected types.
This helps a lot with code quality. However, the far bigger benefit of
annotations for a code maintainer is their documentation value. No more
guessing if a function may return a `None` value. The annotation spells it out.

In the past few weeks, I've gone through the Python code in Nominatim and
annotated parameters and return values of every single function. This was no
small undertaking. The code has grown to more than 500 functions by now. Some
of them are quickly annotated but others caused some real headache. Here
are the most important lessons I learned.

### The temptations of Python data types

Python comes with a set of basic data types: tuples, lists, dictionaries, sets.
They are simple to understand and, when put together, provide convenient way
to quickly build up complex data structures. There are some places in Nominatim
where I was lazy and used such nested data types instead of defining a proper data class.
These turned out to be a big hurdle for type annotations. Reverse engineering
the structures from the code is time consuming and the resulting annotations are
hard to read. In addition, the annotations have a limited documentation value.
It is nice to know that a function returns a
`Tuple[List[Tuple[int, str]], str, Optional[str]]`. The type checker may
even infer if the function was used correctly. But the programmer is none
the wiser what all these lists and strings in the return value may contain
and has to go back to reading the code.

The type annotations have pinpointed the parts where there is some
future work to do. Getting rid of nested data structures will make the code
more understandable for future maintainers and contributors alike.

### The battle of the code checkers

One of the dangers of having many different code checkers is that they
disagree on how things are done. This usually is less of a problem with Python
because it come with a lot of official coding rules. If you stick to the
recommendations, then most code checkers will work right out of the box.
Type annotations seem to be a bit of an exception. They do come with
official recommendations how to use them in code but the recommended style is
different enough from that for normal code, that our linting tool
[pylint](https://pylint.pycqa.org/en/latest/) would often enough disagree
with the demands of mypy. In the end, it is a question of containing the
problematic cases. A new module `nominatim.typing` takes mostly care of that.

### Working with external libraries

Probably the most tricky part of type annotations was where external libraries
are involved. While Python's standard library is well annotated by now, there
is very little typing information available for the other libraries Nominatim
uses. In theory, this shouldn't be a problem because mypy can work with a
mixture of dynamically and statically typed code. In practise, the transition
from unannotated library functions to our statically typed code occasionally
requires rather ugly casting. Not helpful for the goal to produce code that
is well readable. In the case of the psycopg2 library it turned out to be
easier to [submit type annotations to typeshed](https://github.com/python/typeshed/pull/8263)
than to litter Nominatim with casts. The PR was reviewed, merged and published
in a matter of days. That's the spirit of open source!
