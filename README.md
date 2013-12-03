# ActionArgs : RoR plugin

ActionArgs is a Ruby on Rails plugin.  A declarative DSL for
your controller actions.

A quick _examplet_:

```ruby
# First, declare the formal parameters for your action...
args_for :my_action do

  # We require an arg called "hours".
  # If absent, raise an ActionArgs::ArgumentError.
  #
  # It's an Integer. Converted for you (from the input String).
  #
  # It must be between 0-23 inclusive, else an ActionArgs::ArgumentError.
  #
  req(:hours).as(:int).validate_in(0..23)

  # Same deal, basically, except "minutes".
  req(:minutes).as(:int).validate_in(0..59)

  # We may get an arg "filter", a Symbol.
  # If provided, downcase it.
  # If missing, defaults to :name.
  opt(:sort).as(:symbol).default(:name).
    munge(:downcase).
    validate_in [:name, :time]
end

# Then, use the 'args' in your action...
def my_action
  # Use 'args' here, kinda like 'params', except already
  # type-converted, default-valued, and validated.
  case args[:sort]
  when :name
    ...
  when :time
    ...
  end
end

```


## Contents

* [Motivation][1]
* [How to Use It][2]
* [Exceptions][3]

[1]: #motivation
[2]: #use
[3]: #exceptions


<a name="motivation"></a>
## Motivation

Controller actions are special methods in that they interface with
external programs.  In particular:

* They have **no formal parameters** to allow one to declare what input
  they expect.  Rather, they're provided a special hash-like object
  called `params` comprising all supplied arguments from the client.
* And all those arguments arrive as `Strings` (or collections of
  same).

This means that the action has to do work to:

* Sort out what it was given.
* Determine whether it's sufficient and valid.
* Turn it into what it actually needs.

That's a lot of work for each action to have to do.  So let's make it
easier and declarative.

### What Is Expected?

The client-supplied arguments are not guaranteed to match the action's
expectations.  From the action's perspective, these arguments may fall
in one of three varieties:

* **Required**. Necessary for the action's proper functioning.
* **Optional**.  Their mere presence or absence may impact the action's
  behavior in addition to their value.
* **Unused**.  From the action's perspective, they're spurious.  (They
  may be used only for logging, for example.)

The action must deal with these different varieties of arguments
differently.

### Writing Actions

