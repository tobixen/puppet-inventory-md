require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.default_facts = {
    kernel: 'Linux',
    operatingsystem: 'Ubuntu',
    operatingsystemrelease: '22.04',
    osfamily: 'Debian',
  }
end
