# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: wagg 0.1.0.pre0 ruby lib

Gem::Specification.new do |s|
  s.name = "wagg"
  s.version = "0.1.0.pre0"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Guillermo Rodriguez Cano"]
  s.date = "2015-02-11"
  s.description = "This is a nice Meneame crawler"
  s.email = "wschutz@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "lib/wagg.rb",
    "lib/wagg/crawler/comment.rb",
    "lib/wagg/crawler/crawler.rb",
    "lib/wagg/crawler/news.rb",
    "lib/wagg/crawler/page.rb",
    "lib/wagg/crawler/tag.rb",
    "lib/wagg/crawler/version.rb",
    "lib/wagg/crawler/vote.rb",
    "lib/wagg/utils/constants.rb",
    "lib/wagg/utils/functions.rb",
    "lib/wagg/utils/retriever.rb",
    "test/helper.rb",
    "test/test_wagg.rb",
    "wagg.gemspec"
  ]
  s.homepage = "http://github.com/wileeam/wagg"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.3.0"
  s.summary = "Meneame Dataset Generator"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
      s.add_runtime_dependency(%q<delayed_job>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<delayed_job>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<delayed_job>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end

