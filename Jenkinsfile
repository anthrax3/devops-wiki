// vim: ft=groovy

node {

  git url: 'https://github.com/tokozedg/devops-wiki.git'
  git_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
  short_commit = git_commit.take(6)

  def registry = 'registry.devops.ge:5000'

  slackSend color: 'good', message: "Started ${BUILD_TAG} by changes from commit: ${short_commit}"

  stage('Build Sphinx'){
    sphinx_image = docker.build(
      "${registry}/devops-wiki-sphinx:${short_commit}",
      '-f Dockerfile.sphinx .'
      )
    sphinx_image.push(short_commit)
    sphinx_image.tag('latest')
    sphinx_image.push('latest')
  }

  stage('Commit Stage') {
    sh 'make -i test'
      if (
          failedTest('linkcheck') |
          failedTest('spelling') |
          failedTest('linecheck')
         ){
        error 'Commit test[s] failed!'
      }
  }

  stage('Package'){
    sh 'make TARGET="html" sphinxrun'
      html_image = docker.build("${registry}/devops-wiki:${short_commit}", '.')
      html_image.push(short_commit)
      html_image.tag('latest')
      html_image.push('latest')
  }

}

def failedTest(t){
  content = readFile(".build/${t}/output.txt")
  if (content){
    slackSend color: 'danger', message: "Failed test: ${t}"
    slackSend color: 'danger', message: content
    return true
  }else{
    slackSend color: 'good', message: "Success: ${t}"
    return false
  }
}
