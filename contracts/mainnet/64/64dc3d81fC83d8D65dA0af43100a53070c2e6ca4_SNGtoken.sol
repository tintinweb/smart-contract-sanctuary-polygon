/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract SNGtoken is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Synergy";
    string public symbol = "SNG";
    uint8 public decimals = 1;

    struct User{
        string name;
        address _address;
        uint256 balance;
        string role;
    }

    address public owner;
    bool private paused;

    address[] public users;
    address[] public managers;
    string[] public userNames;
    string[] public managerNames;
    mapping(address => string) public names;

    mapping(address => bool) public transactionPermission;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor ()  {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        paused = false;
    }

    //MODIFIERS
    modifier onlyOwner(){
        require(msg.sender == owner, "Ownable Function: caller is not the owner");
        _;
    }

    modifier onlyUsers(address _address) {
        require(transactionPermission[_address] == true, "transaction is not allowed");
        _;
    }

    modifier isPaused(){
        require(paused == false, "Contract is paused");
        _;
    }
   

    //OWNER MANAGEMENT FUNCTIONS
    function whoIsOwner() public view returns (address) {
        return owner;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //USER MANAGEMENT FUNCTIONS
    function addUser(string memory _userName, address _newUser) onlyOwner external {
        for(uint256 i = 0; i < users.length; i++){
            if(users[i] == _newUser){
                revert("this address is already added to users");
            }
        }
        users.push(_newUser);
        userNames.push(_userName);
        transactionPermission[_newUser] = true;
    }

    function removeUser(address _user) onlyOwner external{
        uint256 index = users.length;
        for(uint256 i = 0; i < users.length; i++){
            if(users[i] == _user){
                index = i;
                break;
            }
        }
        if(index == users.length){
            revert("this user does not exist");
        }
        for(uint256 i = index; i < users.length - 1; i++){
            users[i] = users[i+1];
            userNames[i] = userNames[i+1];
        }
        users.pop();
        userNames.pop();
        transactionPermission[_user] = false;
    }

    // MANAGER MANAGEMENT FUNCTIONS
    function addManager(string memory _managerName, address _newManager) onlyOwner external {
        for(uint256 i = 0; i < managers.length; i++){
            if(managers[i] == _newManager){
                revert("this address is already added to managers");
            }
        }
        managers.push(_newManager);
        managerNames.push(_managerName);
        transactionPermission[_newManager] = true;
    }

    function removeManager(address _manager) onlyOwner external{
        uint256 index = managers.length;
        for(uint256 i = 0; i < managers.length; i++){
            if(managers[i] == _manager){
                index = i;
                break;
            }
        }
        if(index == managers.length){
            revert("this manager does not exist");
        }
        for(uint256 i = index; i < managers.length - 1; i++){
            managers[i] = managers[i+1];
            managerNames[i] = managerNames[i+1];
        }
        managers.pop();
        managerNames.pop();
        transactionPermission[_manager] = false;
    }

    
    //TOKEN FUNCTIONS
    function transfer(address recipient, uint amount) onlyUsers(recipient) isPaused external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) onlyUsers(spender) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) onlyUsers(recipient) isPaused external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    //MINTING AND BURNING FUNCTIONS
    function monthlyMintforUsers(uint256 amount) onlyOwner external {
        for(uint256 i = 0; i < users.length ; i++){
            balanceOf[users[i]] += amount;
            emit Transfer(address(0), users[i], amount);
        }
        totalSupply += amount * users.length;
    }

    function monthlyResetforManagers(uint256 amount) onlyOwner external{
        uint256 managersSupply = 0;
        for(uint256 i = 0; i < managers.length ; i++){
            managersSupply += balanceOf[managers[i]];
            emit Transfer(managers[i], address(0), balanceOf[managers[i]]);
            balanceOf[managers[i]] = amount;
            emit Transfer(address(0), managers[i], amount);
        }
        totalSupply = totalSupply - managersSupply + (managers.length * amount);
    }

    function burn(address _address, uint256 amount) onlyOwner external {
        balanceOf[_address] -= amount;
        totalSupply -= amount;
        emit Transfer(_address, address(0), amount); 
    }

    //PAUSE AND UNPAUSE FUNCTIONS
    function pause() onlyOwner public{
        require(paused == false,"Contract is already paused");
        paused = true;
    }

    function unpause() onlyOwner public{
        require(paused == true,"Contract is not paused");
        paused = false;
    }
    
    //INFORMATION FUNCTIONS
    function showTotalSupply() public view returns(uint256){
        return totalSupply;
    }

    function showBalance(address _address) public view returns(uint256){
        return balanceOf[_address];
    }

    function usersList() public view returns(string[] memory nameList, address[] memory addressList, uint256[] memory balanceList, string[] memory roleList){
        address[] memory allAddresses = new address[](users.length+ managers.length);
        string[] memory allNames = new string[](users.length+ managers.length);
        uint256[] memory allBalances = new uint256[](users.length + managers.length);
        string[] memory allRoles = new string[](users.length+ managers.length);
        
        for(uint256 i = 0; i < users.length; i++){
            allAddresses[i] = users[i];
            allNames[i] = userNames[i];
            allBalances[i] = balanceOf[users[i]];
            allRoles[i] = "USER";
        }

        for(uint256 i = 0; i < managers.length; i++){
            allAddresses[users.length + i] = managers[i];
            allNames[users.length + i] = managerNames[i];
            allBalances[users.length + i] = balanceOf[managers[i]];
            allRoles[users.length + i] = "MANAGER";
        }
        return(allNames,allAddresses,allBalances,allRoles);

    }


}