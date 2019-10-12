<template>
	<div>
		<link
			rel="stylesheet"
			href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"
			integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T"
			crossorigin="anonymous"
		/>
		<div class="container-fluid">
			<h1>GitLab Runner Control</h1>
			<h2 @click="foldConfig = !foldConfig">Config</h2>
			<table v-if="!foldConfig" class="table">
				<tr>
					<td>GitLab URL</td>
					<td>
						<input v-model="gitlabUrl" class="form-control" />
					</td>
				</tr>
				<tr>
					<td>Access Token</td>
					<td>
						<input v-model="personalAccessToken" type="password" class="form-control" />
					</td>
				</tr>
				<tr>
					<td></td>
					<td>
						<button @click="saveConfig" class="btn btn-primary float-right">Save</button>
                        (stored in local storage)
					</td>
				</tr>
			</table>
			<h2 @click="foldRunners = !foldRunners">Runners</h2>
			<template v-if="!foldRunners">
				<div class="row">
					<div class="col-12 my-2">
						<button @click="downloadRunners" class="btn btn-secondary mr-2">Reload</button>
						<button
							@click="activateMatchedRunners"
							class="btn btn-primary mr-2"
						>Activate following runners</button>
						<button @click="pauseMatchedRunners" class="btn btn-danger mr-2">Pause following runners</button>
					</div>
					<div class="col-6 my-2">
						<div class="input-group mb-3">
							<input v-model="tagAdd" placeholder="tag name" class="form-control" />
							<div class="input-group-append">
								<button
									@click="addTagToMatchedRunners"
									:disabled="tagAdd.length == 0"
									class="btn btn-outline-primary"
								>Add tag</button>
							</div>
						</div>
					</div>
					<div class="col-6 my-2">
						<div class="input-group mb-3">
							<input v-model="tagRemove" placeholder="tag name" class="form-control" />
							<div class="input-group-append">
								<button
									@click="removeTagFromMatchedRunners"
									:disabled="tagRemove.length == 0"
									class="btn btn-outline-danger"
								>Remove tag</button>
							</div>
						</div>
					</div>
				</div>
				<table class="table">
					<thead>
						<tr>
							<th>Description</th>
							<th>Status</th>
							<th>Tags</th>
							<th>Running Jobs</th>
						</tr>
						<tr>
							<td>
								<input v-model="descriptionRegexp" placeholder="filter by description" class="form-control" />
							</td>
							<td>
								<input v-model="statusRegexp" placeholder="filter by status" class="form-control" />
							</td>
							<td>
								<input v-model="tagRegexp" placeholder="filter by tags" class="form-control" />
							</td>
							<td></td>
						</tr>
					</thead>
					<tbody>
						<tr v-for="runner in matchedRunners" :key="runner.id">
							<td>{{runner.description}}</td>
							<td>{{runner.status}}</td>
							<td>
								<template v-if="runner.id in runnerDetails">
									<span
										v-for="tag in runnerDetails[runner.id].tag_list"
										:key="tag"
										v-text="tag"
										style="margin: 0px 3px;"
									/>
								</template>
							</td>
							<td>{{ runner.id in runnerJobs ? runnerJobs[runner.id].length : '?' }}</td>
						</tr>
					</tbody>
				</table>
			</template>
			<h2 @click="foldJobs = !foldJobs">Jobs</h2>
			<template v-if="!foldJobs">
				<div class="row">
					<div class="col-12 my-2">
						<button @click="downloadRunners" class="btn btn-secondary mr-2">Reload</button>
					</div>
				</div>
				<table class="table">
					<thead>
						<tr>
							<th>Runner</th>
							<th>Pipeline</th>
							<th>Job Name</th>
							<th>Duration</th>
							<th>Operation</th>
						</tr>
					</thead>
					<tbody>
						<template v-for="jobs, runnerId in runnerJobs">
							<tr v-for="job in jobs" :key="job.id">
								<td>{{ runnerDetails[runnerId].description }}</td>
								<td>
									<a :href="job.pipeline.web_url">#{{ job.pipeline.id }}</a>
								</td>
								<td>
									<a :href="job.web_url">{{ job.name }}</a>
								</td>
								<td>{{ job.duration }}</td>
								<td>
									<button class="btn btn-danger" @click="cancelJob(job.project.id, job.id)">Cancel</button>
								</td>
							</tr>
						</template>
					</tbody>
				</table>
			</template>
		</div>
	</div>
