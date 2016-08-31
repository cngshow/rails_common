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
      $log.error('An invalid url was given!')
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

  def proxify
    URI 'https://foo.com'
  end

end
#load('./lib/rails_common/util/helpers.rb')