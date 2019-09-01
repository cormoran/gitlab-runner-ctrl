# GitLab Runner Ctrl

Managing [GitLab Runner](https://docs.gitlab.com/runner/) from Web UI

## Usage

1. install [vue-cli](https://cli.vuejs.org/) and run `vue serve`
2. <http://localhost:8081/>
3. Click `Config` and set GitLab URL, Access Token (requres sudo auth)
   * `Save` button will store them in the localstorage.
4. Click `Reload` button to load data from gitlab.
   * data is cached in the localstorage

## Features

* Filter runner list by regexp.
* Pause / Resume multiple runners with one-click.
* Alter tags of multiple runners easily.

## Note

* This app sends `O(N)` requests to load data. (N:number of runners)
