class String
	def starts_with?(str)
		return false if self.length < str.length
		return self[0..str.length - 1] == str
	end
	
	def ends_with?(str)
		return false if self.length < str.length
		return self[str.length.. - 1] == str
	end
	
	def collapse
		return self.strip unless self.include?('  ')
		return self.gsub('  ', ' ').collapse
	end
end