# semi-circle
A simple circleci command line application for getting the status of pipelines. 

Has the functionality to poll a workflow until either success or failure. A system notifcation will be dispatched on linux and macos when the workflow has finished

## Dependencies
- `curl`
- `jq`
- `awk`
- A circleci account and API key

# Command line arguments
- `-b` Name of branch
- `-p` Name of project
- `-c` Name of company
- `-i` Pipeline id
- `-v` Version control system, defaults to github
- `-h` Print usage
- `-w` Workflow id

# Supported Methods
The following methods are supported:
- `get_branch_pipeline` returns pipeline information
- `get_workflow` returns workflow information for the given pipeline id and branch
- `cancel_workflow` returns json in the format `{"message": "value"}`
- `poll_workflow` polls workflow until failure or success, notification is dispatched on success
- `get_my_branch_pipeline` returns only your pipelines for a branch
- `list_envionment_variables` returns a list of Environment Variables in circleci, the values are masked
- `get_my_pipelines` returns all of your pipelines for a project, for all branches

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

`cancel_workflow`

To get a workflow id you weill need to run `get_workflow` to return a list of workflows for the specified pipeline id.

```sh
./semi_circle.sh \
  -w eaef-13132-afdc \
  -m cancel_workflow
```

`poll_workflow`

Will poll the given pipeline id until either success or failure, this requires 'jq' to be installed.
The time between invokations is 5 seconds

```sh
./semi_circle.sh \
  -i 13123-asddwe-12313-dsada \
  -m poll_workflow
```

`list_envionment_variables`

Gets all the environment variables for a project, the values are masked

```sh
./semi_circle.sh \
  -p amazing_project \
  -c wow_company \
  -m list_envionment_variables
```

`get_my_pipelines`

Returns the latest 250 pipelines for a project listed with the latest first

```sh
./semi_circle.sh \
  -p amazing_project \
  -c wow_company \
  -m get_my_pipelines
```

# Install

To install run:

```sh
make install # this might need to be run with sudo priveleges
```

Default location is `/usr/local/bin/semi_circle.sh`

command can then be run:
```sh
semi_circle.sh <opts> <commands>
```
