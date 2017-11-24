##
# This file is part of WhatWeb and may be subject to
# redistribution and commercial restrictions. Please see the WhatWeb
# web site for more information on licensing and terms of use.
# http://www.morningstarsecurity.com/research/whatweb
##
# Version 0.8 # 2016-12-16 @anoroozian
# Aggressive version detection matches 4.0 -> 4.0-beta4
# Plugin format update
##
# Version 0.7 # 2016-10-25 @SlivTaMere
# Added "wp-includes" and "wp-json" in href and src detection.
##
# Version 0.6 # 2012-03-05
# Added regex version detection for /readme.html
##
# Version 0.5 # 2012-03-05
# Added regex version detection for /readme.html
##
# Version 0.4 # 2011-04-06 #
# Added aggressive md5 matches
##
# Version 0.3
# Now using :version=>// instead of a passive function, added description, examples and included relative /wp-content/ link detection
##
Plugin.define do
name "WordPress"
  author "Andrew Horton"
  version "0.8"
  description "WordPress is an opensource blogging system commonly used as a CMS."
  website "http://www.wordpress.org/"
  
  # Dorks #
  dorks [
           '"is proudly powered by WordPress"'
        ]
  
  # Matches #
  matches [
         
         {:text=>'<meta name="generator" content="WordPress.com" />'},
         {:text=>'<a href="http://www.wordpress.com">Powered by WordPress</a>', :name=>'powered by link'},
         {:text=>"<link rel='https://api.w.org/'", :name=>'REST API link'},

         {:regexp=>/"[^"]+\/wp-content\/[^"]+"/, :name=>"wp-content", :certainty=>75 },
         
         {:version=>/<meta name="generator" content="WordPress ([0-9\.]+)"/ },
         
         # url exists, i.e. returns HTTP status 200
         {:url=>"/wp-cron.php"},
         
         #{:url=>"/admin/", :full=>true }, # full means that whatweb will run all plugins against this url - this isn't yet implemented as of 0.4.7
         
         # /wp-login.php  exists & contains a string
         {:url=>"/wp-login.php", :text=>'<a title="Powered by WordPress" href="http://wordpress.org/">'},
         {:url=>"/wp-login.php", :text=>'<a href="http://wordpress.org/" title="Powered by WordPress">', :name=>'wp3 login page'},
         {:url=>"/wp-login.php", :text=>'action=lostpassword'},
         
         {:url=>"/wp-login.php", :tagpattern=>"!doctype,html,head,title,/title,meta,link,link,script,/script,meta,/head,body,div,h1,a,/a,/h1,form,p,label,br,input,/label,/p,p,label,br,input,/label,/p,p,label,input,/label,/p,p,input,input,input,/p,/form,p,a,/a,/p,p,a,/a,/p,/div,script,/script,/body,/html"}, #note that WP plugins can add script tags. tags are delimited by commas so we can count how close it is
         {:url=>"favicon.ico", :md5=>'f420dc2c7d90d7873a90d82cd7fde315'}, # not common, seen on http://s.wordpress.org/favicon.ico
         {:url=>"favicon.ico", :md5=>'fa54dbf2f61bd2e0188e47f5f578f736', :name=>'WordPress.com favicon'},  # on wordpress.com blogs  http://s2.wp.com/i/favicon.ico
         
         {:url=>"/readme.html", :version=>/<h1.*WordPress.*Version ([0-9a-z\.]+).*<\/h1>/m}
         
        ]
  
  # Passive #
  passive do
    m=[]
    
    # detect /wp-content/ on this site but don't be confused by links to other sites.
    #<link rel="stylesheet" href="http://bestwebgallery.com/wp-content/themes/master/style.css" type="text/css" />
    
    if @body =~ /(href|src)="[^"]*\/wp-content\/[^"]*/
      # is it a relative link or on the same site?
      links= @body.scan(/(href|src)="([^"]*\/wp-content\/[^"]*)/).map {|x| x[1].strip }.flatten
      links.each do |thislink|
        # join this link wtih target, check if host part is ==, if so, it's relative
        joined_uri=URI.join(@base_uri.to_s,thislink)
        
        if joined_uri.host == @base_uri.host
          #puts "yes, #{joined_uri.to_s} is relative to #{@base_uri.to_s}"
          m << {:name=>"Relative /wp-content/ link" }
          break
        end
      end
    end
	
	if @body =~ /(href|src)="[^"]*\/wp-includes\/[^"]*/
      # is it a relative link or on the same site?
      links= @body.scan(/(href|src)="([^"]*\/wp-includes\/[^"]*)/).map {|x| x[1].strip }.flatten
      links.each do |thislink|
        # join this link wtih target, check if host part is ==, if so, it's relative
        joined_uri=URI.join(@base_uri.to_s,thislink)

        if joined_uri.host == @base_uri.host
          #puts "yes, #{joined_uri.to_s} is relative to #{@base_uri.to_s}"
          m << {:name=>"Relative /wp-includes/ link" }
          break
        end
      end
    end

    if @body =~ /(href|src)="[^"]*\/wp-json\/[^"]*/
      # is it a relative link or on the same site?
      links= @body.scan(/(href|src)="([^"]*\/wp-json\/[^"]*)/).map {|x| x[1].strip }.flatten
      links.each do |thislink|
        # join this link wtih target, check if host part is ==, if so, it's relative
        joined_uri=URI.join(@base_uri.to_s,thislink)

        if joined_uri.host == @base_uri.host
          #puts "yes, #{joined_uri.to_s} is relative to #{@base_uri.to_s}"
          m << {:name=>"Relative /wp-json/ link" }
          break
        end
      end
    end

    
    # Return passive matches
    m
  end
  
  # Aggressive #
  aggressive do
    m=[]
    
    # the paths are relative to the url path if they don't start with /
    # this path, with this md5 = this version

    versions = Hash[
                    "0.71-gold" =>
                    [%w(readme.html 0c1e4a01d4ccf6dbedda30bf3c5eeb9e),
                     %w(b2-include/xmlrpc.inc 14524c5d7f9f72394e04512d9941bc50)],
                    "0.72-rc1" =>
                    [%w(readme.html dacf325336ae55fffbcd54bd08de55b4),
                     %w(wp-layout.css dc04833fd754c0b404ec157e0bb8e7ae)],
                    "0.72-beta1" =>
                    [%w(readme.html dacf325336ae55fffbcd54bd08de55b4),
                     %w(wp-layout.css 7edb4d6b89b4625f6e6c6b9e5cd589b6)],
                    "1.0-rc1" =>
                    [%w(readme.html 613b5eca59267b5b62b6e81dd9536b1b),
                     %w(wp-sitetemplates/main/templates/top.html 120ca99e1b816915e0f27152b7d24a75)],
                    "1.0-platinium" =>
                    [%w(readme.html 6e08f4bfb7f79de78a3278f0f4ad981f)],
                    "1.0.1-rc1" =>
                    [%w(readme.html 11f6a057f13e9413edc98e4614230622)],
                    "1.0.1-miles" =>
                    [%w(readme.html 7ccd56b1c5b7123ed9afb222e6e93924)],
                    "1.0.2" =>
                    [%w(readme.html c91375254e9f56e45939ffcc28424c72)],
                    "1.0.2-blakey" =>
                    [%w(readme.html c91375254e9f56e45939ffcc28424c72)],
                    "1.2-rc1" =>
                    [%w(readme.html 790736d62d442117f9d28b64161919a2)],
                    "1.2-rc2" =>
                    [%w(readme.html 790736d62d442117f9d28b64161919a2)],
                    "1.2-beta" =>
                    [%w(readme.html 790736d62d442117f9d28b64161919a2),
                     %w(wp-layout.css c3f4bd5f3146770c0cba45b10c385047)],
                    "1.2-delta" =>
                    [%w(readme.html 790736d62d442117f9d28b64161919a2),
                     %w(wp-layout.css 1bcc9253506c067eb130c9fc4f211a2f)],
                    "1.2-mingus" =>
                    [%w(readme.html 6c3c457ed408be44244edc121cada9a2),],
                    "1.2.1" =>
                    [%w(readme.html 75eaf1c4b267e11fffd42c34e8832567),
                     %w(wp-layout.css 7140e06c00ed03d2bb3dad7672557510)],
                    "1.2.2" =>
                    [%w(readme.html 6c3c457ed408be44244edc121cada9a2),
                     %w(wp-includes/js/scriptaculous/scriptaculous.js d72a1c859799b4e1355ff65e4a1ad148)],
                    "1.5-strayhorn" =>
                    [%w(readme.html aaa2d12586d9632c76b7b7f03d58a9f6)],
                    "1.5.1" =>
                    [%w(readme.html c60692ee8e176db0ac0be5ca69ba6c24)],
                    "1.5.1.1" =>
                    [%w(readme.html c60692ee8e176db0ac0be5ca69ba6c24)],
                    "1.5.1.2" =>
                    [%w(readme.html c60692ee8e176db0ac0be5ca69ba6c24)],
                    "1.5.1.3" =>
                    [%w(readme.html aaa2d12586d9632c76b7b7f03d58a9f6)],
                    "1.5.2" =>
                    [%w(readme.html aaa2d12586d9632c76b7b7f03d58a9f6)],
                    "2.0" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842),
                     %w(wp-content/themes/default/style.css f786f66d3a40846aa22dcdfeb44fa562)],
                    "2.0.1" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.1-rc1" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.4" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.5" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.5-rc1" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.5-beta1" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.6" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.6-rc1" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.7" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.7-rc1" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.7-rc2" =>
                    [%w(readme.html 010ac2a095f4d30b2a650b94cf3f8842)],
                    "2.0.8" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.8-rc1" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.9" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.9-rc1" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.9-beta" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.10" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.10-rc1" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.10-rc2" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.10-rc3" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.11" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.11-rc1" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.11-rc2" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.0.11-rc3" =>
                    [%w(readme.html ec9a2ffad38a3f0185aa6d9c0b8d6673)],
                    "2.1" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1-rc1" =>
                    [%w(readme.html 1808e8f88b490dffdfe0e3ea0a951e86)],
                    "2.1-rc2" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1-beta1" =>
                    [%w(readme.html 33228916bae952810ca10a09b23bc366)],
                    "2.1-beta2" =>
                    [%w(readme.html 0bb72a5175266c98406b8b42a31114de)],
                    "2.1-beta3" =>
                    [%w(readme.html 1808e8f88b490dffdfe0e3ea0a951e86),
                     %w(wp-includes/js/tinymce/plugins/inlinepopups/editor_plugin.js 527706a40c4a6939c1a47db7a6c4dbaf)],
                    "2.1-beta4" =>
                    [%w(readme.html 1808e8f88b490dffdfe0e3ea0a951e86)],
                    "2.1.1" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.1-rc1" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.1-beta" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.2" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.3" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.3-rc1" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.3-rc2" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.1.3-rc3" =>
                    [%w(readme.html a5bc745849e1971abf8efb9a135ce764)],
                    "2.2" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2-rc1" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2-rc2" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2.1" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2.1-rc1" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2.1-rc2" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2.2" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.2.3" =>
                    [%w(readme.html 939a797929aec1b8e0039014e9a29433)],
                    "2.3" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3-rc1" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3-beta1" =>
                    [%w(readme.html 0384d4bdace37e066df6bb7a85b009aa)],
                    "2.3-beta2" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3-beta3" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.1" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.1-rc1" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.1-beta1" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.2" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.2-rc1" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.2-beta1" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.2-beta2" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.2-beta3" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.3.3" =>
                    [%w(readme.html 95803b846df1873416ee96c1577b3adf)],
                    "2.5" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483)],
                    "2.5-rc1" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483),
                     %w(wp-includes/js/autosave.js c2fa52e7e956c340da6e2d2d86694cee)],
                    "2.5-rc2" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483),
                     %w(wp-includes/js/autosave.js d275157ac090ce476b4914505f8de24f)],
                    "2.5-rc3" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483)],
                    "2.5.1" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483),
                     %w(wp-includes/js/tinymce/tiny_mce.js a3d05665b236944c590493e20860bcdb)],
                    "2.6" =>
                    [%w(readme.html 5bca147a86a1d277328c298ab06b772b)],
                    "2.6-rc1" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483)],
                    "2.6-beta1" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483),
                     %w(wp-includes/js/tinymce/tiny_mce.js 35f98a53dd50907c60b872213da50deb)],
                    "2.6-beta2" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483),
                     %w(wp-includes/js/tinymce/plugins/wpeditimage/editimage.html 48a67e901144ce41af63c8e7d680ac74)],
                    "2.6-beta3" =>
                    [%w(readme.html c3024b888aeb1539f4c29df7b166d483),
                     %w(wp-includes/js/tinymce/plugins/wpeditimage/editimage.html e1e9459af693c6076a6d99997d851ab4)],
                    "2.6.1" =>
                    [%w(readme.html 0377751ad219ccbb809d527952ff7325)],
                    "2.6.1-beta1" =>
                    [%w(readme.html 5bca147a86a1d277328c298ab06b772b),
                     %w(wp-includes/js/tinymce/plugins/wpeditimage/editimage.html cb6e865aa733445c260ac01899542756)],
                    "2.6.1-beta2" =>
                    [%w(readme.html 5bca147a86a1d277328c298ab06b772b)],
                    "2.6.2" =>
                    [%w(readme.html 0377751ad219ccbb809d527952ff7325)],
                    "2.6.3" =>
                    [%w(readme.html 0377751ad219ccbb809d527952ff7325)],
                    "2.6.5" =>
                    [%w(readme.html 0377751ad219ccbb809d527952ff7325)],
                    "2.7" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.7-rc1" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133),
                     %w(wp-includes/js/swfupload/handlers.js a16a9cb39d37486aeacd3b2e1701f6aa)],
                    "2.7-rc2" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.7-beta1" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133),
                     %w(wp-includes/js/autosave.js 9ceecef42a279029e0f97b4def8e542b)],
                    "2.7-beta2" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133),
                     %w(wp-includes/js/autosave.js c1ea7016092c130a51a44ffe232bc7c9)],
                    "2.7-beta3" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133),
                     %w(wp-includes/js/tinymce/tiny_mce.js f73b7c82ff78af24cd7563862084000a)],
                    "2.7.1" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.7.1-rc1" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.8" =>
                    [%w(readme.html 4a64408bdaaa6c8af7cab9346f0ce380)],
                    "2.8-rc1" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.8-beta1" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.8-beta2" =>
                    [%w(readme.html 94c4cdfa20778d1bf9784941f9fca133)],
                    "2.8.1" =>
                    [%w(readme.html 7ed95e0b7ae663cbd0a8e77d787a4637)],
                    "2.8.1-rc1" =>
                    [%w(readme.html 4a64408bdaaa6c8af7cab9346f0ce380)],
                    "2.8.1-beta1" =>
                    [%w(readme.html 4a64408bdaaa6c8af7cab9346f0ce380),
                     %w(wp-includes/js/autosave.js 40f836bb6cf8fa6007aa2bd335754590)],
                    "2.8.1-beta2" =>
                    [%w(readme.html 4a64408bdaaa6c8af7cab9346f0ce380),
                     %w(wp-includes/js/autosave.js 8e58ac561fd6f038843395e7e18fbb0f)],
                    "2.8.2" =>
                    [%w(readme.html ef8665ddd2d87badccb3532705b95992),
                     %w(wp-content/plugins/akismet/readme.txt 48c52025b5f28731e9a0c864c189c2e7)],
                    "2.8.3" =>
                    [%w(readme.html de32a1268d126ea71127ad5f9fa8f60d)],
                    "2.8.4" =>
                    [%w(readme.html 7d93c7feb3e2e2c2112474f92e3ee6f8)],
                    "2.8.5" =>
                    [%w(readme.html f32252ef12c927f6285e4fb29efce04f)],
                    "2.8.5-beta1" =>
                    [%w(readme.html f32252ef12c927f6285e4fb29efce04f)],
                    "2.8.6" =>
                    [%w(readme.html 027283d03b08abae67279fd17a37760b)],
                    "2.8.6-beta1" =>
                    [%w(readme.html 027283d03b08abae67279fd17a37760b)],
                    "2.9" =>
                    [%w(readme.html 1eaf3b4f4c2d039d26a473c0e0b5622e)],
                    "2.9-rc1" =>
                    [%w(readme.html f182f41b25a96a12c393e35d9d063ed4)],
                    "2.9-beta1" =>
                    [%w(readme.html f182f41b25a96a12c393e35d9d063ed4),
                     %w(wp-includes/js/swfupload/handlers.js 67c19dd1aa288610db84ef258e0fde22)],
                    "2.9-beta2" =>
                    [%w(readme.html f182f41b25a96a12c393e35d9d063ed4),
                     %w(wp-includes/js/swfupload/handlers.js 829d0ee86744a34049329f5c461d12d0)],
                    "2.9.1" =>
                    [%w(readme.html 80c4ecc8630395baeb7363a7cf4dad33)],
                    "2.9.1-rc1" =>
                    [%w(readme.html 80c4ecc8630395baeb7363a7cf4dad33)],
                    "2.9.1-beta1" =>
                    [%w(readme.html 1eaf3b4f4c2d039d26a473c0e0b5622e)],
                    "2.9.2" =>
                    [%w(readme.html 6cfb514bbb51d883bb6fece65d5fd450),
                     %w(wp-content/themes/home/rtl.css 64231a50358031e1d92bb02ffcc5579d)],
                    "3.0" =>
                    [%w(readme.html 9ea06ab0184049bf4ea2410bf51ce402),
                     %w(wp-content/themes/twentyten/languages/twentyten.pot 2ea37779cc9cbfc274f1a0273a6ea1b5)],
                    "3.0-rc1" =>
                    [%w(readme.html 9ea06ab0184049bf4ea2410bf51ce402),
                     %w(wp-content/themes/twentyten/style.css 5e86e1dd9c095c1bf8ea8e5ec53bee1e)],
                    "3.0-rc2" =>
                    [%w(readme.html 9ea06ab0184049bf4ea2410bf51ce402),
                     %w(wp-content/themes/twentyten/style.css 23fd2a602c38ec4c611559fb1552afcd)],
                    "3.0-rc3" =>
                    [%w(readme.html 9ea06ab0184049bf4ea2410bf51ce402),
                     %w(wp-content/themes/twentyten/languages/twentyten.pot 497963f44fb84e2c7d425c1fd4eed76e)],
                    "3.0-beta1" =>
                    [%w(readme.html b051ca0b7f06618784dd286da1b3ce95),
                     %w(wp-includes/js/autosave.js a27e28943c0ce3e0438c03c83092c919)],
                    "3.0-beta2" =>
                    [%w(readme.html 9ea06ab0184049bf4ea2410bf51ce402),
                     %w(wp-includes/js/autosave.js 46149fb60863c31931ba3b4c2698bff4)],
                    "3.0.1" =>
                    [%w(readme.html a73cac84b8b9a99377917a6974c9eea2)],
                    "3.0.2" =>
                    [%w(readme.html 0538342b887f11ed4a306d3e7c7d6ea7)],
                    "3.0.3" =>
                    [%w(readme.html 0eb4f7981c3de98df925b3020c147a61)],
                    "3.0.4" =>
                    [%w(readme.html c7a01d814ffbbb790ee5f4f8f3631903)],
                    "3.0.5" =>
                    [%w(readme.html ed20f283f2c1b775219bdb12e5c6ba93)],
                    "3.0.6" =>
                    [%w(readme.html 45119882b8d576a3462f76708b6bc1c5)],
                    "3.1" =>
                    [%w(readme.html f01635ffca23e49e01f47e98553ea75d)],
                    "3.1-rc1" =>
                    [%w(readme.html d48f95db161328051787e2f427148f4a),
                     %w(wp-content/themes/twentyten/languages/twentyten.pot 0aac287d00db838d3bc01a1d6d621d2f)],
                    "3.1-rc2" =>
                    [%w(readme.html d48f95db161328051787e2f427148f4a),
                     %w(wp-content/themes/twentyten/style.css 150c80e23ce93ebced5035e00e4d864b)],
                    "3.1-rc3" =>
                    [%w(readme.html f01635ffca23e49e01f47e98553ea75d),
                     %w(wp-includes/css/admin-bar-rtl.css c032baf7fa4ed30d82b46946f75cbc69)],
                    "3.1-rc4" =>
                    [%w(readme.html f01635ffca23e49e01f47e98553ea75d),
                     %w(wp-admin/css/wp-admin.css 3ccbe532b172e44418888e61301ce1bd)],
                    "3.1-beta1" =>
                    [%w(readme.html 7a8b02d6ce7229e33bd64da8bef83ad7),
                     %w(wp-includes/css/admin-bar.css d858495789b9a37ef8651f54a9f2e12b)],
                    "3.1-beta2" =>
                    [%w(readme.html d48f95db161328051787e2f427148f4a),
                     %w(wp-includes/css/admin-bar.css 912a71bf5137e3a06911d1ebd855c2b7)],
                    "3.1.1" =>
                    [%w(readme.html 5be6140fc3f44126b476dfff5bc0c658)],
                    "3.1.1-rc1" =>
                    [%w(readme.html 5be6140fc3f44126b476dfff5bc0c658),
                     %w(wp-includes/version.php 8638354fc14072dac3ffe1b1c9c28251)],
                    "3.1.2" =>
                    [%w(readme.html 20f882b08b2804bc7431c0866a8999d1)],
                    "3.1.3" =>
                    [%w(readme.html ccc403368e01b3c3b0caf28079a710a5)],
                    "3.1.4" =>
                    [%w(readme.html fbebf5899944a9d7aedd00250bb71745),
                     %w(wp-content/themes/twentyten/languages/twentyten.pot 0702faf14edacb91bb82681870cb6da0)],
                    "3.2" =>
                    [%w(readme.html 573e79628d2ee07670e889569059669e)],
                    "3.2-rc1" =>
                    [%w(readme.html 573e79628d2ee07670e889569059669e),
                     %w(wp-content/themes/twentyeleven/style.css 5a13b9234881621dca42f9430bfdd885)],
                    "3.2-rc2" =>
                    [%w(readme.html 573e79628d2ee07670e889569059669e),
                     %w(wp-content/themes/twentyeleven/style.css 31156206fec3debcc2f9b844ef83d9e1)],
                    "3.2-rc3" =>
                    [%w(readme.html 573e79628d2ee07670e889569059669e),
                     %w(wp-content/themes/twentyeleven/style.css 81b2771858d8ab1ed3ae13d8d5866561)],
                    "3.2-beta1" =>
                    [%w(readme.html 573e79628d2ee07670e889569059669e),
                     %w(wp-includes/js/autosave.js 3bf40ac97632994f5ee6d8d4fc72f0d3)],
                    "3.2-beta2" =>
                    [%w(readme.html 573e79628d2ee07670e889569059669e),
                     %w(wp-includes/js/tinymce/plugins/wordpress/editor_plugin.js 708373211fb001cba51de1138ff9e748)],
                    "3.2.1" =>
                    [%w(readme.html 98d3f05ff1e321dbd58ad154cc95e569)],
                    "3.3" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a)],
                    "3.3-rc1" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-includes/css/admin-bar.css 304a1620b044cc58cef73349359943b3)],
                    "3.3-rc2" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-includes/css/admin-bar.css 9bb37fe637ee3a53d9274fd2d0301260)],
                    "3.3-rc3" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-admin/css/wp-admin.css 83cf78172b0d46d6a808abf644ed118f)
                    ],
                    "3.3-beta1" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-includes/css/admin-bar.css 7d21a462f3b5d5b9ad1f878c45f78e92)],
                    "3.3-beta2" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-includes/css/admin-bar.css e8af3c520f06153ad674eebd7453971e)],
                    "3.3-beta3" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-includes/css/admin-bar.css a30deaec087f1eab3183a2b9d50cd19b)],
                    "3.3-beta4" =>
                    [%w(readme.html e0f97110b60c3a3c71dcd1d4d923495a),
                     %w(wp-includes/css/admin-bar.css 4e6bda0b7acff641f480c4fd5d5b6910)],
                    "3.3.1" =>
                    [%w(readme.html c1ed266e26a829b772362d5135966bc3)],
                    "3.3.2" =>
                    [%w(readme.html 628419c327ca5ed8685ae3af6f753eb8)],
                    # Use  --- diff -bur folder1 folder2
                    # Not distinguishable because the differences are in files that are probably not
                    # World readable
                    # "3.3.2-rc1" =>
                    # [%w(readme.html 628419c327ca5ed8685ae3af6f753eb8)],
                    "3.3.3" =>
                    [%w(readme.html 36b2b72a0f22138a921a38db890d18c1)],
                    "3.4" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516)],
                    "3.4-rc1" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-includes/js/customize-preview.js 453a5ccf234fb8d8ce360aca3672ed95)],
                    "3.4-rc2" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-includes/js/customize-preview.js 7b1408a3cd59c8287efa8c02bd43356e)],
                    "3.4-rc3" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/customize-controls.css 17bcc2c784960eece3c2447f28a66e58)],
                    "3.4-rc4" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/wp-admin.css d8471b68d45739f07aac407c06fb8903)],
                    "3.4-beta1" =>
                    [%w(readme.html 8df86e1e534c349747292e0b56531f63),
                     %w(wp-includes/js/tinymce/tiny_mce.js 078bd9e2c8fa7b6c2ab231183f6ee2cb)],
                    "3.4-beta2" =>
                    [%w(readme.html 8df86e1e534c349747292e0b56531f63),
                     %w(wp-admin/css/colors-classic.css ade77908937b67ccbbb6341a61680855)],
                    "3.4-beta3" =>
                    [%w(readme.html 8df86e1e534c349747292e0b56531f63),
                     %w(wp-includes/js/customize-preview.js e28df79d5eb55f26b46ae88bafadc2b9)],
                    "3.4-beta4" =>
                    [%w(readme.html 8df86e1e534c349747292e0b56531f63),
                     %w(wp-includes/js/customize-preview.js a8a259fc5197a78ffe62d6be38dc52f8)],
                    "3.4.1" =>
                    [%w(readme.html 9ecbb128295ac324f63a6adc0b6e78ea),
                     %w(wp-includes/js/customize-preview.js 617d9fd858e117c7d1d087be168b5643)],
                    "3.4.2" =>
                    [%w(readme.html c6514a15e04bd9ec96df4d9b78c17bc5),
                     %w(wp-includes/js/customize-preview.js 617d9fd858e117c7d1d087be168b5643),
                     %w(/wp-admin/css/wp-admin.css dc906af62607ada3fe2baac62ac3cceb)
                    ],
                    "3.5" =>
                    [%w(readme.html 066cfc0f9b29ae6d491aa342ebfb1b71),
                     %w(wp-admin/css/wp-admin.css c8c02c7d0318ddeb985e324f126a19e8)
                    ],
                    "3.5-rc1" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/wp-admin.css 10fbaf69a4b5a9ef15f066be499b349d)
                    ],
                    "3.5-rc2" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/wp-admin.css f01e2d5cf97b4bc9c36ac84021725d82)
                    ],
                    "3.5-rc3" =>
                    [%w(readme.html 066cfc0f9b29ae6d491aa342ebfb1b71),
                     %w(wp-admin/css/wp-admin.css f1bab65db0d38af5f4934181843e5b61)
                    ],
                    "3.5-rc4" =>
                    [%w(readme.html 066cfc0f9b29ae6d491aa342ebfb1b71),
                     %w(wp-admin/css/wp-admin.css fe9ab9f3b21426b1e0a39fdea7b409e5)
                    ],
                    "3.5-beta1" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/wp-admin.css 67e4c751d9e930f1913dcd6138c4e487)
                    ],
                    "3.5-beta2" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/wp-admin.css 004eb556c35002c24ce79899bc637426)
                    ],
                    "3.5-beta3" =>
                    [%w(readme.html 34b3071c2c48f0b1a611c2ee9f1b3516),
                     %w(wp-admin/css/wp-admin.css 36a3f5a350e6043614dcec6895e5c343)
                    ],
                    "3.5.1" =>
                    [%w(readme.html 05d50a04ef19bd4b0a280362469bf22f),
                     %w(wp-admin/css/wp-admin.css 1906ac1bed40e0c5c7de71f2bc42dc20)
                    ],
                    "3.5.2" =>
                    [%w(readme.html caf7946275c3e885419b1d36b22cb5f3),
                     %w(wp-admin/css/wp-admin.css 1906ac1bed40e0c5c7de71f2bc42dc20)
                    ],
                    "3.6" =>
                    [%w(readme.html 477f1e652f31dae76a38e3559c91deb9),
                     %w(wp-admin/css/wp-admin.css 25dd20710bf1eec392a00fc892b63fde)
                    ],
                    "3.6-rc1" =>
                    [%w(readme.html de004868a26c487b9c11942b62b745f9),
                     %w(wp-admin/css/wp-admin.css 46d07df53129a23214fa5831c994c3f3)
                    ],
                    "3.6-rc2" =>
                    [%w(readme.html 477f1e652f31dae76a38e3559c91deb9),
                     %w(wp-admin/css/wp-admin.css a7d66e08b79c26f671f530a12b8f43f2)
                    ],
                    "3.6-beta1" =>
                    [%w(readme.html 1b496aaa6970179aeddd4d3d650ae509),
                     %w(wp-admin/css/wp-admin.css 08f23593ab7b2e435e7ee406caed224a)
                    ],
                    "3.6-beta2" =>
                    [%w(readme.html 1b496aaa6970179aeddd4d3d650ae509),
                     %w(wp-admin/css/wp-admin.css 4dfd9b0d52fc59f2e0151dfb20587307)
                    ],
                    "3.6-beta3" =>
                    [%w(readme.html 1b496aaa6970179aeddd4d3d650ae509),
                     %w(wp-admin/css/wp-admin.css 0aab1207839ed340da6ccfa40fb76567)
                    ],
                    "3.6-beta4" =>
                    [%w(readme.html 1b496aaa6970179aeddd4d3d650ae509),
                     %w(wp-admin/css/wp-admin.css 0bc88a7a276c4d795ea31114d38587df)
                    ],
                    "3.6.1" =>
                    [%w(readme.html e82f4fe7d3c1166afb4c00856b875f16),
                     %w(wp-admin/css/wp-admin.css 25dd20710bf1eec392a00fc892b63fde)
                    ],
                    "3.7" =>
                    [%w(readme.html 4717bf89e299ff054760ec8b0768c9e1),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd)
                    ],
                    "3.7-rc1" =>
                    [%w(readme.html 477f1e652f31dae76a38e3559c91deb9),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd)
                    ],
                    "3.7-rc2" =>
                    [%w(readme.html 477f1e652f31dae76a38e3559c91deb9),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd),
                     %w(wp-includes/js/autosave.js 8a6348b4b6ccb6fdc485912383cddb04)
                    ],
                    "3.7-beta1" =>
                    [%w(readme.html 477f1e652f31dae76a38e3559c91deb9),
                     %w(wp-admin/css/wp-admin.css befbde4c871c6b73b6b1ceaa5470f8ad)
                    ],
                    "3.7-beta2" =>
                    [%w(readme.html 477f1e652f31dae76a38e3559c91deb9),
                     %w(wp-admin/css/wp-admin.css add112698442cca52e1b76126d3de412)
                    ],
                    "3.7.1" =>
                    [%w(readme.html 4717bf89e299ff054760ec8b0768c9e1),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd),
                     %w(wp-includes/js/tinymce/plugins/wpeditimage/editor_plugin.js 02ed0a4f130b11ee395676d0e26171b8)],
                    "3.7.2" =>
                    [%w(readme.html b3a05c7a344c2f53cb6b680fd65a91e8),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd)
                    ],
                    "3.7.3" =>
                    [%w(readme.html 813e06052daa0692036e60d76d7141d3),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd)
                    ],
                    "3.7.4" =>
                    [%w(readme.html dc09e38cb48fbbec5b5f990513b491e4),
                     %w(wp-admin/css/wp-admin.css f0894fa9c9733d0e577fc5beddc726cd)
                    ],
                    "3.8" =>
                    [%w(readme.html 38ee273095b8f25b9ffd5ce5018fc4f0),
                     %w(wp-admin/css/wp-admin.css 25554fc81989c307119b7d4818dc3963)
                    ],
                    "3.8-rc1" =>
                    [%w(readme.html 38ee273095b8f25b9ffd5ce5018fc4f0),
                     %w(wp-admin/css/wp-admin.css 163718a90c74e7514375c30155a256ba)
                    ],
                    "3.8-rc2" =>
                    [%w(readme.html 38ee273095b8f25b9ffd5ce5018fc4f0),
                     %w(wp-admin/css/wp-admin.css 50f647f0777d6b395af68e346b1c2489)
                    ],
                    "3.8-beta1" =>
                    [%w(readme.html 38ee273095b8f25b9ffd5ce5018fc4f0),
                     %w(wp-admin/css/wp-admin.css a3ccf922e647e5fdea3fca506f91cdde)
                    ],
                    "3.8.1" =>
                    [%w(readme.html 0d0eb101038124a108f608d419387b92),
                     %w(wp-admin/css/wp-admin.css 68600417d5dc22244168b4eeb84f0af4)
		                ],
                    "3.8.1-rc1" =>
                    [%w(readme.html 0d0eb101038124a108f608d419387b92),
                     %w(wp-admin/css/wp-admin.css a89c1c74ad651f75dae35b5d50c1eed9)
                    ],
                    "3.8.2" =>
                    [%w(readme.html e01a2663475f6a7a8363a7c75a73fe23),
                     %w(wp-admin/css/wp-admin.css 68600417d5dc22244168b4eeb84f0af4)
		                ],
                    "3.8.3" =>
                    [%w(readme.html c6de8fc70a18be7e5c36198cd0f99a64),
                     %w(wp-admin/css/wp-admin.css 68600417d5dc22244168b4eeb84f0af4)
		                ],
                    "3.8.4" =>
                    [%w(readme.html fb73e4ab558adc3948adf2653e28d880),
                     %w(wp-admin/css/wp-admin.css 68600417d5dc22244168b4eeb84f0af4)
                    ],
                    "3.9" =>
                    [%w(readme.html cdbf9b18e3729b3553437fc4e9b6baad),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247)
		                ],
                    "3.9-rc1" =>
                    [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247)
                    ],
                    "3.9-rc2" =>
                    [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/about.css 81a0e80cc4f0ecd990badd005100efbb)
                    ],
                    "3.9-beta1" =>
                    [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/about.css dbd9c2905426f46b5dc801a60f5b373b)
                    ],
                    "3.9-beta2" =>
                    [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/common.css a10142b334006a9d416edb96abdcad0f)
                    ],
                    "3.9-beta3" =>
                    [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/admin-menu.css dd96fc841b87130e0a8bfaf04392ac28)
                    ],
                    "3.9.1" =>
                    [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/about.css 08b2f42d94424e7286e13f07c84e2613)
		                ],
                    # Use  --- diff -bur folder1 folder2
                    # Not distinguishable from 3.9.1 because the differences are in files that are probably not
                    # World readable
                    # "3.9.1-rc1" =>
                    # [%w(readme.html 84b54c54aa48ae72e633685c17e67457),
                    #  %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247)
                    # ],
                    "3.9.2" =>
                    [%w(readme.html dfb2d2be1648ee220bf9bd3c03694ed8),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247)
                    ],
                    "4.0" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247)
                    ],
                    "4.0-rc1" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/about.css ec9f0f140656d637f05fd03733fe3266)
                    ],
                    "4.0-rc2" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/forms.css a198106b212083f8421da7a3946757f4)
                    ], ##
                    "4.0-beta1" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/about.css 08b2f42d94424e7286e13f07c84e2613)
                    ],
                    "4.0-beta2" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/colors/blue/colors.css 9bd8c1728e0378655d318aa53edb07f8)
                    ],
                    "4.0-beta3" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/colors/blue/colors.css 0f7c498938809c26b33632dfa11fd2eb)
                    ],
                    "4.0-beta4" =>
                    [%w(readme.html f00855fca05f89294d0fcee6bebea64a),
                     %w(wp-admin/css/wp-admin.css ff37a40c48d23ba4ecc09d9a98da1247),
                     %w(wp-admin/css/colors/blue/colors.css 8650283df6b7aa614d9a51d49571b32f)
                    ],

    ]
    
    v = Version.new("WordPress", versions, @base_uri)
    
    version = v.matches_format
    
    # Set version if present
    unless version.empty?
        version.each { |ver|
            m << {:name => "md5 sums of files", :version => ver}
        }
    end
    
    # Return aggressive matches
    m
  end
  
end

