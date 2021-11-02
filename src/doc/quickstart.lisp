(defpackage #:weblocks/doc/quickstart
  (:use #:cl)
  (:import-from #:40ants-doc
                #:defsection)
  (:import-from #:weblocks/doc/routing
                #:@routing)
  (:import-from #:weblocks/doc/example
                #:defexample)
  (:import-from #:weblocks-ui/form)
  (:import-from #:weblocks/html)
  (:export #:@quickstart))
(in-package weblocks/doc/quickstart)


(defsection @quickstart (:title "Quickstart"
                         :ignore-words ("ASDF"
                                        "TODO"
                                        "CLOS"
                                        "REPL"
                                        "POST"
                                        "HTML"
                                        "DOM"
                                        "UI"
                                        "DONE"
                                        "ADD-TASK"
                                        "ONCLICK"
                                        "TOGGLE"
                                        "TASK-LIST"
                                        "RENDER"
                                        "AJAX"))
  "
> This version of Weblocks is not in Quicklisp yet. To
> install it you need to clone the repository somewhere where
> ASDF will find it, for example, to the `~/common-lisp/` directory.
> You also need to clone [weblocks-ui][weblocks-ui].

> You can also install the [Ultralisp][Ultralisp] Quicklisp distribution where all Weblocks-related libraries are present and up to date.


Load weblocks and create a package for a sandbox:

```
CL-USER> (ql-dist:install-dist \"http://dist.ultralisp.org/\"
                               :prompt nil)
CL-USER> (ql:quickload '(:weblocks :weblocks-ui :find-port))
CL-USER> (defpackage todo
           (:use #:cl
                 #:weblocks-ui/form
                 #:weblocks/html)
           (:import-from #:weblocks/widget
                    #:render
                    #:update
                    #:defwidget)
           (:import-from #:weblocks/actions
                    #:make-js-action)
           (:import-from #:weblocks/app
                    #:defapp))
#<PACKAGE \"TODO\">
CL-USER> (in-package todo)
#<PACKAGE \"TODO\">
```

Now, create an application:

```
TODO> (defapp tasks)
```

By default, the name of the app defines the url where it is
accessible. Here, the \"tasks\" app will be accessible under
<http://localhost:40000/tasks>. We can change it with the
PREFIX argument of WEBLOCKS/APP:DEFAPP:

```
TODO> (defapp tasks
         :prefix \"/\")
```

Now our app runs under the root url.

```
TODO> (weblocks/debug:on)
TODO> (defvar *port* (find-port:find-port))
TODO> (weblocks/server:start :port *port*)
 <INFO> [19:41:00] weblocks/server server.lisp (start) -
  Starting weblocks WEBLOCKS/SERVER::PORT: 40000
  WEBLOCKS/SERVER::SERVER-TYPE: :HUNCHENTOOT DEBUG: T
 <INFO> [19:41:00] weblocks/server server.lisp (start-server) -
  Starting webserver on WEBLOCKS/SERVER::INTERFACE: \"localhost\"
  WEBLOCKS/SERVER::PORT: 40000 DEBUG: T
 #<SERVER port=40000 running>
 (NIL)
```

Open <http://localhost:40000/tasks/> in your browser (double check the port) and you'll see a
text like that:

```
No weblocks/session:init method defined.
Please define a method weblocks.session:init to initialize a session.

It could be something simple, like this one:

(defmethod weblocks/session:init ((app tasks))
            \"Hello world!\")

Read more in the documentaion.
```

It means that you didn't write any code for your application. Let's do
it now and make an application which outputs a list of tasks.

In the end, we'll build the mandatory TODO-list app:

![The TODO-list app in Weblocks](docs/images/quickstart-check-task.gif)

# The Task widget

```
TODO> (defwidget task ()
        ((title
          :initarg :title
          :accessor title)
         (done
          :initarg :done
          :initform nil
          :accessor done)))
```

This code defines a task widget, the building block of our
application. WEBLOCKS/WIDGET:DEFWIDGET is similar to Common Lisp's DEFCLASS,
in fact it is only a wrapper around it. It takes a name, a list of
super-classes (here `()`) and a list of slot definitions.

We can create a task with MAKE-INSTANCE:

```
TODO> (defvar *task-1* (make-instance 'task :title \"Make my first Weblocks app\"))
TODO> *task-1*
#<TASK {1005406F33}>
```

Above, we provide only a TITLE argument, and since we didn't give a DONE argument,
it will be instanciated to its initform, which is NIL.

We defined accessors for both slots, so we can read and set them easily:

```
TODO> (title *task-1*)
\"Make my first Weblocks app\"
TODO> (done *TASK-1*)
NIL
TODO> (setf (done *TASK-1*) t)
T
```

We define a constructor for our task:

```
TODO> (defun make-task (title &key done)
        (make-instance 'task :title title :done done))
```

It isn't mandatory, but it is good practice to do so.


If you are not familiar with the Common Lisp Object System (CLOS), you
can have a look at [Practical Common Lisp][PCL]
and the [Common Lisp Cookbook][CLOS-Cookbook].

Now let's carry on with our application.


# The Tasks-list widget

Below we define a more general widget that contains a list of tasks,
and we tell Weblocks how to display them by *specializing* the
WEBLOCKS/WIDGET:RENDER generic-function for our newly defined classes:

```
TODO> (defwidget task-list ()
        ((tasks
          :initarg :tasks
          :accessor tasks)))

TODO> (defmethod render ((task task))
        \"Render a task.\"
        (with-html
              (:span (if (done task)
                         (with-html
                               (:s (title task)))
                       (title task)))))

TODO> (defmethod render ((widget task-list))
        \"Render a list of tasks.\"
        (with-html
              (:h1 \"Tasks\")
              (:ul
                (loop for task in (tasks widget) do
                      (:li (render task))))))
```

The WEBLOCKS/HTML:WITH-HTML macro uses
[Spinneret][Spinneret] under the hood,
but you can use anything that outputs html.

We can check how the generated html looks like by calling
WEBLOCKS/WIDGET:RENDER generic-function in the REPL:


```
TODO> (render *task-1*)
<div class=\"widget task\"><span>Make my first Weblocks app</span>
</div>
NIL
```

But we still don't get anything in the browser.


```
TODO> (defun make-task-list (&rest rest)
        (let ((tasks (loop for title in rest
                        collect (make-task title))))
          (make-instance 'task-list :tasks tasks)))

TODO> (defmethod weblocks/session:init ((app tasks))
         (declare (ignorable app))
         (make-task-list \"Make my first Weblocks app\"
                         \"Deploy it somewhere\"
                         \"Have a profit\"))
```

This defines a list of tasks (for simplicity, they are defined as a
list in memory) and returns what will be our session's root widget..

Restart the application:

```
TODO> (weblocks/debug:reset-latest-session)
```

Right now it should look like this:

[Webinspector]: https://developers.google.com/web/tools/chrome-devtools/inspect-styles/
[Ultralisp]: https://ultralisp.org/
[Weblocks-ui]: https://github.com/40ants/weblocks-ui/
[PCL]: http://www.gigamonkeys.com/book/object-reorientation-classes.html
[CLOS-Cookbook]: https://lispcookbook.github.io/cl-cookbook/clos.html
[DB-Cookbook]: https://lispcookbook.github.io/cl-cookbook/databases.html
[Spinneret]: https://github.com/ruricolist/spinneret/

"

  (example1 weblocks-example)

  "
# Adding tasks

Now, we'll add some ability to interact with a list – to add some tasks
into it, like so:

![Adding tasks in our TODO-list interactively.](docs/images/quickstart-add-task.gif)

Import a new module, [weblocks-ui][weblocks-ui] to help in creating forms and other UI elements:

```
TODO> (ql:quickload \"weblocks-ui\")
TODO> (use-package :weblocks-ui/form)
```

Write a new ADD-TASK method and modify the RENDER method of a
task-list to call ADD-TASK in response to POST method:

```
TODO> (defmethod add-task ((task-list task-list) title)
        (push (make-task title)
              (tasks task-list))
        (update task-list))
            
TODO> (defmethod render ((task-list task-list))
        (with-html
          (:h1 \"Tasks\")
          (loop for task in (tasks task-list) do
            (render task))
          (with-html-form (:POST (lambda (&key title &allow-other-keys)
                                         (add-task task-list title)))
            (:input :type \"text\"
                    :name \"title\"
                    :placeholder \"Task's title\")
            (:input :type \"submit\"
                    :value \"Add\"))))

TODO> (weblocks/debug:reset-latest-session)
```

The method ADD-TASK does only two simple things:

- it adds a task into a list;
- it tells Weblocks that our task list should be redrawn.

This second point is really important because it allows Weblocks to render
necessary parts of the page on the server and to inject it into the HTML DOM
in the browser. Here it rerenders the task-list widget, but we can as well [WEBLOCKS/WIDGET:UPDATE][generic-function]
a specific task widget, as we'll do soon.

We are calling ADD-TASK from a lambda function to catch a
TASK-LIST in a closure and make it availabe when weblocks will
process AJAX request with POST parameters later.

Another block in our new version of RENDER of a TASK-LIST is the form:

```
(with-html-form (:POST #'add-task)
   (:input :type \"text\"
    :name \"task\"
    :placeholder \"Task's title\")
   (:input :type \"submit\"
    :value \"Add\"))
```

It defines a text field, a submit button and an action to perform on
form submit.

Go, try it! This demo is interative:

[Webinspector]: https://developers.google.com/web/tools/chrome-devtools/inspect-styles/
[Ultralisp]: https://ultralisp.org/
[Weblocks-ui]: https://github.com/40ants/weblocks-ui/
[PCL]: http://www.gigamonkeys.com/book/object-reorientation-classes.html
[CLOS-Cookbook]: https://lispcookbook.github.io/cl-cookbook/clos.html
[DB-Cookbook]: https://lispcookbook.github.io/cl-cookbook/databases.html
[Spinneret]: https://github.com/ruricolist/spinneret/
"

  (example2 weblocks-example)

  
  "
> **This is really amazing!**
> 
> With Weblocks, you can handle all the business logic
> server-side, because an action can be any lisp function, even an
> anonymous lambda, closuring all necessary variables.

Restart the application and reload the page. Test your form now and see in a
[Webinspector][Webinspector] how Weblocks sends requests to the server and receives
HTML code with rendered HTML block.

Now we'll make our application really useful – we'll add code to toggle the tasks' status.


# Toggle tasks

```
TODO> (defmethod toggle ((task task))
        (setf (done task)
              (if (done task)
                  nil
                  t))
        (update task))

TODO> (defmethod render ((task task))
        (with-html
          (:p (:input :type \"checkbox\"
            :checked (done task)
            :onclick (make-js-action
                      (lambda (&key &allow-other-keys)
                        (toggle task))))
              (:span (if (done task)
                   (with-html
                         ;; strike
                         (:s (title task)))
                 (title task))))))
```

We defined a small helper to toggle the DONE attribute, and we've
modified our task rendering function by adding a code to render a
checkbox with an anonymous lisp function, attached to its
ONCLICK attribute.

The WEBLOCKS/ACTIONS:MAKE-JS-ACTION function returns a Javascript code,
which calls back a lisp lambda function when evaluated in the browser.
And because TOGGLE updates a Task widget, Weblocks returns on this
callback a new prerendered HTML for this one task only.

Here is how our app will work now:

[Webinspector]: https://developers.google.com/web/tools/chrome-devtools/inspect-styles/
[Ultralisp]: https://ultralisp.org/
[Weblocks-ui]: https://github.com/40ants/weblocks-ui/
[PCL]: http://www.gigamonkeys.com/book/object-reorientation-classes.html
[CLOS-Cookbook]: https://lispcookbook.github.io/cl-cookbook/clos.html
[DB-Cookbook]: https://lispcookbook.github.io/cl-cookbook/databases.html
[Spinneret]: https://github.com/ruricolist/spinneret/
"

  (example3 weblocks-example)
  "


# What is next?

As a homework:

1. Play with lambdas and add a \"Delete\" button next after
   each task.
2. Add the ability to sort tasks by name or by completion flag.
3. Save tasks in a database (this [Cookbook chapter][DB-Cookbook] might help).
4. Read the WEBLOCKS/DOC/ROUTING:@ROUTING section.
5. Read the rest of the documentation and make a real application, using the full
   power of Common Lisp.

[Webinspector]: https://developers.google.com/web/tools/chrome-devtools/inspect-styles/
[Ultralisp]: https://ultralisp.org/
[Weblocks-ui]: https://github.com/40ants/weblocks-ui/
[PCL]: http://www.gigamonkeys.com/book/object-reorientation-classes.html
[CLOS-Cookbook]: https://lispcookbook.github.io/cl-cookbook/clos.html
[DB-Cookbook]: https://lispcookbook.github.io/cl-cookbook/databases.html
[Spinneret]: https://github.com/ruricolist/spinneret/
")


(defexample example1 ()
  (weblocks/widget:defwidget task ()
    ((title
      :initarg :title
      :accessor title)
     (done
      :initarg :done
      :initform nil
      :accessor done)))
  
  (weblocks/widget:defwidget task-list ()
    ((tasks
      :initarg :tasks
      :accessor tasks)))

  (defmethod weblocks/widget:render ((task task))
    "Render a task."
    (weblocks/html:with-html
      (:span (if (done task)
                 (:s (title task))
                 (title task)))))

  (defmethod weblocks/widget:render ((widget task-list))
    "Render a list of tasks."
    (weblocks/html:with-html
      (:h1 "Tasks")
      (:ul
       (loop for task in (tasks widget) do
         (:li (weblocks/widget:render task))))))

  (defun make-task (title &key done)
    (make-instance 'task :title title :done done))

  (defun make-example ()
    (make-instance 'task-list
                   :tasks (list (make-task "Make my first Weblocks app")
                                (make-task "Deploy it somewhere")
                                (make-task "Have a profit")))))


(defexample example2 (:inherits example1 :height "15em")
  (defmethod add-task ((task-list task-list) title)
    (push (make-task title)
          (tasks task-list))
    (weblocks/widget:update task-list))
  
  (defmethod weblocks/widget:render ((task-list task-list))
    (weblocks/html:with-html
      (:h1 "Tasks")
      (loop for task in (tasks task-list) do
        (weblocks/widget:render task))
      (weblocks-ui/form:with-html-form (:POST (lambda (&key title &allow-other-keys)
                                                (add-task task-list title)))
        (:input :type "text"
                :name "title"
                :placeholder "Task's title")
        (:input :type "submit"
                :value "Add")))))


(defexample example3 (:inherits example2 :height "15em")

  (defmethod toggle ((task task))
    (setf (done task)
          (if (done task)
              nil
              t))
    (weblocks/widget:update task))

  (defmethod weblocks/widget:render ((task task))
          (weblocks/html:with-html
            (:p (:input :type "checkbox"
                        :checked (done task)
                        :onclick (weblocks/actions:make-js-action
                                  (lambda (&key &allow-other-keys)
                                    (toggle task))))
                (:span (if (done task)
                           (weblocks/html:with-html
                             ;; strike
                             (:s (title task)))
                           (title task)))))))
