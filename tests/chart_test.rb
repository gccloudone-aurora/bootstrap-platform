require "open3"
require "yaml"

CHART = File.expand_path("../charts/argocd-bootstrap", __dir__)
NAMESPACE = "platform-management-system"

def assert(condition, message)
  raise message unless condition
end

def render(phase, values = {})
  output, errors, result = Open3.capture3(
    "helm", "template", "argocd-bootstrap", CHART,
    "--namespace", NAMESPACE, "--set-string", "phase=#{phase}", "--values", "-",
    stdin_data: YAML.dump(values)
  )
  raise errors unless result.success?
  YAML.load_stream(output).compact
end

git = {
  "url" => "https://github.com/example/platform.git",
  "branch" => "feature/bootstrap",
  "path" => "platform/with: space/**/config.yaml"
}
resources = render("resources", "git" => git)
projects = resources.select { |resource| resource["kind"] == "AppProject" }
assert(resources.length == 5, "Expected exactly four projects and one ApplicationSet")
assert(projects.map { |project| project.dig("metadata", "name") }.sort ==
  %w[aurora aurora-app aurora-core aurora-solution], "Project names changed")
resources.each do |resource|
  assert(resource.dig("metadata", "namespace") == NAMESPACE, "Incorrect namespace")
end
projects.each do |project|
  spec = project.fetch("spec")
  assert(spec["clusterResourceWhitelist"] == [{ "group" => "*", "kind" => "*" }], "Resource permissions changed")
  assert(spec["destinations"].all? { |destination| destination["server"].start_with?("https://kubernetes.default.svc") }, "Destination clusters must be restricted")
  assert(spec["sourceRepos"] == ["https://gccloudone-aurora.github.io/aurora-platform-charts"] && spec.dig("orphanedResources", "warn"), "Repository allowlist changed")
  assert(spec["syncWindows"] == [{
    "clusters" => ["*"], "duration" => "3h", "kind" => "allow", "manualSync" => true,
    "schedule" => "* 19 * * 2,4", "timeZone" => "America/Toronto"
  }], "Sync windows changed")
end

appset = resources.find { |resource| resource["kind"] == "ApplicationSet" }.fetch("spec")
assert(appset.dig("generators", 0, "git") == {
  "files" => [{ "path" => git["path"] }], "repoURL" => git["url"], "revision" => git["branch"]
}, "Git generator values were not preserved")
assert(appset.dig("template", "metadata", "name") == "platform-{{ path.basename }}", "ApplicationSet name template changed")
source = appset.dig("template", "spec", "source")
assert(source.dig("helm", "releaseName") == "{{ path.basename }}", "Release template was evaluated by Helm")
assert(source.dig("helm", "values") == "{{ settings }}\n", "Settings template was evaluated by Helm")
assert(source["targetRevision"] == "{{ version }}", "Version template was evaluated by Helm")
assert(appset.dig("syncPolicy", "preserveResourcesOnDeletion"), "Deletion policy changed")
assert(appset.dig("template", "spec", "syncPolicy", "automated").nil?, "Default applications must require manual sync")
automated = render("resources", "automation" => { "enabled" => true }).find { |resource| resource["kind"] == "ApplicationSet" }
assert(automated.dig("spec", "template", "spec", "syncPolicy", "automated") == {
  "prune" => false, "selfHeal" => true
}, "Automatic sync must be explicit and non-pruning")
puts "PASS: chart preserves projects, policies, Git values, and ApplicationSet expressions"

readiness = render("readiness")
assert(readiness.map { |resource| resource["kind"] }.sort ==
  %w[ClusterRole ClusterRoleBinding Job ServiceAccount], "Readiness phase must contain only built-in kinds")
job = readiness.find { |resource| resource["kind"] == "Job" }
assert(job.dig("metadata", "annotations", "helm.sh/hook") == "post-install,post-upgrade", "Readiness hook is missing")
pod = job.dig("spec", "template", "spec")
assert(pod.dig("initContainers", 0, "args").include?("--for=create"), "Creation gate is missing")
assert(pod.dig("containers", 0, "args").include?("--for=condition=Established"), "Readiness gate is missing")
%w[initContainers containers].each do |section|
  %w[crd/appprojects.argoproj.io crd/applicationsets.argoproj.io].each do |name|
    assert(pod.dig(section, 0, "args").include?(name), "Missing CRD gate for #{name}")
  end
end
role = readiness.find { |resource| resource["kind"] == "ClusterRole" }
assert(role["rules"] == [{
  "apiGroups" => ["apiextensions.k8s.io"], "resources" => ["customresourcedefinitions"],
  "verbs" => %w[get list watch]
}], "Readiness job must have read-only CRD permissions")
puts "PASS: readiness phase waits for CRD creation and establishment with read-only RBAC"