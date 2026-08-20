pipeline {
    agent any
    parameters {
        string(name: 'REPO_URL', defaultValue: 'https://github.com/vaishvikpatel79/Go_Demo', description: 'Repository URL')
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
    }
    options { timeout(time: 90, unit: 'MINUTES'); skipDefaultCheckout() }
    environment {
        // Build versioning default: v1 (incremented to v2 only when code updates)
        IMAGE_TAG = "v1"
        IMAGE_NAME = "my_microservices_app_frontend"
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git url: "${params.REPO_URL}", branch: "${params.BRANCH}"
                sh 'git submodule update --init --recursive || true'
            }
        }
        stage('Repository Intelligence') {
            steps {
                sh '''
echo "================================================"
echo "   REPOSITORY INTELLIGENCE SNAPSHOT"
echo "================================================"
echo "Repo type        : microservices"
echo "Language         : go"
echo "Framework        : go"
echo "Build strategy   : compose"
echo "Buildable svcs   : 2"
echo "Dockerfile reused: True"
echo "Compose reused   : True"
echo "Jenkinsfile reuse: False"
echo "================================================"
'''
            }
        }
        stage('Prepare Compose for Build') {
            steps {
                sh '''
set -eu
if [ -f "docker-compose.yml" ]; then
  echo "[prepare] Stripping runtime config from docker-compose.yml for build-only mode"

  # Back up original before mutation
  cp "docker-compose.yml" "docker-compose.yml.bak"

  # 1. Strip env_file and environment entries AND capture them for metadata
  python3 - <<'PYEOF'
import sys, os

path = "docker-compose.yml"
if not os.path.exists(path):
    sys.exit(0)

with open(path) as f:
    lines = f.readlines()

out = []
runtime_envs = []
skip_block = False
block_indent = 0

for line in lines:
    ls = line.strip()
    if not ls or ls.startswith('#'):
        if not skip_block:
            out.append(line)
        continue

    indent = len(line) - len(line.lstrip())

    # Capture .env references (e.g., "env_file: .env" or "- .env")
    if ".env" in ls:
        # Simple extraction: remove punctuation and split
        clean_line = ls.replace(':', ' ').replace('-', ' ').replace('"', ' ').replace("'", ' ')
        parts = clean_line.split()
        for p in parts:
            if p.startswith('.') and 'env' in p:
                if p not in runtime_envs:
                    runtime_envs.append(p)

    # Detect start of runtime-only blocks
    is_env_start = ls.startswith('env_file:') or ls.startswith('environment:')
    if is_env_start:
        skip_block = True
        block_indent = indent
        continue

    if skip_block:
        # If indent returns to or goes above the block level, stop skipping
        if indent <= block_indent and ls:
            skip_block = False
            out.append(line)
        continue

    out.append(line)

with open(path, 'w') as f:
    f.writelines(out)

# Important: Double-braces { } are required below because this block is inside
with open('runtime_envs.txt', 'w') as f:
    for _e in runtime_envs:
        print(_e, file=f)

print(f"[prepare] Discovered {len(runtime_envs)} runtime env files")
PYEOF

  # 2. Repair malformed port mappings
  if grep -q "127.0.0.1:9229" "docker-compose.yml" 2>/dev/null; then
    DQ='"'
    if grep -E "127.0.0.1:9229.*:9229" "docker-compose.yml" >/dev/null 2>&1; then
      echo "[prepare] Repairing malformed 127.0.0.1:9229 port mapping"
      sed -i "/127.0.0.1:9229/ s/${DQ}.*${DQ}/ ${DQ}127.0.0.1:9229:9229${DQ}/" "docker-compose.yml"
    fi
  fi

  echo "[prepare] Compose file is ready for build-only mode."
fi
'''
            }
        }
        stage('Validate Build Strategy') {
            steps {
                sh '''
set -eu
test -f "docker-compose.yml" || (echo "ERROR: docker-compose.yml not found after checkout" && exit 1)
echo "[validate] Build strategy validated: compose"
'''
            }
        }
        stage('Compose Build') {
            steps {
                sh '''
set -eu

# Resolve compose command
find_compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        echo "ERROR: neither 'docker compose' nor 'docker-compose' is available." >&2
        exit 1
    fi
}
COMPOSE_CMD=$(find_compose_cmd)
echo "[compose] Using: $COMPOSE_CMD"
echo "[compose] File : docker-compose.yml"
echo "[compose] Project: my-microservices-app"
$COMPOSE_CMD -p "my-microservices-app" -f "docker-compose.yml" build
$COMPOSE_CMD -p "my-microservices-app" -f "docker-compose.yml" create || true
'''
            }
        }
        stage('Discover Compose Images') {
            steps {
                sh '''
set -eu
mkdir -p artifact-layers
rm -f compose_image_map.tsv compose_missing_count.txt compose_service_map.txt
touch compose_image_map.tsv
touch compose_service_map.txt

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo "ERROR: neither docker compose nor docker-compose is available." >&2
  exit 1
fi

PROJECT="my-microservices-app"
if [ -n "${IMAGE_TAG:-}" ]; then
  TAG="${IMAGE_TAG}"
else
  TAG="v1"
fi

echo "frontend|frontend|my_microservices_app_frontend" >> compose_service_map.txt
echo "api|api|my_microservices_app_api" >> compose_service_map.txt

echo "[compose] Project=$PROJECT IMAGE_TAG=$TAG"
echo "[compose] Service map:"
cat compose_service_map.txt

MISSING=0
FOUND=0
ARTIFACTS=0
TOTAL=0

while IFS='|' read -r REPORT_NAME COMPOSE_SVC TARGET_IMAGE
do
  if [ -z "$REPORT_NAME" ]; then
    continue
  fi
  TOTAL=$((TOTAL + 1))
  echo "[compose] Discovering compose service $COMPOSE_SVC -> target $TARGET_IMAGE:$TAG report=$REPORT_NAME"

  ACTUAL_IMAGE=""

  # Prefer the image compose just built: <project>-<service>:latest
  if docker image inspect "${PROJECT}-${COMPOSE_SVC}:latest" >/dev/null 2>&1; then
    ACTUAL_IMAGE="${PROJECT}-${COMPOSE_SVC}:latest"
  elif docker image inspect "${PROJECT}-${COMPOSE_SVC}" >/dev/null 2>&1; then
    ACTUAL_IMAGE="${PROJECT}-${COMPOSE_SVC}"
  elif docker image inspect "${PROJECT}_${COMPOSE_SVC}:latest" >/dev/null 2>&1; then
    ACTUAL_IMAGE="${PROJECT}_${COMPOSE_SVC}:latest"
  elif docker image inspect "${PROJECT}_${COMPOSE_SVC}" >/dev/null 2>&1; then
    ACTUAL_IMAGE="${PROJECT}_${COMPOSE_SVC}"
  fi

  # Fallback: compose labels
  if [ -z "$ACTUAL_IMAGE" ]; then
    ACTUAL_IMAGE=$(docker images --filter "label=com.docker.compose.project=$PROJECT" --filter "label=com.docker.compose.service=$COMPOSE_SVC" --format "{{.Repository}}:{{.Tag}}" | head -n 1 || true)
  fi

  if [ -z "$ACTUAL_IMAGE" ]; then
    ACTUAL_IMAGE=$($COMPOSE_CMD -p "$PROJECT" -f "docker-compose.yml" config 2>/dev/null | sed -n "/^  $COMPOSE_SVC:/,/^  [a-z]/p" | grep "image:" | head -n 1 | awk '{print $2}' | tr -d '"' | tr -d "'" || true)
  fi

  if [ -n "$ACTUAL_IMAGE" ] && docker image inspect "$ACTUAL_IMAGE" >/dev/null 2>&1; then
    FINAL_IMAGE="${TARGET_IMAGE}:${TAG}"
    if [ "$ACTUAL_IMAGE" != "$FINAL_IMAGE" ]; then
      echo "[compose] Retagging $ACTUAL_IMAGE -> $FINAL_IMAGE"
      docker tag "$ACTUAL_IMAGE" "$FINAL_IMAGE"
    else
      echo "[compose] Image already tagged as $FINAL_IMAGE"
    fi
    SAFE_NAME=$(echo "$FINAL_IMAGE" | sed 's#[/:]#-#g')
    ARTIFACT_NAME="${SAFE_NAME}.tar.gz"
    echo "[compose] Archiving $REPORT_NAME: $FINAL_IMAGE -> $ARTIFACT_NAME"
    docker save "$FINAL_IMAGE" | gzip > "artifact-layers/${ARTIFACT_NAME}"
    echo "${REPORT_NAME}|${FINAL_IMAGE}|${ARTIFACT_NAME}|true" >> compose_image_map.tsv
    FOUND=$((FOUND + 1))
    ARTIFACTS=$((ARTIFACTS + 1))
  else
    echo "[compose] Warning: Could not find image for compose service: $COMPOSE_SVC"
    echo "${REPORT_NAME}|||false" >> compose_image_map.tsv
    MISSING=$((MISSING + 1))
  fi
done < compose_service_map.txt

TOTAL=$(grep -c . compose_image_map.tsv || true)
FOUND=$(awk -F'|' '$4=="true" {c++} END{print c+0}' compose_image_map.tsv)
ARTIFACTS=$FOUND
MISSING=$(awk -F'|' '$4!="true" {c++} END{print c+0}' compose_image_map.tsv)

echo "$MISSING" > compose_missing_count.txt
echo "${TOTAL}|${FOUND}|${ARTIFACTS}" > compose_counts.tsv

echo "[compose] Discovery summary: total=$TOTAL found=$FOUND missing=$MISSING"
'''
            }
        }
        stage('Build Metadata') {
            steps {
                script {
                    def detected = 0
                    def discovered = 0
                    def artifacts = 0
                    def deploymentConfigRequired = false
                    if (!fileExists('compose_counts.tsv')) {
                        error "compose_counts.tsv not found — 'Discover Compose Images' stage may have failed"
                    }
                    def rawCounts = readFile('compose_counts.tsv').trim()
                    def countsParts = rawCounts.split(/\|/)
                    if (countsParts.size() >= 3) {
                        detected = countsParts[0] as Integer
                        discovered = countsParts[1] as Integer
                        artifacts = countsParts[2] as Integer
                    }

                    def services = []
                    if (fileExists('compose_image_map.tsv')) {
                        def mapRaw = readFile('compose_image_map.tsv')
                        def mapLines = mapRaw.split(/\n/)
                        mapLines.each { line ->
                            if (line && line.trim()) {
                                def parts = line.split(/\|/, -1)
                                if (parts.size() >= 4) {
                                    services << [
                                        service: parts[0],
                                        actual_image: parts[1],
                                        artifact_name: parts[2],
                                        image_found: parts[3] == 'true'
                                    ]
                                }
                            }
                        }
                    }

                    def runtimeEnvFiles = []
                    if (fileExists('runtime_envs.txt')) {
                        def envsRaw = readFile('runtime_envs.txt')
                        def envLines = envsRaw.split(/\n/)
                        runtimeEnvFiles = envLines.findAll { it && it.trim() }
                    }

                    def servicesJson = services.collect { s -> "{\"service\": \"${s.service}\", \"actual_image\": \"${s.actual_image}\", \"artifact_name\": \"${s.artifact_name}\", \"image_found\": ${s.image_found}}" }.join(", ")
                    def runtimeEnvJson = runtimeEnvFiles.collect { f -> "\"${f}\"" }.join(", ")
                    def metaJson = "{\"build_strategy\": \"compose\", \"repo_type\": \"microservices\", \"services_detected\": ${detected}, \"images_discovered\": ${discovered}, \"artifacts_generated\": ${artifacts}, \"services\": [${servicesJson}], \"runtime_env_files\": [${runtimeEnvJson}], \"deployment_configuration_required\": ${deploymentConfigRequired}}"
                    writeFile file: 'build_metadata.json', text: metaJson
                    echo "Build metadata written to build_metadata.json"
                }
            }
        }
        stage('Archive Service Images') {
            steps {
                archiveArtifacts artifacts: 'artifact-layers/*.tar.gz', fingerprint: true, allowEmptyArchive: true
                archiveArtifacts artifacts: 'build_metadata.json', fingerprint: false, allowEmptyArchive: false
            }
        }
        stage('Validate Compose Discovery') {
            steps {
                sh '''
set -eu
MISSING=$(cat compose_missing_count.txt)
if [ "$MISSING" -ne 0 ]; then
  echo "Compose image discovery failed for $MISSING service(s)."
  exit 1
fi
'''
            }
        }

        stage('Verify Local Images') {
            steps {
                script {
                    def targetImages = [
                    [name: 'my_microservices_app_frontend', tag: 'v1'],
                    [name: 'my_microservices_app_api', tag: 'v1']
                ]
                    for (img in targetImages) {
                        def tagToUse = (env.IMAGE_TAG && env.IMAGE_TAG != '') ? env.IMAGE_TAG : img.tag
                        def localImg = "${img.name}:${tagToUse}"
                        echo "Verifying local docker image exists: ${localImg}"
                        if (sh(script: "docker image inspect ${localImg} >/dev/null 2>&1", returnStatus: true) != 0) {
                            if (sh(script: "docker image inspect ${img.name}:${img.tag} >/dev/null 2>&1", returnStatus: true) == 0) {
                                localImg = "${img.name}:${img.tag}"
                            } else if (env.IMAGE_NAME && sh(script: "docker image inspect ${env.IMAGE_NAME}:${tagToUse} >/dev/null 2>&1", returnStatus: true) == 0) {
                                localImg = "${env.IMAGE_NAME}:${tagToUse}"
                                img.name = env.IMAGE_NAME
                            }
                        }
                        sh "docker image inspect ${localImg} >/dev/null"
                    }
                }
            }
        }

        stage('Verify Google Cloud Access') {
            steps {
                script {
                    def hasGcloud = sh(script: "command -v gcloud >/dev/null 2>&1", returnStatus: true) == 0
                    if (hasGcloud) {
                        def authRc = sh(
                            script: "gcloud auth list 2>/dev/null || true",
                            returnStdout: true
                        ).trim()
                        if (!authRc) {
                            echo "Notice: gcloud auth check returned empty — ensuring authentication active."
                        }
                        def gcpProject = 'cloudteam-490409'.trim() ?: (env.GCP_PROJECT_ID ?: '')
                        if (gcpProject) {
                            sh "gcloud config set project ${gcpProject} > /dev/null 2>&1 || true"
                            env.GCP_PROJECT_ID = gcpProject
                            echo "Google Cloud project configured: ${gcpProject}"
                        }
                    } else {
                        echo "Notice: 'gcloud' CLI is not installed on Jenkins agent node."
                    }
                }
            }
        }

        stage('Resolve Cloud Account & Registry') {
            steps {
                script {
                    env.GCP_REGION = 'us-central1'
                    env.GAR_REPOSITORY = 'fastapi-demo-dev'
                    def userRegistry = 'us-central1-docker.pkg.dev/cloudteam-490409/fastapi-demo-dev'.trim()
                    if (userRegistry && !userRegistry.contains('localhost')) {
                        env.TARGET_REGISTRY = userRegistry
                        echo "Using User Provided GCP Artifact Registry: ${env.TARGET_REGISTRY}"
                    } else {
                        def gcpProj = env.GCP_PROJECT_ID ?: 'cloudteam-490409'
                        if (!gcpProj) {
                            try {
                                gcpProj = sh(script: 'gcloud config get-value project 2>/dev/null', returnStdout: true).trim()
                            } catch (Exception e) {
                                echo "Warning: Could not fetch GCP project via gcloud: ${e}"
                            }
                        }
                        if (!gcpProj) {
                            gcpProj = 'cloudteam-490409'
                        }
                        env.GCP_PROJECT_ID = gcpProj
                        env.TARGET_REGISTRY = "${env.GCP_REGION}-docker.pkg.dev/${env.GCP_PROJECT_ID}/${env.GAR_REPOSITORY}"
                        echo "Resolved Artifact Registry URI: ${env.TARGET_REGISTRY}"
                    }
                }
            }
        }

        stage('Ensure Repositories Exist') {
            steps {
                script {
                    def hasGcloud = sh(script: "command -v gcloud >/dev/null 2>&1", returnStatus: true) == 0
                    if (!hasGcloud) {
                        echo "Notice: 'gcloud' CLI is not installed on agent node — skipping remote repository auto-creation check."
                    } else {
                        def describeRc = sh(
                            script: "gcloud artifacts repositories describe ${env.GAR_REPOSITORY} --location=${env.GCP_REGION} > /dev/null 2>&1",
                            returnStatus: true
                        )
                        if (describeRc != 0) {
                            echo "Artifact Registry repository not found. Creating..."
                            def createRc = sh(
                                script: "gcloud artifacts repositories create ${env.GAR_REPOSITORY} --repository-format=docker --location=${env.GCP_REGION} --description='Docker repository for container images'",
                                returnStatus: true
                            )
                            if (createRc != 0) {
                                echo "Notice: Could not auto-create Artifact Registry repository via gcloud CLI. Proceeding with push."
                            } else {
                                echo "Artifact Registry repository created."
                            }
                        } else {
                            echo "Artifact Registry repository already exists."
                        }
                    }
                }
            }
        }

        stage('Login To Registry') {
            steps {
                script {
                    def hasGcloud = sh(script: "command -v gcloud >/dev/null 2>&1", returnStatus: true) == 0
                    if (hasGcloud) {
                        def rc = sh(
                            script: "gcloud auth configure-docker ${env.GCP_REGION}-docker.pkg.dev --quiet",
                            returnStatus: true
                        )
                        if (rc != 0) {
                            echo "Warning: gcloud auth configure-docker failed — proceeding with push attempt."
                        } else {
                            echo "Docker authentication configured for GCP Artifact Registry."
                        }
                    } else {
                        echo "Notice: 'gcloud' CLI is not installed on agent node — using local Docker credential store for ${env.TARGET_REGISTRY}."
                    }
                }
            }
        }

        stage('Tag And Push Images') {
            steps {
                script {
                    def targetImages = [
                    [name: 'my_microservices_app_frontend', tag: 'v1'],
                    [name: 'my_microservices_app_api', tag: 'v1']
                ]
                    def pushResults = []
                    for (img in targetImages) {
                        def tagToUse = (env.IMAGE_TAG && env.IMAGE_TAG != '') ? env.IMAGE_TAG : img.tag
                        def localImg = "${img.name}:${tagToUse}"
                        if (sh(script: "docker image inspect ${localImg} >/dev/null 2>&1", returnStatus: true) != 0) {
                            if (sh(script: "docker image inspect ${img.name}:${img.tag} >/dev/null 2>&1", returnStatus: true) == 0) {
                                localImg = "${img.name}:${img.tag}"
                            } else if (env.IMAGE_NAME && sh(script: "docker image inspect ${env.IMAGE_NAME}:${tagToUse} >/dev/null 2>&1", returnStatus: true) == 0) {
                                localImg = "${env.IMAGE_NAME}:${tagToUse}"
                                img.name = env.IMAGE_NAME
                            }
                        }
                        def remoteUri = "${env.TARGET_REGISTRY}/${img.name}:${tagToUse}"
                        
                        echo "Tagging ${localImg} -> ${remoteUri}"
                        sh "docker tag ${localImg} ${remoteUri}"
                        
                        echo "Pushing ${remoteUri}..."
                        sh "docker push ${remoteUri}"
                        
                        pushResults.add('{"image_name": "' + img.name + ':' + tagToUse + '", "image_tag": "' + tagToUse + '", "image_uri": "' + img.name + ':' + tagToUse + '", "push_status": "success"}')
                    }
                    env.PUSH_RESULTS_JSON = "[" + pushResults.join(",") + "]"
                }
            }
        }

        stage('Write Push Metadata') {
            steps {
                script {
                    if (env.PUSH_RESULTS_JSON && env.PUSH_RESULTS_JSON != '[]') {
                        sh '''
                            python3 -c 'import json, os; open("push_metadata.json", "w").write(json.dumps(json.loads(os.environ["PUSH_RESULTS_JSON"]), indent=2))'
                        '''
                        archiveArtifacts artifacts: 'push_metadata.json', allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    def targetImages = [
                    [name: 'my_microservices_app_frontend', tag: 'v1'],
                    [name: 'my_microservices_app_api', tag: 'v1']
                ]
                    for (img in targetImages) {
                        def remoteUri = "${env.TARGET_REGISTRY}/${img.name}:${img.tag}"
                        echo "Removing tagged image: ${remoteUri}"
                        sh "docker rmi ${remoteUri} || true"
                    }
                    sh "docker logout ${env.TARGET_REGISTRY} || true"
                }
            }
        }

    }
    post {
        always {
            script {
                try {
                    cleanWs()
                } catch (err) {
                    echo "Cleanup: " + err.message
                }
            }
        }
        failure {
            echo 'BUILD FAILED - check console output above'
        }
    }
}
