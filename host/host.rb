#!/usr/bin/ruby
# -*- coding: shift_jis -*-

require "socket"
require "json"
require 'sys/filesystem'

class Host

  def initialize
    @json_file_path = 'vm_memories.json'
    @home = "C:\\Users\\xx"
    @vms = @home + "\\VirtualBox VMs"
    @ctrl_ip = "192.168.1.2"
    @ova = "centos.ova"
    @port = 55555
    @adapter = "Broadcom 802.11n ネットワーク アダプタ"
    @rest_memory = 10280
    open(@json_file_path) do |io|
      @vm_memories = JSON.load(io)
    end    
  end

  def update_rest_memory
    @vm_memories.each_value do |value|
      @rest_memory -= value
    end
  end
#

#---
  #HOST_UPDATEコマンド
  def host_update()
    stat = Sys::Filesystem.stat('c:\\')
    rest_volume = (stat.blocks_free * stat.block_size).to_f / 1024 / 1024 / 1024
    rest_volume = rest_volume.to_s.scan(/^(\d+\.\d{0,3})/)[0][0].to_f
    hash_host = {}
    hash_host['function'] = "HOST_UPDATE"
    host = {}
    host['host_id'] = '2'
    host['ip_address'] = '192.168.1.3'
    host['min_cpu'] = '1'
    host['max_cpu'] = '4'
    host['min_memory'] = '768'
    host['max_memory'] = '10280'
    host['min_volume'] = '8'
    host['max_volume'] = '100'
    host['rest_memory'] = @rest_memory.to_s
    host['rest_volume'] = rest_volume.to_s
    hash_host['field'] = host
    return hash_host.to_json
  end


# クライアントからの接続を待つソケット
# 常に繰り返す

  def start_server
    p "tcpsocket open"
    begin
      sock = TCPSocket.open(@ctrl_ip, @port)
    rescue
      puts "TCPSocket.open failed : #$!\n"
    end

    m = host_update()
    p m
    sock.write(m) if sock
    sock.close if sock

    p "server open"
#  p port
    s0 = TCPServer.new('0.0.0.0', @port)

    while true
      p "wait"
      # クライアントからの接続をacceptする
      accept = s0.accept
      p "accepted"
      str = ""
      # クライアントからのデータを全て受け取る
      while buf = accept.gets
        str += buf.to_s
      end

      accept.close

      json = JSON.parser.new(str)
      hash = json.parse()

      function = hash['function']
      hash['message'] = ""
      p function

#-------------------------------------------------------------------------------
      case function
      when 'VM_CREATE' then
        Thread.start(hash) do |h|
          vm_create(h['field'])
          send_ack(h, host_update())
        end
#-------------------------------------------------------------------------------
      when 'VM_MODIFY' then
        Thread.start(hash) do |h| 
          vm_modify(h['field'])
          send_ack(h, host_update())
        end
#-------------------------------------------------------------------------------
      when 'VM_DELETE' then
        Thread.start(hash) do |h| 
          vm_delete(h['field'])
          send_ack(h, host_update())
        end
#-------------------------------------------------------------------------------
      when 'VM_STATUS' then
        Thread.start(hash) do |h| 
          vm_status(h['field'])
          send_ack(h, "")
        end
#-------------------------------------------------------------------------------
      when 'VM_START' then
        Thread.start(hash) do |h| 
	  user_id = h['field']['user_id']
	  vm_id = h['field']['vm_id']
	  vm_name = user_id + "_" + vm_id
          stdout = `VBoxManage startvm #{vm_name}`
          h['message'] = "Start VM #{vm_name}."
          send_ack(h, "")
        end

      when 'VM_STOP' then
        Thread.start(hash) do |h| 
	  user_id = h['field']['user_id']
	  vm_id = h['field']['vm_id']
	  vm_name = user_id + "_" + vm_id
          stdout = `VBoxManage controlvm #{vm_name} poweroff`
          h['message'] = "Poweroff VM #{vm_name}."
          send_ack(h, "")
        end
