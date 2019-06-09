##
# This file is part of WhatWeb and may be subject to
# redistribution and commercial restrictions. Please see the WhatWeb
# web site for more information on licensing and terms of use.
# http://www.morningstarsecurity.com/research/whatweb
##
Plugin.define do
name "AmazonElasticLoadBalancer"
authors [
  "Bhavin Senjaliya <bhavin.senjaliya@gmail.com>", # 2016-08-19
  "Andrew Horton", # v0.2 # 2017-11-27 # Update Website. Remove comments. 
]
version "0.2"
description "Amazon Elastic Load Balancer"
website "https://aws.amazon.com/elasticloadbalancing/"

# Matches #
matches [

	# Cookie 
	{ :search => "headers[set-cookie]", :regexp => /AWSELB/, :name=>"AWSELB cookie" },

] 

end
