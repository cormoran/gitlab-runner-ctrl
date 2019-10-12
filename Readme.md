# GitLab Runner Ctrl

Managing [GitLab Runner](https://docs.gitlab.com/runner/) from Web UI

## Usage

1. install [vue-cli](https://cli.vuejs.org/) and run `vue serve`
2. <http://localhost:8081/>
3. Click `Config` and set GitLab URL, Access Token (requres sudo auth)
   - `Save` button will store them in the localstorage.
4. Click `Reload` button to load data from gitlab.
   - data is cached in the localstorage

## Features

- Filter runner list by regexp.
- Pause / Resume multiple runners with one-click.
- Alter tags of multiple runners easily.

## Note

- This app sends `O(N)` requests (N:number of runners) due to gitlab's api interface.
- Results are cached to local storage and only refreshed by reload button to prevent too much request.

## Demo

<https://blog.cormoran-web.com/gitlab-runner-ctrl/>

Warning: this app stores access token in browser's local storage. I recommend running it on local.

## Use Case

### minimal GPU resource management on shared server

Gitlab runner can manage GPU resources by registering runners per GPU (I prepared [scripts](usecase/gpu_server) to register runners per GPU).

Because of the lack of functionality of gitlab's runner management page, this strategy has some trouble when sharing GPU servers with others who does not use CI.

GitLab Runner Ctrl can stop multi runners by one click (if you set appropriate tags) to release GPU resources for others.

### resource management for multi-GPU program

To run multi-GPU program with GPU resource management on gitlab-ci, one of the easiest way is registering runners which use fixed multi GPUs.

ex)

- runner: `ServerXXX-GPU0` for GPU0
- runner: `ServerXXX-GPU1` for GPU1
- runner: `ServerXXX-GPU01` for GPU0 and GPU1, multi GPUs

You can switch runners (a little) easier by using GitLab Runner Ctrl.