When writing controller actions, dealing with **Unused** arguments is
usually easy (ignore 'em), but with an important caveat: one must be
careful not to pass along the params hash intact to other code, as the
presence of spurious key-value pairs may induce improper behavior.

Dealing with **Required** and **Optional** arguments, however, is trickier.

* For **Required** args, one must explicitly check for their presence
  before using them, or exception-handle if absent.
* For **Optional** args, one must:
  * likewise check for their presence, and either
    * possibly branch on their presence or absence, or
    * supply a default value if absent.
* For both **Required** and **Optional** args, one
  * _must_ usually convert the `Strings` into values of the type one
    really needs (such as ints or booleans or what-have-you).
  * _may_ need to validate those values before using them.

So writing good, robust actions is difficult work.

### Reading Actions

Controller code is not only difficult to write, it can also be
difficult to understand.

First, this is because so much of the action code may be dedicated to
digesting the parameters that the (other) "real" work of the
controller is obscured.

Second, the action's expectations about arguments are not made
immediately apparent.  Sometimes, an argument is expect from the
client but not used directly in the controller and instead passed
along to another object (or chain of them) which may ignore it, or
convert it to another type, or otherwise modify its value, and then
perhaps validate it before using it.  _Oy vey!_ Considerable detective
work may be necessary to determine which arguments are actually used
and how.

### ActionArgs to the Rescue

The goal of ActionArgs is to solve these problems.

<a name="use"></a>
## How to Use It

Or, ["Pulling Args from Params"][4].

[4]: http://www.youtube.com/watch?v=3WngGeI9lnA

### Plugin

First, include ActiveArgs in your RoR application by adding this line
to your Gemfile:

```ruby
gem 'action-args', git: 'git://github.com/marklar/action-args.git'
```

Then, include the mixin ArgyBargy in your ApplicationController:

```ruby
# app/controllers/application.rb
class ApplicationController < ActionController::Base
  include ActionController::ArgyBargy
end
````

ArgyBargy adds the class method `.args_for` which you'll use to
declare your parameters...


### Declare Your Args

Then, in your controller, you may:

* declare for each action:
  * which arguments you expect, and
  * some info about each
* access them via `params`'s evil twin, `args`.

Here's an excessively-commented example:

```ruby
# app/controllers/bojacks_controller.rb
class BojacksController < ApplicationController

  VERTICALS = [:books, :games, :other_crap]
    
  args_for :my_action do

    # Required arg called :vertical.  (If absent: ActionArgs::ArgumentError.)
    # Value is a Symbol (converted from supplied String).
    # Ensure value's validity or raise ActionArgs::ArgumentError.
    #
    req(:vertical).as(:symbol).validate_in(VERTICALS)

    # Optional string arg called :filter.
    # If provided, its value is downcased automatically.
    # If not provided, its value is nil.  (The "default default" is nil.)
    #
    opt(:filter).as(:string).munge(:downcase)

    # Optional hash called :paging.
    # If not provided, :paging is nil.
    #
    # One may not supply a default value for an entire (optional) hash.
    # Instead:
    #  - make the hash required, but
    #  - make each of its k:v pairs optional (with defaults).
    #
    # In this case, the hash is optional.  But if present,
    # both of its members are required.
    #
    opt_hash(:paging) do
      # If :paging hash is present...

      # Required int (Fixnum, really) called :offset.
      # Must be non-negative (or raises ActionArgs::ArgumentError).
      #
      # We then increment it (with :next), because (let's pretend)
      # in our app we really want to use indices starting at 1, not 0.
      # Instead of :next, We could equally well have used:
      #   * a lambda: ->(i) {i+1}
      #   * a block:  {|i| i+1}
      #
      req(:offset).as(:unsigned_int).munge(:next)
    
      # Required int called :limit.
      # Must be positive (or raises ActionArgs::ArgumentError).
      #
      req(:limit).as(:positive_int)
    end
    
    # Optional boolean arg called :show_related_p.
    # If absent, default value is false.
    #
    opt(:show_related_p).as(:bool).default(false)
  end

  def my_action
    # you can use...
    args[:vertical]        # a Symbol, one of VERTICALS
    args[:filter]          # nil -or- a downcased String
    args[:paging]          # nil -or- {offset: <non-neg. int>, limit: <pos. int>}
    args[:show_related_p]  # true -or- false
  end

end
```

#### Optional or Required?

Within your `args_for` block, you may specify whether arguments are
required or optional.

* independent args
  * `req`
  * `opt`
* hash args
  * `req_hash`
  * `opt_hash`
* groups of inter-related args
  * `at_least_one_of` - Unlike the other declarations, `at_least_one_of` doesn't take an argument name.  It takes only a block, within which one defines only `opt` or `opt_hash` arguments.  For example:

```ruby
args_for :foo do
  at_least_one_of do
    opt(:username).as(:string)
    opt(:email_address).as(:string)
  end
end
```

#### Types using `#as`

ActionArgs tries to cover the most common patterns.

Using `#as`, you may declare an argument to be any of these types:

* fundamental
  * `:bool`          (false: `['f', 'false', '0']`.  true: `['t', 'true', '1']`.)
  * `:int`
  * `:positive_int`  (i >  0)
  * `:unsigned_int`  (i >= 0)
  * `:float`
  * `:string`        (_default_)
  * `:symbol`        (for enums)
* arrays
  * `:float_array`
  * `:int_array`
  * `:positive_int_array`
  * `:unsigned_int_array`

If you declare something as `:positive_int` or `:unsigned_int`, or an
`_array` of either of those fundamental types, then ActionArgs
essentially handles part of your validation for you.  However, you are
not restricted from providing additional validation criteria.

You are not required to assign a type using `#as`.  If you don't
declare a type, it will simply remain a String.

(You may wonder why there aren't corresponding `_array` types for all
simple types.  Just haven't gotten there; could do.)

#### Munging using `#munge`

You may specify how to normalize an argument by providing a "munge"
function.

If your munging is simply a unary instance method on the value, you may simply provide its name, like this:

```ruby
req(:some_string).munge(:downcase)
```

That will call `String#downcase` on the passed-in value.

You may instead provide a block:

```ruby
req(:some_string).munge {|s| s.gsub(' ', '_') }
```

NB: Don't use `#gsub!` here, because what you want is the munge
function's return value (which in the case of `#gsub!` might be
`nil`), rather than its mutated argument.

Or, if it's convenient for you, a lambda:

```ruby
some_reusable_lambda = ->(s) { s.gsub(' ', '_') }
...
req(:some_string).munge(some_reusable_lambda)
```

Specifying more than a single "munge" function per parameter does not
work.  If you call `#munge` more than once, the last one "wins".

#### Validation using `#validate` or `#validate_in`

You may also specify a validation function using `#validate`, again
either as a lambda/proc or as a symbol (i.e. method name).  As with
`#munge`, do so only once per parameter.

However, you probably won't. Since checking for set/enum membership is
a very common validation case, ActionArgs also provides a special
`#validate_in` method which you'll probably usually use.
`#validate_in` takes either an Array or a Range.  (Note to self: it
should probably also accept a Set.)  Like this:

```ruby
req(:minutes).as(:unsigned_int).validate_in(0..59)
```

<a name="exceptions"></a>
## Exceptions

But wait, what if something goes wrong?  What if a parameter
declaration actually makes no sense?  Or what if the proper arguments
aren't passed at runtime?

### ActionArgs::ConfigError

If there's an error in an `#args_for` method (which is detectable by
the library), then your app server won't even start up.  ActionArgs
will raise an exception of type `ActionArgs::ConfigError`, explaining what it
thinks you did wrong.  Here are some examples of invalid declarations:

