module CommonController

  def trinidad?
    root_path.to_s.eql?('/')
  end

  def setup_routes
    routes = Rails.application.routes.named_routes.helpers.to_a
    @@routes_hash ||= {}
    if(@@routes_hash.empty?)
      routes.each do |route|
        begin
          @@routes_hash[route.to_s] = self.send(route)
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
            @@routes_hash[route.to_s] = self.send(route, required_keys_hash)
          else
            raise ex
          end
        end
      end
    end
    #$log.debug('routes hash passed to javascript is ' + @@routes_hash.to_s)
    gon.routes = @@routes_hash
  end

  ##
  # get_next_id - generates a unique ID by using the systems nano-second time and date
  # @return [Integer] returns a unique ID by using the systems nano-second time and date
  def get_next_id
    return java.lang.System.nanoTime
  end

  ##
  # add_to_recents - uses the standard fields for recently searched concepts to add an id and description to an array of these values in the session
  # @param [Symbol] recent_name - The name of the array in the session as a symbol
  # @param [String] id - The id of the searched concept
  # @param [String] description - The description of the searched concept
  # @param [Integer] max_items - The total number of items to store in the array. When array has reached the limit the oldest entry will be removed to make room. Optional, defaults to 20
  # @return [Boolean] returns true if the values were added, false if they were not because they already existed in the array.
  def add_to_recents(recent_name, id, description, max_items: 20)

    recents_array = []
    added = false

    # see if the recents array already exists in the session
    if session[recent_name]
      recents_array = session[recent_name]
    end

    # only proceed if the array does not already contain the id and term that were searched for
    already_exist = recents_array.find {|recent|
      (recent[:id] == id && recent[:text] == description)
    }

    if already_exist == nil

      # if the recents array has the max items remove the last item before adding a new one
      if recents_array.length == max_items
        recents_array.delete_at(max_items - 1)
      end

      # put the current items into the beginning of the array
      recents_array.insert(0, {id: id, text: description})

      # put the array into the session
      session[recent_name] = recents_array
      added = true
    end

    return added
  end
end