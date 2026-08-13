source "https://rubygems.org"

gemspec

group :development do
  gem "bundler"
  gem "immosquare-cleaner"
  gem "rake"
  ##============================================================##
  ## Language Server Protocol : https://shopify.github.io/ruby-lsp/
  ##============================================================##
  gem "ruby-lsp"
end

##============================================================##
## Anything the specs need belongs here and not in :development,
## which the CI skips (cf. bin/ci).
##============================================================##
group :test do
  gem "rspec"
  gem "simplecov",      :require => false
  gem "simplecov-lcov", :require => false
end
