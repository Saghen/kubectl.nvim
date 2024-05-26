local commands = require("kubectl.commands")
local tables = require("kubectl.view.tables")
local actions = require("kubectl.actions")
local pods = require("kubectl.pods")
local deployments = require("kubectl.deployments")

local M = {}

function M.Hints(hint)
	actions.new_buffer(hint, "k8s_hints", { is_float = true, title = "Hints" })
end

-- Pod view
function M.Pods()
	local results = commands.execute_shell_command("kubectl", { "get", "pods", "-A", "-o=json" })
	local data = pods.processRow(vim.json.decode(results))
	local pretty = tables.pretty_print(data, pods.getHeaders())
	local hints = tables.generateHints({
		{ key = "<l>", desc = "logs" },
		{ key = "<d>", desc = "desc" },
		{ key = "<t>", desc = "top" },
		{ key = "<enter>", desc = "containers" },
	})
	actions.new_buffer(pretty, "k8s_pods", { is_float = false, hints = hints })
end

function M.PodTop()
	local results = commands.execute_shell_command("kubectl", { "top", "pods", "-A" })
	actions.new_buffer(vim.split(results, "\n"), "k8s_pods", { is_float = true, title = "Top" })
end

function M.PodLogs(pod_name, namespace)
	local results = commands.execute_shell_command("kubectl", { "logs", pod_name, "-n", namespace })
	actions.new_buffer(vim.split(results, "\n"), "less", { is_float = true, title = pod_name })
end

function M.PodDesc(pod_name, namespace)
	local desc = commands.execute_shell_command("kubectl", { "describe", "pod", pod_name, "-n", namespace })
	actions.new_buffer(vim.split(desc, "\n"), "yaml", { is_float = true, title = pod_name })
end

function M.PodContainers(pod_name, namespace)
	local results = commands.execute_shell_command("kubectl", {
		"get",
		"pods",
		pod_name,
		"-n",
		namespace,
		"-o",
		'jsonpath=\'{range .status.containerStatuses[*]} \z
  {"name: "}{.name} \z
  {"\\n ready: "}{.ready} \z
  {"\\n state: "}{.state} \z
  {"\\n"}{end}\'',
	})
	actions.new_buffer(vim.split(results, "\n"), "yaml", { is_float = true, title = pod_name })
end

-- Deployment view
function M.Deployments()
	local results = commands.execute_shell_command("kubectl", { "get", "deployments", "-A", "-o=json" })
	local data = deployments.processRow(vim.json.decode(results))
	local pretty = tables.pretty_print(data, deployments.getHeaders())
	local hints = tables.generateHints({
		{ key = "<d>", desc = "desc" },
		{ key = "<enter>", desc = "pods" },
	})

	actions.new_buffer(pretty, "k8s_deployments", { is_float = false, hints = hints, title = "Deployments" })
end

function M.DeploymentDesc(deployment_desc, namespace)
	local cmd = string.format("kubectl describe deployment %s -n %s", deployment_desc, namespace)
	local desc = commands.execute_shell_command(cmd)
	actions.new_buffer(vim.split(desc, "\n"), "yaml", { is_float = true, title = deployment_desc })
end

return M
