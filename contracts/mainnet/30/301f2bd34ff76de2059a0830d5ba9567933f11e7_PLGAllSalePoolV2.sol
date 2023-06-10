/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }

    modifier forRole(string memory str) {
        require(checkpermit(msg.sender,str),"Permit Revert!");
        _;
    }
}

contract PLGAllSalePoolV2 is permission {
    
    address public owner;

    struct Users {
        uint256 balance;
        uint256 claimed;
    }

    uint256 public totalPaid;
    uint256 public totalStakedPLG;
    uint256 public totalRewardDeposit;

    mapping(address => Users) public user;

    IPLGFactory factory;

    bool locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
    }

    function addMaticReward() public payable returns (bool) {
        totalRewardDeposit += msg.value;
        return true;
    }

    function StakePLG(uint256 amount) public returns (bool) {
        IERC20(factory.getAddr("plg_token")).transferFrom(msg.sender,address(this),amount);
        totalStakedPLG += amount;
        user[msg.sender].balance += amount;
        return true;
    }

    function claimReward() public noReentrant() returns (bool) {
        uint256 claimAmount = getUnclaimReward(msg.sender);
        uint256 maxClaimed = getMaximumedClaim(msg.sender);
        if(user[msg.sender].claimed+claimAmount<maxClaimed){
        }else{
            if(user[msg.sender].claimed <= maxClaimed){
                claimAmount = maxClaimed - user[msg.sender].claimed;
            }
        }
        require(claimAmount>0,"Nothing For Claim!");
        totalPaid += claimAmount;
        user[msg.sender].claimed += claimAmount;
        (bool success,) = msg.sender.call{ value: claimAmount }("");
        require(success, "!fail to send eth");
        return success;
    }

    function getUnclaimReward(address account) public view returns (uint256) {
        uint256 AmongReward = user[account].balance * totalRewardDeposit / totalStakedPLG;
        if(AmongReward>user[account].claimed){
            uint256 reward = AmongReward - user[account].claimed;
            if(reward<address(this).balance){
                return reward;
            }else{
                return address(this).balance;
            }
        }return 0;

    }

    function getMaximumedClaim(address account) public view returns (uint256) {
        return user[account].balance * 250 / 100;
    }

    function updateAppStateWithPermit(uint256[] memory data) public forRole("permit") returns (bool) {
        totalPaid = data[0];
        totalStakedPLG = data[1];
        totalRewardDeposit = data[2];
        return true;
    }

    function updateUserWithPermit(address account, uint256[] memory data) public forRole("permit") returns (bool) {
        user[account].balance = data[0];
        user[account].balance = data[1];
        return true;
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function purgeToken(address token,uint256 amount) public forRole("owner") returns (bool) {
        IERC20(token).transfer(msg.sender,amount);
        return true;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      _clearStuckBalance(owner);
      return true;
    }

    function _clearStuckBalance(address receiver) internal {
      (bool success,) = receiver.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
    }

    function grantRole(address adr,string memory role) public forRole("owner") returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public forRole("owner") returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public forRole("owner") returns (bool) {
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    receive() external payable {}
}