#-------------------------------------------------------------------------------
      else
        hash['message'] =  "unavailable function."
      end
#-------------------------------------------------------------------------------
    end

  end

  def vm_create(field)
    user_id = field['user_id']
    vm_id = field['vm_id']
    vm_name = user_id + "_" + vm_id
    cpu = field['cpu']
    mac_address = field['mac_address']
    mac_address = mac_address.gsub(":","")
    memory = field['memory']
    volume = field['volume'].to_i*1024
    vm_folder = @vms+"\\"+vm_name

    cmd = "VBoxManage import #{@home}\\#{@ova} --vsys 0 "
    cmd += "--vmname #{vm_name} "
    cmd += "--cpus #{cpu} "
    cmd += "--memory #{memory} "
    cmd += "--unit 11 --disk \"#{vm_folder}\\#{vm_name}-disk1.vdi\""
    p cmd
    stdout = `#{cmd}`
    if $?.to_i==0
      stdout += `VBoxManage modifyvm #{vm_name} --macaddress1 #{mac_address} ` 
    end
    if $?.to_i==0
      stdout += `VBoxManage modifyhd \"#{vm_folder}\\#{vm_name}-disk1.vdi\" --resize #{volume}`
    end

    @rest_memory -= memory.to_i
    `vboxmanage modifyvm #{vm_name} --nic1 bridged --bridgeadapter1 \"#{@adapter}\"`

    @vm_memories[vm_name] = memory.to_s

    open(@json_file_path,'w') do |io|
      JSON.dump(@vm_memories, io)
    end

  end

  def vm_modify(field)
    user_id = field['user_id']
    vm_id = field['vm_id']
    vm_name = user_id + "_" + vm_id
    cpu = field['cpu']
    memory = field['memory']
    volume = field['volume'].to_i*1024
    vm_folder = @vms+"\\"+vm_name
    cmd = "VBoxManage modifyvm #{vm_name} "
    cmd += "--cpus #{cpu} "
    cmd += "--memory #{memory}" 
    memory_change = memory.to_i - @vm_memories[vm_name].to_i
    @vm_memories[vm_name] = memory.to_s
    @rest_memory -= memory_change
    open(@json_file_path,'w') do |io|
      JSON.dump(@vm_memories, io)
    end
    stdout = `#{cmd}`
    if $?.to_i==0
      stdout += `VBoxManage modifyhd \"#{vm_folder}\\#{vm_name}-disk1.vdi\" --resize #{volume}`
    end
  end

  def vm_delete(field)
    user_id = field['user_id']
    vm_id = field['vm_id']
    vm_name = user_id + "_" + vm_id
    vm_folder = @vms+"\\"+vm_name
    stdout = `VBoxManage unregistervm #{vm_name} --delete`
    @rest_memory += @vm_memories[vm_name].to_i
    @vm_memories.delete(vm_name)
    open(@json_file_path,'w') do |io|
      JSON.dump(@vm_memories, io)
    end
  end

  def vm_status(field)
    user_id = field['user_id']
    out = `VBoxManage list runningvms`
    field['vms'].each do |vm|
      vm_name = field['user_id'] + "_" + vm['vm_id']
      n = out.index("\"#{vm_name}\"")
      if n
        vm['status'] = "running"
      else
        vm['status'] = "standby" 
      end 
    end
  end


  def send_ack(hash, message)
    p "hash remake"
    hash['function'] += '_ACK'
    if $?.to_i == 0
      hash['field']['status'] = 'OK'
    else
      hash['field']['status'] = 'NG'
    end

    p hash
    p "tcpsocket open"
    begin
      sock = TCPSocket.open(@ctrl_ip, @port)
    rescue
      puts "TCPSocket.open failed : #$!\n"
    end
    result = hash.to_json 
    p result
    sock.write(result)
    sock.close

    if message != ""
      begin
        sock = TCPSocket.open(@ctrl_ip, @port)
      rescue
        puts "TCPSocket.open failed : #$!\n"
      end
      p message
      sock.write(message)
      sock.close
    end
  end

end

server = Host.new
server.start_server


