# cd-semaphore

A semaphore script that fails gitlab jobs for merge requests where the target branch has failed jobs.
(To be used in cojunction with "Pipelines must succeed" merge check feature) see https://docs.gitlab.com/ee/user/project/merge_requests/merge_when_pipeline_succeeds.html#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds

The main purpose of this script is to block merging feature branches if the target pipeline has failed jobs.
Having a clean green pipeline for the main branch is key in continuous delivery. 

Merging you branch on top of other branches where there are failing pipeline jobs is a bad practice, and if you did this in the past you should be ashamed of yourself.

example run:
```
./semaphore_exec.sh -p 256 -h gitlab.host.int -t <token> -b latest
```
