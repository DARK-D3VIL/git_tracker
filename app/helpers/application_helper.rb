module ApplicationHelper
  def performance_color(score)
    if score == 0 || score == 100
      return "black"
    elsif score > 75
      return "green"
    elsif score > 50
      return "goldenrod"
    elsif score > 25
      return "orange"
    else
      return "red"
    end
  end
end
