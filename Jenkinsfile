// Jenkinsfile for building the CRAY Pre-install Toolkit LiveOS image
// via kiwi-ng.

// Jenkins Shared Libraries are implemented in our CI model (https://connect.us.cray.com/confluence/display/DST/Best+Practices+and+How-To%27s)
// Jenkins Global Variables are enabled in our CI mode
@Library('dst-shared@master') _

def skipSuccess = false
def masterBranch = "main"

pipeline {
  // FIXME: Need to build when basecamp RPM and nexus RPM build, not when basecamp docker is built.
  triggers {
    upstream(upstreamProjects: 'basecamp,ipxe,cray-pre-install-toolkit-builder,cray-site-init,docs-non-compute-nodes', threshold: hudson.model.Result.SUCCESS)
    cron(env.BRANCH_NAME ==~ 'main' ? '@daily' : '')
  }

  environment {
    LATEST_NAME="cray-pre-install-toolkit-latest"
    // Set product family
    PRODUCT = "csm"
    // Set the target for building
    TARGET_OS = "sle15_sp2_ncn"
    ARCH = "x86_64"
    IYUM_REPO_MAIN_BRANCH = "main"
  }

  agent {
    node { label 'metal-gcp-builder' }
  }

  // Configuration options applicable to the entire job
  options {
    // This build should not take long, fail the build if it appears stuck
    timeout(time: 240, unit: 'MINUTES')

    // Don't fill up the build server with unnecessary cruft
    buildDiscarder(logRotator(numToKeepStr: '20'))

    // Don't bog down the build pipeline; only build on push and manuals or other human intent.
    disableConcurrentBuilds()
    disableResume()
  }

  parameters {
    string(name: 'csmRpmRef', defaultValue: "main", description: 'The branch or ref to use when checking out csm-rpm repo for repo list and package lock versions')
  }

  stages {
    stage('PREP: ISO NAME') {
      steps {
        script {
          // Define these vars here so they're mutable (vs. global).
          env.VERSION = sh(returnStdout: true, script: "cat .version").trim()
          env.BUILD_DATE = sh(returnStdout: true, script: "date -u '+%Y%m%d%H%M%S'").trim()
          env.GIT_TAG = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          env.PIT_SLUG = "${env.VERSION}-${env.BUILD_DATE}-g${env.GIT_TAG}"
          env.GIT_REPO_NAME = sh(returnStdout: true, script: "basename -s .git ${GIT_URL}").trim()
          echo "${env.GIT_REPO_NAME}-${env.TARGET_OS.replaceAll('_', '')}.${env.ARCH}-${env.PIT_SLUG}.iso"
          slackNotify(channel: "livecd-ci-alerts", credential: "", color: "#cccccc", message: "Repo: *${env.GIT_REPO_NAME}*\nBranch: *${env.GIT_BRANCH}*\nSlug: ${env.PIT_SLUG}\nBuild: ${env.BUILD_URL}\nStatus: `STARTING`")
        }
      }
    }

    stage('Checkout csm-rpms') {
      steps {
        dir('suse/x86_64/cray-pre-install-toolkit-sle15sp2/root/srv/cray/csm-rpms') {
          git credentialsId: '18f63634-7b3e-4461-acfe-83c6ee647fa4', url: 'https://stash.us.cray.com/scm/csm/csm-rpms.git', branch: params.csmRpmRef
        }
      }
    }

    stage('BUILD: Build Image') {
      steps {
        script {
          // Run the build script. It will ensure
          // any cached docker image is removed so
          // the latest is pulled. The output of the
          // build will be copied to the 'build_output'
          // subdirectory.
          sh '''
              ./build.sh ${WORKSPACE}
          '''
        }
      }
    }

    stage('PUBLISH: Transfer Images') {
      steps {
        // Create a "latest" copy
        sh "cp build_output/*.iso build_output/${LATEST_NAME}.iso"
        sh "cp build_output/*.packages build_output/${LATEST_NAME}.packages"
        sh "cp build_output/*.verified build_output/${LATEST_NAME}.verified"

        transfer (artifactName:"build_output/*.iso")
        transfer (artifactName:"build_output/*.packages")
        transfer (artifactName:"build_output/*.verified")
      }
    }
  }

  post('Post Run Conditions') {
    always {
      script {
        currentBuild.result = currentBuild.result == null ? "SUCCESS" : currentBuild.result
        // Forcefully cleanup leftover files from docker owned by root so next run wont error out
        sh 'sudo rm -rf build_output'
      }
    }

    fixed {
      notifyBuildResult(headline: "FIXED")
      script {
        slackNotify(channel: "livecd-ci-alerts", credential: "", color: "#1d9bd1", message: "Repo: *${env.GIT_REPO_NAME}*\nBranch: *${env.GIT_BRANCH}*\nSlug: ${env.PIT_SLUG}\nBuild: ${env.BUILD_URL}\nStatus: `FIXED`")
          // Set to true so the 'success' post section is skipped when the build result is 'fixed'
          // Otherwise both 'fixed' and 'success' sections will execute due to Jenkins behavior
          skipSuccess = true
      }
    }

    success {
      script {
        if (skipSuccess != true) {
            slackNotify(channel: "livecd-ci-alerts", credential: "", color: "good", message: "Repo: *${env.GIT_REPO_NAME}*\nBranch: *${env.GIT_BRANCH}*\nSlug: ${env.PIT_SLUG}\nBuild: ${env.BUILD_URL}\nStatus: `${currentBuild.result}`")
        }
      }
    }

    failure {
      notifyBuildResult(headline: "FAILED")
      script {
        slackNotify(channel: "livecd-ci-alerts", credential: "", color: "danger", message: "Repo: *${env.GIT_REPO_NAME}*\nBranch: *${env.GIT_BRANCH}*\nSlug: ${env.PIT_SLUG}\nBuild: ${env.BUILD_URL}\nStatus: `${currentBuild.result}`")
      }
    }
  }
}
