require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_140chars')
PuppetLint.configuration.ignore_paths = ['spec/**/*.pp', 'pkg/**/*.pp', 'vendor/**/*.pp']

desc 'Configure git to use the project hooks in .githooks/'
task :setup do
  sh 'git config core.hooksPath .githooks'
  puts 'Git hooks in .githooks/ are now active for this clone (commit-msg needs pre-commit installed).'
end

desc 'Run all linting and unit tests'
task default: [:lint, :spec]
