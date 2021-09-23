pipeline {
	agent any
	stages {
		stage ("Git checkout"){
			steps {
				git branch: "main",
					url: "https://github.com/madmongoose/epam-diploma.git"
				sh "ls"
				
			}
		}
		stage ("Python Flask Prepare"){
			steps {
				sh "pip3 install -r python/api/requirements.txt"
			}

		}
		stage ("Unit Test"){
			steps{
				sh "python3 python/api/basic-test-api.py"
			}
		}
		stage ("Python Bandit Security Scan"){
			steps{
				sh "cat report/banditResult.json"
				sh "sh run_bandit.sh || true"
				sh "ls"
			}
		}
		stage ("Dependency Check with Python Safety"){
			steps{
				sh "docker run --rm --volume \$(pwd) pyupio/safety:latest safety check"
				sh "docker run --rm --volume \$(pwd) pyupio/safety:latest safety check --json > report.json"
			}
		}
		stage ("Static Analysis with python-taint"){
			steps{
				sh "docker run --rm --volume \$(pwd) madmongoose/test pyt ."
			}
		}
		stage ("sonar-publish"){
			steps {
				echo "===========Performing Sonar Scan============"
				sh "${tool("sonarqube")}/bin/sonar-scanner"
			}
		}
		stage ("docker-push"){
			steps {
				echo "===========Performing Sonar Scan============"
				sh "${tool("sonarqube")}/bin/sonar-scanner"
			}
		}
	}
}
