def gitUrl = 'https://github.com/ChomCHOB/tyk-pump-docker'
def gitBranch = 'refs/heads/master'

def label = "buildpod.${env.JOB_NAME}.${env.BUILD_NUMBER}".replace('-', '_').replace('/', '_')

podTemplate(
  label: label,
) {
node(label) {

  echo sh(returnStdout: true, script: 'env')
  
  build(
    job: '../../bitbucket-infra/ccif-build-docker/master', 
    parameters: [
      booleanParam(name: 'PUBLISH_TO_DOCKER_HUB', value: true), 
      booleanParam(name: 'PUBLISH_LATEST', value: true), 
      string(name: 'GIT_URL', value: gitUrl), 
      string(name: 'GIT_BRANCH', value: gitBranch), 
      string(name: 'DOCKERFILE', value: 'Dockerfile'), 
    ]
  )
}
}