# NAME

got - A tool to make it easier to manage multiple code repositories using different VCSen

# VERSION

version 1.11

# SYNOPSIS

    cd some/proj/in/a/vcs

    got add
    # answer prompts for various information
    # or run with '-D' to take all defaults

    # show managed repositories
    got list
    got ls

    # show managed repositories sorted by path (default = sort by name)
    got ls -p

    # remove repo #1 from the list
    got remove 1

    # remove repo named 'bar' from the list
    got remove bar

    # remove all repos tagged 'foo' without confirmation prompts
    got rm -f -t foo

    # remove repo #3 without confirmation prompts and be noisy about it
    got rm -f -v 3

    # show status (up-to-date, dirty, etc.) for all repos
    got status

    # show status for repo #3
    got st 3

    # update all repos with configured remotes
    got update

    # update repo named 'bar'
    got up bar

    # Note: if a repo is in the list but doesn't have a local checkout, 'got
    # update' will create directories as needed and do the initial check out.

    # spawn a subshell with working directory set to 'path' of repo #1
    got chdir 1

    # spawn a subshell with working directory set to 'path' of repo foo
    got cd foo

    # or use 'tmux' subcommand to open a new tmux window instead
    got tmux 1
    got tmux foo
    # N.b., 'tmux' will reuse an existing window if one is open

    # fork a github repo, add it to your list of repos, and check it out in
    # the current working directory
    got fork https://github.com/somebodies/repo_name

    # note: the default path to a repo added via 'fork' is a directory
    # named 'repo_name' in the current working directory

    # if you just want to fork without checking out a working copy:
    got fork --noclone https://github.com/somebodies/repo_name

    # finally, please note that you need a C<~/.github-identity> file set up
    # with your access token or your username and password in the following key-value
    # format:
    user username
    pass password

    # *OR*
    access_token token

    # note that if you specify both, the access_token value will be used

    # show version of got
    got version

# DESCRIPTION

`got` is a script to make it easier to manage all the version controlled
repositories you have on all the computers you use. It can operate on all,
some, or just one repo at a time, to both check the status of the repo (up to
date, pending changes, dirty, etc.) and sync it with any upstream master.

got also supports forking a GitHub repo and adding it to the list of managed
repositories.

# OPTIONS

In addition to the subcommand-specific options illustrated in the SYNOPSIS,
all the subcommands accept the following options:

- `--verbose / -v`

    Be more verbose about what is happening behind the scenes

- `--quiet / -q`

    Be more quiet

- `--tags / -t`

    Select all repositories that have the given tag. May be given multiple
    times. Multiple args are (effectively) 'and'-ed together.

- `--skip-tags / -T`

    Skip all repositories that have the given tag. May be given multiple
    times. Multiple args are (effectively) 'or'-ed together.  May be combined with
    \-t to select all repos with the -t tag except for those with the -T tag.

- `--no-color / -C`

    Suppress colored output

- `--color-scheme / -c`

    Specify a color scheme. Defaults to 'dark'. People using light backgrounds may
    want to specify "-c light".

    The name given to the option indicates a library to load. By default this
    library is assumed to be in the 'App::GitGot::Outputter::' namespace; the
    given scheme name will be appended to that namespace. You can load something
    from a different namespace by prefacing a '+'. (E.g., '-C +GitGot::pink' will
    attempt to load 'GitGot::pink'.)

    If the requested module can't be loaded, the command will exit.

    See COLOR SCHEMES for details on how to write your own custom color scheme.

- repo name, repo number, range

    Commands may be limited to a subset of repositories by giving a combination of
    additional arguments, consisting of either repository names, repository
    numbers (as reported by the '`list`' subcommand), or number ranges (e.g., `2-4`
    will operate on repository numbers 2, 3, and 4).

    Note that if you have a repository whose name is an integer number, bad things
    are going probably going to happen. Don't do that.

# COLOR SCHEMES

Color scheme libraries should extend `App::GitGot::Outputter` and need to
define four required attributes: `color_error`, `color_warning`,
`color_major_change`, and `color_minor_change`. Each attribute should be a
read-only of type 'Str' with a default value that corresponds to a valid
`Term::ANSIColor` color string.

# SEE ALSO/CREDITS

- [http://github.com/ingydotnet/app-aycabtu-pm/](http://github.com/ingydotnet/app-aycabtu-pm/)

    Seeing Ingy döt Net speak about AYCABTU at PPW2010 was a major factor in the
    development of this script -- earlier (unreleased) versions did not have any way
    to limit operations to a subset of managed repositories; they also didn't deal
    well managing output. After lifting his interface (virtually wholesale) I
    ended up with something that I thought was worth releasing.

- [http://www.leancrew.com/all-this/2010/12/batch-comparison-of-git-repositories/](http://www.leancrew.com/all-this/2010/12/batch-comparison-of-git-repositories/)

    drdrang prodded me about making the color configuration more friendly to those
    that weren't dark backrgound terminal people. The colors in
    `App::GitGot::Outputter::light` are based on a couple of patches that drdrang
    sent me.

- [The Wire](http://en.wikipedia.org/wiki/The_Wire)

# LIMITATIONS

Currently git is the only supported VCS.

# CONTRIBUTORS

- Yanick Champoux <yanick@babyl.dyndns.org>
- Michael Greb <michael@thegrebs.com>
- Chris Prather <chris@prather.org>
- Rolando Pereira

# AUTHOR

John SJ Anderson <genehack@genehack.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
