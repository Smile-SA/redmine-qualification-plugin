require 'uri'
require 'net/http'
require 'json'

class QualificationHooks < Redmine::Hook::ViewListener
    #before_filter :controller_issues_new_before_save, :authorize, :only => :true
    
    def controller_issues_new_before_save(context)

        return nil unless Project.find(context[:issue][:project_id]).enabled_module('auto qualification')
        
        # format
        if Setting.plugin_qualification['prepend_title']
            context[:text] = context[:issue].subject + " " + context[:issue].description
        else
            context[:text] = context[:issue].description
        end
        
        if Setting.plugin_qualification['tokenize']
            context[:text] = context[:text].scan(/\w+/).join(" ")
        end

        if Setting.plugin_qualification['maxlegth'].to_i > 0
            context[:text] = context[:text][0..Setting.plugin_qualification['maxlegth'].to_i]
        end

        call_hook(:controller_issues_new_before_save_before_qualification, context)
        
        # update custom fields
        if Setting.plugin_qualification['customFieldsMappingUrl']
            custom_field_values = context[:params][:issue][:custom_field_values]

            Setting.plugin_qualification['customFieldsMappingUrl'].each do |field_id, app_id|
                if !app_id.blank?
                    begin
                        custom_field_values[field_id] = cast_to_field_type(
                            field_id, 
                            fetch_end_point(app_id, context[:text]))
                    rescue
                    end
                end
            end

            context[:issue].custom_field_values = custom_field_values
        end
        
        # update default fields
        if Setting.plugin_qualification['defaultFieldsMappingUrl']
            Setting.plugin_qualification['defaultFieldsMappingUrl'].each do |field_name, url|
                if !url.blank?
                    begin
                    rescue
                    context[:issue][field_name] = cast_to_field_type(
                        field_name,
                        fetch_end_point(url, context[:text]))
                    end
                end
            end
        end

        call_hook(:controller_issues_new_before_save_after_qualification, context)
    end

    # cast value to respect the type of the field
    def cast_to_field_type(field, value)

        case field
        when 'tracker_id', 'project_id',  'category_id', 'status_id', 'assigned_to_id', 'priority_id'
            return value.to_i
        else
            return value
        end
    end

    def fetch_end_point(url, text)

        uri = URI(url + text)
        request = Net::HTTP::Get.new(uri)

        response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :open_timeout => 2, :read_timeout => 2) do |http|
            http.request(request)
        end

        deep_fetch_arr(JSON.parse(response.body), Setting.plugin_qualification['reponse_path'])
    end

    # deep fetch an array
    # keys should match key1.subKey.subsubKey
    def deep_fetch_arr(arr, keys)
        
        keys.split(".").reduce(arr) { |hsh, k| hsh.fetch(k) { |x| yield(x) } }
    end
end
