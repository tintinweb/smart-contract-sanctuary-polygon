// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "AggregatorV3Interface.sol";
import "UsersGroups.sol";
import "Initializable.sol";

/// @title Bank.
/// @notice Contract, who store ether and transfer it to winner.
/// @dev
contract Bank is Initializable{
    /// @notice address UserRoles Contract.
    /// @dev address UserRoles Contract.
    UsersGroups private roles;
    
    /// @notice address Bank Contract Owner.
    /// @dev address Bank Contract Owner.
    address payable private owner;

    uint private contractBalance;//contract value 
    uint private ownerBalance;
    uint private balanceTo;

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

    /// @notice Address for Aggregator to calculate current price.
    /// @dev Address for Aggregator to calculate current price.
    address addressDataFeed;


    /// @notice constructor Bank Contract.
    /// @dev constructor Bank Contract.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize contrace Bank Contract by Proxy.
    /// @dev Initialize contrace Bank Contract by Proxy.
    /// @param roleContract - address of UserRoles Contract.
    /// @param dataFeed - address of AggregatorV3Interface Contract.
    function initialize (address roleContract, address dataFeed) initializer public {
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
    function internalTransfer(address payable _to,uint _value)
    public
    payable
    onlyBank
    {
        uint denominator = uint(getLatestPrice()); 
        uint256 ethInUsdAmount = _value * 1000000000000000000000/denominator * 100000/100; 
        emit Send(_to, ethInUsdAmount);
        (bool sent,)=_to.call{value: ethInUsdAmount}("");
        ownerBalance=owner.balance;
        balanceTo=_to.balance;
        contractBalance=address(this).balance;
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

    /// @notice Get Bank Balance.
    /// @dev Get Bank Balance.
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
    function getDataFeedAddress() 
    public view returns (address) {
        return addressDataFeed;
    }


    /// @notice Get current Reference to UsersGroups Address.
    /// @dev Get current Reference to UsersGroups Address.
    /// @return address DataFeed Address.
    function getUsersGroups() 
    onlyAdmin
    public view returns (address) {
        return address(roles);
    }

    /// @notice Set dataFeed Address.
    /// @dev Set dataFeed Address.
    /// @param _addressDataFeed DataFeed Address.
    function setDataFeedAddress(address _addressDataFeed) 
    public
    onlyAdmin
    {
        addressDataFeed=  _addressDataFeed;
        priceFeed = AggregatorV3Interface(_addressDataFeed);
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

// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
pragma solidity 0.8.12;
import "Initializable.sol";

/// @title RequestMembers.
/// @notice Contract stored User and groum membership.
/// @dev Contract stored User and groum membership.
contract UsersGroups is Initializable {

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

    /// @notice  token for authentication
    /// @dev  token for authentication
    string private tokenAuth;

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
  constructor() {
        _disableInitializers();
    }

  /// @notice Initializer for proxy contract migration - future release.
  /// @dev Initializer for proxy contract migration - future release.
  /// @param _owner Owner Address.
  function initialize (address _owner, string memory token) initializer public {
    static_group.push(bytes32("DAO_EXECUTE"));
    static_group.push(bytes32("Bank"));
    static_group.push(bytes32("Integration"));
    static_group.push(bytes32("Member"));
    static_group.push(bytes32("Admin"));

    tokenAuth = token;

    users.push(User(_owner,0 ,0,block.timestamp, false));
    usersMap[_owner] = true;
    userIndex[_owner] = UserCount;
    userToGroupMap[_owner][static_group[3]] = true;
    groupToUserAddressMap[static_group[3]].push(_owner);
    UserCount=UserCount+1;

    for(uint256 i=0;i<static_group.length;i++)
    {
      groups.push(Group(static_group[i],0,0,block.timestamp,0));
      groupsMap[static_group[i]] = true;
      groupIndex[static_group[i]] = GroupCount;
      GroupCount=GroupCount+1;
    }

    userToGroupMap[_owner][static_group[4]]=true;
    groupToUserAddressMap[static_group[4]].push(_owner);
    
  }

  modifier onlyAdmin()
  {
    require((owner == msg.sender || isAdmin(msg.sender)), "Restricted to admins or owner.");
    _;
  }

  modifier onlyMember()
  {
    require((isMember(msg.sender)), "Restricted to members.");
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

  

  /// @notice Get Token.
  /// @dev Get Token.
  /// @return tokenAuth Token
  function getToken()
  public
  onlyMember
  returns (string memory){
    return tokenAuth;
  }

  /// @notice Set token.
  /// @dev Set token.
  /// @param _token User Address.
  function setToken(string memory _token)
  public
  onlyAdmin
  returns (string memory){
     tokenAuth = _token;
  }






}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}