</template>
<script>
export default {
	name: 'app',
	data() {
		return {
			personalAccessToken: '',
			gitlabUrl: '',
			descriptionRegexp: '',
			statusRegexp: '',
			tagRegexp: '',
			tagAdd: '',
			tagRemove: '',
			runners: [],
			runnerDetails: {},
			runnerJobs: {},
			foldConfig: true,
			foldRunners: false,
			foldJobs: false,
		};
	},
	computed: {
		matchedRunners() {
			const description = new RegExp(this.descriptionRegexp);
			const status = new RegExp(this.statusRegexp);
			const tag = new RegExp(this.tagRegexp);
			let res = this.runners;
			res = res.filter(r => description.test(r.description));
			res = res.filter(r => status.test(r.status));
			res = res.filter(
				r =>
					!(r.id in this.runnerDetails) ||
					tag.test(this.runnerDetails[r.id].tag_list.join(' '))
			);
			return res;
		},
	},
	created() {
		this.loadCache();
	},
	methods: {
		loadCache() {
			this.runners = JSON.parse(localStorage.getItem('runners') || '[]');
			this.runnerDetails = JSON.parse(
				localStorage.getItem('runnerDetails') || '{}'
			);
			this.runnerJobs = JSON.parse(localStorage.getItem('runnerJobs') || '{}');
			this.personalAccessToken = localStorage.getItem('personalAccessToken');
			this.gitlabUrl = localStorage.getItem('gitlabUrl');
		},
		saveConfig() {
			localStorage.setItem('personalAccessToken', this.personalAccessToken);
			localStorage.setItem('gitlabUrl', this.gitlabUrl);
		},
		async getAll(url, config, queryParams = {}) {
			let params = new URLSearchParams();
			params.set('per_page', 100);
			for (const key of Object.keys(queryParams))
				params.set(key, queryParams[key]);
			const chunks = [];
			let nextPage = 1;
			while (nextPage) {
				params.set('page', nextPage);
				const response = await fetch(url + '?' + params.toString(), config);
				const data = await response.json();
				chunks.push(data);
				nextPage = response.headers.get('X-Next-Page');
			}
			return [].concat(...chunks);
		},
		async downloadRunners() {
			let runners = await this.getAll(`${this.gitlabUrl}/api/v4/runners/all`, {
				headers: {
					'PRIVATE-TOKEN': this.personalAccessToken,
				},
			});
			localStorage.setItem('runners', JSON.stringify(runners));
			this.runners = runners;
			this.downloadRunnerDetails();
			this.downloadRunnerJobs();
		},
		downloadRunnerDetails() {
			this.runnerDetails = {};
			let promise = [];
			for (const runner of this.runners) {
				promise.push(
					this.getRunner(runner.id).then(runnerDetail => {
						this.$set(this.runnerDetails, runner.id, runnerDetail);
					})
				);
			}
			Promise.all(promise).then(() => {
				localStorage.setItem(
					'runnerDetails',
					JSON.stringify(this.runnerDetails)
				);
			});
		},
		async downloadRunnerJobs() {
			this.runnerJobs = {};
			let promise = [];
			for (const runner of this.runners) {
				promise.push(
					this.getJobs(runner.id).then(jobs => {
						this.$set(this.runnerJobs, runner.id, jobs);
					})
				);
			}
			Promise.all(promise).then(() => {
				localStorage.setItem('runnerJobs', JSON.stringify(this.runnerJobs));
			});
		},
		async pauseMatchedRunners() {
			if (!confirm('Really stop them?')) return;
			for (const runner of this.matchedRunners) {
				await this.updateRunner(runner.id, { active: false });
			}
			return this.downloadRunners();
		},
		async activateMatchedRunners() {
			if (!confirm('Really activate them?')) return;
			for (const runner of this.matchedRunners) {
				await this.updateRunner(runner.id, { active: true });
			}
			return this.downloadRunners();
		},
		async addTagToMatchedRunners() {
			if (this.tagAdd.length == 0) return;
			if (!confirm(`Add tag: ${this.tagAdd} to them?`)) return;
			const runners = this.matchedRunners.filter(
				r => r.id in this.runnerDetails
			);
			await Promise.all(
				runners.map(r =>
					this.updateRunner(r.id, {
						tag_list: [].concat(
							this.tagAdd,
							...this.runnerDetails[r.id].tag_list
						),
					})
				)
			);
			return this.downloadRunners();
		},
		async removeTagFromMatchedRunners() {
			if (this.tagRemove.length == 0) return;
			if (!confirm(`Remove tag: ${this.tagRemove} from them?`)) return;
			const runners = this.matchedRunners.filter(
				r => r.id in this.runnerDetails
			);
			await Promise.all(
				runners.map(r =>
					this.updateRunner(r.id, {
						tag_list: this.runnerDetails[r.id].tag_list.filter(
							t => t != this.tagRemove
						),
					})
				)
			);
			return this.downloadRunners();
		},
		async cancelJob(projectId, jobId) {
			if (!confirm(`Cancel job?`)) return;
			await fetch(
				`${this.gitlabUrl}/api/v4/projects/${projectId}/jobs/${jobId}/cancel`,
				{
					method: 'POST',
					headers: {
						'PRIVATE-TOKEN': this.personalAccessToken,
					},
				}
			);
			return this.downloadRunners();
		},
		updateRunner(id, body) {
			return fetch(`${this.gitlabUrl}/api/v4/runners/${id}`, {
				method: 'PUT',
				body: JSON.stringify(body),
				headers: {
					'PRIVATE-TOKEN': this.personalAccessToken,
					'Content-Type': 'application/json',
				},
			}).then(response => response.json());
		},
		getRunner(id) {
			return fetch(`${this.gitlabUrl}/api/v4/runners/${id}`, {
				headers: {
					'PRIVATE-TOKEN': this.personalAccessToken,
				},
			}).then(response => response.json());
		},
		getJobs(runnerId, status = 'running') {
			return this.getAll(
				`${this.gitlabUrl}/api/v4/runners/${runnerId}/jobs`,
				{
					headers: {
						'PRIVATE-TOKEN': this.personalAccessToken,
					},
				},
				{
					status: status,
				}
			);
		},
	},
};
</script>

