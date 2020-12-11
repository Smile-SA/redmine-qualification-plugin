require 'uri'
require 'net/http'

class QualificationHooks < Redmine::Hook::ViewListener
    
    def controller_issues_new_after_save(context)
        custom_field_values = context[:params][:issue][:custom_field_values]
        project = Project.find(context[:issue][:project_id])
       
        if !project.enabled_module('auto qualification')
            return nil
        end

        Rails.logger.info "Qualification plugin triggered"
        
        Setting.plugin_qualification.dup.each do | id , service |

            Rails.logger.info "Project Name: "+project.name.inspect
            Rails.logger.info "Is Service disabled?: "+service["disabled_projects"].inspect
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
                                
                if(response["closest"])
                    updated_response=JSON.parse(response)
                    notes = "-- Redmine Advise -- <br>"
                    notes << "<br> Ticket le plus ressemblant: <br>"
                    notes << "id | autheur | commun% | date | titre  <br>"
                    notes << adviseDetails(updated_response["closest"])
                    notes << "<br> Tickets les proches du même projet: <br>"
                    notes << "id | autheur | commun% | date | titre <br>"
                    notes << (updated_response["project_closests"].map {|x| adviseDetails(x)}).join("")
                    custom_field_values[service["target_field"]] = notes
                    
                end
                #black magic applies the custom field values changes
                #context[:issue].custom_field_values = custom_field_values
                issue=Issue.find(context[:issue][:id])
                Rails.logger.info issue.custom_field_values
                issue.custom_field_values=context[:params][:issue][:custom_field_values]
                issue.save
            rescue Exception => e
                Rails.logger.info "Service resolution failed: "
                Rails.logger.info e.inspect
            end
        end

    end

    def fetch(service)
        """
        Fetch a service and return it\'s response
        """
        uri = URI.parse(URI.encode(service["url"]))

        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 2 # in seconds
        http.read_timeout = 2 # in seconds
        http.use_ssl = uri.scheme === 'https'
    
        request = Net::HTTP.const_get(service["method"].capitalize.to_sym).new(uri.request_uri)
        if service["request_body"].empty?
            request.body=service["request_body"]
        else
            request.body=URI.encode_www_form(JSON.parse(service["request_body"].to_s))
            
        end
    
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
        Replace all the occurences of \"{{contextProp.subProp}}\" in text with the values in context
        """
        text = text.dup()

        # matches all {{contextProp.subProp}}
        matches = text.scan(/({{\w+(?:\.\w+)*}})/).map { |a| a[0] }
        # transform them into arrays of symbols [:contextProp, :subProp]
        contextPaths = matches.map { |s| s[2, s.length-4].split('.').map { |s| s.to_sym } }
        matches.zip(contextPaths).each do |match, path|
            # value = dig(context.dup.rehash, *path)
            if path[0] === :custom
                custom_field = IssueCustomField.find_by_name(path[1])
                value = context[:params][:issue][:custom_field_values][custom_field.id.to_s]
                
            elsif path[0] === :project
                value = context[:project][path[1]]
            
            else
                value = dig(context.dup.rehash, :params, :issue, path[0]) 
                
            end

            text.gsub!(match, value.to_s)
        end
        Rails.logger.info "Replaced Input Variables"
        Rails.logger.info text
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

    def adviseDetails(advise)
        """
        Generate details of advise plugin as per the Advise template
        """
        begin
            ticket = Issue.find(advise["id"])
            correlation = (100 * (1 - advise["distance"])).round
            username = User.find(ticket[:author_id]).to_s || 'anonymous'
        
            return "#" + advise["id"].to_s + "  | " + username + " | " + correlation.to_s + " | " + ticket[:start_date].to_s + " | " + ticket[:subject].to_s + " <br>"
        rescue
            Rails.logger.error "ADVISE_PLUGIN WARN: could'nt find issue ##{advise["id"].to_s}"
            return ""
        end
    end
end