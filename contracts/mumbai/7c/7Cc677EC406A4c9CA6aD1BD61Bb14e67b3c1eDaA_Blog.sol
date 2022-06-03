// SPDX-License-Identifier: MIT
//pragma solidity >=0.8.0 <0.9.0;
pragma solidity 0.8.12;
import "UsersGroups.sol";
import "Bank.sol";

/// @title Blog
/// @notice Contract stored Blog Posts. Only Governance Contract can add Blog Post after successfull voting.
/// @dev Contract stored Blog Posts. Only Governance Contract can add Blog Post after successfull voting.
contract Blog {

    /// @notice Total number of posts.
    /// @dev Total number of posts.
    uint256 totalPostsNumber;

    /// @notice Reference to UserRoles Contract.
    /// @dev Reference to UserRoles Contract.
    UsersGroups roles;

    /// @notice Reference to Bank Contract.
    /// @dev Reference to Bank Contract.
    Bank bank;

    /// @notice Event emited, when post is added.
    /// @dev Event emited, when post is added.
    /// @return _value Post ID.
    event PostAdded(uint _value);

    /// @notice Event emited, when post is updated.
    /// @dev Event emited, when post is updated.
    /// @return _value Post ID.
    event PostUpdated(bool _value);
    
    /// @notice structure of single Post
    /// @dev structure of single Post
    /// @param hash cid IPFS
    /// @param account account added proposal for that post
    struct Posts {
        string hash;
        address account;
    }

    /// @notice List of Posts.
    /// @notice List of Posts.
    Posts[] public posts;


    /// @notice Constructor.
    /// @dev Constructor.
    /// @param roleContract Address UserRoles contract.
    /// @param bankContract Address Bank contract.
    constructor (address roleContract, address payable bankContract) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
    }

    
    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyPost()
    {
        require(roles.isPost(msg.sender), "Restricted to posts.");
        _;
    }

    /// @notice Add single Post.
    /// @dev Add single Post.
    /// @param _hash IPFS CID with metadata about post.
    /// @param _account Account created proposal for this post. Also account who get "money" when proposal is executed.
    /// @return _id post ID in array of posts
    function addPost(string memory _hash, address payable _account)
    public
    onlyPost
    returns (uint256) {
        //address _account = msg.sender;
        posts.push(Posts(_hash, _account));
        totalPostsNumber++;
        uint _id= posts.length -1;
        bank.internaltransfer(_account,1);
        emit PostAdded(_id);
        return _id;
    }

    /// @notice Total number of posts.
    /// @dev Total number of posts.
    /// @return totalPostsNumber Number of posts.
    function getTotalPostsNumber()
    public
    view
    returns (uint256)  {
        return totalPostsNumber;
    }

    /// @notice Update CID IPFS.
    /// @dev Update CID IPFS.
    /// @param id ID of Post.
    /// @param _hash New IPFS CID.
    function updateSinglePostHash(uint id,string memory _hash)
    public
    onlyPost {
        posts[id].hash =_hash;
        emit PostUpdated(true);
    }

    /// @notice Delete post.
    /// @dev Delete post.
    /// @param _id ID of Post
    function deleteSinglePost(uint _id)
    public
    onlyPost
    {
        //delete posts[_id];
        for(uint i = _id; i < posts.length-1; i++){
            posts[i] = posts[i+1];      
        }
        posts.pop();
    }

    /// @notice Get IPFS CID of post.
    /// @dev Get IPFS CID of post.
    /// @param id ID of Post.
    /// @return hash CID IPFS of post
    function getSinglePostHash(uint256 id)
    public
    view
    returns (string memory) {
        return posts[id].hash;
    }
    

    /// @notice Get account of post.
    /// @dev Get account of post.
    /// @param id ID of Post
    /// @return account Account sended proposal for post.
    function getSinglePostAccount(uint256 id)
    public
    view
    returns (address) {
        return posts[id].account;
    }

    /// @notice Get single post data.
    /// @dev Get single post data.
    /// @param id ID of Post
    /// @return hash IPFS CID.
    /// @return address Account sended proposal for post.
    function getSinglePost(uint256 id)
    public
    view
    returns (  string memory, address) {
        return ( posts[id].hash, posts[id].account) ;
    }

    /// @notice Get all post post.
    /// @dev Get all post post.
    /// @return list_of_post List of Enum Posts.
    function getAllPosts()
    public
    view
    returns (Posts[] memory) {
        return posts;
    }

}

// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
pragma solidity 0.8.12;

/// @title RequestMembers.
/// @notice Contract stored User and groum membership.
/// @dev Contract stored User and groum membership.
contract UsersGroups {

    /// @notice Array of static group.
    /// @dev Array of static group.
    bytes32[] private static_group = [
      
      bytes32("DAO_EXECUTE"),
      bytes32("Bank"),
      bytes32("Integration"),
      bytes32("Member"),
      bytes32("Admin")
    ];

    /// @notice Event emmited when new group is added.
    /// @dev Event emmited when new group is added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    event GroupAdd(bool status, string message,bytes32 group);

    /// @notice Event emmited when new group is deleted.
    /// @dev Event emmited when new group is deleted.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    event GroupRemove(bool status, string message,bytes32 group);

    /// @notice Event emmited when group budget is calculated.
    /// @dev Event emmited when group budget is calculated.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    event GroupCalculate(bool status, string message,bytes32 group);

    /// @notice Event emmited when group timestam is set.
    /// @dev Event emmited when group timestam is set.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name.
    /// @return timestamp Timestamp for integration to set.
    event GroupIntegrationTimestamp(bool status, string message,bytes32 group,uint256 timestamp);

    /// @notice Event emmited when new user is added.
    /// @dev Event emmited when new user is added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    event UserAdd(bool status, string message,address user);

    /// @notice Event emmited when new user is added to group.
    /// @dev Event emmited when new user is added to group.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    /// @return group Group Name.
    event UserToGroupAdd(bool status, string message,address user,bytes32 group);

    /// @notice Event emmited when new user is removed from group.
    /// @dev Event emmited when new user is removed from group.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    /// @return group Group Name.
    event UserToGroupRemove(bool status, string message,address user,bytes32 group);

    /// @notice Event emmited when new user is deleted.
    /// @dev Event emmited when new user is deleted.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address.
    event UserRemove(bool status, string message,address user);



    /// @notice Owner address.
    /// @dev Owner address.
    address private owner;

    /// @notice Array of groups.
    /// @dev Array of groups.
    Group[] private groups; 

    /// @notice Array of users.
    /// @dev Array of users.
    User[] private users;

    /// @notice User count.
    /// @dev User count.
    uint256 private UserCount=0;

    /// @notice Group count.
    /// @dev Group count.
    uint256 private GroupCount=0;

    /// @notice Map user address to: map group to status if added to this group.
    /// @dev Map user address to: map group to status if added to this group.
    mapping(address => mapping(bytes32 => bool)) userToGroupMap;

    /// @notice Map user address to status if exist.
    /// @dev Map user address to status if exist.
    mapping(address => bool) usersMap; 

     /// @notice Map user address to index in users array.
    /// @dev Map user address to index in users array.
    mapping(address => uint256) userIndex; 

    /// @notice Map group to status if exist.
    /// @dev Map group to status if exist.
    mapping(bytes32 => bool) groupsMap; 

    /// @notice Map group to index in group array.
    /// @dev Map group to index in group array.
    mapping(bytes32 => uint256) groupIndex; 

    /// @notice Map group to array of membership users.
    /// @dev Map group to array of membership users.
    mapping(bytes32 => address[]) groupToUserAddressMap; 

    /// @notice Structure of group.
    /// @dev Structure of group.
    /// @param group_name Group name.
    /// @param current_balance For future use.
    /// @param blocked_balance For future use.
    /// @param timestamp_created Timestamp Creation.
    /// @param timestamp_last_integration Timestamp for last integration.
    struct Group {
        bytes32 group_name;
        uint256 current_balance;
        uint256 blocked_balance;
        uint256 timestamp_created;
        uint256 timestamp_last_integration;
    }

    /// @notice Structure of users.
    /// @dev Structure of users.
    /// @param userID User Address.
    /// @param current_balance For future use.
    /// @param blocked_balance  For future use.
    /// @param timestamp_status Timestamp Creation.
    struct User {
        address userID;
        uint256 current_balance;
        uint256 blocked_balance;
        uint256 timestamp_created;
        bool timestamp_status;
    }

  /// @notice Contructor.
  /// @dev Contructor.
  /// @param _owner Owner Address 
  constructor (address _owner) public  {
    owner = _owner;
    addUser(owner);
    
    for(uint256 i=0;i<static_group.length;i++)
    {
      addGroup(static_group[i]);
    }
    setUserToGroup(owner, static_group[4]);
    //addUser(owner);
    //setUserToGroup(owner, static_group[0]);
  }

  /// @notice Initializer for proxy contract migration - future release.
  /// @dev Initializer for proxy contract migration - future release.
  /// @param _owner Owner Address.
  function initializer (address _owner) public {

    
    static_group.push(keccak256("DAO_EXECUTE"));
    static_group.push(keccak256("Bank"));
    static_group.push(keccak256("Integration"));
    static_group.push(keccak256("Admin"));
    static_group.push(keccak256("Member"));

    users.push(User(_owner,0 ,0,block.timestamp, false));
    usersMap[_owner] = true;
    userIndex[_owner] = UserCount;
    userToGroupMap[_owner][keccak256("Member")] = true;
    UserCount=UserCount+1;
    
    for(uint256 i=0;i<static_group.length;i++)
    {
      groups.push(Group(static_group[i],0,0,block.timestamp,0));
      groupsMap[static_group[i]] = true;
      groupIndex[static_group[i]] = GroupCount;
      GroupCount=GroupCount+1;
    }

    userToGroupMap[_owner][static_group[0]]=true;
    groupToUserAddressMap[static_group[0]].push(_owner);
    
  }

  modifier onlyAdmin()
  {
    require((owner == msg.sender || isAdmin(msg.sender)), "Restricted to admins or owner.");
    _;
  }

  modifier onlyPost()
  {
    require((isPost(msg.sender)), "Restricted to posts.");
    _;
  }

  /// @notice Check if User exist.
  /// @dev Check if User exist.
  /// @param user Account Address.
  /// @return status True/False if exist.
  function ifUserExist(address user)
  public
  view
  returns (bool)
  {
    return usersMap[user];
  }

  /// @notice Check if group exist.
  /// @dev Check if group exist.
  /// @param group Group Name.
  /// @return status True/False if exist.
  function ifGroupExist(bytes32 group)
  public
  view
  returns (bool)
  {
    return groupsMap[group];
  }

  /// @notice Check if User is in Group.
  /// @dev e Check if User is in Group.
  /// @param user Account Address.
  /// @param group Group Name.
  /// @return status True/False if exist.
  function ifUserHasGroup(address user,bytes32 group)
  internal
  view
  returns (bool)
  {
    if(!ifUserExist(user)||!ifGroupExist(group))
    {
      return false;
    }

    return userToGroupMap[user][group];
  }

  /// @notice Get data of user.
  /// @dev Get data of user.
  /// @param user Account Address.
  /// @return [balance,blocked_balance,timestamp_created,timestamp_status]
  function getUser(address user)
  public
  view
  onlyAdmin
  returns (uint256,uint256,uint256,bool)
  {
    require(ifUserExist(user),"User not exist");
    return (users[userIndex[user]].current_balance,users[userIndex[user]].blocked_balance,users[userIndex[user]].timestamp_created,users[userIndex[user]].timestamp_status);
  }

  /// @notice Get User Address by User Index.
  /// @dev Get User Address by User Index.
  /// @param _index User Index.
  /// @return [userID,balance,blocked_balance,timestamp_created,timestamp_status].
  function getUserByIndex(uint256 _index)
  public
  view
  onlyAdmin
  returns (address)
  {
    return (users[_index].userID);
  }

  /// @notice Get user Index.
  /// @dev Get user Index.
  /// @param user Account Address.
  /// @return struct_of_user User Enum.
  function getUserindex(address user)
  public
  view
  onlyAdmin
  returns (uint256)
  {
    require(ifUserExist(user),"User not exist");
    return userIndex[user];
  }

  /// @notice Get array of Struct User.
  /// @dev Get array of Struct User.
  /// @return list_of_struct_of_userGet List User Enum.
  function getUsers()
  public
  view 
  onlyAdmin
  returns (User[] memory)
  {
    return users;
  }

  /// @notice Get group members.
  /// @dev Get group members.
  /// @param group Group Name
  /// @return array_of_address Array of accounts.
  function getUsersInGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (address[] memory)
  {
    return groupToUserAddressMap[group];
  }

  /// @notice Get total number of users.
  /// @dev Get total number of users.
  /// @return count Number Of Users.
  function getUsersCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return UserCount;
  }

  /// @notice Get total number of groups.
  /// @dev Get total number of groups.
  /// @return count Number Of Groups.
  function getGroupsCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return GroupCount;
  }

  /// @notice Get All Group.
  /// @dev Get All Group.
  /// @return list_of_struct_group List of Group Enum.
  function getGroups()
  public
  view
  returns (Group[] memory)
  {
    return groups;
  }
  /// @notice Get group.
  /// @dev Get group.
  /// @param group Group Name.
  /// @return group_data  Array of group data [group_name,timestamp_created,timestamp_last_integration]
  function getGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (bytes32,uint256,uint256)
  {
    //require(ifGroupExist(group),"Group not exist");
    return (groups[groupIndex[group]].group_name,
    groups[groupIndex[group]].timestamp_created,
    groups[groupIndex[group]].timestamp_last_integration);
  }

  /// @notice Add group.
  /// @dev Add group.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function addGroup(bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifGroupExist(group)){
      emit GroupAdd(false,"Group Exist.",group);
      return false;
    }
    groups.push(Group(group,0,0,block.timestamp,0));
    groupsMap[group] = true;
    groupIndex[group] = GroupCount;
    GroupCount=GroupCount+1;
    emit GroupAdd(true,"Group added successfully.",group);
    return true;
  }

  /// @notice Remove group.
  /// @dev Remove group.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function removeGroup(bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {
    for(uint256 i=0;i<static_group.length;i++)
    {
      if(static_group[i] == group)
      {
        emit GroupRemove(false,"Group can't be removed.",group);
        return false;
      }
    }
    if(ifGroupExist(group))
    {
      
      for(uint256 i=0;i<users.length;i++)
      {
        if(ifUserHasGroup(users[i].userID,group))
        {
          emit GroupRemove(false,"Group has members, Please delete members from group.",group);
          return false;
        }
      }

      if(users.length== 1)
      {
        users.pop();
      }
      else
      {
        for(uint256 i=groupIndex[group];i<groups.length-1;i++)
        {
          groups[i]=groups[i+1];
          groupIndex[groups[i+1].group_name]=i;
        }
        groups.pop();
      }
        delete groupIndex[group];
        delete groupsMap[group];
        GroupCount=GroupCount-1;
        emit GroupRemove(true,"group removed successfully.",group);
        return true;
    }
    else
    {
      emit GroupRemove(false,"Group Not Exist.",group);
      return false;
    }
  }
  /// @notice Set last Integration Timestamp.
  /// @dev Set last Integration Timestamp.
  /// @param group Group Name.
  /// @param timestamp_last_integration Integration Timestamp.
  /// @return status True/False - status of excution.
  function setIntegrationTimestamp(bytes32 group,uint256 timestamp_last_integration)
  public
  onlyPost
  returns (bool){
    if(!ifGroupExist(group))
    {
      emit GroupIntegrationTimestamp(false,"Group not exist.",group, timestamp_last_integration);
      return false;
    }
    else
    {
      if(groups[groupIndex[group]].timestamp_last_integration < timestamp_last_integration){
        groups[groupIndex[group]].timestamp_last_integration = timestamp_last_integration;
        emit GroupIntegrationTimestamp(true,"Timestamp is set.",group, timestamp_last_integration);
        return true;
      }
      else{
        emit GroupIntegrationTimestamp(true,"Timestamp is not set, because is less than current timestamp for this group.",group, timestamp_last_integration);
        return true;
      }
    }
  }
  /// @notice Add User.
  /// @dev Add User.
  /// @param user User Address.
  /// @return status True/False - status of excution.
  function addUser(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user)){
      emit UserAdd(false,"User Exist.",user);
      return false;
    }
    
    users.push(User(user,0,0,block.timestamp, false));
    usersMap[user] = true;
    userIndex[user] = UserCount;
    userToGroupMap[user][static_group[3]] = true;
    groupToUserAddressMap[static_group[3]].push(user);
    UserCount=UserCount+1;
    emit UserAdd(true,"User added successfully.",user);
    return true;
  }
  /// @notice Add Smart Contract to Users, beacuse they need permissions based on groups.
  /// @dev Add Smart Contract to Users, beacuse they need permissions based on groups.
  /// @param user User Address.
  /// @return status True/False - status of excution.
  function addSmartContract(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user)){
      emit UserAdd(false,"User Exist.",user);
      return false;
    }
    
    users.push(User(user,0,0,block.timestamp, false));
    usersMap[user] = true;
    userIndex[user] = UserCount;
    UserCount=UserCount+1;
    emit UserAdd(true,"User added successfully.",user);
    return true;
  }

  /// @notice Remove group.
  /// @dev Remove group.
  /// @param user User Address.
  /// @return status True/False - status of excution.
  function removeUser(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user))
    {
      if(users.length== 1)
      {
        users.pop();
      }
      else
      {
        uint256 user_index = userIndex[user];
        for(uint256 i=user_index;i<users.length-1;i++)
        {
          users[i]=users[i+1];
          userIndex[users[i+1].userID]=i;
        }
        users.pop();
      }
        delete userIndex[user];
        delete usersMap[user];
        for(uint i=0;i<groups.length;i++){
          if(ifUserHasGroup(user,groups[i].group_name))
          {
            delete userToGroupMap[user][groups[i].group_name];
          }
        }
        
        UserCount=UserCount-1;
        emit UserRemove(true,"User removed.",user);
        return true;
    }
    else
    {
      emit UserRemove(false,"User Not Exist.",user);
      return false;
    }
  }

  /// @notice Add user to group.
  /// @dev Add user to group.
  /// @param user User Address.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function setUserToGroup(address user,bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {

    if(!ifUserExist(user)){
      emit UserToGroupAdd(false,"User not Exist.",user,group);
      return false;
    }

    if(!ifGroupExist(group)){
      emit UserToGroupAdd(false,"Group not Exist.",user,group);
      return false;
    }

    if(ifUserHasGroup(user,group))
    {
      emit UserToGroupAdd(false,"User is in group.",user,group);
      return false;
    }

    userToGroupMap[user][group]=true;
    groupToUserAddressMap[group].push(user);
    emit UserToGroupAdd(true,"User added to group successfully.",user,group);
    return true;
  }

  /// @notice Remove user from group.
  /// @dev Remove user from group.
  /// @param user User Address.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function removeUserFromGroup(address user,bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {

    if(!ifUserExist(user)){
      emit UserToGroupRemove(false,"User not Exist.",user,group);
      return false;
    }

    if(!ifGroupExist(group)){
      emit UserToGroupRemove(false,"Group not Exist.",user,group);
      return false;
    }

    if(!ifUserHasGroup(user,group)){
      emit UserToGroupRemove(false,"User is not in group.",user,group);
      return false;
    }

    
    uint256 index = 0;
    uint256 long = groupToUserAddressMap[group].length-1;
    address[] memory assets = new address[](groupToUserAddressMap[group].length-1);

    for(uint i=0;i<groupToUserAddressMap[group].length;i++)
    {
      if(groupToUserAddressMap[group][i] == user){
        for(uint ii=i; ii<long;ii++){
            emit UserToGroupRemove(true,"Finded user.",groupToUserAddressMap[group][ii] ,group);
        }
        
        //groupToUserAddressMap[group].pop();
      }
      else
      {
        assets[index]=groupToUserAddressMap[group][i];
        index++;
      }
      
    }
    userToGroupMap[user][group]=false;
    groupToUserAddressMap[group] = assets;
    emit UserToGroupRemove(true,"User removed group successfully.",user,group);
    return true;
  }

  /// @notice Check if user is admin.
  /// @dev Check if user is admin.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isAdmin(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[4].group_name);
  }

  /// @notice Check if user is in group Integration.
  /// @dev Check if user is in group Integration.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isIntegration(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[2].group_name);
  }

  /// @notice Check if user is in group who can add Blog Post.
  /// @dev Check if user is in group who can add Blog Post.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isPost(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[0].group_name);
  }

  /// @notice Check if user is in group who can transfer from Bank.
  /// @dev Check if user is in group who can transfer from Bank.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isBank(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[1].group_name);
  }

  /// @notice Check if user is in group Member.
  /// @dev Check if user is in group Member.
  /// @param account User Address.
  /// @return status True/False - status of excution.
  function isMember(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[3].group_name);
  }

  /// @notice Check if user is in this group.
  /// @dev Check if user is in this group.
  /// @param account User Address.
  /// @param group Group Name.
  /// @return status True/False - status of excution.
  function isRole(address account,bytes32 group)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,group);
  }

  /// @notice Calculate, if group can add Integration.
  /// @dev Calculate, if group can add Integration.
  /// @param group User Address.
  /// @param future_integration_timestamp Future Integration timestamp.
  /// @param integration_budget Budget needed for integration.
  /// @return status True/False - status of excution
  function groupCalculate(bytes32 group,uint256 future_integration_timestamp, uint256 integration_budget)
  public
  onlyPost
  returns (bool)
  {
    if(!ifGroupExist(group)){
      emit GroupCalculate(false,"Group not Exist.",group);
      return false;
    }
    //if date was in past
    if(future_integration_timestamp < block.timestamp)
    {
      //uint256 diff_time = future_integration_timestamp - block.timestamp;
      emit GroupCalculate(false,"Integration timestamp is wrong.",group);
      //emit GroupCalculateBlock(false,"Timestamp block.",block.timestamp);
      //emit GroupCalculateBlock(false,"Timestamp integration.",future_integration_timestamp);
      //emit GroupCalculateBlock(false,"Timestamp difference.",diff_time);
      return false;
    }

    //if less than 60days
    uint diff = (future_integration_timestamp - groups[groupIndex[group]].timestamp_last_integration) / 60 / 60 / 24;
    //emit GroupCalculateBlock(false,"Timestamp difference day.",diff);
    if(diff < 60){
      emit GroupCalculate(false,"Beetween integrations is less than 60days.",group);
      return false;
    }

    //if budget is to hight
    if(integration_budget > groupToUserAddressMap[group].length * 25)
    {
      emit GroupCalculate(false,"Budget is too hight.",group);
      return false;
    }


    emit GroupCalculate(true,"Group can organize integration.",group);
    return true;
  }






}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "AggregatorV3Interface.sol";
import "UsersGroups.sol";

