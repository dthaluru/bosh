require 'spec_helper'

describe 'Photon 1 OS image', os_image: true do
  it_behaves_like 'every OS image'
  it_behaves_like 'a systemd-based OS image'
  it_behaves_like 'a Linux kernel 3.x based OS image'

  context 'installed by base_rhel' do
        describe file('/etc/photon-release') do
      it { should be_file }
    end

    describe file('/etc/locale.conf') do
      it { should be_file }
      it { should contain 'en_US.UTF-8' }
    end

    %w(
      yum
      photon-release
    ).each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  context 'installed by base_photon_packages' do
    %w(
      curl
      e2fsprogs
      glibc
      openssh
      openssl
      rpm
      sudo
      systemd
      unzip
      wget
      linux
    ).each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  context 'installed by system_grub' do
    describe package('grub') do
      it { should be_installed }
    end
  end
end
