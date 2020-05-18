class QualificationController < ApplicationController
    def enable
        if params["enabled"].blank?
            params["enabled"] = {}
        end
        
        Setting.plugin_qualification.each do | id, service |
            if !service.key?("disabled_projects")
                service["disabled_projects"] = {}
            end

            # if the service is enabled for this project
            # remove it from the disabled list
            if params["enabled"].key?(id)
                service["disabled_projects"].delete(params[:project])
            else
                service["disabled_projects"][params[:project]] = true
            end

            Rails.logger.info service.inspect
        end
       
        project = Project.find_by(name:params[:project])
        redirect_to settings_project_path(project.identifier, :tab => 'qualification')
    end
end