module KLUtils
  def medianDate(array)
    sorted = array.sort
    len = sorted.length
    return [sorted[(len - 1) / 2], sorted[len / 2]].min
  end

  def toDate(strDate)
    Date.strptime strDate, '%m/%d/%Y'
  end
end