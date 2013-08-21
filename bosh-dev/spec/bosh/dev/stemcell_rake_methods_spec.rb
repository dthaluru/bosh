require 'spec_helper'
require 'bosh/dev/stemcell_rake_methods'
require 'bosh/dev/stemcell_environment'

module Bosh::Dev
  describe StemcellRakeMethods do
    let(:env) { { 'FAKE' => 'ENV' } }
    let(:args) { { infrastructure: 'aws' } }

    let(:gems_generator) { instance_double('Bosh::Dev::GemsGenerator', build_gems_into_release_dir: nil) }

    let(:stemcell_builder_command) do
      instance_double('Bosh::Dev::BuildFromSpec', build: nil)
    end

    let(:stemcell_builder_options) do
      instance_double('Bosh::Dev::StemcellBuilderOptions',
                      default: { default: 'options' })
    end

    let(:stemcell_environment) do
      instance_double('Bosh::Dev::StemcellEnvironment',
                      build_path: '/fake/build_path',
                      work_path: '/fake/work_path')
    end

    subject(:stemcell_rake_methods) do
      StemcellRakeMethods.new(args: args, environment: env, stemcell_environment: stemcell_environment)
    end

    before do
      Bosh::Dev::StemcellBuilderOptions.stub(:new).with(args: args, environment: env).and_return(stemcell_builder_options)
      Bosh::Dev::GemsGenerator.stub(:new).and_return(gems_generator)
    end

    describe '#build_stemcell' do
      before do
        Bosh::Dev::StemcellBuilderCommand.stub(:new).with(env,
                                                          'stemcell-aws',
                                                          stemcell_environment.build_path,
                                                          stemcell_environment.work_path,
                                                          { default: 'options' }).and_return(stemcell_builder_command)
      end

      it "builds bosh's gems so we have the gem for the agent" do
        gems_generator.should_receive(:build_gems_into_release_dir)

        stemcell_rake_methods.build_stemcell
      end

      it 'builds a basic stemcell with the appropriate name and options' do
        stemcell_builder_command.should_receive(:build)

        stemcell_rake_methods.build_stemcell
      end
    end
  end
end
