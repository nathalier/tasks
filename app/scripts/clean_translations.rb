require 'rexml/document'

STRINGS = {}
STRING_ARRAYS = {}
PLURALS = {}

def load(path)
  file = File.new(path)
  doc = REXML::Document.new(file)
  doc.context[:attribute_quote] = :quote
  doc
end

def get_items(elem)
  items = []
  elem.each_element('item') do |item|
    items << item.text
  end
  items
end

def get_plurals(elem)
  plurals = {}
  elem.each_element('item') do |item|
    plurals[item.attributes['quantity']] = item.text
  end
  plurals
end

def index_elements(doc)
  doc.elements['resources'].each_element('string') { |elem| STRINGS[elem.attributes['name']] = elem.text }
  doc.elements['resources'].each_element('string-array') { |elem| STRING_ARRAYS[elem.attributes['name']] = get_items(elem) }
  doc.elements['resources'].each_element('plurals') { |elem| PLURALS[elem.attributes['name']] = get_plurals(elem) }
end

def find_duplicate_plurals(doc)
  dups = []
  doc.elements['resources'].each_element('plurals') do |elem|
    string_name = elem.attributes['name']
    plurals = get_plurals(elem)
    dups << string_name if plurals.eql? PLURALS[string_name]
  end
  dups
end

def find_duplicate_string_arrays(doc)
  dups = []
  doc.elements['resources'].each_element('string-array') do |elem|
    string_name = elem.attributes['name']
    items = get_items(elem)
    dups << string_name if items.eql? STRING_ARRAYS[string_name]
  end
  dups
end

def find_duplicate_strings(doc)
  dups = []
  doc.elements['resources'].each_element('string') do |elem|
    string_name = elem.attributes['name']
    dups << string_name if elem.text.eql? STRINGS[string_name]
  end
  dups
end

def remove_items(doc, type, names)
  names.each { |name| doc.elements.delete("resources/#{type}[@name='#{name}']") }
end

def clean(path)
  doc = load(path)
  remove_items(doc, 'string', find_duplicate_strings(doc))
  remove_items(doc, 'string-array', find_duplicate_string_arrays(doc))
  remove_items(doc, 'plurals', find_duplicate_plurals(doc))
  prolog, *tail = doc.to_s.split("\n").reject { |x| x.strip.eql? "" }
  File.open(path, 'w') do |f|
    f.puts prolog
    f.puts "<!-- ************************************************************** -->"
    f.puts "<!-- ********* THIS FILE IS GENERATED BY GETLOCALIZATION ********** -->"
    f.puts "<!-- ******** http://www.getlocalization.com/tasks_android ******** -->"
    f.puts "<!-- ******************* DO NOT MODIFY MANUALLY ******************* -->"
    f.puts "<!-- ************************************************************** -->"
    f.puts "<!--suppress AndroidLintTypographyEllipsis,AndroidLintTypographyDashes-->"
    f.print tail.join("\n")
  end
end

def remove_untranslated_strings(*string_files)
  Dir.glob("src/main/res/values/strings*.xml").each { |path| index_elements(load(path)) }
  string_files.each { |path| clean path }
end

if __FILE__ == $0
  lang = ARGV[0]
  remove_untranslated_strings("src/main/res/values-#{lang}/strings.xml")
end