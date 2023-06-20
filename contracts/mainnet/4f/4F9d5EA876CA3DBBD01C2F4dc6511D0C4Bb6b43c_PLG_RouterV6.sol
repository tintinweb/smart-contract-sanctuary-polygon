/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGData {
    function invest(address account) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}

interface IUserManager {
    function register(address referree,address referral) external returns (bool);
    function getUserRegistered(address account) external view returns (bool);
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

contract PLG_RouterV6 is permission {
    
    address public owner;

    uint256 public lockperiod = 86400 * 15;
    uint256 public breakperiod = 86400 * 3;
    bool locked;

    uint256 public rewardPerCycle = 225;
    uint256 denominator = 1000;

    IPLGFactory factory;

    struct Invest {   
        uint256 balance;
        uint256 repeat;
        uint256 block_deposit;
        uint256 block_withdraw;
        uint256 block_break;
        uint256 cycle;
        uint256 recycle;
    }

    mapping(address => Invest) public invest;

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

    function depositWithPermit(address account,address referral,uint256 value) public forRole("permit") returns (bool) {
        if(!IUserManager(factory.getAddr("plg_user")).getUserRegistered(account)){
            require(IUserManager(factory.getAddr("plg_user")).getUserRegistered(referral),"Referral Address Must Be Registered");
            IUserManager(factory.getAddr("plg_user")).register(account,referral);
        }
        _deposit(account,value);
        return true;
    }

    function clearWithPermit(address account) public forRole("permit") returns (bool) {
        invest[account].balance = 0;
        invest[account].block_deposit = 0;
        invest[account].block_withdraw = 0;
        invest[account].block_break = 0;
        return true;
    }

    function _deposit(address account,uint256 amount) internal {
        invest[account].balance = amount;
        if(block.timestamp>invest[account].block_break){
            invest[account].repeat = 1;
            invest[account].cycle += 1;
        }else{
            invest[account].repeat += 1;
        }
        if(invest[account].repeat>5){
            invest[account].repeat = 1;
            invest[account].cycle += 1;
            invest[account].recycle += 1;
        }
        invest[account].block_deposit = block.timestamp;
        invest[account].block_withdraw = block.timestamp + lockperiod;
        invest[account].block_break = block.timestamp + lockperiod + breakperiod;
    }

    function updateWithPermit(address account,uint256[] memory data) public forRole("permit") returns (bool) {
        _updateWithPermit(account,data);
        return true;
    }

    function _updateWithPermit(address account,uint256[] memory data) internal returns (bool) {
        invest[account].balance = data[0];
        invest[account].repeat = data[1];
        invest[account].block_deposit = data[2];
        invest[account].block_withdraw = data[3];
        invest[account].block_break = data[4];
        invest[account].cycle = data[5];
        invest[account].recycle = data[6];
        return true;
    }

    function getReward(address account) public view returns (uint256) {
        uint256 balanceAmount = invest[account].balance;
        uint256 stakedPeriod = block.timestamp - invest[account].block_deposit;
        uint256 maximumReward = balanceAmount * rewardPerCycle / denominator;
        uint256 reward = maximumReward * stakedPeriod / lockperiod;
        if(reward>maximumReward){
            return maximumReward;
        }else{
            return reward;
        }
    }

    function getBlock() public view returns (uint256) {
        return block.timestamp;
    }

    function migrate(address[] memory accounts,address oldRouter) public forRole("owner") returns (bool) {
        for(uint256 i=0; i<accounts.length; i++){
            (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGData(oldRouter).invest(accounts[i]);
            invest[accounts[i]].balance = a;
            invest[accounts[i]].repeat = s;
            invest[accounts[i]].block_deposit = d;
            invest[accounts[i]].block_withdraw = f;
            invest[accounts[i]].block_break = g;
            invest[accounts[i]].cycle = h;
            invest[accounts[i]].recycle = j;
        }
        return true;
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function changeDappVariables(uint256[] memory input) public forRole("owner") returns (bool) {
        lockperiod = input[0];
        rewardPerCycle = input[1];
        return true;
    }

    function purgeToken(address token) public forRole("owner") returns (bool) {
      uint256 amount = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(msg.sender,amount);
      return true;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      (bool success,) = msg.sender.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
      return true;
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