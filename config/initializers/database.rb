class Database
  # gateway = Net::SSH::Gateway.new('ekomehf2.beget.tech', 'ekomehf2')
  #
  # port = gateway.open('127.0.0.1', 3306, 3307)
  #
  @@db = Mysql2::Client.new(
    host: "ekomehf2.beget.tech",
    username: 'ekomehf2_wpshop',
    password: 'xPi6*oZD',
    database: 'ekomehf2_wpshop',
    port: 3306,
    reconnect: true
  )

  class << self
    def method_missing(method_name, *args)
      if args.last.class == Hash
        result = @@db.send(method_name, *args[0..-2], **args.last)
      else
        result = @@db.send(method_name, *args)
      end

      result.to_a
    end
  end

end