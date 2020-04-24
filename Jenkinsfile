// Jenkinsfile for building Shasta preinstall-toolkit LiveOS image
// via kiwi-ng.

// Jenkins Shared Libraries are implemented in our CI model (https://connect.us.cray.com/confluence/display/DST/Best+Practices+and+How-To%27s)
// Jenkins Global Variables are enabled in our CI mode
@Library('dst-shared@master') _

pipeline {
	environment {
		DOCKER_IMAGE="dtr.dev.cray.com:443/cray/cray-preinstall-toolkit-builder:latest"
		LATEST_NAME="cray-preinstall-toolkit-latest"

		// Set product family
		PRODUCT = "internal"
		// Set the target for building
		TARGET_OS = "sle15_sp1_ncn"
		MASTER_BRANCH = "master"
		PARENT_BRANCH = setParentBranch("${MASTER_BRANCH}")

		// Use x.y.z version from .version and get build timestamp
		IMG_VER  = sh(returnStdout: true, script: "cat .version").trim()
		BUILD_TS = sh(returnStdout: true, script: "date --utc '+%Y%m%d%H%M%S'").trim()
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
		stage('BUILD: Prep') {
			steps {
				// Remove any existing 'build' directory
				sh "rm -rf ${WORKSPACE}/build"

				// Create the 'build' directory
				sh "mkdir -p ${WORKSPACE}/build/output"
			}
		}

		stage('BUILD: Build Image') {
			steps {
				// If the image already exists on the node,
				// remove it. If the image is in use by a
				// running container it will only be untagged.
				// The untagged container will eventually be
				// deleted by pruning. The test for count
				// of lines from docker image ls has to account
				// for the always present header line.
				sh "if [[ \$(docker image ls ${DOCKER_IMAGE} | wc -l) -gt 1 ]]; then docker rmi -f ${DOCKER_IMAGE}; fi"

				sh "docker run -e PARENT_BRANCH -e IMG_VER -e BUILD_TS -v ${WORKSPACE}/build:/build -v ${WORKSPACE}/cray:/cray -v ${WORKSPACE}:/base --privileged --dns 172.30.84.40 --dns 172.31.84.40 ${DOCKER_IMAGE} bash /base/build.sh"
			}
		}

		stage('PUBLISH: Transfer Images') {
			steps {
				// Rename the files to match Cray versioning
				sh "./img-rename.sh build/output/*.iso"
				sh "./img-rename.sh build/output/*.packages"
				sh "./img-rename.sh build/output/*.verified"

				// Create a "latest" copy
				sh "cp build/output/*.iso build/output/${LATEST_NAME}.iso"
				sh "cp build/output/*.packages build/output/${LATEST_NAME}.packages"
				sh "cp build/output/*.verified build/output/${LATEST_NAME}.verified"

				transfer (artifactName:"build/output/*.iso")
				transfer (artifactName:"build/output/*.packages")
				transfer (artifactName:"build/output/*.verified")
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