/// @title Bank.
/// @notice Contract, who store ether and transfer it to winner.
/// @dev
contract Bank {
    /// @notice address UserRoles Contract.
    /// @dev address UserRoles Contract.
    UsersGroups roles;
    
    /// @notice address Bank Contract Owner.
    /// @dev address Bank Contract Owner.
    address payable public owner;

    uint public contractbalance;//contract value 
    uint public ownerbalance;
    uint public balanceto;

    /// @notice Event emited, when transfer to bank
    /// @dev Event emited, when transfer to bank
    /// @return address Address transfer from.
    /// @return amount Amount transfer.
    event Received(address, uint);

    /// @notice Event emited, when transfer from bank
    /// @dev Event emited, when transfer from bank
    /// @return address Address transfer to.
    /// @return amount Amount transfer
    event Send(address, uint);

    /// @notice Aggregator to calculate current price.
    /// @dev Aggregator to calculate current price.
    AggregatorV3Interface internal priceFeed;
    address addressDataFeed;


    /// @notice constructor Bank Contract.
    /// @dev constructor Bank Contract.
    /// @param roleContract - address of UserRoles Contract.
    /// @param dataFeed - address of AggregatorV3Interface Contract.
    constructor (address roleContract, address dataFeed)  {
        owner=payable(msg.sender);   
        roles = UsersGroups(roleContract);
        priceFeed = AggregatorV3Interface(dataFeed);
        addressDataFeed = dataFeed;

    }
    
    modifier onlyBank()
    {
        require(roles.isBank(msg.sender), "Restricted to bank.");
        _;
    }

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    /// @notice Transfer ether from bank to another account.
    /// @dev Transfer from bank to another account.
    /// @param _to - account for transfer in 0.01, its mean 1 is 0.01, if you want transfer 10, input is 100*10=1000,etc.
    /// @param _value - amount for transfer in 0.01, its mean 1 is 0.01, if you want transfer 10, input is 100*10=1000,etc.
    function internaltransfer(address payable _to,uint _value)
    public
    payable
    onlyBank
    {
        uint denominator = uint(getLatestPrice()); 
        uint256 ethInUsdAmount = _value * 1000000000000000000000/denominator * 100000/100; 
        emit Send(_to, ethInUsdAmount);
        (bool sent,)=_to.call{value: ethInUsdAmount}("");
        ownerbalance=owner.balance;
        balanceto=_to.balance;
        contractbalance=address(this).balance;
        require(sent,"failed to send");
    }
    /// @notice For receive money for another account.
    /// @dev For receive money for another account.
    receive()
    external
    payable
    {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Get Bank Balance
    /// @dev Get Bank Balance
    /// @return balance Bank balance.
    function getCurrentStatus()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

    /// @notice Get calculated price.
    /// @dev Get calculated price.
    /// @return price Price from V3Aggregator.
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice Get dataFeed Address.
    /// @dev Get dataFeed Address.
    /// @return address DataFeed Address.
    function getDataFeedAddress() public view returns (address) {
        return addressDataFeed;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}