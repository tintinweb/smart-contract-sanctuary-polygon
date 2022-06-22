// SPDX-License-Identifier: MIT
//pragma solidity >=0.8.0 <0.9.0;
pragma solidity 0.8.12;
import "UsersGroups.sol";
import "Bank.sol";
import "IntegrationApprove.sol";
import "GovernorContract.sol";

/// @title Integration
/// @notice store integrations
/// @dev
contract Integration {

    /// @notice Total number of Integrations.
    /// @dev Total number of Integrations. 
    uint256 private totalNumber;

    /// @notice Reference to UsersGroups Contract.
    /// @dev Reference to UsersGroups Contract. 
    UsersGroups private roles;

    /// @notice Reference to Bank Contract.
    /// @dev Reference to Bank Contract. 
    Bank private bank;

    /// @notice Reference to IntegrationApprove Contract.
    /// @dev Reference to IntegrationApprove Contract.
    IntegrationApprove private integration_approve;

    /// @notice Reference to Governor contract.
    /// @dev Reference to Governor contract.
    GovernorContract private governor;


    /// @notice Event emmited when Integration is Added.
    /// @dev Event emmited when Integration is Added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return amount Amount of Money for Integration.
    /// @return id Integration ID.
    event IntegrationAdded(bool status,string message,uint256 amount, uint256 id);

    /// @notice Event emmited when Integration CID IPFS is updated.
    /// @dev Event emmited when Integration CID IPFS is updated.
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return id Integration ID
    event IntegrationUpdated(bool status,string message, uint256 id);

    /// @notice Event emmited when Integration CID IPFS is deleted.
    /// @dev Event emmited when Integration CID IPFS is deleted.
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return id Integration ID
    event IntegrationDelete(bool status,string message, uint256 id);

    /// @notice map ID to index in array in integration Approve.
    /// @dev map ID to index in array in integration Approve.
    mapping(uint256 => uint256) integrationIndexMap;

    /// @notice map ID to status if exist.
    /// @dev map ID to status if exist.
    mapping(uint256 => bool) integrationExistMap;
    
    /// @notice Structure of single Integration.
    /// @dev Structure of single Integration.
    /// @param ipfs_hash IPFS CID of Proposal
    struct Integrations {
        uint256 id; // Proposal ID
        string ipfs_hash; // IPFS CID
    }

    /// @notice Array of Integration.
    /// @dev Structure of single Integration.
    Integrations[] private integrations;

    /// @notice Constructor.
    /// @dev Constructor.
    /// @param roleContract Address of UsersGroups Contract.
    /// @param bankContract  Address of Bank Contract.
    /// @param integration_approveContract Address of IntegrationApprove Contract.
    constructor (address roleContract,address payable bankContract, address integration_approveContract,address payable governorContract) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
        integration_approve = IntegrationApprove(integration_approveContract);
        governor = GovernorContract(governorContract);
    }

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    modifier onlyPost()
    {
        require(roles.isPost(msg.sender), "Restricted to posts.");
        _;
    }
    
    /// @notice Add integration.
    /// @dev Add integration.
    /// @param _hash_integration IPFS CID of Interation.
    /// @param _hash_integration_approve  IPFS CID of Interation Approve.
    /// @param _account Account sended Proposal for this Integration.
    /// @param amount_integration USD to be sended to account, when proposal for integration is succesfull executed => 1 = 0.01 USD.
    /// @param amount_approve USD to be sended, when approve will be confirmed => 1 = 0.01 USD.
    /// @param groups Array of groups, when one member from group must confirm Integration Approve.
    /// @param group_for_vote  Group for votee on Integraion Approve, when 51% of members must Confirm Approve.
    /// @param timestamp_inegration_approve Block when Integration Approve shoud start.
    /// @return _id Id of integration
    function addIntegration(string memory _hash_integration,string memory _hash_integration_approve,
     address payable _account, uint256 amount_integration,
     uint256 amount_approve, bytes32[] memory groups,bytes32 group_for_vote, uint256 timestamp_inegration_approve)
    public
    onlyPost
    returns (uint256) {
        
        uint256 _id= governor.getSingleProposalIdByCID(_hash_integration);
        integrations.push(Integrations(_id,_hash_integration));
        totalNumber++;
        integrationIndexMap[_id] = integrations.length-1;
        integrationExistMap[_id] = true;
        bank.internaltransfer(_account,amount_integration);
        integration_approve.addIntegrationApprove(_hash_integration_approve,_account,amount_approve, groups,group_for_vote,timestamp_inegration_approve+1,timestamp_inegration_approve+1000);
        roles.setIntegrationTimestamp(group_for_vote,timestamp_inegration_approve);
        emit IntegrationAdded(true,"Integration added",amount_integration,_id);
        return _id;
    }

    /// @notice Total number of Integration.
    /// @dev Total number of Integration.
    /// @return totalNumber Total number of Integration
    function getTotalIntegrationsNumber()
    public
    view
    returns (uint256)  {
        return totalNumber;
    }

    /// @notice Update Integration.
    /// @dev Update Integration.
    /// @param id Id of Integration.
    /// @param _hash New IPFS CID.
    /// @return status Status of execution.
    function updateSingleIntegrationHash(uint id,string memory _hash)
    public
    onlyPost
    returns (bool) {
        require(integrationExistMap[id],"Proposal not exist");  
        integrations[integrationIndexMap[id]].ipfs_hash =_hash;
        emit IntegrationUpdated(true,"Integration updated",id);
        return true;
    }

    /// @notice Delete Integration.
    /// @dev Delete Integration.
    /// @param id Id of Integration.
    /// @return status Status of execution.
    function deleteSingleIntegration(uint id)
    public
    onlyPost
    returns (bool)
    {
        require(integrationExistMap[id],"Proposal not exist");    
            for(uint i = id; i < integrations.length-1; i++)
            {
                integrations[i] = integrations[i+1];      
            }
            integrations.pop();
            emit IntegrationDelete(true,"Inegration deleted",id);
            return true;       
    }

    /// @notice Get IPFS CID Integration.
    /// @dev Get IPFS CID Integration.
    /// @param id Id of Integration.
    /// @return CID IPFS CID.
    function getSingleIntegrationHash(uint256 id)
    public
    view
    returns (string memory) {
        require(integrationExistMap[id],"Proposal not exist"); 
        return integrations[integrationIndexMap[id]].ipfs_hash;
    }

    /// @notice Get all Integration.
    /// @dev Get all Integration.
    /// @return Integration Array of Struct integration.
    function getAllIntegrations()
    public
    view
    returns (Integrations[] memory) {
        return integrations;
    }

    /// @notice Get single Integration.
    /// @dev Get single Integration.
    /// @param id Id of Integration.
    /// @return Integration Struct of Integration.
    function getIntegration(uint256 id)
    public
    view
    returns (Integrations memory) {
        require(integrationExistMap[id],"Proposal not exist"); 
        return integrations[integrationIndexMap[id]];
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
    UsersGroups private roles;
    
    /// @notice address Bank Contract Owner.
    /// @dev address Bank Contract Owner.
    address payable private owner;

    uint private contractbalance;//contract value 
    uint private ownerbalance;
    uint private balanceto;

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

// SPDX-License-Identifier: MIT
//pragma solidity >=0.8.0 <0.9.0;
pragma solidity 0.8.12;
import "UsersGroups.sol";
import "Bank.sol";
import "GovernorContract.sol";

/// @title IntegrationApprove
/// @notice IntegrationApprove Contract stored Integration Approve.
/// @dev  IntegrationApprove Contract stored Integration Approve.
contract IntegrationApprove {

    /// @notice Total Number of Integration.
    /// @dev Total Number of Integration.
    uint256 private totalNumber=0;

    /// @notice Reference to UsersGroups contract.
    /// @dev Reference to UsersGroups contract.
    UsersGroups private roles;

    /// @notice Reference to Bank contract.
    /// @dev Reference to Bank contract.
    Bank private bank;

    /// @notice Reference to Governor contract.
    /// @dev Reference to Governor contract.
    GovernorContract private governor;

    /// @notice Event emmited when Integration Approve is added.
    /// @dev Event emmited when Integration Approve is added.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveAdded(bool status,string message,uint id);

    /// @notice Event emmited when Integration Approve is approved by user.
    /// @dev Event emmited when Integration Approve is approved by user.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveApproved(bool status,string message,uint id);

    /// @notice Event emmited when Integration Approve is updated.
    /// @dev Event emmited when Integration Approve is updated.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveUpdated(bool status,string message,uint id);

    /// @notice Event emmited when Integration Approve is approved by one user group required group.
    /// @dev Event emmited when Integration Approve is approved by one user group required group.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    /// @return group Group confirmed.
    /// @return confirmation_status Status of confirmation.
    event IntegrationApproveGroup(bool status,string message,uint id, bytes32 group, bool confirmation_status);

    /// @notice Event emmited when Integration Approve is executed.
    /// @dev Event emmited when Integration Approve is executed.
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveExecute(bool status,string message,uint id);

    /// @notice Event emmited when user send confirmation.
    /// @dev Event emmited when user send confirmation.
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return account ID of integraition approve.
    /// @return confirmation_status Status of confirmation.
    event IntegrationApproveUser(bool status,string message,address account, bool confirmation_status);

    /// @notice Structure of integration Approve.
    /// @dev Structure of integration Approve.
    /// @param status Status
    /// @param ipfs_hash IPFS CID of integration Approve
    /// @param to_user User to transfer money, when integration approve is confirmed.
    /// @param amount Amount of WEI to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Block for Start Confirmation Process
    /// @param block_end Block for End Confirmation Process
    /// @param confirmation_status Current Status
    struct IntegrationsApprove {
        uint256 id; // Proposal ID
        bool status; //if its blocked
        string ipfs_hash; // ipfs CID
        address payable to_user; // user transfer ether
        uint256 amount; // amoun to tranfer to that user
        bytes32[] groups; // groups should all confirm
        bytes32 group_for_vote; // group for vote on integration events
        uint256 block_start; // when start confirm
        uint256 block_end; // when stop confirm
        Confirmation confirmation_status;
    }

    /// @notice Structure of integration Approve Aggregate.
    /// @dev Structure of integration Approve Aggregate.
    /// @param status Status
    /// @param ipfs_hash IPFS CID of integration Approve
    /// @param to_user User to transfer money, when integration approve is confirmed.
    /// @param amount Amount of WEI to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Block for Start Confirmation Process
    /// @param block_end Block for End Confirmation Process
    /// @param confirmation_status Current Status
    /// @param hasConfirm If User Confrim Approve.
    struct IntegrationsApproveAggregate {
        uint256 id; // Proposal ID
        bool status; //if its blocked
        string ipfs_hash; // ipfs CID
        address payable to_user; // user transfer ether
        uint256 amount; // amoun to tranfer to that user
        bytes32[] groups; // groups should all confirm
        bytes32 group_for_vote; // group for vote on integration events
        uint256 block_start; // when start confirm
        uint256 block_end; // when stop confirm
        Confirmation confirmation_status;
        bool hasConfirm;
    }

    /// @notice Current status of confirmation.
    /// @dev Current status of confirmation.
    /// @common 123
    enum Confirmation {
        Pending,
        Confirmed,
        Execute,
        Defeted,
        Active,
        Waiting
    }

    /// @notice Constructor.
    /// @dev Constructor.
    /// @param roleContract Address UsersGroups contract
    /// @param bankContract Address Bank contract
    /// @param groups for future
    constructor (address roleContract,address payable bankContract,bytes32[] memory groups,address payable governorContract) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
        governor = GovernorContract(governorContract);

    }

    /// @notice Array of Integration Approve.
    /// @dev Array of Integration Approve.
    IntegrationsApprove[] private integrationsApprove;

    /// @notice map ID to index in array in integration Approve.
    /// @dev map ID to index in array in integration Approve.
    mapping(uint256 => uint256) integrationIndexMap;

    /// @notice map ID to status if exist.
    /// @dev map ID to status if exist.
    mapping(uint256 => bool) integrationExistMap;

    /// @notice mapping id of integration approve to group and bool; //true - confirmed
    /// @dev mapping id of integration approve to group and bool; //true - confirmed
    mapping(uint256 => mapping(bytes32 => bool)) groupStatusMap; //mapping id of integration approve to group and bool; //true - confirmed
    
    /// @notice mapping id of integration approve to user and bool; //true - confirmed
    /// @dev mapping id of integration approve to user and bool; //true - confirmed
    mapping(uint256 => mapping(address => bool)) userStatusMap; //mapping id of integration approve to user and bool; //true - confirmed
    
    /// @notice mapping  of integration approve to its approved status.
    /// @dev mapping  of integration approve to its approved status.
    mapping(uint256 => bool) groupApprovedMap; // mapping  of integration approve to its status
    
    /// @notice mapping  of integration approve to its excution status.
    /// @dev mapping  of integration approve to its excution status.
    mapping(uint256 => bool) groupApprovedExecutionMap; // mapping  of integration approve to its status

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    modifier onlyIntegration()
    {
        require(roles.isIntegration(msg.sender), "Restricted to integration contract.");
        _;
    }

    /// @notice Add integration approve.
    /// @dev Add integration approve.
    /// @param _hash CID IPFS to integration Approve
    /// @param _account Account to transfer WEI, when integration approve is confirmed
    /// @param amount Amount USD to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Timestamp of Start Confirmation Process
    /// @param block_end Timestamp of Emd Confirmation Process
    /// @return integratipnApproveID ID of integration Approve
    function addIntegrationApprove(string memory _hash, address payable _account, uint256 amount, bytes32[] memory groups,bytes32 group_for_vote,uint256 block_start,uint256 block_end)
    public
    onlyIntegration
    returns (uint256) {
        
        
        uint256 _id= governor.getSingleProposalIdByCID(_hash);
        integrationsApprove.push(IntegrationsApprove(_id,false,_hash,_account,amount,groups,group_for_vote,block_start,block_end,Confirmation.Pending));
        totalNumber++;
        integrationIndexMap[_id] = integrationsApprove.length -1;
        groupApprovedExecutionMap[_id] = false;
        integrationExistMap[_id] = true;
        for(uint256 i=0;i<groups.length;i++){
            groupStatusMap[_id][groups[i]] = false;
        }
        emit IntegrationApproveAdded(true,"IntegrationApprove added",_id);
        return _id;
    }

    /// @notice Update IPFS CID.
    /// @dev Update IPFS CID.
    /// @param _id ID Integration Approve
    /// @param _hash New IPFS CID
    function updateHash(uint _id,string memory _hash)
    public
    onlyMember {
        require(integrationExistMap[_id],"Proposal not exist");
        if(integrationsApprove[integrationIndexMap[_id]].status== false)
        {
            integrationsApprove[integrationIndexMap[_id]].status== true;
            integrationsApprove[integrationIndexMap[_id]].ipfs_hash = _hash;
            emit IntegrationApproveUpdated(true,"IntegrationApproved updated",_id);
            integrationsApprove[integrationIndexMap[_id]].status== false;
        }
        else
        {
            emit IntegrationApproveUpdated(false,"IntegrationApproved update blocked by other task.",_id);
        }
    }

    /// @notice Get Total Integration Approve.
    /// @dev Get Total Integration Approve.
    /// @return count Count oF Integration Approve
    function getTotalIntegrationsNumber()
    public
    view
    returns (uint256)  {
        return totalNumber;
    }

    /// @notice Get Integration Approve By ID.
    /// @dev Get Integration Approve By ID.
    /// @param _id Integration Approve ID 
    /// @return struct of Integration
    function getIntegration(uint256 _id)
    public
    view
    returns (IntegrationsApprove memory)  {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]];
    }

    /// @notice Get Integration Approve CID IPFS.
    /// @dev Get Integration Approve CID IPFS.
    /// @param _id ID of Integration Approve
    /// @return cid_ipfs IPFS CID
    function getIntegrationHash(uint256 _id)
    public
    view
    returns (string memory) {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]].ipfs_hash;
    }

    /// @notice Get All Integration Approve.
    /// @dev Get All Integration Approve.
    /// @return list [] Array of Struct integration Approve.
    function getAllIntegrations()
    public
    view
    returns (IntegrationsApprove[] memory) {
        return integrationsApprove;
    }

    /// @notice Get Groups for Integration Approve.
    /// @dev Get Groups for Integration Approve.
    /// @param _id ID of Integration Approve.
    /// @return array Array fo Groups Names.
    function getGroupsAll(uint256 _id)
    public
    view
    returns (bytes32[] memory) {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]].groups;
    }

    /// @notice Validate if Inetgration Approve Exist.
    /// @dev Validate if Inetgration Approve Exist.
    /// @param _id ID of Integration Approve.
    /// @return status Status of Integration Approve.
    function ifIntegrationExist(uint256 _id)
    public
    view
    returns (bool) {
        return integrationExistMap[_id];
    }

    /// @notice Get Process status - not use, because of bug.
    /// @dev Get Process status - not use, because of bug.
    /// @param _id ID of Integration Approve.
    /// @return status Status of Integration Approve.
    function getProcessStatus(uint256 _id)
    public
    view
    returns (Confirmation) {
        require(integrationExistMap[_id],"Proposal not exist");
        return integrationsApprove[integrationIndexMap[_id]].confirmation_status;
    }

    /// @notice Validate if confirmation is in progress.
    /// @dev Validate if confirmation is in progress.
    /// @param _id ID of Integration Approve.
    /// @return status Status of Integration Approve.
    function getConfirmStatus(uint256 _id)
    public
    view
    returns (Confirmation) {
        require(integrationExistMap[_id],"Proposal not exist");
        if( block.timestamp < integrationsApprove[integrationIndexMap[_id]].block_start){
            return Confirmation.Pending;
        }
        if( block.timestamp >= integrationsApprove[integrationIndexMap[_id]].block_start && block.timestamp <=integrationsApprove[integrationIndexMap[_id]].block_end )
        {
            return Confirmation.Active;
        }
        if( integrationsApprove[integrationIndexMap[_id]].confirmation_status == Confirmation.Execute)
        {
            return Confirmation.Execute;
        }
        if( integrationsApprove[integrationIndexMap[_id]].confirmation_status == Confirmation.Defeted)
        {
            return Confirmation.Defeted;
        }
        if( integrationsApprove[integrationIndexMap[_id]].confirmation_status == Confirmation.Confirmed)
        {
            return Confirmation.Confirmed;
        }
        return Confirmation.Waiting;
    }

    /// @notice Validate if group is confirmed.
    /// @dev Validate if group is confirmed.
    /// @param _id ID of Integration Approve.
    /// @param _group Group name.
    /// @return status Status of confirmation.
    function ifGroupConfirmed(uint256 _id,bytes32 _group)
    public
    view
    returns (bool) {
        require(integrationExistMap[_id],"Proposal not exist");
        return groupStatusMap[_id][_group];
        //return groupStatusMap[0][integrationsApprove[0].groups[0]];
    }
    
    /// @notice Confirm Integration Approve by Group.
    /// @dev Confirm Integration Approve by Group.
    /// @param _id ID of Integration Approve.
    /// @param _group Group name.
    /// @param status True - For, False - Against.
    /// @return status Status of execution.
    function setGroupMap(uint256 _id,bytes32 _group,bool status)
    public
    
    onlyMember
    returns (bool) {

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveGroup(false,"Integration not exist.",_id,_group,status);
            return false;
        }
        
        if(ifGroup(_id, _group))
        {
            if(getConfirmStatus(_id) != Confirmation.Active)
            {
                emit IntegrationApproveGroup(false,"Confirmation not ready.",_id,_group,status);
                return false;
            }

            if(!roles.isRole(msg.sender, _group)){
                emit IntegrationApproveGroup(false,"User is not in required group.",_id,_group,status);
                return false;
            }

            groupStatusMap[_id][_group] = status;
            emit IntegrationApproveGroup(true,"Group was changed",_id,_group,status);
            return true;
        }
        else
        {
            //walidate if one from given group, who should vote can vote
            emit IntegrationApproveGroup(false,"This group not exist for this IntegrationApprove.",_id,_group,status);
            return false;
        }    
    }

    /// @notice Execute Integration Approve by User.
    /// @dev Execute Integration Approve by User.
    /// @param _id ID of Integration Approve.
    /// @return status Status of execution.
    function execute(uint256 _id)
    public
    onlyMember
    returns (bool){

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveExecute(false,"Integration not exist.",_id);
            return false;
        }

        if(block.timestamp > integrationsApprove[integrationIndexMap[_id]].block_end && block.timestamp > integrationsApprove[integrationIndexMap[_id]].block_start)
        {  
            if(groupApprovedExecutionMap[_id]){
                emit IntegrationApproveExecute(false,"Approve already executed.",_id);
                return false;
            }
            
            for(uint i=0; i<integrationsApprove[integrationIndexMap[_id]].groups.length;i++){            
                if(groupStatusMap[_id][integrationsApprove[integrationIndexMap[_id]].groups[i]] == false)            
                {         
                    groupApprovedExecutionMap[_id] = true;  
                    integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Defeted;     
                    emit IntegrationApproveExecute(false,"Not all group approved.",_id);
                    return false;
                
                }            
            }

            address[] memory users = roles.getUsersInGroup(integrationsApprove[integrationIndexMap[_id]].group_for_vote);
            //emit IntegrationApproveExecute(false,"Members",users.length);
            uint256 confirmed_Status = 0;

            for(uint i=0; i<users.length;i++){          
                if(userStatusMap[_id][users[i]] == true)            
                {                
                    confirmed_Status=confirmed_Status+1;
                }            
            }

            if((confirmed_Status *100)/(users.length) < 50)
            {
                groupApprovedExecutionMap[_id] = true;
                integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Defeted;
                emit IntegrationApproveExecute(false,"Required number of users not confirmed this approve.",confirmed_Status*100/users.length);
                return false;
            }

            groupApprovedExecutionMap[_id] = true;
            integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Confirmed;
            bank.internaltransfer(integrationsApprove[integrationIndexMap[_id]].to_user,integrationsApprove[integrationIndexMap[_id]].amount);
            //integrationsApprove[_id].amount
            emit IntegrationApproveExecute(true,"Execute completed.",_id);
            return true;
        }
        else
        {
            emit IntegrationApproveExecute(false,"Confirmation in not ended.",_id);
            return false;
        }
    }
    
    /// @notice Validate if group exist in list of groups for this integration.
    /// @dev Validate if group exist in list of groups for this integration.
    /// @param _id ID of Integration Approve.
    /// @param group Group Name.
    /// @return status Status of execution.
    function ifGroup(uint256 _id,bytes32 group)
    public
    view
    returns (bool) {
        if( !integrationExistMap[_id])
        {
            return false;
        }
        for(uint i=0; i<integrationsApprove[integrationIndexMap[_id]].groups.length;i++){
            if(integrationsApprove[integrationIndexMap[_id]].groups[i] == group)
            {
                return true;
            }
        }
        return false;
    }

    /// @notice Get if User is confirm application approve.
    /// @dev Get if User is confirm application approve.
    /// @param _id ID of Integration Approve.
    /// @param _user Group Name.
    /// @return status Status of execution.
    function ifUserConfirmed(uint256 _id,address _user)
    public
    view
    returns (bool) {
        require(integrationExistMap[_id],"Proposal not exist");
        return userStatusMap[_id][_user];
        //return groupStatusMap[0][integrationsApprove[0].groups[0]];
    }

    /// @notice Confirm Integration Approve by user.
    /// @dev Confirm Integration Approve by user.
    /// @param _id ID of Integration Approve.
    /// @param status True - yes, False - no
    /// @return status Status of execution.
    function setConfirmUser(uint256 _id,bool status)
    public
    onlyMember
    returns (bool) {

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveUser(false,"Integration not exist.",msg.sender,status);
            return false;
        }
        
            if(getConfirmStatus(_id) != Confirmation.Active)
            {
                emit IntegrationApproveUser(false,"Confirmation not ready.",msg.sender,status);
                return false;
            }

            if(!roles.isRole(msg.sender, integrationsApprove[integrationIndexMap[_id]].group_for_vote)){
                 emit IntegrationApproveUser(false,"User is not in required group for confirmation.",msg.sender,status);
                return false;
            }

            userStatusMap[_id][msg.sender] = status;
            emit IntegrationApproveUser(true,"User was changed",msg.sender,status);
            return true;
        
    }

    /// @notice Get Aggregate Info of Integration Approve.
    /// @dev Get Aggregate Info of Integration Approve.
    /// @return list List of Aggregation Appprove.
    /// , _id Proposal ID.
    /// , status Status.
    /// , ipfs_hash IPFS CID of integration Approve.
    /// , to_user User to transfer money, when integration approve is confirmed.
    /// , amount Amount of WEI to transfer.
    /// , groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// , group_for_vote Group for users, who can confirm.
    /// , block_start Block for Start Confirmation Process.
    /// , block_end Block for End Confirmation Process.
    /// , confirmation_status Current Status.
    /// , hasConfirm If User Confrim Approve.
    function getAllIntegrationAggregate()
    public
    view
    returns (IntegrationsApproveAggregate[] memory) {
        IntegrationsApproveAggregate[] memory  integration_aggregate = new IntegrationsApproveAggregate[](integrationsApprove.length);
        for(uint256 i=0; i<integrationsApprove.length;i++){
            integration_aggregate[i].id = integrationsApprove[i].id;
            integration_aggregate[i].status = integrationsApprove[i].status;
            integration_aggregate[i].ipfs_hash = integrationsApprove[i].ipfs_hash;
            integration_aggregate[i].to_user = integrationsApprove[i].to_user;
            integration_aggregate[i].amount = integrationsApprove[i].amount;
            integration_aggregate[i].groups = integrationsApprove[i].groups;
            integration_aggregate[i].group_for_vote = integrationsApprove[i].group_for_vote;
            integration_aggregate[i].block_start = integrationsApprove[i].block_start;
            integration_aggregate[i].block_end = integrationsApprove[i].block_end;
            integration_aggregate[i].confirmation_status = getConfirmStatus(integrationsApprove[i].id);
            integration_aggregate[i].hasConfirm =ifUserConfirmed(integrationsApprove[i].id, msg.sender);
        }

        return integration_aggregate;
    }


    /// @notice Get Aggregate Info of Integration Approve Single.
    /// @dev Get Aggregate Info of Integration Approve Single.
    /// @param _id ID of Integration Approve.
    /// @return list List of Aggregation Appprove.
    /// , _id Proposal ID.
    /// , status Status.
    /// , ipfs_hash IPFS CID of integration Approve.
    /// , to_user User to transfer money, when integration approve is confirmed.
    /// , amount Amount of WEI to transfer.
    /// , groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// , group_for_vote Group for users, who can confirm.
    /// , block_start Block for Start Confirmation Process.
    /// , block_end Block for End Confirmation Process.
    /// , confirmation_status Current Status.
    /// , hasConfirm If User Confrim Approve.
    function getSingleIntegrationAggregate(uint256 _id)
    public
    view
    returns (IntegrationsApproveAggregate memory) {
        IntegrationsApproveAggregate memory  integration_aggregate = IntegrationsApproveAggregate(
            _id,
            integrationsApprove[integrationIndexMap[_id]].status,
            integrationsApprove[integrationIndexMap[_id]].ipfs_hash,
            integrationsApprove[integrationIndexMap[_id]].to_user,
            integrationsApprove[integrationIndexMap[_id]].amount,
            integrationsApprove[integrationIndexMap[_id]].groups,
            integrationsApprove[integrationIndexMap[_id]].group_for_vote,
            integrationsApprove[integrationIndexMap[_id]].block_start,
            integrationsApprove[integrationIndexMap[_id]].block_end,
            getConfirmStatus(_id),
            ifUserConfirmed(_id,msg.sender)
            );

        return integration_aggregate;
    }

    /// @notice Set Timestamp for start and end.
    /// @dev Set Timestamp for start and end.
    /// @param _id ID of Integration Approve.
    /// @param timestamp_start Timestam start vote.
    /// @param timestamp_end Timestamp stop vote.
    /// @return status Status of execution
    /// @return message Message of execution
    function setIntegrationApproveTimestamp(uint256 _id,uint256 timestamp_start, uint256 timestamp_end)
    public
    returns (bool,string memory,Confirmation) {

        Confirmation status = getConfirmStatus(_id);

        if(timestamp_start > timestamp_end)
        {
            return (false,"Start timestamp is grather than end timestamp.",status);
        }

        if(timestamp_start < block.timestamp)
        {
            return (false,"Start timestamp is lower than current block timestamp.",status);
        }

        if(getConfirmStatus(_id) != Confirmation.Pending)
        {
            return (false,"You can only change timestamp, before vote is started.",status);
        }

        integrationsApprove[integrationIndexMap[_id]].block_start = timestamp_start;
        integrationsApprove[integrationIndexMap[_id]].block_end = timestamp_end;
        return (true,"New timestamp is set.",status);
    }
        

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "Governor.sol";
import "GovernorCountingSimple.sol";
import "GovernorVotes.sol";
import "GovernorVotesQuorumFraction.sol";
import "GovernorTimelockControl.sol";

