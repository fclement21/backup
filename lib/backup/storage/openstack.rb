# encoding: utf-8
require 'fog'
##
# Only load the Fog gem when the Backup::Storage::OpenStack class is loaded
# Backup::Dependency.load('fog')

module Backup
  module Storage
    class OpenStack < Base

      ##
      # OpenStack credentials
      attr_accessor :username, :api_key, :auth_url, :region, :tenant_id, :tenant

      ##
      # OpenStack storage container name and path
      attr_accessor :container, :path, :keep

      ##
      # Creates a new instance of the storage object
      def initialize(model, storage_id = nil, &block)
        super(model, storage_id)

        @path       ||= 'backups'
        @region     ||= nil

        instance_eval(&block) if block_given?
      end

      protected

      ##
      # This is the provider that Fog uses
      def provider
        'OpenStack'
      end
      ##
      # Establishes a connection
      def connection
        @connection ||= Fog::Storage.new(
          :provider             => provider,
          :openstack_username   => username,
          :openstack_api_key    => api_key,
          :openstack_tenant_id  => tenant_id,
          :openstack_tenant     => tenant,
          :openstack_auth_url   => auth_url,
          :openstack_region     => region,
          :connection_options       => {ssl_verify_peer: false }
        )
      end

      ##
      # Transfers the archived file to the specified container
      def transfer!
        remote_path = remote_path_for(@package)
        local_path = Config.tmp_path
        @package.filenames.each do |local_file, remote_file|
          Logger.info "#{storage_name} started transferring '#{ local_file }'."
          connection.directories.get("#{container}").files.create :key => "#{Time.now.strftime("%Y.%m.%d")}_#{local_file}", :body => File.open(File.join(local_path, local_file))
          # connection.directories.get("#{container}").files.create :key => "#{Time.now}_#{local_file}", :body => File.open(File.join(local_path, local_file))
        end
        if connection.directories.get("#{container}").count.to_i > keep
          Logger.info "Remove first #{connection.directories.get("#{container}").files.first.key}"
          connection.directories.get("#{container}").files.first.destroy
        end
      end

      ##
      # Removes the transferred archive file(s) from the storage location.
      # Any error raised will be rescued during Cycling
      # and a warning will be logged, containing the error message.
      def remove!(package)
        remote_path = remote_path_for(package)

        package.filenames.each do |local_file, remote_file|
          Logger.info "#{storage_name} started removing '#{ local_file }' " +
              "from container '#{ container }'."
          # connection.delete_object(container, File.join(remote_path, remote_file))
          connection.directories.get("#{container}").files.get(remote_file).destroy
        end
      end

    end
  end
end
