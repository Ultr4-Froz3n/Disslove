do

  local function check_member(extra, success, result)
    local data = extra.data
    for k,v in pairs(result.members) do
      if v.id ~= our_id then
        data[tostring(extra.msg.to.id)] = {
          moderators = {[tostring(v.id)] = '@'..v.username},
          settings = {
            set_name = string.gsub(extra.msg.to.print_name, '_', ' '),
            L_bots = 'no',
            L_names = 'yes',
            L_photo = 'no',
            L_member = 'no',
            an = 'ban',
            welcome = 'group',
            sticker = 'ok',
            }
         }
        save_data(_config.moderation.data, data)
        return send_large_msg(get_receiver(extra.msg), 'You have been promoted as moderator for this group.')
      end
    end
  end

  local function p(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    local group = string.gsub(receiver, 'chat#id', '')
    if not data[group] then
      return send_large_msg(receiver, 'Group is not added.')
    end
    if data[group]['moderators'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is already a moderator.')
    end
    data[group]['moderators'][tostring(member_id)] = member_username
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, member_username..' has been promoted as moderator for this group.')
  end

  local function d(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    local group = string.gsub(receiver, 'chat#id', '')
    if not data[group] then
      return send_large_msg(receiver, 'Group is not added.')
    end
    if not data[group]['moderators'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is not a moderator.')
    end
    data[group]['moderators'][tostring(member_id)] = nil
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, member_username..' has been demoted from moderator of this group.')
  end

  local function admin_promote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    if not data['admins'] then
      data['admins'] = {}
      save_data(_config.moderation.data, data)
    end
    if data['admins'][tostring(member_id)] then
     return send_large_msg(receiver, member_username..' is already as admin.')
    end
    data['admins'][tostring(member_id)] = member_username
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, member_username..' has been promoted as admin.')
  end

  local function admin_demote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    if not data['admins'] then
      data['admins'] = {}
      save_data(_config.moderation.data, data)
    end
    if not data['admins'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is not an admin.')
    end
    data['admins'][tostring(member_id)] = nil
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, 'Admin '..member_username..' has been demoted.')
  end

  local function username_id(extra, success, result)
    for k,v in pairs(result.members) do
      if v.username == extra.username then
        if extra.mod_cmd == 'p' then
          return p(extra.receiver, '@'..extra.username, v.id)
        elseif extra.mod_cmd == 'd' then
          return d(extra.receiver, '@'..extra.username, v.id)
        elseif extra.mod_cmd == 'add' then
          return admin_promote(extra.receiver, '@'..extra.username, v.id)
        elseif extra.mod_cmd == 'rem' then
          return admin_demote(extra.receiver, '@'..extra.username, v.id)
        end
      end
    end
    send_large_msg(extra.receiver, 'No user '..extra.username..' in this group.')
  end

  local function action_by_id(extra, success, result)
    if success == 1 then
      for k,v in pairs(result.members) do
        if extra.matches[2] == tostring(v.id) then
          if extra.matches[1] == 'p' then
            return p('chat#id'..result.id, 'user#id'..extra.matches[2], tostring(v.id))
          elseif extra.matches[1] == 'd' then
            return d('chat#id'..result.id, 'user#id'..extra.matches[2], tostring(v.id))
          elseif extra.matches[1] == 'add' then
            return admin_promote('chat#id'..result.id, 'user#id'..extra.matches[2], tostring(v.id))
          elseif extra.matches[1] == 'rem' then
            return admin_demote('chat#id'..result.id, 'user#id'..extra.matches[2], tostring(v.id))
          end
        end
      end
      send_large_msg('chat#id'..result.id, 'No user user#id'..extra.matches[2]..' in this group.')
    end
  end

  local function action_by_reply(extra, success, result)
    local msg = result
    local full_name = (msg.from.first_name or '')..' '..(msg.from.last_name or '')
    if msg.from.username then
      member_username = '@'..msg.from.username
    else
      member_username = full_name
    end
    local member_id = msg.from.id
    if msg.to.type == 'chat' and not is_sudo(member_id) then
      if extra.msg.text == '!p' then
        return p(get_receiver(msg), member_username, member_id)
      elseif extra.msg.text == '!d' then
        return d(get_receiver(msg), member_username, member_id)
      elseif extra.msg.text == '!add' then
        return admin_promote(get_receiver(msg), member_username, member_id)
      elseif extra.msg.text == '!rem' then
        return admin_demote(get_receiver(msg), member_username, member_id)
      end
    else
      return 'Use This in Your Groups.'
    end
  end

  function run(msg, matches)

    local receiver = get_receiver(msg)

    if is_chat_msg(msg) then
      if is_mod(msg.from.id, msg.to.id) then
        if matches[1] == 'p' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg})
          end
          if matches[2] then
            if string.match(matches[2], '^%d+$') then
              chat_info(receiver, action_by_id, {msg=msg, matches=matches})
            elseif string.match(matches[2], '^@.+$') then
              local username = string.gsub(matches[2], '@', '')
              chat_info(receiver, username_id, {mod_cmd=matches[1], receiver=receiver, username=username})
            end
          end
        elseif matches[1] == 'd' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg})
          end
          if matches[2] then
            if string.match(matches[2], '^%d+$') then
              d(receiver, 'user_'..matches[2], matches[2])
            elseif string.match(matches[2], '^@.+$') then
              local username = string.gsub(matches[2], '@', '')
              if username == msg.from.username then
                return 'You can\'t d yourself.'
              else
                chat_info(receiver, username_id, {mod_cmd=matches[1], receiver=receiver, username=username})
              end
            end
          end
        elseif matches[1] == 'modlist' then
          local data = load_data(_config.moderation.data)
          if not data[tostring(msg.to.id)] then
            return 'Group is not added.'
          end
          -- determine if table is empty
          if next(data[tostring(msg.to.id)]['moderators']) == nil then --fix way
            return 'No moderator in this group.'
          end
          local message = 'List of moderators for ' .. string.gsub(msg.to.print_name, '_', ' ') .. ':\n'
          for k,v in pairs(data[tostring(msg.to.id)]['moderators']) do
            message = message .. '- '..v..' [' ..k.. '] \n'
          end
          return message
        end
      end
      if is_admin(msg.from.id, msg.to.id) then
        if matches[1] == 'add' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg})
          end
          if matches[2] then
            if string.match(matches[2], '^%d+$') then
              chat_info(receiver, action_by_id, {msg=msg, matches=matches})
            elseif matches[2] and string.match(matches[2], '^@.+$') then
              local username = string.gsub(matches[2], '@', '')
              chat_info(receiver, username_id, {mod_cmd=matches[1], receiver=receiver, username=username})
            end
          end
        elseif matches[1] == 'rem' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg})
          end
          if matches[2] then
            if string.match(matches[2], '^%d+$') then
              admin_demote(receiver, 'user_'..matches[2], matches[2])
            elseif string.match(matches[2], '^@.+$') then
              local username = string.gsub(matches[2], '@', '')
              chat_info(receiver, username_id, {mod_cmd=matches[1], receiver=receiver, username=username})
            end
          end
        elseif matches[1] == 'adlist' then
          local data = load_data(_config.moderation.data)
          if not data['admins'] then
            data['admins'] = {}
            save_data(_config.moderation.data, data)
          end
          if next(data['admins']) == nil then --fix way
            return 'No admin available.'
          end
          for k,v in pairs(data['admins']) do
            message = 'List for Bot admins:\n'..'- '..v..' ['..k..'] \n'
          end
          return message
        end
      end
    else
      return 'Only works on group'
    end

    if matches[1] == 'chat_created' and msg.from.id == 0 then
      local data = load_data(_config.moderation.data)
      if msg.action.type == 'chat_created' then
        chat_info(get_receiver(msg), check_member,{data=data, msg=msg})
      else
        if data[tostring(msg.to.id)] then
          return 'Group is already added.'
        end
        local username = msg.from.username or msg.from.print_name
        -- create data array in moderation.json
        data[tostring(msg.to.id)] = {
          moderators ={[tostring(msg.from.id)] = '@'..username},
          settings = {
            set_name = string.gsub(msg.to.print_name, '_', ' '),
            L_bots = 'no',
            L_names = 'yes',
            L_photo = 'no',
            L_member = 'no',
            an = 'ban',
            welcome = 'group',
            sticker = 'ok',
            }
          }
        save_data(_config.moderation.data, data)
        return 'Group has been added, and @'..username..' has been promoted as moderator for this group.'
      end
    end
  end

  return {
    description = 'Moderation plugin',
    usage = {
      moderator = {
        '!p : If typed when replying, p replied user as moderator',
        '!p <user_id> : Promote user_id as moderator',
        '!p @<username> : Promote username as moderator',
        '!d : If typed when replying, d replied user from moderator',
        '!d <user_id> : Demote user_id from moderator',
        '!d @<username> : Demote username from moderator',
        '!modlist : List of moderators'
        },
      sudo = {
        '!add : If typed when replying, p replied user as admin.',
        '!add <user_id> : Promote user_id as admin.',
        '!add @<username> : Promote username as admin.',
        '!rem : If typed when replying, d replied user from admin.',
        '!rem <user_id> : Demote user_id from admin.',
        '!rem @<username> : Demote username from admin.'
        },
      },
    patterns = {
      '^!(rem) (%d+)$',
      '^!(rem) (.*)$',
      '^!(rem)$',
      '^!(adlist)$',
      '^!(add) (%d+)$',
      '^!(add) (.*)$',
      '^!(add)$',
      '^!(d) (.*)$',
      '^!(d)$',
      '^!(modlist)$',
      '^!(p) (.*)$',
      '^!(p)$',
      '^!(p) (%d+)$',
      '^!!tgservice (chat_add_user)$',
      '^!!tgservice (chat_created)$'
    },
    run = run
  }

end
