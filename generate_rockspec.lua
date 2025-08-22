#!/usr/bin/env lua

local git_ref = os.getenv("CI_COMMIT_TAG") or "scm"
local repo_url = os.getenv("CI_REPO_URL")
local repo_name = os.getenv("CI_REPO_NAME")
local summary = os.getenv("ROCKSPEC_SUMMARY")
local license = os.getenv("ROCKSPEC_LICENSE")
local dependencies = os.getenv("DEPENDENCIES") or {}
local test_dependencies = os.getenv("TEST_DEPENDENCIES") or {}

local modrev = git_ref:match("^v?(.+)$")
local specrev = 1

local template = [[
rockspec_format = '3.0'
package = '$package'
version = '$version'

description = {
  summary = '$summary',
  homepage = '$homepage',
  license = '$license'
}

source = {
  url = '$repo_url/archive/$git_ref.zip',
  dir = '$package'
}

dependencies = $dependencies

test_dependencies = $test_dependencies

build = {
  type = 'builtin',
  copy_directories = {}
}
]]

---@diagnostic disable param-type-mismatch
local content = template:gsub("$package", repo_name)
    :gsub("$version", modrev .. "-" .. specrev)
    :gsub("$summary", summary)
    :gsub("$homepage", repo_url)
    :gsub("$license", license)
    :gsub("$dependencies", dependencies)
    :gsub("$test_dependencies", test_dependencies)
    :gsub("$repo_url", repo_url)
    :gsub("$git_ref", git_ref)

print(content)
