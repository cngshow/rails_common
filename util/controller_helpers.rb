module CommonController
  ERROR_DIALOG_CSS = File.open("#{Rails.root}/lib/rails_common/public/error_dialog.css", 'r') { |file| file.read }
  CONCEPT_RECENTS = 'general_concept_recents'
  CONCEPT_RECENTS_ASSOCIATION = 'association'
  CONCEPT_RECENTS_MAPSET = 'mapset'
  CONCEPT_RECENTS_SEMEME = 'sememe'
  CONCEPT_RECENTS_METADATA = 'metadata'
  
  def pundit_error(exception)
    $log.error(exception.message)
    $log.error(exception.class.to_s)
    $log.error request.fullpath
    $log.error(exception.backtrace.join("\n"))

    if exception.is_a?(Pundit::NotAuthorizedError) || exception.is_a?(Pundit::AuthorizationNotPerformedError)
      erb = "#{Rails.root}/lib/rails_common/public/not_authorized.html.erb"
      erb_str = File.open(erb, 'r') { |file| file.read }
      erb_str = ERB.new(erb_str).result(binding)
      render html: erb_str.html_safe
    else
      raise exception
    end
  end

  def renew_session
    # this action cannot be blacklisted by ssoi
    render json: {roundtrip: Time.now.to_i}
  end

  def self.get_rest_connection(url, header = 'application/json')
    conn = Faraday.new(url: url) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.headers['Accept'] = header
      faraday.adapter :net_http # make requests with Net::HTTP
      #faraday.basic_auth(props[PrismeService::NEXUS_USER], props[PrismeService::NEXUS_PWD])
    end
    conn
  end

  def get_rest_connection(url, header = 'application/json')
    CommonController.get_rest_connection(url, header)
  end

  def trinidad?
    root_path.to_s.eql?('/')
  end

  def setup_routes
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    routes = Rails.application.routes.named_routes.helper_names
    $VERBOSE = original_verbosity
    @@routes_hash ||= {}
    ssoi = ssoi? rescue false
    @@routes_hash[ssoi] ||= {}
    if @@routes_hash[ssoi].empty?
      routes.each do |route|
        begin
          @@routes_hash[ssoi][route] = self.send(route)
        rescue ActionController::UrlGenerationError => ex
          if (ex.message =~ /missing required keys: \[(.*?)\]/)
            keys = $1
            keys = keys.split(',')
            keys.map! do |e|
              e.gsub!(':', '')
              e.strip
            end
            required_keys_hash = {}
            keys.each do |key|
              required_keys_hash[key.to_sym] = ':' + key.to_s
            end
            @@routes_hash[ssoi][route] = self.send(route, required_keys_hash)
          else
            raise ex
          end
        end
      end
    end
    #$log.debug('routes hash passed to javascript is ' + @@routes_hash.to_s)
    gon.routes = @@routes_hash[ssoi]
  end

  ##
  # get_next_id - generates a unique ID by using the systems nano-second time and date
  # @return [String] returns a unique ID by using the systems nano-second time and date
  def get_next_id
    return java.lang.System.nanoTime.to_s
  end

  ##
  # is_id? - tests to see if the provided ID is really an ID of the type specified
  # @param [String] id - the ID to test
  # @param [String] type - the type of id to test the passed value against. Options are 'uuid' (default), 'nid', 'sequence'
  # @return [String] returns a unique ID by using the systems nano-second time and date
  def is_id?(id, type: 'uuid')

    is_id = false

    # TODO - add support for other id types
    if type == 'uuid'
      is_id = id.to_s.match(/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/) != nil
    end

    return is_id
  end

  ##
  # add_to_recents - uses the standard fields for recently searched concepts to add an id and description to an array of these values in the session
  # @param [Symbol] recent_name - The name of the array in the session as a symbol
  # @param [String] id - The id of the searched concept
  # @param [String] description - The description of the searched concept
  # @param [String] type - The terminology type of the searched concept
  # @param [Integer] max_items - The total number of items to store in the array. When array has reached the limit the oldest entry will be removed to make room. Optional, defaults to 20
  # @return [Boolean] returns true if the values were added, false if they were not because they already existed in the array.
  def add_to_recents(recent_name, id, description, type, max_items: 20)

    recents_array = []
    added = false

    # see if the recents array already exists in the session
    if session[recent_name]
      recents_array = session[recent_name]
    end

    # only proceed if the array does not already contain the id and term that were searched for
    already_exist = recents_array.find { |recent|
      (recent[:id] == id && recent[:text] == description)
    }

    if already_exist == nil

      # if the recents array has the max items remove the last item before adding a new one
      if recents_array.length == max_items
        recents_array.delete_at(max_items - 1)
      end

      # put the current items into the beginning of the array
      recents_array.insert(0, {id: id, text: description, type: type})

      # put the array into the session
      session[recent_name] = recents_array
      added = true
    end

    return added
  end

  ##
  # find_metadata_by_id - loops through the metadata and finds an entry containing the specified id.
  # @param [String] id - the ID to search for
  # @param [String] id_type - the type of id search for. Options are 'uuid' (default), 'sequence'
  # @param [boolean] return_description - Should the function return the FSN description (true) or the metadata key of the found value (false). Default is true
  # @return [String] returns either the FSN description or the metadata object of the found value, as specified by return_description. If no entry matches returns nil.
  def find_metadata_by_id (id, id_type: 'uuid', return_description: true)

    # loop through the metadata structure
    $isaac_metadata_auxiliary.each_value do |value|

      # check to see if the passed id matches the specified id in the metadata
      if id_type == 'uuid' && value['uuids'].first[:uuid] == id
        found = true
      elsif id_type == 'sequence' && value['uuids'].first[:translation]['value'].to_s == id.to_s
        found = true
      end

      # if this value was a match, return the specified object
      if found && return_description
        return value['fsn']
      elsif found
        return value
      end
    end

    # if nothing was found return nil
    return nil
  end

  ##
  # ruby_classname_to_java - takes a class name in Ruby format (ex: 'Gov::Vha::Isaac::Rest::Api1::Data::Sememe::DataTypes::RestDynamicSememeString') and translates it into the format Java requires (ex: 'gov.vha.isaac.rest.api1.data.sememe.dataTypes.RestDynamicSememeString')
  # @param [String] class_name - The Ruby formatted class name to translate
  # @return [String] returns the class name in Java format
  def ruby_classname_to_java(class_name:)

    parts = class_name.to_s.split('::')
    packageless_class_name = parts.pop

    parts.map! do |package_part|
      package_part[0] = package_part[0].downcase
      package_part
    end

    parts << packageless_class_name
    parts.join('.')
  end
end