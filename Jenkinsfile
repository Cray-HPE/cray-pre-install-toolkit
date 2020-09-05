// Jenkinsfile for building Shasta pre-install-toolkit LiveOS image
// via kiwi-ng.

// Jenkins Shared Libraries are implemented in our CI model (https://connect.us.cray.com/confluence/display/DST/Best+Practices+and+How-To%27s)
// Jenkins Global Variables are enabled in our CI mode
@Library('dst-shared@master') _

pipeline {
// FIXME: Need to build when basecamp RPM and nexus RPM build, not when basecamp docker is built.
    triggers {
        upstream(upstreamProjects: 'basecamp,ipxe,shasta-pre-install-toolkit-builder', threshold: hudson.model.Result.SUCCESS)
        cron('@daily')
     }

	environment {
		LATEST_NAME="shasta-pre-install-toolkit-latest"

		// Set product family
		PRODUCT = "internal"
		// Set the target for building
		TARGET_OS = "sle15_sp2_ncn"

	}

	agent {
		node { label 'dstbuild' }
	}

	// Configuration options applicable to the entire job
	options {
		// This build should not take long, fail the build if it appears stuck
		timeout(time: 240, unit: 'MINUTES')

		// Don't fill up the build server with unnecessary cruft
		buildDiscarder(logRotator(numToKeepStr: '5'))

		// Don't bog down the build pipeline; only build on push and manuals or other human intent.
		disableConcurrentBuilds()
		disableResume()
	}

	stages {
		stage('BUILD: Build Image') {
			steps {
				// Run the build script. It will ensure
				// any cached docker image is removed so
				// the latest is pulled. The output of the
				// build will be copied to the 'build_output'
				// subdirectory.
                env.PIT_VERSION = "$(cat .version)"
                env.PIT_TIMESTAMP = "$(date -u '+%Y%m%d%H%M%S')"
                env.PIT_HASH = "$(git log -n 1 --pretty=format:'%h')"
                env.PIT_SLUG = "${PIT_VERSION}-${PIT_TIMESTAMP}-g${PIT_HASH}"
				sh '''
				    ./build.sh ${WORKSPACE}
                '''
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
		success {
			script {
				slackNotify(channel: "metal-build", credential: "", color: "#1d9bd1", message: "*${env.JOB_NAME}*: ${currentBuild.result}\n Version: $PIT_SLUG\nBuild URL:{$env.BUILD_URL}\n")
			}

			// Delete the 'build' directory
			dir('build') {
				// the 'deleteDir' command recursively deletes the
				// current directory
				deleteDir()
			}
		}

		failure {
			script {
				slackNotify(channel: "metal-build", credential: "", color: "danger", message: "*${env.JOB_NAME}*: ${currentBuild.result}\n Version: $PIT_SLUG\nBuild URL:{$env.BUILD_URL}\n")
			}

			// Delete the 'build' directory
			dir('build') {
				// the 'deleteDir' command recursively deletes the
				// current directory
				deleteDir()
			}
		}
	}
}
