## Dependency graphs

<i class="icon-tint icon-large"></i> Sometimes, you may wonder why Drupid has retrieved a given project when there is no trace of it in the makefile. Sure, it's to meet some dependency. To discover which one, or just to take a look at the relationships among the various modules and themes, you may draw a dependency graph from your platform:

    drupid --graph -p mysite

The result is an SVG image, which you can open in any modern browser. And the  names of the projects will be searchable!
