# This file will generate a single file containing all dependencies
# needed to embed Instagram stories onto your website

js_content = File.read("web/instapipe.js")
css_content = File.read("web/instapipe.css")
html_content = File.read("web/index.html").split("<!-- Start -->").last

final_content = [html_content]
final_content << "<script type='text/javascript'>"
final_content << js_content
final_content << "</script>"
final_content << "<style type='text/css'>"
final_content << css_content
final_content << "</style>"

final_content = final_content.join("\n")
File.write("instapipe.html", final_content)
puts "Success! " + "./instapipe.html"
