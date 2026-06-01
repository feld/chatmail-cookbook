module ChatmailCookbook
  module SizeHelpers
    UNITS_IN_MB = {
      'B' => 1.0 / 1_048_576,
      'K' => 1.0 / 1024,
      'M' => 1,
      'G' => 1024,
      'T' => 1024 * 1024,
      'P' => 1024 * 1024 * 1024,
      'E' => 1024 * 1024 * 1024 * 1024
    }.freeze

    def to_megabytes(str)
      match = str.to_s.strip.match(/^(\d+(?:\.\d+)?)\s*([BKMGTPE])$/i)
      raise ArgumentError, "unrecognized format: #{str}" unless match

      value = match[1].to_i
      unit  = match[2].upcase

      (value * UNITS_IN_MB.fetch(unit)).round(2)
    end
  end
end

Chef::Recipe.include(ChatmailCookbook::SizeHelpers)
Chef::Resource.include(ChatmailCookbook::SizeHelpers)
Chef::Provider.include(ChatmailCookbook::SizeHelpers)
