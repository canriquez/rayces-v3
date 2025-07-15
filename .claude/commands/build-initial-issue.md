generete the INITIAL-{{$ARGUMENTS}}.md file by learning about the issue $ARGUMENTS using the gh mcp and searching through the github account for this project repository. Find the project repository url inside the file CLAUDE.md

You will store the new file `INITIAL-{{$ARGUMENTS}}.md` inside the final location `issues/{{$ARGUMENTS}}/INITIAL-{{$ARGUMENTS}}.md` if the folders do not exist, you will create them so you can successfully add the final file in the right location.

To complete the generation of this file, you will use all available and latest documentation conained already in the project folder, and also check inside jira and confluence for all related documentation material that you see necessary. You will seach using gh account inside the issues using the name of the issue and not the url. As an example, it might be that containst the string `{{$ARGUMENTS}}` inside its name is actually the issue located in the url `https://github.com/... .../2`, so be careful with this.

The file should have the following structure sections

## Feature
## Examples
## Documentation
## Other considerations - e.g: Check README.md to learn key instructions on how to run tests on the current dev environment.

# File content example: Now find below a by section explanation example that should help you generate each of the sections of this file. I will include between double quotes ("") the explanation pargraphs


<example_file>
## Feature
""With all the documentation collected, you should summarise the feature description including all its requirements. The include on this sections a summary auto explanatory list of al the tasks that are required for this issue to be solved""

## Examples
""You will search the web for valid examples and generate all example code snippets that you see required for further context inside the folder `issues/{{$ARGUMENTS}}/examples/`. 

Considering that the issue has the references called `{{$ARGUMENTS}}`, you will search the internet and use our documentation mcp `context7` for references and store the top 5 code snippet examples relative to the issue we need to solve and generate the files and locate them in the right places. Then you will include te absolut reference inside the section examples of the document


The files should be stored inside the project folder like this example below:

```
issues/[SCRUM-40]/examples/multi-tenant-example.rb
issues/[SCRUM-40]/examples/ui-module.ts
```

then later inside the ## Examples section of the document you should store the references like this: 
""

- `issues/{{$ARGUMENTS}}/examples/multi-tenant-example.rb` use this snippet generate the multi tenant code
- `issues/{{$ARGUMENTS}}/examples/ui-module.ts` read through all this example to understand the best practices we should use inside the final solution for the ui-module.


Do not copy any of this examples directly, it is for a different project entirely. But use this as inspiration for best practices.

## Documentation

""Store here any relevant documentation link that sould help solve and implement the issue""

## Other considerations

""Here you will add any other generic considerations that should help the implementation of the issue with no problems""

- Include a .env.example, README with instructions for setup including how to configure Gmal and Brave
- Include the project structure in the README
- Virtual environment has already been setup with the necessary dependancies.
- Usepthon_dotenv and load_env() for environment variables

</example_file>
