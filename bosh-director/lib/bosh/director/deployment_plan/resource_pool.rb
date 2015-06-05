# Copyright (c) 2009-2012 VMware, Inc.

module Bosh::Director
  module DeploymentPlan
    class ResourcePool
      include ValidationHelper

      # @return [String] Resource pool name
      attr_reader :name

      # @return [DeploymentPlan] Deployment plan
      attr_reader :deployment_plan

      # @return [DeploymentPlan::Stemcell] Stemcell spec
      attr_reader :stemcell

      # @return [DeploymentPlan::Network] Network spec
      attr_reader :network

      # @return [Hash] Cloud properties
      attr_reader :cloud_properties

      # @return [Hash] Resource pool environment
      attr_reader :env

      # @return [Array<DeploymentPlan::IdleVm] List of allocated VMs
      attr_reader :allocated_vms

      # @return [Integer] Number of VMs reserved
      attr_reader :reserved_capacity

      # @param [DeploymentPlan] deployment_plan Deployment plan
      # @param [Hash] spec Raw resource pool spec from the deployment manifest
      # @param [Logger] logger Director logger
      def initialize(deployment_plan, spec, logger)
        @deployment_plan = deployment_plan

        @logger = logger

        @name = safe_property(spec, "name", class: String)

        @cloud_properties =
          safe_property(spec, "cloud_properties", class: Hash, default: {})

        stemcell_spec = safe_property(spec, "stemcell", class: Hash)
        @stemcell = Stemcell.new(self, stemcell_spec)

        network_name = safe_property(spec, "network", class: String)
        @network = @deployment_plan.network(network_name)

        if @network.nil?
          raise ResourcePoolUnknownNetwork,
                "Resource pool `#{@name}' references " +
                "an unknown network `#{network_name}'"
        end

        @env = safe_property(spec, "env", class: Hash, default: {})

        @allocated_vms = []
        @reserved_capacity = 0
        @reserved_errand_capacity = 0
      end

      def vms
        @allocated_vms
      end

      # Returns resource pools spec as Hash (usually for agent to serialize)
      # @return [Hash] Resource pool spec
      def spec
        {
          "name" => @name,
          "cloud_properties" => @cloud_properties,
          "stemcell" => @stemcell.spec
        }
      end

      # Attempts to allocate a dynamic IP addresses for all VMs
      # (unless they already have one).
      def reserve_dynamic_networks
        vms.each do |vm|
          unless vm.has_network_reservation?
            instance = vm.bound_instance
            origin = instance ? "Job instance `#{instance}' in resource pool `#{@name}'" : nil
            vm.network_reservation = reserve_dynamic_network(origin)
          end
        end
      end

      # Tries to obtain one dynamic reservation in its own network
      # @raise [NetworkReservationError]
      # @return [NetworkReservation] Obtained reservation
      def reserve_dynamic_network(origin="Resource pool `#{@name}'")
        reservation = NetworkReservation.new_dynamic
        @network.reserve!(reservation, origin)
        reservation
      end

      def allocate_vm
        vm = Vm.new(self)
        register_allocated_vm(vm)
      end

      def add_allocated_vm
        register_allocated_vm(Vm.new(self))
      end

      def deallocate_vm(vm_cid)
        deallocated_vm = @allocated_vms.find { |vm| vm.model.cid == vm_cid }
        if deallocated_vm.nil?
          raise DirectorError, "Resource pool `#{@name}' does not contain an allocated VM with the cid `#{vm_cid}'"
        end

        @logger.info("ResourcePool `#{name}' - Deallocating VM: #{deallocated_vm.model.cid}")
        @allocated_vms.delete(deallocated_vm)

        deallocated_vm.release_reservation

        nil
      end

      # Checks if there is enough capacity to run _extra_ N VMs,
      # raise error if not enough capacity
      # @raise [ResourcePoolNotEnoughCapacity]
      # @return [void]
      def reserve_capacity(n)
        @reserved_capacity += n
      end

      # Checks if there is enough capacity to run _up to_ N VMs,
      # raise error if not enough capacity.
      # Only enough capacity to run the largest errand is required,
      # because errands can only run one at a time.
      # @raise [ResourcePoolNotEnoughCapacity]
      # @return [void]
      def reserve_errand_capacity(n)
        needed = n - @reserved_errand_capacity

        if needed > 0
          reserve_capacity(needed)
          @reserved_errand_capacity = n
        end
      end

      private
      # Adds an existing VM to allocated_vms
      def register_allocated_vm(vm)
        @logger.info("ResourcePool `#{name}' - Adding allocated VM (index=#{@allocated_vms.size})")
        @allocated_vms << vm
        vm
      end
    end
  end
end
