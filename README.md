
<h1>ETS_COMMON - git submodule</h1>
We have moved the prop loader and logging code into a git repository at https://github.com/VA-CTT/ets_common.git so that the code can
be shared with ets_tooling and the PRISME project

To pull the latest code do the following:
<ol>
<li>VCS -> Update Project - from within RubyMine</li>
<li>open a terminal and navigate to ets_tooling/lib</li>
<li>git submodule add https://github.com/VA-CTT/ets_common</li>
<li>run git reset from within the lib/ets_common directory</li>
</ol>

```
git reset .
```

You should now see an ets_common directory under the lib directory. 