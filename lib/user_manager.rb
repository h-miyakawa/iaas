require 'json_api'
require 'slice'

class UserManager

  def self.create(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['field']['user_id']])
    Slice.create(user['user_id'])
    user['fw_rule'] = []
    user['vms'] = []
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  def self.delete(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(data, ['users','user_id',request['field']['user_id'])
    Slice.destroy(user['user_id'])
    users.delete(user)
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

end
