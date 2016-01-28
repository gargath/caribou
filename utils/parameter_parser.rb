require 'optparse'
require_relative './keyvalparse'
require_relative './aws_helper'
require 'aws-sdk'

module AwsParser

  #Set Defaults
  COMMANDS = {'list' => "List all AWS regions available with the credentials provided",
              'getsgid' => "Get the ID of the default AWS Security Group Caribou will use",
              'deploy_master' => "Deploy the Caribou Master Node",
              'master_status' => "Get the status of the currently deployed Caribou Master Node",
              'shutdown' => "Shutdown the Caribou Cluster"
              }
  @options =  {:awsregion => "us-east-1"}
  
  def self.parse(args)

    #Setup option parser
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} <command> [options]"
      opts.separator ""
      opts.separator "Command can be one of:"
      COMMANDS.each {|key, value| opts.separator "#{key.ljust(10)} - #{value}"}
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on("-a", "--awskeyid ID", "The AWS key ID to use") do |id|
        @options[:awskey_id] = id
      end
      
      opts.on("-r", "--region REGION", "The AWS region to use") do |region|
        @options[:awsregion] = region
      end

      opts.on("-k", "--keypair-name NAME", "The key pair name to use for master node") do |key|
        @options[:key_name] = key
      end
      
      opts.on("-i", "-master-instance-type TYPE") do |type|
        @options[:master_instance_type] = type
      end

      opts.on("-t", "--master-image-id ID") do |id|
        @options[:master_image_id] = id
      end
      
      opts.on("-s", "--security-group-name GROUPNAME", "The AWS EC2 Security Group name to use") do |name|
        @options[:securitygroup_name] = name
      end
      
      opts.on_tail("-f", "--cfgfile FILE", "Load configuration from FILE") do |configfile|
        fileconfig = KeyValueParser.parseFile(configfile)
        @options = fileconfig.merge!(@options)
      end
      
      opts.on_tail("-v", "--verbose", "Show verbose logging") do |v|
        @options[:verbose] = v
      end
      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      opts.on_tail("--version", "Show version information") do
        File.open(File.expand_path("./VERSION", File.dirname(__FILE__)), "r") do |vfile|
          puts ("Caribou version: #{vfile.read}")
          puts
          exit
        end
        exit
      end
    end.parse!(args)
    
    #Verify parsed options
    if !@options.has_key?(:awskey_id)
        raise OptionParser::MissingArgument.new("AWS Key ID is required.")
    elsif !@options.has_key?(:awskey)
      print "Please enter AWS secret key: "
      @options[:awskey] = gets.chomp
    end
    
    unless @options[:awsregion] == 'us-east-1'
      puts "Validating specified AWS region"
      helper = AwsHelper.new({
        key: @options[:awskey_id],
        secret: @options[:awskey]
      })
      raise OptionParser::ParseError.new("Region #{@options[:awsregion]} is not a valid AWS region.") unless helper.verifyAwsRegion(@options[:awsregion])
    end
    
    @options
  end
  
end