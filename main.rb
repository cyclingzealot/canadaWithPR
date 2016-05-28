#!/usr/bin/ruby -w

require 'nokogiri'
require 'open-uri'


start = Time.now

doc = Nokogiri::HTML(open("https://www.sfu.ca/~aheard/elections/1867-present.html"))

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
        data[year] = {}
    elsif firstCell.attr("bgcolor").nil? && firstCell.attr("colspan").nil?
        party = firstCell.text.strip
        data[year][party] = {}

        seats = r.xpath("./#{cellElem}")[1].text.strip.to_i
        votePct = /[0-9]{2}.[0-9]/.match(r.xpath("./#{cellElem}")[3].text.strip).to_s.to_f

        data[year][party]['seats'] = seats
        data[year][party]['votePct'] = votePct

        #$stderr.puts "Found for #{year}, #{party}, #{seats} seats, #{votePct} % vote"
    end

}

### Begin calculations here!!!!!!

# For each year
## Calculate the total number of seats
## Calculate seats for each party under PR
## Calculate difference

data.each_with_index { |yd,y|
    totalSeats = 0
    data[y].each_with_index { |pd,p|
        puts pd.class.name
        puts p.class.name
        totalSeats += pd['seats'].to_i
    }

    y.each_with_index { |pd,p|
        pd['seatsUnderPR'] = (totalSeats * p['votePct']/100).round
        pd['seatGain'] = p['seastsUnderPR'] - p['seats']
    }
}

done = Time.now

elapsed = (done - start)

$stderr.puts "Time elapsed: #{elapsed} seconds"

