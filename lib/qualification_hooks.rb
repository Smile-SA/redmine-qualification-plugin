require 'uri'
require 'net/http'
require 'json'

class QualificationHooks < Redmine::Hook::ViewListener
    
    def controller_issues_new_before_save(context)
        project = Project.find(context[:issue][:project_id])
        subject = context[:issue].subject
        description = context[:issue].description

        if !project.enabled_module('auto qualification')
            return nil
        end

        Rails.logger.info "Qualification plugin triggered"

        # update custom fields
        mapping = Setting.plugin_qualification['customFieldsMappingUrl']
        custom_field_values = context[:params][:issue][:custom_field_values]

        if mapping && custom_field_values
            begin
                type_field_id = (IssueCustomField.find { |f| f.name == 'type' }).id
                type = fetch(mapping[type_field_id.to_s] + '?t=' + subject + '&b=' + description)
                
                mapping.each do |field_id, app_id|
                    if !app_id.blank?
                        begin
                            data = '?t=' + subject + '&b=' + description + '&type=' + type
                            custom_field_values[field_id] = fetch(app_id + data)
                        rescue Exception => e
                            Rails.logger.error "QUALIFICATION_PLUGIN ERROR 1: #{e}"
                        end
                    end
                end
            rescue Exception => e
                Rails.logger.error "QUALIFICATION_PLUGIN ERROR 2: #{e}"
            end

            context[:issue].custom_field_values = custom_field_values
        end

        call_hook(:controller_issues_new_before_save_after_qualification, context)
    end

    def fetch(url)
        uri = URI.parse(URI.encode(url))
        request = Net::HTTP::Get.new(uri)

        response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :open_timeout => 2, :read_timeout => 2) do |http|
            http.request(request)
        end
        
        return JSON.parse(response.body)
    end
end
