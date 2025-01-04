class Float
	def sign
		return -1 if self < 0
		return 1
	end
	
	def to_square_normal(bottom, top)
		((self.abs - bottom).abs ** 0.5 * ((top - bottom) ** - 0.5)) * (self - bottom).sign
	end
	
	def to_linear_normal(bottom, top)
		(self - bottom) / (top - bottom)
	end
	
	def to_triangle_normal(bottom, mid, top)
	  if self <= mid
      self.to_linear_normal(bottom, mid)
    else
      self.to_linear_normal(top, mid)
	  end
  end
	
	def to_score(bottom, top)
		if self < bottom
			return bottom
		elsif self > top
			return top
		else
			return self.round
		end
	end
end