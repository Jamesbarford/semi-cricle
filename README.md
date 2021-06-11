# WIP: semi-circle

A simple circle ci command line application for getting the status of pipelines. Can be used in a loop to perform simple polling and piped into `jq` for queriying

# Command line arguments

- `-b` Name of branch
- `-p` Name of project
- `-c` Name of company
- `-i` Pipeline id
- `-v` Version control system, defaults to github
- `-h` Print usage

# Supported Methods
The following methods are supported:
- `get_branch_pipeline` returns pipeline information
- `get_workflow` pipeline id, returns workflow information for the given pipeline id and branch
- `get_my_branch_pipeline` returns only your pipelines for a branch

__Examples:__

`get_branch_pipeline` and `get_my_branch_pipeline`

Getting pipline information for a branch, will return `JSON` this can then be piped into `jq` to query or format

```sh
./semi_circle.sh \
  -b dev \
  -p amazing_project \
	-c wow_company \
	-m get_branch_pipeline
```

`get_workflow`

In order to obtain the pipeline id, you will probably need to run the above command first to find the id and then subsequently run this:

```sh
./semi_circle.sh \
	-i 13123-asddwe-12313-dsada \
	-m get_workflow
```
