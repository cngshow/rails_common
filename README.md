<h1>RAILS_COMMON - git submodule</h1>
We have moved the prop loader and logging code into a git repository at https://github.com/VA-CTT/rails_common.git so that the code can
be shared with rails_komet and the PRISME project

To pull the latest code do the following (replace my username with yours where appropriate.):
<ol>
<li>VCS -> Update Project - from within RubyMine</li>
<li>open a terminal and navigate to rails_komet/lib</li>
<li>git submodule add https://cshupp@vadev.mantech.com:4848/git/r/rails_common.git
<li>run git reset from within the lib/rails_common directory</li>
<li>run git  rm -f --cached rails_common from within the lib/rails_common directory if the line above fails</li>
</ol>

```
git reset .
```

You should now see an rails_common directory under the lib directory.
 
