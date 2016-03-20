#!/usr/bin/env lua

local bc='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
-- encoding
function base64_enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return bc:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function base64_dec(data)
    data = string.gsub(data, '[^'..bc..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(bc:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local mydnsip = '127.0.0.1'
local mydnsport = '1153'
local ipsetname = 'gfwlist'
-- User Define Extra Domain;
EX_DOMAIN = {".githubusercontent.com", ".google.com",".google.com.hk",".google.com.tw",".google.com.sg",".google.co.jp",".blogspot.com",".blogspot.sg",".blogspot.hk",".blogspot.jp",".gvt1.com",".gvt2.com",".gvt3.com",".1e100.net",".blogspot.tw"}

-- the url of gfwlist
local baseurl = "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
-- match comments/title/whitelist/ip address
local comment_pattern = "^[!\\[@]+"
local ip_pattern = "^%d+%.%d+%.%d+%.%d+"
local domain_pattern = "([%w%-%_]+%.[%w%.%-%_]+)[%/%*]*"
local tmpfile = "./gfwlisttmp"
-- do not write to router internal flash directly
local outfile = './dnsmasq_list.conf'

function log(text)
    print(os.date("%Y/%m/%d %H:%M:%S ") .. text)
end
function check_wget()
    local wget = "/usr/bin/wget-ssl"
    local wget = io.open(wget, "r")
    if (wget) then
        log("wget-ssl had been installed...")
        return true
    end

    log("wget-ssl require install...")
    os.execute("opkg update") 
    local isInstalled = os.execute("opkg install wget")
    if (isInstalled) then
        log("wget-ssl had been installed.")
    end

    return isInstalled
end

function fetch_gfwlist()
    --请求gfwlist
    local wget = "wget --no-check-certificate -O " .. tmpfile .. " -q " .. baseurl
    log('fetching gfwlist...')
    local isSuccess = os.execute(wget)

    if(isSuccess) then
        --解码gfwlist
        local gfwlist = io.open(tmpfile, "r")
        local decode = base64_dec(gfwlist:read("*all"))
        gfwlist:close()
        --写回gfwlist
        gfwlist = io.open(tmpfile, "w")
        gfwlist:write(decode)
        gfwlist:close()

    end

    return isSuccess;
end    

function generate_dnsmasq()
    local domains = {}
    local out = io.open(outfile, "w")
    out:write('# gfw list ipset rules for dnsmasq\n')
    out:write('# updated on ' .. os.date("%Y-%m-%d %H:%M:%S") .. '\n')
    out:write('#\n')

    
    for line in io.lines(tmpfile) do  
        --print(line)
        if(string.find(line, comment_pattern) or string.find(line, ip_pattern)) then
            print("ignored line: " .. line)
        else
            local start, finish, match = string.find(line, domain_pattern)
            if (start)  then 
                domains[match] = true   
            end    
        end    
    end

    for k,v in pairs(domains) do
        out:write(string.format("server=/.%s/%s#%s\n", k,mydnsip,mydnsport))
        out:write(string.format("ipset=/.%s/%s\n", k,ipsetname))

    end

    for i,v in ipairs(EX_DOMAIN) do
        out:write(string.format("server=/%s/%s#%s\n", v,mydnsip,mydnsport))
        out:write(string.format("ipset=/%s/%s\n", v,ipsetname))
    end

    out:close()
end

function reload_dnsmasq( )
    if(os.execute("/etc/init.d/dnsmasq reload")) then
        log("dnsmasq reload success!!!")

    else
        log("dnsmasq reload fail!!!")
    end    
end

function main(arg)

    if (not check_wget()) then
        log("wget required...")
        return
    end    
  

    if (not fetch_gfwlist()) then
        log("fetch gfwlist on fail!!!")
        return
    end    


    generate_dnsmasq()

    log("dnsmasq generated!!!")

    reload_dnsmasq()

end

main(arg)

