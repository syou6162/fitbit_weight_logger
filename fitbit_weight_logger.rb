require "json"

def parse_date line_
  # June 9, 2014 at 8:01AM
  line = JSON.parse(line_)["title"]["$t"]
  str2month = {"January" => "01",
               "February" => "02",
               "March" => "03",
               "April" => "04",
               "May" => "05",
               "June" => "06",
               "July" => "07",
               "August" => "08",
               "September" => "09",
               "October" => "10",
               "November" => "11",
               "December" => "12"}
  date1, date2 = line.split(", ")
  month, day = date1.split(" ")
  year, _, rest = date2.split(" ")
  is_am = rest.reverse[0, 2] == "MA" # Equals to AM?
  hour_tmp = rest.split(":")[0]
  hour = if is_am
           if hour_tmp == 12
             0
           else
             hour_tmp
           end
         else
           if hour_tmp == 12
             12
           else
             hour_tmp.to_i + 12
           end
         end.to_s.rjust(2, '0')
  minute = rest.split(":")[1][0, 2]
  "#{year}-#{str2month[month]}-#{day.to_s.rjust(2, '0')} #{hour}:#{minute}:00 +0900"
end

def get_weight line
  JSON.parse(line)["content"]["$t"].split(",")[0].split(": ")[1].to_f
end

def get_bmi line
  JSON.parse(line)["content"]["$t"].split(",")[2].split(": ")[1].to_f
end

index = "fitbit_weight"
type = "log"
`curl -XDELETE http://localhost:9876/#{index}`

`curl -XPUT localhost:9876/#{index} -d '{
  "mappings": {
    "#{type}": {
      "properties": {
        "time": { "type": "date", "format": "yyyy-MM-dd HH:mm:ss Z" }
      }
    }
  }
}'`

STDIN.each{|line|
  result = {}
  date = parse_date line
  result["time"] = date
  result["weight"] = get_weight line
  result["bmi"] = get_bmi line
  puts "{ \"index\" : { \"_index\" : \"#{index}\", \"_type\" : \"#{type}\", \"_id\" : \"#{date}\" } }"
  puts result.to_json
}
