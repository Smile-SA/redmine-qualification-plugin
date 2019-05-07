require 'uri'
require 'net/http'
require 'json'

class QualificationHooks < Redmine::Hook::ViewListener
    
    def controller_issues_new_before_save(context)

        project = Project.find(context[:issue][:project_id])

        if !project.enabled_module('auto qualification')
            call_hook(:controller_issues_new_before_save_before_qualification, context)
            call_hook(:controller_issues_new_before_save_after_qualification, context)

            return nil
        end
        Rails.logger.info "Qualification plugin triggered"

        call_hook(:controller_issues_new_before_save_before_qualification, context)
        
        # update custom fields
        mapping = Setting.plugin_qualification['customFieldsMappingUrl']       
        if mapping && context[:params][:issue][:custom_field_values]
            
            custom_field_values = context[:params][:issue][:custom_field_values]

            mapping.each do |field_id, app_id|
                if !app_id.blank?
                    begin
                        custom_field_values[field_id] = fetch_end_point(app_id, context)
                    rescue Exception => e
                        Rails.logger.error "QUALIFICATION_PLUGIN ERROR: #{e}"
                    end
                end
            end

            context[:issue].custom_field_values = custom_field_values
        end

        call_hook(:controller_issues_new_before_save_after_qualification, context)
    end

    def fetch_end_point(url, context)
        data = '?t=' + context[:issue].subject + '&b=' + context[:issue].description
        uri = URI.parse(URI.encode(url + data))
        request = Net::HTTP::Get.new(uri)

        response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :open_timeout => 2, :read_timeout => 2) do |http|
            http.request(request)
        end
        
        deep_fetch_arr(JSON.parse(response.body), 'topScoringIntent.intent')
    end

    # deep fetch an array
    # keys should match key1.subKey.subsubKey
    def deep_fetch_arr(arr, keys)
        keys.split(".").reduce(arr) { |hsh, k| hsh.fetch(k) { |x| yield(x) } }
    end
end
