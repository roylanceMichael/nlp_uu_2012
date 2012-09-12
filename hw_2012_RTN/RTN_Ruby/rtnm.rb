require './rule.rb'
class Rtnm
	attr_accessor :machinename, :init, :final, :rules
	
	#sm is used to access the sentence
	#dict is a static dictionary
	#chart is used to keep a history of what we've tried
	#altpaths is used to keep track of alternate paths
	def as(sm, dict, index)
		#start at beginning
		puts "processing #{@machinename} at #{sm.windex index}"
		#get all start states for current machine
		rulesToTry = []
		@rules.select{|t| t.start == @init}.each do |r|
			tr = RuleTuple.new
			tr.rule = r
			tr.index = index
			rulesToTry.push tr
		end
		
		success = []
		
		puts "found #{rulesToTry.length} rules to try"
		
		while rulesToTry.length > 0
			cr = rulesToTry.delete_at 0
			word = sm.windex cr.index
			if word == nil
				next
			end
			
			result = cr.rule.ar sm, dict, cr.index
			if result.class == TrueClass
				puts "PROCESSED #{cr.rule.start} - #{cr.rule.arcname} (#{sm.windex cr.index}) - #{cr.rule.end} was success"
				puts "                   "
				
				newCr = RuleTuple.new
				newCr.rule = cr.rule
				newCr.index = cr.index
				newCr.prev = cr.prev
				
				if final.any? {|t| t == cr.rule.end}
					#puts "found some end rules! #{cr.rule.start} - #{cr.rule.end} #{cr.index}"
					tr = RuleTuple.new
					tr.rule = newCr.rule
					tr.index = newCr.index
					tr.prev = newCr.prev
					puts "-------------------#{newCr.index}-----------pushing " 
					tr.history sm
					puts "             "
					success.push tr.copy
				else
					puts "             "
					puts "printing CR-History"
					newCr.history sm
					puts "             "
				end
				
				@rules.select{|t| t.start == cr.rule.end}.each do |rule|
					tr = RuleTuple.new
					tr.rule = rule
					tr.index = newCr.index + 1
					tr.prev = newCr
					rulesToTry.push tr.copy
				end
			#number if the rule was successful
			#what to return if multiple rules were successful?
			elsif result != nil && result.length > 0
				puts "PROCESSED #{cr.rule.start} - #{cr.rule.arcname} (#{sm.windex cr.index}) - #{cr.rule.end} was #{result.length > 0 ? 'success' : 'failure'} with #{result.length}"
				puts "                   "
				result.each do |nrnh|
					newCr = RuleTuple.new
					newCr.rule = cr.rule
					newCr.index = cr.index
					newCr.prev = cr.prev
					nrnh.root.prev = newCr
					
					if final.any? {|t| t == cr.rule.end}
						#puts "found some end rules! #{cr.rule.start} - #{cr.rule.end} #{cr.index}"
						tr = RuleTuple.new
						tr.rule = nrnh.rule
						tr.index = nrnh.index
						tr.prev = nrnh.prev
						puts "-------------------#{nrnh.index}-----------pushing " 
						tr.history sm
						puts "             "
						success.push tr
					else
						puts "             "
						puts "printing CR-History MULTI"
						#newCr.history sm
						#puts "YO"
						nrnh.history sm
						puts "             "
					end
					
					@rules.select{|t| t.start == cr.rule.end}.each do |rule|
						tr = RuleTuple.new
						tr.rule = rule
						tr.index = nrnh.index + 1
						tr.prev = nrnh
						rulesToTry.push tr
					end
				end
			else
				#puts "THROWN AWAY #{cr.rule.start} - #{cr.rule.arcname} (#{sm.windex cr.index}) - #{cr.rule.end} was #{result.length > 0 ? 'success' : 'failure'} with #{result.length}"
				#puts "                 "
			end
		end
		puts "exiting #{machinename} with #{success.length}"
		
		success.each do |t| 
			puts "---------------------------------------------"
			t.history sm
			puts "---------------------------------------------"
		end
		
		success
	end
	
	def applySentence(sm, dict)
		#we are assuming we're at the beginning now
		#we're also assuming there's one path
		
		if sm.word == nil
			return nil
		end
		
		rulesToTry = rules.select{|t| t.start == @init}.each{|t| t.sm = sm.copy}
		
		successfulRules = []
		
		while rulesToTry.length > 0
			currentRule = rulesToTry.delete_at 0
			
			if currentRule.sm.word == nil
				next
			end
			
			#pretty sure I need to do more here...
			result = currentRule.applyRule sm, dict
			
			if result != nil
				if final.any? {|t| t == currentRule.end}
					puts result.length
					result.each {|sentenceModel| successfulRules.push sentenceModel}
				end
				#add more rules, if we can
				result.each do |sentenceModel|
					moreRules = rules.select{|t| t.start == currentRule.end}
					
					moreRules.each do |rule|
						newRule = rule.copy
						newRule.sm = sm.copy
						rulesToTry.push newRule
					end
				end
			end
		end
		
		puts "ended #{@machinename} with #{successfulRules.length} rules"
		successfulRules.each do |anotherSm|
			puts "       "
			puts "-------"
			puts anotherSm
			anotherSm.printhistory
			puts "-------"
			puts "       "
		end
		
		successfulRules
	end
	
	def self.factory(filePath)
		rawFile = File.new(filePath)
		content = rawFile.read
		propertyRegex = /MACHINE\s+([a-zA-Z0-9]+?)\s+INIT\s+([a-zA-Z0-9]+?)\s+FINAL\s+([a-zA-Z0-9\s]+?)\s+BEGIN([A-Za-z0-9\s]+?)END\s*/
		machines = []
		
		match = propertyRegex.match(content)
		while(match != nil)
			#puts "match: #{match}"
			#puts "post match: #{match.post_match}"
			
			rtnm = Rtnm.new
			rtnm.machinename = match[1]
			rtnm.init = match[2]
			rtnm.final = match[3].strip.split(/\s/)
			rtnm.rules = Rule.factory match[4], rtnm
			
			machines.push rtnm
			match = propertyRegex.match match.post_match
		end
		machines
	end
end