```ruby
# The arg :foo is specified twice.
#
args_for :action1
  req(:foo).as(:int)
  opt(:foo).as(:int)
end

# Required args may not have default values.
# ('Default' means "what to give it if not provided",
# but required args must be provided.)
#
args_for :action2
  req(:foo).default('bar')
end
    
# In this case, the default value ('true') is of the wrong type.
# (It should be an int.)
#
args_for :action3
  opt(:id).as(:int).default(true)
end
    
# The default value (:books) doesn't validate (because `#validate_in`
# is mistakenly looking for a String, not a Symbol).
#
args_for :action4
  opt(:vertical).as(:symbol).default(:books).validate_in(['books', 'games'])
end

# The 'munge' block should accept only one argument, not two.
# This will raise a ConfigError, complaining of an arity error.
#
args_for :action5
  opt(:foo).munge {|a,b| a+b }
end

# This *is* an invalid declaration, because the 'munge' block attempts
# to call #:+ on a boolean.  However, ActionArgs doesn't notice this
# type of declaration error until runtime, when the actual argument is
# passed in.  Had the parameter been an 'opt' arg with a specified
# default, then ActionArgs would have caught the error.
#
args_for :action6
  req(:should_filter).as(:bool).munge {|b| b + 3 }
end

````

ActionArgs can't always know when you've made a mistake, but when it
can determine that a declaration is incoherent, it'll catch it early,
which is good.

### ActionArgs::ArgumentError

If, on the other hand, your declaration seems perfectly sound, but
then at runtime the supplied arguments don't pass muster, then
ActionArgs will raise an exception of type
`ActionArgs::ArgumentError`.  How to handle this?  There are two
options:

* By default, the plugin will handle the exception for you in a
  standard way, using `ApplicationController#rescue_action_locally`.
  Your controller action code will never get called.  If that's good
  by you, you're golden.
* If you want your controller action to get called regardless of
  ActionArgs errors, then you'll need to add `raise_p: false` to
  your `#args_for` declaration, like this:

```ruby
args_for :my_action, raise_p: false do
  ...
end
```

If you tell `#args_for` not to raise, then your action code will be
called, and you may ask of the args object what happened by inspecting
the errors it gathered up in `args.errors`.  Here's an example:

```ruby
def my_action
  if !args.valid?
    # action-specific exception-handling code...
    errors_str = args.errors.map(&:to_s).join("\n")
    render_json(success:   false,
                exception: "Some bojackedness occurred: #{errors_str}")
  else
    # "real" action code...
  end
end
```

And that's it.

