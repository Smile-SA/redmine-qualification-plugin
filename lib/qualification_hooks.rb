require 'uri'
require 'net/http'

class QualificationHooks < Redmine::Hook::ViewListener
    def controller_issues_new_before_save(context)
        custom_field_values = context[:params][:issue][:custom_field_values]
        project = Project.find(context[:issue][:project_id])
       
        if !project.enabled_module('auto qualification')
            return nil
        end

        Rails.logger.info "Qualification plugin triggered"
        
        Setting.plugin_qualification.dup.each do | id , service |

            Rails.logger.info project.name.inspect
            Rails.logger.info service["disabled_projects"].inspect
            service = service.dup()

            if (service["disabled_projects"] || {})[project.name]
                Rails.logger.info "service " + project.name + " is disabled project wide"
                next
            end

            begin 
                Rails.logger.info "Resolving service: "
                Rails.logger.info service.inspect
                
                service["url"] = replaceVariables(service["url"], context)
                service["request_body"] = replaceVariables(service["request_body"], context)

                response = fetch(service)
            
                custom_field_values[service["target_field"]] = response
                Rails.logger.info "Service responded with: "
                Rails.logger.info response.inspect
            rescue Exception => e
                Rails.logger.info "Service resolution failed: "
                Rails.logger.info e.inspect
            end
        end

        # black magic applies the custom field values changes
        context[:issue].custom_field_values = custom_field_values
    end

    def fetch(service)
        """
        fetch a service and return it\'s response
        """
        uri = URI.parse(URI.encode(service["url"]))

        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 2 # in seconds
        http.read_timeout = 2 # in seconds
        http.use_ssl = uri.scheme === 'https'
    
        request = Net::HTTP.const_get(service["method"].capitalize.to_sym).new(uri.request_uri)
        request.body=service["request_body"]
    
        if service["headers"]
            service["headers"].each do | header |
                header_name, header_value = header.split('=')
                request[header_name] = header_value
            end
        end
            
        response = http.request(request)
        return response.body
    end
    
    def replaceVariables(text, context)
        """
        replace all the occurences of \"{{contextProp.subProp}}\" in text with the values in context
        """
        text = text.dup()

        # matches all {{contextProp.subProp}}
        matches = text.scan(/({{\w+(?:\.\w+)*}})/).map { |a| a[0] }
        # transform them into arrays of symbols [:contextProp, :subProp]
        contextPaths = matches.map { |s| s[2, s.length-4].split('.').map { |s| s.to_sym } }

        matches.zip(contextPaths).each do |match, path|
            value = dig(context.dup.rehash, *path)
            text.gsub!(match, value)
        end

        return text
    end

    def dig(hash, key, *args)
        """
        dig polyfill since ActiveRecord::Base doesnt implement dig in some versions
        """
        value = hash[key]
        return value if args.length == 0 || value.nil?
        dig(value, *args)
    end
end