require 'redmine'
require_dependency 'qualification_hooks'

Redmine::Plugin.register :qualification do
  name 'Qualification plugin'
  author 'Damien GILLES'
  description 'Set issue fields by fetching a remote end point'
  version '0.1.5'
  settings partial: 'settings/qualification', default: {}
  project_module 'auto qualification' do
    permission :qualification, :public => true
  end
end