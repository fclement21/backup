# encoding: utf-8

module Backup
  module Syncer
    module Cloud
      class OpenStack < Base

        ##
        # OpenStack redentials
        attr_accessor :api_key, :username, :region

        ##
        # OpenStack container
        attr_accessor :container

        ##
        # OpenStack AuthURL allows you to connect to a different datacenter
        attr_accessor :auth_url

        ##
        # Instantiates a new Cloud::OpenStack Syncer.
        #
        # Pre-configured defaults specified in
        # Configuration::Syncer::Cloud::OpenStack
        # are set via a super() call to Cloud::Base,
        # which in turn will invoke Syncer::Base.
        #
        # Once pre-configured defaults and Cloud specific defaults are set,
        # the block from the user's configuration file is evaluated.
        def initialize(&block)
          super

          instance_eval(&block) if block_given?
          @path = path.sub(/^\//, '')
          @region ||= nil
        end

        protected

        ##
        # Established and creates a new Fog storage object for CloudFiles.
        def connection
          @connection ||= Fog::Storage.new(
            :provider             => provider,
            :openstack_username   => username,
            :openstack_api_key    => api_key,
            :openstack_auth_url   => auth_url,
            :openstack_region     => region
          )
        end

        ##
        # Creates a new @repository_object (container).
        # Fetches it if it already exists,
        # otherwise it will create it first and fetch use that instead.
        def repository_object
          @repository_object ||= connection.directories.get(container) ||
            connection.directories.create(:key => container)
        end

        ##
        # This is the provider that Fog uses
        def provider
          "OpenStack"
        end

      end # class Cloudfiles < Base
    end # module Cloud
  end
end
