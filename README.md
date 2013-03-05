pugpig-feed-page-validator
==========================

Pugpig Feed Page Validator will run all pages markup from an editions atom feed through the validator.nu HTML5 validator.

How to use
--------

cd into the pugpig-feed-page-validator directory and run the following command:

```./fpv.rb <feed url here>```

e.g.

```./fpv.rb http://localhost/my-feed.xml```

Once the script has run you will have a results.html file containing the validation results.

Requirements
---------

* Ruby 1.9.3
* nokogiri - gem install nokogiri
* nestful - gem install nestful
