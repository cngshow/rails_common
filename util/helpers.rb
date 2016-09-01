=begin
Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
=end
require 'uri'
module KOMETUtilities
  TMP_FILE_PREFIX = './tmp/'
  YML_EXT = '.yml'
  MAVEN_TARGET_DIRECTORY = './target'
  ##
  # this method takes a camel cased word and changes it to snake case
  # Example: RailsKomet -> rails_komet
  #
  def to_snake_case(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr('-', '_').
        downcase
  end

  def self.isaac_rest_site_up?(uri:)
    result = false
    begin
      path = uri.path.empty? ? '/' : uri.path
      path << 'rest/1/system/systemInfo'
      result = Net::HTTP.new(uri.host, uri.port)
      result.use_ssl = uri.scheme.eql?('https')
      result = (result.head(path).kind_of?(Net::HTTPSuccess) || result.head(path).kind_of?(Net::HTTPInternalServerError))
        # Net::HTTP.new(u, p).head('/').kind_of? Net::HTTPOK
    rescue => ex
      $log.warn("I could not check the URL #{uri.path} at port #{uri.port} against path #{uri.path} because #{ex}.")
      result = false
    end
    result
  end

  ##
  # writes the json data to a tmp file based on the filename passed
  # @param json - the JSON data to write out
  # @param file_name - the filename to write out to the /tmp directory
  def json_to_yaml_file(json, file_name)
    if Rails.env.development?
      prefix = '#Fixture created on ' + Time.now.strftime('%F %H:%M:%S') + "\n"
      File.write("#{TMP_FILE_PREFIX}#{file_name}" + YML_EXT, prefix + json.to_yaml)
      $log.debug("Writing yaml file #{TMP_FILE_PREFIX}#{file_name}.yml.")
    else
      $log.debug("Not writing yaml file #{TMP_FILE_PREFIX}#{file_name}.yml. Rails.env = #{Rails.env}")
    end

  end

  ##
  # Convert the URL to a string for use with the json_to_yaml_file method call
  # @param url - the URL path to convert to a string with underscores
  # @return - the filename based on the URL passed
  def url_to_path_string(url)
    url = url.clone
    begin
      url.gsub!('{', '') #reduce paths like http://www.google.com/foo/{id}/faa to http://www.google.com/foo/id/faa
      url.gsub!('}', '') #reduce paths like http://www.google.com/foo/{id}/faa to http://www.google.com/foo/id/faa
      path = URI(url).path.gsub('/', '_')
      path = 'no_path' if path.empty?
      return path
    rescue => ex
      $log.error('An invalid matched_url was given!')
      $log.error(ex)
    end
    'bad_url'
  end

  ##
  # Find all IDs in a string and return the match object (right now only UUID and NID are implemented)
  # @param [String] string - the string to search for UUIDs
  # @param [String] type - optional paramter to specify which type of ID to search for. Values are [uuid, nid]
  # @return - the match object from the search
  def find_ids(string, type = nil)

    expressions = []

    if type == nil || type == 'uuid'
      expressions << /[a-zA-Z0-9]{8}-([a-zA-Z0-9]{4}-){3}[a-zA-Z0-9]{12}/
    end

    if type == nil || type == 'nid'
      expressions << /-[0-9]{10}/
    end

    Regexp.union(expressions).match(string.to_s)
  end

end

module Kernel
  TRUE_VALS = %w(true t yes y on 1)
  FALSE_VALS = %w(false f no n off 0)

  def boolean(boolean_string)
    val = boolean_string.to_s.downcase.gsub(/\s+/, '')
    return false if val.empty?
    return true if TRUE_VALS.include?(val)
    return false if FALSE_VALS.include?(val)
    raise ArgumentError.new("invalid value for Boolean: \"#{val}\"")
  end

end

module URI

  SERVICE_URL_PROXY = 'apache_url_proxy'
  SERVICE_URL_PROXY_URLS = 'urls'
  SERVICE_URL_PROXY_PATH = 'path'
  SERVICE_URL_PROXY_LOCATION = 'location'
  SERVICE_URL_PROXY_ROOT = 'proxy_pass'

  class << self
    attr_accessor :proxy_mappings
  end

  def base_url(include_port = true, trailing_slash = false)
    base_path = "#{scheme}://#{host}"
    base_path << ":#{port}" if include_port
    base_path << '/' if trailing_slash
    base_path
  end

  def to_https(https_port = 443, trailing_slash = false)
    base_path = "https://#{host}"
    base_path << ":#{https_port}"
    base_path << '/' if trailing_slash
    base_path
  end

  def valid_proxy_url?(url_string:)
    ret = true
    begin
      $log.debug("validating matched_url #{url_string}")
      u = URI url_string
      raise 'No scheme (http or https found!)' unless u.scheme
      $log.debug('valid!')
    rescue => ex
      $log.error("The matched_url #{url_string} is malformed in the proxy file.")
      $log.error("#{ex.message}")
      ret = false
    end
    ret
  end

  def self.build(uri)
    URI uri
  end

  def proxify
    if URI.proxy_mappings.nil?
      proxy_file = File.exists?("#{$PROPS['PRISME.data_directory']}/service_url_proxy.yml") ? "#{$PROPS['PRISME.data_directory']}/service_url_proxy.yml" : './config/service/service_url_proxy.yml'
      unless File.exists? proxy_file
        $log.warn('No proxy mapping file found.  Doing nothing!')
        return self
      end
      $log.debug('initializing the proxy mappings to:')
      URI.proxy_mappings = YAML.load_file(proxy_file)
      $log.debug("PROXY MAPPINGS ARE: #{URI.proxy_mappings.inspect}")
      apache_host = URI.proxy_mappings[SERVICE_URL_PROXY_ROOT][SERVICE_URL_PROXY]
      $log.debug("apache host is #{apache_host}")
      valid_urls = valid_proxy_url?(url_string: apache_host)
      URI.proxy_mappings[SERVICE_URL_PROXY_ROOT][SERVICE_URL_PROXY_URLS].each do |url_hash|
        url = url_hash[SERVICE_URL_PROXY_PATH]
        valid_urls = valid_urls & valid_proxy_url?(url_string: url) # & will not short circuit
      end
      unless valid_urls
        URI.proxy_mappings = nil
        return self
      end
      URI.proxy_mappings[SERVICE_URL_PROXY_ROOT][SERVICE_URL_PROXY_URLS].sort! do |a, b|
        b[SERVICE_URL_PROXY_PATH].length <=> a[SERVICE_URL_PROXY_PATH].length
      end
      URI.proxy_mappings.freeze
      $log.debug(URI.proxy_mappings.inspect)
    end
    proxy_url = URI.proxy_mappings[SERVICE_URL_PROXY_ROOT][SERVICE_URL_PROXY].clone
    proxy_url << '/' unless proxy_url.last.eql? '/'
    #sorted longest to shortest
    urls = URI.proxy_mappings[SERVICE_URL_PROXY_ROOT][SERVICE_URL_PROXY_URLS]
    urls.each do |url_hash|
      matched_url = url_hash[SERVICE_URL_PROXY_PATH]
      location = url_hash[SERVICE_URL_PROXY_LOCATION]
      if (self.to_s.starts_with?(matched_url) || (self.clone.to_s << '/').starts_with?(matched_url))
        #we found our mappings!!
        apache_proxy = URI(proxy_url)
        clone = self.clone
        clone.path << '/' unless clone.path.last.eql? '/'
        matched_url = URI matched_url
        matched_url.path << '/' if matched_url.path.empty?
        matched_url.path << '/' unless matched_url.path.last.eql? '/'
        context = matched_url.path
        unless location.eql? '/'
          location = '/' + location unless location.first.eql? '/'
          location << '/' unless location.last.eql? '/'
        end
        clone.path.sub!(context, location)
        clone.scheme = apache_proxy.scheme
        clone.port = apache_proxy.port
        clone.host = apache_proxy.host
        return clone
      end
    end
    $log.warn("No proxy mapping found for #{self}, returning self.")
    self
  end

end
#load('./lib/rails_common/util/helpers.rb')
# URI('https://cris.com').proxify
# URI.proxy_mappings = nil

#works:
# URI('https://vaausappctt704.aac.va.gov:8080/komet_b/foo/faa').proxify

#irb(main):011:0> URI('https://vaausappctt704.aac.va.gov:8080/komet_b/').proxify
#=> #<URI::HTTPS https://vaauscttweb81.aac.va.gov/server_1_rails_fazzle/>
#    irb(main):012:0> URI('https://vaausappctt704.aac.va.gov:8080/komet_b').proxify
