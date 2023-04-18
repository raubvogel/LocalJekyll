# LocalJekyll
Docker container for developing Jekyll-based websites

## Warnings

1. If you want to run Jekyll in a
[docker](https://www.docker.com/)/[podman](https://podman.io/) container
in a production kind of fashion, this may not be the repo for you.
Instead, this is less about running Jekyll and more about building and 
quickly testing a jekyll-based website. Once you are satisfied with your
deed, put it in the production site, or build such a site using something like
[jekyll-docker](https://github.com/envygeeks/jekyll-docker)
instead.

2. I need to come up with another warning...

## About
I do tend to use docker a lot to spool up a dev environment that does not
affect my computer. That means that I am not running docker as it is 
supposed to be (a service), but more like the 
[Python Virtual Environment](https://docs.python.org/3/tutorial/venv.html):
start it, do things as if you were in your desktop, and then close it leaving
no cruft like libraries and modules that you needed to build your 
module/code/library which may conflict with your desktop's setup.

Case in point are some python stuff I do, and now building websites using
[Jekyll](https://jekyllrb.com/), 
specially if they are going to run here at github. 
I learn quickly that fiddling with your repo locally, pushing it up, and
hoping it will look good enough was not the smartest thing to do.

The next best thing to do was to create a container to install all the 
packages I needed in a way that I can run the container, feeding the
local repo, and then do everything I would do if I had installed Jekyll
in my local drive.

The problem I had with that was ensuring the user inside the container had 
enough permissions to use the local drive.  Matching the UID between the two
users was how I initially did it, but thought there was a better way. 
I talked about the solution I came up with (I will not claim I invented
because others may have dones that before me; I just never found them) in
[my blog](https://unixwars.blogspot.com/2023/03/docker-container-user-cannot-write-to.html), and create a 
[repo](https://github.com/raubvogel/bob) for that test case. This repo is 
more about showing a practical application: I use this whenever I am working
on a jekyll website.

## Building it

Nothing special here. Copy repo to your local drive (`git clone` works just
fine) and then go to the using session below.

### Assumptions

These are the default values for the custom settings used in this doc.
Change them to fit your needs.

- Path to your jekyll website: `/path/to/my/repo`. In my case, that may be
`~/dev/web/jekyll/repo`

- We will also say said path is `NFS` mounted to add a bit of difficulty. And
to emulate my own setup (automount `~/dev/web/jekyll`).

- The name of the computer used in these instructions is `lappy` in homage to
the one used by StrongBad. The username for the external user, `user`, has a 
lesser interesting background history. `user` UID and GID are the same, `1500`

- The user inside the container is called `mrhide`, whose UID and GID are
`1995` (with $9 shipping and handling). 

- The default UID for `user` is different than that of `mrhide`. This is
exactly the point of this entire repo.

- For this example I am using the default jekyll server port, `4000`, both 
inside the container and as the exposed port. 

## Using it

My (local) user can run docker, which is why I am passing its default group ID
(using `id -g`). That is not a requirement; what matters is that the
group being passed to `EXTGID` is the group which can write to 
`/path/to/my/repo`.

If you peeked at the `Dockerfile` you will notice that it installs `vim`,
`git`, and even `lynx`. The idea is that if you, for instance, chose
to follow the 
[step-by-step setup](https://jekyllrb.com/docs/step-by-step/01-setup/)
in the jekyl site, it has already installed `jekyll` and `bundler` for you,
including all of their requirements. When you start the container, you
go to wherever you are building the site and start from the `bundle init` 
step. If you are using the 
[github](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/creating-a-github-pages-site-with-jekyll)
instructions. 


### Configure the directory you need to access from inside the container

1. Create the directory `/path/to/my/repo`.

``` bash
user@lappy:~$ mkdir /path/to/my/repo
user@lappy:~$ 
```

2. Set the permissions for `/path/to/my/repo`. Note the usage of the sticky 
bit.

``` bash
user@lappy:~$ chmod -R 2770 /path/to/my/repo
user@lappy:~$ 
```

3. Now start the container. Note we are exposing port `4000` as we mentioned 
earlier on. 

``` bash
user@lappy:~$ docker run -i --rm -p 4000:4000 \
-v /path/to/my/repo:/home/mrhide/site \
-e EXTGID=$(id -g) -t localjekyll bash
Adding user `mrhide' to group `extgroup' ...
Adding user mrhide to group extgroup
Done.
mrhide@6aaefdf74d14:~$ 
```

4. Let's now create the `docs` file used by jekyll. Note the UID and GID; they
look like that because my repos are first mounted off a nfs fileshare into my
local drive and then passed to docker. Ignore it.

``` bash
mrhide@6aaefdf74d14:~$ mkdir site/docs
mrhide@6aaefdf74d14:~$ ls -l site/
total 8
drwxrwxr-x 6 nobody 4294967294 4096 Mar 12 01:50 docs
mrhide@6aaefdf74d14:~$ 
```

5. What is my UID inside the container and which groups do I belong to?

``` bash
mrhide@6aaefdf74d14:~$ id
uid=1995(mrhide) gid=1995(mrhide) groups=1995(mrhide),1500(extgroup)
mrhide@6aaefdf74d14:~$ 
```

6. Let's create a file

``` bash
mrhide@6aaefdf74d14:~$ touch site/docs/noo
mrhide@6aaefdf74d14:~$ ls -lh site/docs/noo
-rw-rw-r-- 1 nobody 4294967294 0 Mar 12 03:32 site/docs/noo
mrhide@6aaefdf74d14:~$ 
```

7. How does that look from the outside of the container? In another 
terminal session/tmux tab,

``` bash
user@lappy:~$ ls -l /path/to/my/repo/docs/noo 
-rw-rw-r-- 1 nobody 4294967294 0 Mar 12 03:32 /path/to/my/repo/docs/noo
user@lappy:~$ rm /path/to/my/repo/docs/noo 
user@lappy:~$ 
```

8. Now we are ready to test it by building the default test website using the 
[minima](https://github.com/jekyll/minima) jekyll template.
I will not show the output of each step but something like this would get it
working (I like to use `bundle update` instead of `bundle install`).
So, get inside the `docs` directory and

``` bash
jekyll new --skip-bundle .
bundle update
bundle exec jekyll serve --host 0.0.0.0
```

And then check if you can see the website as usual.

## To Be Done
1. The alpine Dockerfile. I started it and then just focused on getting the
ubuntu one done.
