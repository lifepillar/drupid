### <i class="icon-info-sign icon-large"></i> make.lock files

After each synchronization, Drupid writes a `.make.lock` file, which contains all the version information that is needed to re-build your platform from scratch exactly as it was when the `.make.lock` file was created.
You can also use the `.make.lock` file to quickly verify that your platform has not been tampered:

    drupid -s mysite.make.lock -p mysite -n

Since Drupid caches projects, a command like the above will likely be relatively fast, and it may not even hit the network at all.