import "UsersGroups.sol";

/// @title GovernorContract
/// @notice GovernorContract implementation from openzeppelin
/// @dev GovernorContract implementation from openzeppelin
contract GovernorContract is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /// @notice Delay before voting shoud start.
    /// @dev Delay before voting shoud start.
    uint256 public s_votingDelay;

    /// @notice Voting period.
    /// @dev Voting period.
    uint256 public s_votingPeriod;

    /// @notice Reference to UsersGroups contract.
    /// @dev Reference to UsersGroups contract.
    UsersGroups roles;

    /// @notice Structure of single proposal.
    /// @dev Structure of single proposal.
    /// @param proposalID Proposal ID.
    /// @param hash IPFS CID of Proposal.
    /// @param typ Proposal Type: 0 - blog, 1 - integration.
    /// @param owner Accout sended Proposal.
    /// @param groups group for Vote on proposal.
    struct Proposal {
        uint256 proposalID;
        string hash;
        uint8 typ;
        address owner;
        bytes32 groups;
    }

    /// @notice Structure of single proposal with aggregate data.
    /// @dev Structure of single proposal with aggregate data.
    /// @param proposalID Proposal ID.
    /// @param hash IPFS CID of Proposal.
    /// @param typ Proposal Type: 0 - blog, 1 - integration.
    /// @param owner Accout sended Proposal.
    /// @param groups group for Vote on proposal.
    /// @param state Proposal State.
    /// @param votes_for - Number of tokens voted  "for".
    /// @param votes_against - Number of tokens voted  "agains".
    /// @param quorum - Number of tokens needed to quorum. It is sum of voting power, beforere vote is stated, form all accounts * 0.5.
    /// @param hasVoted - If user voted for this proposal.
    /// @param hasVoteproposalSnapshotd - Block Start for voting.
    /// @param proposalDeadline - Block End for voting.
    /// @param getVotes - Voting power of account on block, when voting is started.
    struct ProposalAggregate {
        uint256 proposalID;
        string hash;
        uint8 typ;
        address owner;
        bytes32 groups;
        Governor.ProposalState state;
        uint256 votes_for;
        uint256 votes_against;
        uint256 quorumPerGroup;
        bool hasVoted;
        uint256 proposalSnapshot;
        uint256 proposalDeadline;
        uint256 getVotes;
    }

    /// @notice Proposal list.
    /// @dev Proposal list.
    Proposal[] public proposals;

    /// @notice Mapping proposalID to status if exist.
    /// @dev Mapping proposalID to status if exist.
    mapping(uint256 => bool) proposalsMap;

    /// @notice Mapping proposal ID to index in array of Proposals.
    /// @dev Mapping proposal ID to index in array of Proposals.
    mapping(uint256 => uint256) proposalsIndexMap;

    /// @notice Total number of proposals.
    /// @dev Total number of proposals.
    uint256 numberOfProposals = 0;

    /// @notice Event emmited when proposal is added.
    /// @dev Event emmited when proposal is added.
    /// @return status True/False - status of excution
    /// @return proposalID Proposal ID
    /// @return message Information with Error or Successfull execution.
    event ProposalAdd(bool status, uint256 proposalID, string message);

    /// @notice Event emmited when proposal is updated.
    /// @dev Event emmited when proposal is updated.
    /// @return status True/False - status of excution.
    /// @return proposalID Proposal ID.
    /// @return message Information with Error or Successfull execution.
    event ProposalUpdated(bool status, uint256 proposalID, string message);

    /// @notice Event emmited when user is voted.
    /// @dev Event emmited when user is voted.
    /// @return status True/False - status of excution.
    /// @return proposalID Proposal ID.
    /// @return message Information with Error or Successfull execution.
    event GCVote(bool status,string message, address account);

    /// @notice Event emmited when proposal is added.
    /// @dev Event emmited when proposal is added.
    /// @return status True/False - status of excution.
    /// @return proposalID Proposal ID.
    /// @return message Information with Error or Successfull execution.
    event GCPropose(bool status,string message, address account);


    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins .");
        _;
    }

    /// @notice Constructor.
    /// @dev Constructor.
    /// @param _token Address of Governance Token Contract.
    /// @param _timelock Address of Time Locker Contract .
    /// @param _quorumPercentage Qourum.
    /// @param _votingPeriod Voting period.
    /// @param _votingDelay Voting delay.
    /// @param roleContract Address of UsersGroups Contract.
    constructor(
        ERC20Votes _token,
        TimelockController _timelock,
        uint256 _quorumPercentage,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        address roleContract
    )
        Governor("GovernorContract")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
        GovernorTimelockControl(_timelock)
    {
        
        s_votingDelay = _votingDelay;
        s_votingPeriod = _votingPeriod;
        roles = UsersGroups(roleContract);
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    /// @notice Get voting delay.
    /// @dev Get voting delay.
    /// @return s_votingDelay Voting delay.
    function votingDelay() public view override returns (uint256) {
        return s_votingDelay; // 1 = 1 block
    }

    /// @notice Get voting period.
    /// @dev Get voting period.
    /// @return s_votingPeriod Voting period.
    function votingPeriod() public view override returns (uint256) {
        return s_votingPeriod; // 45818 = 1 week
    }

    /// @notice Calculate All Tokens at start of voting.
    /// @dev Calculate All Tokens at start of voting.
    /// @return status Amount of tokens per group.   
    function TokensPerGroup(uint256 proposalId) public view  
    returns (uint256) {

        uint256 blockNumber = proposalSnapshot(proposalId);
        bytes32 group = proposals[proposalsIndexMap[proposalId]].groups;
        address [] memory members = roles.getUsersInGroup(group);

        uint256 totalSupply = 0;
        for (uint8 i=0; i< members.length;i++){
            totalSupply = totalSupply + getVotes(members[i],blockNumber);
        }

        return totalSupply;

    }

    /// @notice Calculate quorum for group - sum of tokens for memebers * quorumNumerator/quorumDenumerator, when vote is starting.
    /// @dev Calculate quorum for group - sum of tokens for memebers * quorumNumerator/quorumDenumerator, when vote is starting.
    /// @return quorum Quorum per group.(0-100%)
    function quorumPerGroup(uint256 proposalId) public view  
    returns (uint256) {

        return TokensPerGroup(proposalId) * quorumNumerator() / quorumDenominator();

    }

    /// @notice Override validate quorum needed per group, it is members token, when vote is starting;
    /// @dev Override validate quorum needed per group, it is members token, when vote is starting;
    /// @return status Status of execution.
    function _quorumReached(uint256 proposalId) internal view  
    override(Governor,GovernorCountingSimple) 
    returns (bool) {
        (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        ) = proposalVotes(proposalId);

        return quorumPerGroup(proposalId) <= forVotes + abstainVotes;

        //return quorum(proposalSnapshot(proposalId)) <= forVotes + abstainVotes;
    }


    /// @notice Get quorum.
    /// @dev Get quorum.
    /// @param blockNumber - block number for validate quorum.
    /// @return quorum Quorum.
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    
    }

    /// @notice Get votes for account on block(number of tokens).
    /// @dev Get votes for account on block(number of tokens).
    /// @param account Account.
    /// @param blockNumber Block number for validate vote.
    /// @return number_of_tokens  Number of tokens voted in blockNumber in format: (against,for,not interested).
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotes)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /// @notice Get status of proposal ID.
    /// @dev Get status of proposal ID.
    /// @param proposalId Proposal ID.
    /// @return state Status of proposal.
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @notice Add proposal.
    /// @dev Add proposal.
    /// @param targets addrees for execute.
    /// @param values amount to transfer.
    /// @param calldatas encoded function with arg to execute.
    /// @param description Proposal Description.
    /// @return proposalID Proposal ID.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        
        return super.propose(targets, values, calldatas, description);
    }

     /// @notice Add proposal for Blog.
    /// @dev Add proposal for Blog.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas Encoded function with arg to execute.
    /// @param description Proposal Description.
    /// @param group Group for integration.
    /// @param owner Accout sended this Proposal.
    /// @param hash_ipfs_proposal CID IPFS Proposal.
    /// @param _typ_proposal Proposal type: 0 - Blog, 1 - Integration.
    function proposeBlog(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        bytes32 group,
        address owner,
        string memory hash_ipfs_proposal,
        uint8 _typ_proposal
    )
    public
    onlyMember 
    returns (bool) {
        uint256 proposalID = super.propose(targets, values, calldatas, description);

        if(!proposalsMap[proposalID]){
                proposals.push(Proposal(proposalID, hash_ipfs_proposal,_typ_proposal,owner,group));
                proposalsMap[proposalID]=true;
                proposalsIndexMap[proposalID] = numberOfProposals;
                numberOfProposals++;
                emit ProposalAdd(true,proposalID,"Proposall added.");
                return true;
        }
        else
        {
            emit ProposalAdd(false,proposalID,"Proposall exist.");
            return false;
        }
    }
    
    /// @notice Add proposal for Integration.
    /// @dev Add proposal for Integration.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas encoded function with arg to execute.
    /// @param description Proposal Description.
    /// @param group Group for integration.
    /// @param owner Accout sended this Proposal.
    /// @param future_integration_timestamp Timestamp, when Integration will be.
    /// @param integration_budget Budget in USD for integration.
    /// @param hash_ipfs_proposal Proposal CID IPFS.
    /// @param _typ_proposal Proposal type: 0 - Blog, 1 - Integration.
    /// @return status True if Added, False if Not Added.
    function proposeIntegration(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        bytes32 group,
        address owner,
        uint256 future_integration_timestamp,
        uint256 integration_budget,
        string memory hash_ipfs_proposal,
        uint8 _typ_proposal
    )
    public
    onlyMember 
    returns (bool) {
        //uint256 proposalID = super.propose(targets, values, calldatas, description);
        for(uint i=0;i<proposals.length; i++){
            if( proposals[i].groups == group){
                uint256 last_block = this.proposalDeadline(proposals[i].proposalID);
                if(last_block > block.number)
                {
                    emit ProposalAdd(false,0,"For group exist another proposal with status active pr pending.");
                    return false;
                }
                ProposalState st = state(proposals[i].proposalID);
                if(st == ProposalState.Succeeded)
                {
                    emit ProposalAdd(false,0,"For group exist another proposal with status Succeeded.");
                    return false;
                }
                if(st == ProposalState.Queued)
                {
                    emit ProposalAdd(false,0,"For group exist another proposal with status Queued.");
                    return false;
                }
            }

        }
        
        uint256 proposalId = uint256(keccak256(abi.encode(targets, values, calldatas, keccak256(bytes(description)))));
        //uint256 proposalID = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        if(!proposalsMap[proposalId]){
            bool status = roles.groupCalculate(group,future_integration_timestamp,integration_budget);
            if(status)
            {
                uint256 proposalID = super.propose(targets, values, calldatas, description);
                proposals.push(Proposal(proposalID, hash_ipfs_proposal,_typ_proposal,owner,group));
                proposalsMap[proposalID]=true;
                proposalsIndexMap[proposalID] = numberOfProposals;
                numberOfProposals++;
                emit ProposalAdd(true,proposalID,"Proposall added.");
                //emit ProposalAdd(true,proposalId,"Proposall added.");
                return true;
            }
            else
            {
                emit ProposalAdd(false,0,"Problem with budget.");
                return false;
            }
        }
        else
        {
            emit ProposalAdd(false,proposalId,"Proposall exist.");
            return false;
        }
    }
    
    /// @notice Execute proposal.
    /// @dev Execute proposal.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas Encoded function with arg to execute.
    /// @param descriptionHash Proposal Description.
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /// @notice Cancel proposal.
    /// @dev Cancel proposal.
    /// @param targets Addrees for execute.
    /// @param values Amount to transfer.
    /// @param calldatas encoded Function with arg to execute.
    /// @param descriptionHash Proposal Description.
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    /// @notice Vote for Proposal with Reason.
    /// @dev Vote for Proposal with Reason.
    /// @param proposalID Proposal ID.
    /// @param support Vote: 0 - agains, 1 - for, 2 - Another. 
    /// @param reason Reason For Vote.
    function castVoteWithReason(
        uint256 proposalID, 
        uint8 support, 
        string calldata reason
    )
        public override(Governor,IGovernor)
        returns (uint256)
    {
        bytes32 group = proposals[proposalsIndexMap[proposalID]].groups;
        address owner = proposals[proposalsIndexMap[proposalID]].owner;

        bool ifUserIsInGroup = roles.isRole(msg.sender, group);

        if(msg.sender == owner){
            emit GCVote(false, "Owner can't vote!", msg.sender);
            return 0;  
        }

        if(!ifUserIsInGroup)
        {
            emit GCVote(false, "User don'h have permissions to vote!", msg.sender);  
            return 0;
        }

        emit GCVote(true, "User has permissions to vote!", msg.sender);
        return super.castVoteWithReason(proposalID,support,reason);
    }

    /// @notice Vote for Proposal with Reason.
    /// @dev Vote for Proposal with Reason.
    /// @param proposalID Proposal ID.
    /// @param support Vote: 0 - agains, 1 - for, 2 - Another. 
    function castVote(
        uint256 proposalID, 
        uint8 support
    )
        public override(Governor,IGovernor)
        returns (uint256)
    {
        bytes32 group = proposals[proposalsIndexMap[proposalID]].groups;
        address owner = proposals[proposalsIndexMap[proposalID]].owner;

        bool ifUserIsInGroup = roles.isRole(msg.sender, group);

        if(msg.sender == owner){
            emit GCVote(false, "Owner can't vote!", msg.sender);
            return 0;  
        }

        if(!ifUserIsInGroup)
        {
            emit GCVote(false, "User don'h have permissions to vote!", msg.sender);  
            return 0;
        }

        emit GCVote(true, "User has permissions to vote!", msg.sender);
        return super.castVote(proposalID,support);
    }

    /// @notice Update Quorum.
    /// @dev Update Quorum.
    /// @param newQuorumNumerator Quorum numberator
    function updateQuorumNumerator(
        uint256 newQuorumNumerator
    )
        
        public
        override(GovernorVotesQuorumFraction)
    {
        return super._updateQuorumNumerator(newQuorumNumerator);
    }

    /// @notice Update Voting Delay
    /// @dev Update Voting Delay
    /// @param _votingDelay Number of Block
    function updateVotingDelay(
        uint256 _votingDelay
    )
        public
        onlyAdmin
    {
        s_votingDelay = _votingDelay;
    }

    /// @notice Update Voting Period
    /// @dev Update Voting Period
    /// @param _votingPeriod Number of Block
    function updateVotingPeriod(
        uint256 _votingPeriod
    )
        public
        onlyAdmin
    {
        s_votingPeriod = _votingPeriod;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Update IPFS CID of Proposal.
    /// @dev Update IPFS CID of Proposal.
    /// @param proposalID Proposal ID.
    /// @param _hash IPFS CID.
    /// @return status True/False - status of update.
    function updateSingleProposalHash(uint256 proposalID,string memory _hash)
    public
    onlyMember 
    returns (bool){
        if(proposalsMap[proposalID]){
            proposals[proposalsIndexMap[proposalID]].hash = _hash ;
            emit ProposalUpdated(true,proposalID,"Proposall updated.");
            return true;
        }
        else
        {
            emit ProposalUpdated(false,proposalID,"Proposall not exist.");
            return false;
        }
    }


    /// @notice Get Single Proposal Data.
    /// @dev Get Single Proposal Data.
    /// @param proposalID Proposal ID.
    /// @return proposal [hash,type,owner,groups] Get Structure of single Proposal.
    function getSingleProposal(uint256 proposalID)
    public
    view
    returns (string memory,uint8,address,bytes32) {
        require(proposalsMap[proposalID],"Proposal not exist");
        return (proposals[proposalsIndexMap[proposalID]].hash,proposals[proposalsIndexMap[proposalID]].typ, proposals[proposalsIndexMap[proposalID]].owner,proposals[proposalsIndexMap[proposalID]].groups);
    }

    /// @notice Get Single Proposal Group for vote on this proposal.
    /// @dev Get Single Proposal Group for vote on this proposal.
    /// @param proposalID Proposal ID.
    /// @return groups Groups for vote on this proposal.
    function getSingleProposalGroup(uint256 proposalID)
    public
    view
    returns (bytes32) {
        require(proposalsMap[proposalID],"Proposal not exist");
        return (proposals[proposalsIndexMap[proposalID]].groups) ;
    }

    /// @notice Get Single Proposal Owner.
    /// @dev Get Single Proposal Owner.
    /// @param proposalID Proposal ID.
    /// @return groups Owner for this proposal.
    function getSingleProposalOwner(uint256 proposalID)
    public
    view
    returns (address) {
        require(proposalsMap[proposalID],"Proposal not exist");
        return (proposals[proposalsIndexMap[proposalID]].owner) ;
    }

    /// @notice Get All Proposals.
    /// @dev Get All Proposals.
    /// @return proposals List of proposals with elements[hash,type,owner,groups].
    function getAllProposals()
    public
    view
    returns (Proposal[] memory) {
        return proposals;
    }

    /// @notice Get Proposal ID by CID.
    /// @dev Get Single Proposal Owner.
    /// @param ipfs_CID Proposal ID.
    /// @return proposalID Proposal ID.
    function getSingleProposalIdByCID(string memory ipfs_CID)
    public
    view
    returns (uint256) {
        for(uint256 i=0;i<proposals.length;i++)
        {
            if(keccak256(abi.encodePacked(proposals[i].hash)) ==  keccak256(abi.encodePacked(ipfs_CID))){
                return proposals[i].proposalID;
            }
        }
        revert("Proposal not exist for this IPFS CID.");
    }

    /// @notice Get Aggregate Info for all Proposal.
    /// @dev Get Aggregate Info for all Proposal.
    /// @return list_of_aggregate List of aggregated data: 
    ///  proposalID Proposal ID.
    ///  hash IPFS CID of Proposal.
    ///  typ - Proposal Type: 0 - blog, 1 - integration.
    ///  owner - Accout sended Proposal.
    ///  groups group - for Vote on proposal.
    ///  state - Proposal State.
    ///  votes_for - Number of tokens voted  "for".
    ///  votes_against - Number of tokens voted  "agains".
    ///  quorumPerGroup - Number of tokens needed to quorum. It is sum of voting power, beforere vote is stated, form all accounts * 0.5.
    ///  hasVoted - If user voted for this proposal.
    ///  proposalSnapshot - Block Start for voting.
    ///  proposalDeadline - Block End for voting. 
    ///  getVotes - Voting power of account on block, when voting is started.
    function getAllProposalAggregate()
    public
    view
    returns (ProposalAggregate[] memory) {
        uint256 size = proposals.length;
        ProposalAggregate [] memory  proposal_aggregate = new ProposalAggregate[](size);
        string memory hash = "123";

        for(uint256 i=0;i<size;i++){
            proposal_aggregate[i].proposalID = proposals[i].proposalID;
            proposal_aggregate[i].hash = proposals[i].hash;
            proposal_aggregate[i].owner = proposals[i].owner;
            proposal_aggregate[i].groups = proposals[i].groups;
            proposal_aggregate[i].typ = proposals[i].typ;
            proposal_aggregate[i].state = state(proposals[i].proposalID);
            (proposal_aggregate[i].votes_for,proposal_aggregate[i].votes_against,) = proposalVotes(proposals[i].proposalID);
            proposal_aggregate[i].proposalDeadline =  proposalDeadline(proposals[i].proposalID);
            proposal_aggregate[i].proposalSnapshot = proposalSnapshot(proposals[i].proposalID);
            proposal_aggregate[i].hasVoted = hasVoted(proposals[i].proposalID,msg.sender);
            proposal_aggregate[i].quorumPerGroup = quorumPerGroup(proposals[i].proposalID);
            proposal_aggregate[i].getVotes = getVotes(msg.sender,proposalSnapshot(proposals[i].proposalID));
        }
        return proposal_aggregate;
    }

    /// @notice Get Aggregate Info for single proposal.
    /// @dev Get Aggregate Info for single proposal.
    /// @param proposalID Proposal ID.
    /// @return list_of_aggregate Aggregated data: 
    ///  proposalID Proposal ID.
    ///  hash IPFS CID of Proposal.
    ///  typ Proposal Type: 0 - blog, 1 - integration.
    ///  owner Accout sended Proposal.
    ///  groups group for Vote on proposal.
    ///  state Proposal State.
    ///  votes_for - Number of tokens voted  "for".
    ///  votes_against - Number of tokens voted  "agains".
    ///  quorumPerGroup - Number of tokens needed to quorum. It is sum of voting power, beforere vote is stated, form all accounts * 0.5.
    ///  hasVoted - If user voted for this proposal.
    ///  proposalSnapshot - Block Start for voting.
    ///  proposalDeadline - Block End for voting. 
    ///  getVotes - Voting power of account on block, when voting is started.
    function getSingleProposalAggregate(uint256 proposalID)
    public
    view
    returns (ProposalAggregate memory) {
        (uint256 votes_for,uint256 votes_against,) = proposalVotes(proposals[proposalsIndexMap[proposalID]].proposalID);
        ProposalAggregate memory  proposal_aggregate = ProposalAggregate(
            proposalID,
            proposals[proposalsIndexMap[proposalID]].hash,
            proposals[proposalsIndexMap[proposalID]].typ,
            proposals[proposalsIndexMap[proposalID]].owner,
            proposals[proposalsIndexMap[proposalID]].groups,
            state(proposalID),
            votes_for,
            votes_against,
            quorumPerGroup(proposalID),
            hasVoted(proposalID,msg.sender),
            proposalSnapshot(proposalID),
            proposalDeadline(proposalID),
            getVotes(msg.sender,proposalSnapshot(proposalID))
            );

        return proposal_aggregate;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/Governor.sol)

pragma solidity ^0.8.0;

import "ECDSA.sol";
import "draft-EIP712.sol";
import "ERC165.sol";
import "SafeCast.sol";
import "Address.sol";
import "Context.sol";
import "Timers.sol";
import "IGovernor.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {getVotes}
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract Governor is Context, ERC165, EIP712, IGovernor {
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    struct ProposalCore {
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    /**
     * @dev Restrict access to governor executing address. Some module might override the _executor function to make
     * sure this modifier is consistant with the execution model.
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_) EIP712(name_, version()) {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IGovernor).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * accross multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore memory proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.voteStart.getDeadline() >= block.number) {
            return ProposalState.Pending;
        } else if (proposal.voteEnd.getDeadline() >= block.number) {
            return ProposalState.Active;
        } else if (proposal.voteEnd.isExpired()) {
            return
                _quorumReached(proposalId) && _voteSucceeded(proposalId)
                    ? ProposalState.Succeeded
                    : ProposalState.Defeated;
        } else {
            revert("Governor: unknown proposal id");
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(msg.sender, block.number - 1) >= proposalThreshold(),
            "GovernorCompatibilityBravo: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _execute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overriden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = getVotes(account, proposal.voteStart.getDeadline());
        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight, reason);

        return weight;
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "ERC165.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor is IERC165 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast.
     *
     * Note: `support` values should be seen as buckets. There interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
     * quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "Governor.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimple is Governor {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "Governor.sol";
import "ERC20Votes.sol";
import "Math.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotes is Governor {
    ERC20Votes public immutable token;

    constructor(ERC20Votes tokenAddress) {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {IGovernor-getVotes}).
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "draft-ERC20Permit.sol";
import "Math.sol";
import "SafeCast.sol";
import "ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "draft-IERC20Permit.sol";
import "ERC20.sol";
import "draft-EIP712.sol";
import "ECDSA.sol";
import "Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "GovernorVotes.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFraction is GovernorVotes {
    uint256 private _quorumNumerator;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    constructor(uint256 quorumNumeratorValue) {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumerator;
    }

    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator()) / quorumDenominator();
    }

    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = _quorumNumerator;
        _quorumNumerator = newQuorumNumerator;

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "IGovernorTimelock.sol";
import "Governor.sol";
import "TimelockController.sol";

/**
 * @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
 * delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (an ideally the executor) roles for the {Governor} to work properly.
 *
 * Using this model means the proposal will be operated by the {TimelockController} and not by the {Governor}. Thus,
 * the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Governor} will be
 * inaccessible.
 *
 * _Available since v4.3._
 */
abstract contract GovernorTimelockControl is IGovernorTimelock, Governor {
    TimelockController private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    constructor(TimelockController timelockAddress) {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Governor) returns (bool) {
        return interfaceId == type(IGovernorTimelock).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overriden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId) public view virtual override(IGovernor, Governor) returns (ProposalState) {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(state(proposalId) == ProposalState.Succeeded, "Governor: proposal not successful");

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(targets, values, calldatas, 0, descriptionHash);
        _timelock.scheduleBatch(targets, values, calldatas, 0, descriptionHash, delay);

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overriden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(targets, values, calldatas, 0, descriptionHash);
    }

    /**
     * @dev Overriden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled and executed using the {Governor} workflow.
     */
    function updateTimelock(TimelockController newTimelock) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(TimelockController newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "IGovernor.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelock is IGovernor {
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "AccessControl.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}