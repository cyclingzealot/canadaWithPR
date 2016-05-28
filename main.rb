#!/usr/bin/ruby -w

require 'nokogiri'
require 'open-uri'
require 'pp'
require 'set'


start = Time.now

url = "https://www.sfu.ca/~aheard/elections/1867-present.html"
doc = Nokogiri::HTML(open(url))

rows = doc.xpath('//*[@id="table6"]//tr')

data = {}
rowCount = 0
year = 10000
rows.each { |r|
    if year < 1945
        next
    end

    rowCount += 1
    cellElem = 'td'
    if r.xpath('./td').count == 0
        if r.xpath('./th').count > 0
            cellElem = 'th'
        else
            $stderr.puts("No td or th cells for row #{rowCount}")
            exit 1
        end
    end

    firstCell = r.xpath("./#{cellElem}").first
    if firstCell.attr("bgcolor") == "#99ccff"
        year = /[0-9]{4}/.match(r.xpath("./#{cellElem}").first.text).to_s.to_i
        data.merge!(year => {})
    elsif firstCell.attr("bgcolor").nil? && firstCell.attr("colspan").nil?
        party = /[a-z\.éA-Z ]*/.match(firstCell.text.strip).to_s

        seats = r.xpath("./#{cellElem}")[1].text.strip.to_i
        votePct = /[0-9]+.[0-9]/.match(r.xpath("./#{cellElem}")[3].text.strip).to_s.to_f

        data[year].merge!({party.strip => {'seats' => seats, 'votePct' => votePct}})

        #$stderr.puts "Found for #{year}, #{party}, #{seats} seats, #{votePct} % vote"
    end


}

### Begin calculations here!!!!!!

# For each year
## Calculate the total number of seats
## Calculate seats for each party under PR
## Calculate difference

partySet = SortedSet.new
data.each { |y,yd|
    totalSeats = 0
    yd.each { |p,pd|
        totalSeats += pd['seats'].to_i
    }

    yd.each { |p,pd|
        pd['seatsUnderPR'] = (totalSeats * pd['votePct']/100).round
        pd['seatGain'] = pd['seatsUnderPR'] - pd['seats']
        partySet.add(p.strip)
    }
}

printf "\t"
partySet.each { |p|
    printf "%s\t", p
}
printf "\n"


data.each { |y,yd|
    printf "%d\t", y
    partySet.each { |p|
        printf "%s\t", yd[p].nil? ? "" : yd[p]['seatGain']
    }

    printf "\n"

}
#pp partySet

puts url

done = Time.now

elapsed = (done - start)

$stderr.puts "Time elapsed: #{elapsed} seconds"

