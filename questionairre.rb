require "pstore"

STORE_NAME = "tendable.pstore"
QUESTIONS = {
  "q1" => "Can you code in Ruby?",
  "q2" => "Can you code in JavaScript?",
  "q3" => "Can you code in Swift?",
  "q4" => "Can you code in Java?",
  "q5" => "Can you code in C#?"
}.freeze

def do_prompt(store)
  answers = {}
  QUESTIONS.each do |key, question|
    print "#{question} (Yes/No): "
    ans = gets.chomp.downcase
    until ["yes", "no", "y", "n"].include?(ans)
      print "Please enter 'Yes' or 'No': "
      ans = gets.chomp.downcase
    end
    answers[key] = ans
  end

  store.transaction do
    store[:answers] ||= []
    store[:answers] << answers
  end
end

def calculate_rating(answers)
  total_questions = QUESTIONS.size
  yes_count = answers.count { |_, ans| ["yes", "y"].include?(ans) }
  rating = (yes_count.to_f / total_questions) * 100
  rating.round(2)
end

def do_report(store)
  total_ratings = store.transaction(true) { store[:answers] }
  return if total_ratings.nil? || total_ratings.empty?

  total_runs = total_ratings.size
  sum_ratings = total_ratings.sum { |answers| calculate_rating(answers) }
  average_rating = sum_ratings / total_runs

  current_run_answers = total_ratings.last
  current_run_rating = calculate_rating(current_run_answers)

  puts "\nCurrent Run Rating: #{current_run_rating}%"
  puts "Average Rating: #{average_rating.round(2)}%"
end

store = PStore.new(STORE_NAME)
store.transaction { store[:answers] ||= [] }

begin
  loop do
    do_prompt(store)
    do_report(store)

    print "\nDo you want to run the survey again? (Yes/No): "
    run_again = gets.chomp.downcase
    break unless ["yes", "y"].include?(run_again)
  end
end
