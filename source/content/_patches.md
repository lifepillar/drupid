## Patches

<i class="icon-tint icon-large"></i> Drupid greatly simplifies the process of creating patches for any project. For example:

    drupid --edit drupal-8.x
    drupid --edit media-7.x-1.2
    drupid --edit http://codemirror.net/codemirror.zip

Drupid downloads a pristine copy of the specified project in a temporary directory, creates a temporary Git repository, and opens an interactive shell. From there, you may make any changes you wish, using the method you prefer. When you are done, just exit the shell. Puff, the patch will be printed to the standard output. Or you can use `--out` to specify an output file.

If the project you want to patch already exists locally, just do:

    cd path/to/myproject
    drupid --edit
