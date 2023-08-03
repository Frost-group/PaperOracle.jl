module PaperOracle

# Write your package code here.

end
using HTTP
using JSON
using ExprTools
using REPL

prompt_template = raw"""
Q: QUESTION

Tools available:
TOOLS

Observation: 
"""

merge_template = raw"""
Q: QUESTION

Previous conversation:
HISTORY
  
Observation:
"""

function google_search(question)
  resp = HTTP.get("https://serpapi.com/search", query=Dict("api_key" => ENV["SERPAPI_API_KEY"], "q" => question))
  data = JSON.parse(String(resp.body))
  
  # try to extract answer from response
  get(data, "answer_box", Dict())["answer"] |>
  get(data, "answer_box", Dict())["snippet"] |>
  get(data, "organic_results", [])[1]["snippet"]
end

tools = Dict("search" => Dict("description" => "a search engine. useful for when you need to answer questions about current events. input should be a search query.",
                              "execute" => google_search),
             "calculator" => Dict("description" => "Useful for getting the result of a math expression. The input to this tool should be a valid mathematical expression that could be executed by a simple calculator.",
                                  "execute" => x -> eval(Meta.parse(x)) |> string))

function complete_prompt(prompt)
  println("Speaking to Orac...")
  resp = HTTP.post("https://api.openai.com/v1/completions"; 
                 headers = Dict("Content-Type" => "application/json",
                               "Authorization" => "Bearer $(ENV["OPENAI_API_KEY"])"),
                 body = JSON.json(Dict("model" => "text-davinci-003",
                                       "prompt" => prompt,
                                       "max_tokens" => 256,
                                       "temperature" => 0.7,
                                       "stream" => false,
                                       "stop" => ["Observation:"])))

  data = JSON.parse(String(resp.body))
  printstyled(prompt, color=:light_red)
  printstyled(data["choices"][1]["text"], color=:light_green)
  
  return data["choices"][1]["text"]
end  

function answer_question(question)
  prompt = replace(prompt_template, "QUESTION" => question , "TOOLS" => tools)
  
  while true
    response = complete_prompt(prompt)
    prompt *= response

    action = match(r"Action: (.*)", response) |> x -> x[1]
    if action ≢ nothing
      action_input = match(r"Action Input: \"?(.*)\"?", response) |> x -> x[1]
      result = tools[action]["execute"](action_input)
      prompt *= "Observation: $result\n"
    else
      return match(r"Final Answer: (.*)", response) |> x -> x[1]
    end
  end
end

function merge_history(question, history)
  prompt = replace(merge_template, "QUESTION" => question, "HISTORY" => history)
  complete_prompt(prompt)
end

function replloop()
  history = ""
  while true
    print("How can I help? ")
    question = readline()
    if length(history) > 0
      question = merge_history(question, history)
    end
  
    answer = answer_question(question)
    println(answer)
  
    history *= "Q: $question\nA: $answer\n"
  end
end

replloop()
