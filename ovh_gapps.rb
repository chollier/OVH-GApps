#!/usr/bin/ruby
require 'soap/wsdlDriver'

class GApps

  def initialize(login, password, domain)
    @domain = domain

    #ovh stuff
    wsdl = 'https://www.ovh.com/soapi/soapi-re-1.9.wsdl'
    @soapi = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

    #login
    @session = @soapi.login(login, password, 'fr', false)
    puts "login successfull"
  end

  def getMXs
    result = @soapi.zoneEntryList(@session, @domain)
    puts "zoneEntryList successfull"

    #Les anciens MX que l'on va DEL
    proutMX = []

    result.each do |x|
      if x.fieldtype =~ /MX.*/
        puts "#{x.fieldtype} : #{x.target}"
        proutMX.push(x)
      end
    end

    return proutMX

  end

  def delAllMXs
    self.getMXs.each do |x|
      @soapi.zoneEntryDel(@session, @domain, x.subdomain, x.fieldtype, x.target)
      puts "#{x.fieldtype} #{x.target} effacé"
    end
  end

  def addGoogleMXs
    gappsdomains = [
      {:target => "ASPMX.L.GOOGLE.COM", :priority => 10},
      {:target => "ALT1.ASPMX.L.GOOGLE.COM", :priority => 20},
      {:target => "ALT2.ASPMX.L.GOOGLE.COM", :priority => 20},
      {:target => "ASPMX2.GOOGLEMAIL.COM", :priority => 30},
      {:target => "ASPMX3.GOOGLEMAIL.COM", :priority => 30},
      {:target => "ASPMX4.GOOGLEMAIL.COM", :priority => 30},
      {:target => "ASPMX5.GOOGLEMAIL.COM", :priority => 30}
    ]
    gappsdomains.each do |x|
      begin 
        @soapi.zoneEntryAddCustom(@session, @domain, 'MX', 'CUSTOM', '', '', x[:priority], x[:target], '')
        puts "#{x[:target]} created"
      rescue
        puts "/!\ #{x[:target]} NOT created"
      end
    end
  end
  
  def addAppsRecord
    apps = ['docs', 'agenda', 'mail']
    apps.each do |x|
      @soapi.zoneEntryAddCustom(@session, @domain, 'CNAME', 'CUSTOM', '', x, '', 'ghs.google.com', '')
      puts "#{x}.#{@domain} created"
    end
  end

end

if ARGV.length == 3

  if ARGV[0] =~ /[a-zA-Z]{2}[0-9]{4}-ovh/
    $login = ARGV[0]
  end

  $password = ARGV[1] 

  if ARGV[2] =~ /.*\..*/
    $domain = ARGV[2]
  end

  #you can use it like that :
   prout = GApps.new($login, $password, $domain)
  # prout.getMXs
   prout.delAllMXs
   prout.addGoogleMXs
   prout.addAppsRecord

else
  puts "USAGE : ./ovh_gapps.rb [login] [password] [domain]"
end
