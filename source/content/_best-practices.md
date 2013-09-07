### <i class="icon-thumbs-up icon-large"></i> Best practices

If you use version control (and you should), keeping under version control the `.make` file and the `.make.lock` file, together with all the necessary patches, is all you need to maintain a history of your platform changes and the integrity of your platform (provided that you run Drupid from time to time!).

Note that, if you use Drupid, the only correct way to change the code of a project is to create a patch, include it in the site's makefile, and run Drupid to synchronize your site. You should never modify a project's code directly!
