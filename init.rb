require 'redmine'

require_dependency 'qualification_hooks'

Redmine::Plugin.register :qualification do
    name 'Qualification plugin'
    author 'Damien GILLES'
    description 'Set issue fields by fetching a remote end point'
    version '0.2.1'
    settings partial: 'settings/qualification', default: {}
    project_module 'auto qualification' do
        permission :qualification, :public => true
    end
end

# due to ruby's black magic, removing this log of the list of ProjectsHelper's
# methods create an error (undefined method `project_settings_tabs')
Rails.logger.info ProjectsHelper.instance_methods

module ProjectsHelper
    '''
    ProjectsHelper.project_settings_tabs monkey patching to include a new tab: qualification
    This view is used for per project service configuration
    '''
    old_project_settings_tabs = instance_method(:project_settings_tabs)

    define_method(:project_settings_tabs) do 
        tabs = old_project_settings_tabs.bind(self).()

        if !@project.enabled_module('auto qualification')
            return tabs
        end

        tabs.push({
            :name=>"qualification", # html id (any unique value)
            :action=>:edit_project, # some role/permission
            :partial=>"projects/settings/qualification", # some view ??
            :label=>:qualification}) # should match a translation file entry
        Rails.logger.info tabs
        return tabs
    end
end
