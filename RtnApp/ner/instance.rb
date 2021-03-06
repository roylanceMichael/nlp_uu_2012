class Instance
  attr_accessor :context, :np, :tclass
  
  def npSplit
    if @np != nil
      return @np.split(/\s+/)
    end
    return []
  end
  
  def contextSplit
    if @context != nil
      return @context.split(/\s+/)
    end
    return []
  end
  
  def printSelf
    "np: #{@np}, context: #{@context}, tclass: #{@tclass}"
  end
  
  def self.if(fileLocation)
    str = (File.new fileLocation).read
    result = Instance.factory str
    result
  end
  
  def self.factory(content)
    splitContent = content.lstrip.rstrip.split /\n/
    
    instances = []
    tempInstance = Instance.new
    
    splitContent.each do |c|
      c = c.gsub(/\s+/, " ")
      if tempInstance.context == nil && c != nil && c.length > 8
        temp = c.slice(8, c.length - 8).lstrip.rstrip
        tempInstance.context = temp 
      elsif c != nil && c.length > 3
        temp = c.slice(3, c.length - 3).lstrip.rstrip
        tempInstance.np = temp
        instances.push tempInstance
        tempInstance = Instance.new
      end
    end
    
    instances
  end
end