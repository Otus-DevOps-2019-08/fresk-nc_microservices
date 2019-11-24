docker run -d --name gitlab-runner --restart always \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest

docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "$GITLAB_URL" \
    --registration-token "$GITLAB_REGISTRATION_TOKEN" \
    --executor "docker" \
    --docker-image alpine:latest \
    --description "docker-runner" \
    --tag-list "docker,alpine" \
    --run-untagged="true" \
    --locked="false" \
    --access-level="not_protected"
