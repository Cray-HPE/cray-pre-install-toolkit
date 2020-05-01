// Jenkinsfile for building Shasta preinstall-toolkit LiveOS image
// via kiwi-ng.

// Jenkins Shared Libraries are implemented in our CI model (https://connect.us.cray.com/confluence/display/DST/Best+Practices+and+How-To%27s)
// Jenkins Global Variables are enabled in our CI mode
@Library('dst-shared@master') _

pipeline {
	environment {
		LATEST_NAME="cray-preinstall-toolkit-latest"

		// Set product family
		PRODUCT = "internal"
		// Set the target for building
		TARGET_OS = "sle15_sp1_ncn"
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
	}

	stages {
		stage('BUILD: Build Image') {
			steps {
				// Run the build script. It will ensure
				// any cached docker image is removed so
				// the latest is pulled. The output of the
				// build will be copied to the 'build.out'
				// subdirectory.
				sh "./build.sh ${WORKSPACE}"
			}
		}

		stage('PUBLISH: Transfer Images') {
			steps {
				// Create a "latest" copy
				sh "cp build.out/*.iso build.out/${LATEST_NAME}.iso"
				sh "cp build.out/*.packages build.out/${LATEST_NAME}.packages"
				sh "cp build.out/*.verified build.out/${LATEST_NAME}.verified"

				transfer (artifactName:"build.out/*.iso")
				transfer (artifactName:"build.out/*.packages")
				transfer (artifactName:"build.out/*.verified")
			}
		}
	}

	post('Post Run Conditions') {
		success {
			script {
				slackNotify(channel: "skern-build", credential: "", color: "good", message: "Results: ${env.JOB_NAME}\n${env.BUILD_URL}\n}")
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
				slackNotify(channel: "skern-build", credential: "", color: "danger", message: "Results: ${env.JOB_NAME}\n${env.BUILD_URL}\nDescription:\n\nBuild failed.\n")
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
