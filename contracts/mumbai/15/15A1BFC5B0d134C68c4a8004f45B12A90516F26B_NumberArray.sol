//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PartialMessage, Message, Reactions } from "./Message.sol";
import { Permission } from "./PermissionInterface.sol";
import { Profile } from "./ProfileInterface.sol";

contract ChannelManager {

    event MessageEvent(string channel_name, Message message);
    event ReactionEvent(string channel_name, uint message_id, uint reaction_id);
    event ChannelEvent(string channel_name);
    string public global_channel_name;
    string public icon_link;
    string public banner_link;

    uint constant TOTAL_REACTIONS = 5;
    // mapping of channel name to message id to map of reaction enum values, and their counts
    mapping(string => mapping(uint => mapping(uint => uint))) message_reactions;
    // channel name => message id => Message
    mapping(string => mapping(uint => Message)) messages;
    // channel name => message_id
    mapping(string => uint) message_ids;
    // channel index => name
    mapping(uint => string) channels;
    uint public channel_id = 0;
    // channel name => bool
    mapping(string => bool) channel_exists;

    Permission public permission_manager;

    Profile public profile_manager;

    constructor (address _permission_manager, address _profile_manager) {
        permission_manager = Permission(_permission_manager);
        profile_manager = Profile(_profile_manager);
    }

    /*
        __     __     ______     __     ______   ______    
       /\ \  _ \ \   /\  == \   /\ \   /\__  _\ /\  ___\   
       \ \ \/ ".\ \  \ \  __<   \ \ \  \/_/\ \/ \ \  __\   
        \ \__/".~\_\  \ \_\ \_\  \ \_\    \ \_\  \ \_____\ 
         \/_/   \/_/   \/_/ /_/   \/_/     \/_/   \/_____/ 
    */

    function updateName(string memory _name) public onlyModerator(msg.sender) {
        global_channel_name = _name;
    }

    function updateIcon(string memory _icon) public onlyModerator(msg.sender) {
        icon_link = _icon;
    }

    function updateBanner(string memory _banner) public onlyModerator(msg.sender) {
        banner_link = _banner;
    }

    function createChannel(string memory name) public onlyModerator(msg.sender) {
      // check if channel exists
      require(!channel_exists[name]);
      channels[channel_id] = name;
      channel_exists[name] = true;
      channel_id += 1;
      emit ChannelEvent(name);
    }

    function newMessage(string memory channel_name, PartialMessage memory _message) public onlyLiveChannels(channel_name) {
        require(profile_manager.isAccountOperator(_message.username, msg.sender));
        Message memory message = Message(
            message_ids[channel_name],
            block.timestamp,
            _message.username,
            _message.message,
            _message.reply_id,
            _message.media
        );
        messages[channel_name][message_ids[channel_name]] = message;
        message_ids[channel_name] += 1;
        profile_manager.incrementKarma(message.username);
        emit MessageEvent(channel_name, message);
    }

    function reactToMessage(string memory channel_name, uint message_id, uint reaction_id) public onlyLiveChannels(channel_name) {
        require (message_ids[channel_name] > message_id);
        require (reaction_id < TOTAL_REACTIONS);
        message_reactions[channel_name][message_id][reaction_id] += 1;
        emit ReactionEvent(channel_name, message_id, reaction_id);
    }

    /*
         ______     ______     ______     _____    
         \  == \   /\  ___\   /\  __ \   /\  __-.  
        \ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
         \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
          \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
    */       

    function getMessage(string memory channel_name, uint message_id) public view onlyLiveChannels(channel_name) returns (Message memory) {
        require(message_ids[channel_name] > message_id);
        return messages[channel_name][message_id];
    }

    function getMessagesPaginated(string memory channel_name, uint page, uint total) public view onlyLiveChannels(channel_name) returns (Message[] memory all_messages) {
        require(channel_exists[channel_name]);
        uint offset = page*total;
        all_messages = new Message[](total);
        for (uint i = 0; i < total; i++) {
            all_messages[i] = messages[channel_name][offset + i];
        }
    }

    function getNumberMessages(string memory channel_name) public view onlyLiveChannels(channel_name) returns (uint) {
        return message_ids[channel_name];
    }

    function getChannelNames() public view returns (string[] memory channel_names) {
        channel_names = new string[](channel_id);
        for (uint i = 0; i < channel_id; i++) {
            channel_names[i] = channels[i];
        }
    }

    function getReactionsForMessage(string memory channel_name, uint message_id) public view onlyLiveChannels(channel_name) returns (uint[] memory) {
        require (message_ids[channel_name] > message_id);
        uint[] memory counts = new uint[](TOTAL_REACTIONS);
        for (uint i = 0; i < TOTAL_REACTIONS; i++) {
            counts[i] = message_reactions[channel_name][message_id][i];
        }
        return counts;
    }

    modifier onlyModerator(address potential_moderator) {
        require(permission_manager.isModerator(potential_moderator));
        _;
    }

    modifier onlyLiveChannels(string memory channel_name) {
        require(channel_exists[channel_name]);
        _;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Message {
    uint id;
    uint timestamp;
    string username;
    string message;
    uint reply_id;
    string media;
}

struct PartialMessage {
    string username;
    string message;
    uint reply_id;
    string media;
}

enum Reactions {
    Fire,
    ThumbsUp,
    ThumbsDown,
    Heart,
    Siren
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { User } from "./User.sol";

contract Permission {
    mapping(address => bool) public moderators;

    mapping(address => bool) public system_contracts;
    address public owner;
    address public deployer;
    
    constructor () {
        deployer = msg.sender;
    }

    /*
        __     __     ______     __     ______   ______    
       /\ \  _ \ \   /\  == \   /\ \   /\__  _\ /\  ___\   
       \ \ \/ ".\ \  \ \  __<   \ \ \  \/_/\ \/ \ \  __\   
        \ \__/".~\_\  \ \_\ \_\  \ \_\    \ \_\  \ \_____\ 
         \/_/   \/_/   \/_/ /_/   \/_/     \/_/   \/_____/ 
    */

    function addSystemContract(address system_contract) public onlyDeployer {
        system_contracts[system_contract] = true;
    }

    function setOwner(address new_owner) public {
        require(isSystemContract(msg.sender) || isDeployer(msg.sender));
        owner = new_owner;
    }
 
    function updateModerator(address moderator, bool state) public {
        require(isSystemContract(msg.sender));
        moderators[moderator] = state;
    }

    function relinquish() public onlyDeployer {
        deployer = address(0);
    }

    /*
         ______     ______     ______     _____    
         \  == \   /\  ___\   /\  __ \   /\  __-.  
        \ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
         \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
          \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
    */   

    function isOwner(address potential_owner) public view returns (bool) {
        return potential_owner == owner;
    }

    function isModerator(address potential_moderator) public view returns (bool) {
        return moderators[potential_moderator];
    }

    function isSystemContract(address potential_system_contract) public view returns (bool) {
        return system_contracts[potential_system_contract];
    }

    function isDeployer(address potential_deployer) public view returns (bool) {
        return deployer == potential_deployer;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    modifier onlyModerator() {
        require(isModerator(msg.sender));
        _;
    }

    modifier onlyDeployer() {
        require(isDeployer(msg.sender));
        _;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { User, PartialUser } from "./User.sol";
import { Permission } from "./PermissionInterface.sol";


contract Profile {
    // username => user
    mapping(string => User) users;

    // address => username
    mapping(address => string) user_by_main_address;

    // index => username
    mapping(uint => string) total_users;
    uint public current_user_count = 0;

    Permission public permission_manager;

    constructor (address _permission_manager) {
        permission_manager = Permission(_permission_manager);
    }

    /*
        __     __     ______     __     ______   ______    
       /\ \  _ \ \   /\  == \   /\ \   /\__  _\ /\  ___\   
       \ \ \/ ".\ \  \ \  __<   \ \ \  \/_/\ \/ \ \  __\   
        \ \__/".~\_\  \ \_\ \_\  \ \_\    \ \_\  \ \_____\ 
         \/_/   \/_/   \/_/ /_/   \/_/     \/_/   \/_____/ 
    */

    function newUser(PartialUser memory user) public {
        // Don't make an account if the username requested already exists
        require(!userExists(user.username));
        // An empty username is invalid
        // require(keccak256(bytes(user.username)) != keccak256(bytes("")));
        User memory _user = User(user.username, user.pfp_link, 0, msg.sender, user.operator_wallet, false, user.bio);
        users[user.username] = _user;
        total_users[current_user_count] = user.username;
        user_by_main_address[msg.sender] = user.username;
        current_user_count += 1;
    }

    function updateProfilePicture(string memory username, string memory new_pfp_link) public onlyAccountOperator(username, msg.sender) {
        users[username].pfp_link = new_pfp_link;
    }

    function updateBio(string memory username, string memory bio) public onlyAccountOperator(username, msg.sender) {
        users[username].bio = bio;
    }

    function updateOperatorAddress(string memory username, address new_operator) public onlyAccountOwner(username, msg.sender) {
        if(users[username].is_moderator) {
            permission_manager.updateModerator(users[username].operator_wallet, false);
            permission_manager.updateModerator(new_operator, true);
        }
        if(permission_manager.isOwner(users[username].operator_wallet)) {
            permission_manager.setOwner(new_operator);
        }
        users[username].operator_wallet = new_operator;
    }

    function incrementKarma(string memory username) public {
        require(permission_manager.isSystemContract(msg.sender));
        users[username].activity_karma += 1;
    }

    function updateModeratorStatus(string memory username, bool update) public onlyOwner(msg.sender) {
        require(userExists(username));
        users[username].is_moderator = update;
        permission_manager.updateModerator(users[username].operator_wallet, update);
    }

    /*
         ______     ______     ______     _____    
         \  == \   /\  ___\   /\  __ \   /\  __-.  
        \ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
         \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
          \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
    */                                

    function userExists(string memory username) public view returns (bool) {
        return keccak256(bytes(users[username].username)) != keccak256(bytes(""));
    }

    function isAccountOwner(string memory username, address potential_user_address) public view returns (bool) {
        return userExists(username) && (users[username].main_wallet == potential_user_address);
    }

    function isAccountOperator(string memory username, address potential_user_address) public view returns (bool) {
        return userExists(username) && (users[username].operator_wallet == potential_user_address);
    }

    function getUser(string memory username) public view returns (User memory) {
        return users[username];
    }

    function getUserFromMainAddress(address main_address) public view returns (User memory) {
        return users[user_by_main_address[main_address]];
    }

    function getUsersPaginated(uint page, uint total) public view returns (User[] memory _users) {
        _users = new User[](total);
        uint offset = page*total;
        for (uint i = 0; i < total; i++) {
            _users[i] = users[total_users[offset+i]];
        }
    }

    function getAllUsers() public view returns (User[] memory _users) {
        _users = new User[](current_user_count);
        for (uint i = 0; i < current_user_count; i++) {
            _users[i] = users[total_users[i]];
        }
    }

    modifier onlyAccountOperator(string memory username, address potential_user_address) {
        require(isAccountOperator(username, potential_user_address));
        _;
    }

    modifier onlyAccountOwner(string memory username, address potential_user_address) {
        require(isAccountOwner(username, potential_user_address));
        _;
    }

    modifier onlyOwner(address username) {
        require(permission_manager.isOwner(msg.sender));
        _;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct User {
    string username;
    string pfp_link;
    uint activity_karma;
    address main_wallet;
    address operator_wallet;
    bool is_moderator;
    string bio;
}

// Used on sign up
struct PartialUser {
    string username;
    address operator_wallet;
    string pfp_link;
    string bio;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Permission {
    function isOwner(address potential_owner) external view returns (bool);
    function isModerator(address potential_moderator) external view returns (bool);
    function isSystemContract(address potential_system_contract) external view returns (bool);
    function isDeployer(address potential_deployer) external view returns (bool);
    function updateModerator(address moderator, bool state) external;
    function setOwner(address new_owner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { User } from "./User.sol";
    
interface Profile {
    function getUser(string memory username) external view returns (User memory);
    function isAccountOperator(string memory username, address user_address) external view returns (bool);
    function userExists(string memory username) external view returns (bool);
    function incrementKarma(string memory username) external;
}

// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract NumberArray {
    uint[] public numbers;

    constructor(uint numberToAdd) {
        numbers.push(numberToAdd);
    }
}