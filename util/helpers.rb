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
module ETSUtilities
  TMP_FILE_PREFIX = "./tmp/"
  YML_EXT = ".yml"
  ##
  # this method takes a camel cased word and changes it to snake case
  # Example: EtsTooling -> ets_tooling
  #
  def to_snake_case(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr("-", "_").
        downcase
  end

  ##
  # writes the json data to a tmp file based on the filename passed
  # @param json - the JSON data to write out
  # @param file_name - the filename to write out to the /tmp directory
  def json_to_yaml_file(json, file_name)
    if Rails.env.development?
      File.write("#{TMP_FILE_PREFIX}#{file_name}" + YML_EXT,json.to_yaml)
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
    begin
      path = URI(url).path.gsub('/','_')
      path = "no_path" if path.empty?
      return path
    rescue => ex
      $log.error("An invalid url was given!")
      $log.error(ex)
    end
    "bad_url"
  end

end
