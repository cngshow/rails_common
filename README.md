
<h1>ETS_COMMON - git submodule</h1>
We have moved the prop loader and logging code into a git repository at https://github.com/VA-CTT/ets_common.git so that the code can
be shared with ets_tooling and the PRISME project

To pull the latest code do the following:
1) VCS -> Update Project - from within RubyMine
2) open a terminal and navigate to ets_tooling/lib
3) git submodule add https://github.com/VA-CTT/ets_common
4) run git reset from within the lib/ets_common directory

```
git reset .
```

You should now see an ets_common directory under the lib directory.
 
