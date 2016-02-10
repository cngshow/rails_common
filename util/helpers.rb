module ETSUtilities
    ##
    # this method takes a camel cased word and changes it to snake case
    # Example: EtsTooling -> ets_tooling
    #
    def to_snake_case(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
    end
end
