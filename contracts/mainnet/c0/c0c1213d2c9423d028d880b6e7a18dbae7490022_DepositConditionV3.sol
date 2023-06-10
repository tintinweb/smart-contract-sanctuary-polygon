/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGPool {
    function depositFor(address recipient) external payable returns (bool);
    function processETHRequest(address recipient,uint256 amount) external returns (bool);
}

interface IPLGData {
    function depositWithPermit(address account,address referral,uint256 value) external returns (bool);
    function clearWithPermit(address account) external returns (bool);
    function updateWithPermit(address account,uint256[] memory data) external returns (bool);
    function invest(address account) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function getReward(address account) external view returns (uint256);
}

interface IPLGReward {
    function rewardDistribute(address account,address userContract,string memory dataSlot) external payable returns (bool);
    function increaseRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) external returns (bool);
    function updateVIPBlockWithPermit(address account,uint256 timer) external returns (bool);
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

contract DepositConditionV3 is permission {
    
    address public owner;

    uint256 public deleyed_maximumed = 86400*30;
    uint256 public deleyed_default = 86400*6;

    uint256 public minimam_deposit = 30 * 1e18;
    uint256 public maximum_deposit = 1000 * 1e18;

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

    function getAccountPreventBlock(address account) public view returns (uint256) {
        (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGData(factory.getAddr("plg_router")).invest(account);
        uint256 preventBlock = deleyed_default+(86400*h);
        if(preventBlock>deleyed_maximumed){ preventBlock = deleyed_maximumed; }
        return d+preventBlock;
    }

    function depositWithMATIC(address account,address referral) public payable returns (bool) {
        (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGData(factory.getAddr("plg_router")).invest(account);
        uint256 preventBlock = deleyed_default+(86400*h);
        require(block.timestamp>=d+preventBlock,"Revert By Minimum Deposit");
        require(msg.value>=minimam_deposit,"Revert By Minimum Deposit");
        require(msg.value<=maximum_deposit,"Revert By Maximum Deposit");
        require(msg.value>=a,"Must Be Deposit More or Equal Balance");
        if(a>0){ require(msg.value<=a*150/100,"Must Be Deposit Below or Equal 1.5x Balance"); }
        _withdraw(account,a,h);
        IPLGPool(factory.getAddr("plg_pool")).processETHRequest(factory.getAddr("implement"),a * 15 / 100);
        IPLGData(factory.getAddr("plg_router")).depositWithPermit(account,referral,msg.value);
        if(a==0){
            IPLGPool(factory.getAddr("plg_pool")).processETHRequest(address(this),a * 15 / 100);
            IPLGReward(factory.getAddr("plg_refreward")).rewardDistribute{ value: address(this).balance }(account,factory.getAddr("plg_user"),"ref");
        }else{
            if(msg.value>a){
                uint256 divAmount = msg.value - a;
                IPLGPool(factory.getAddr("plg_pool")).processETHRequest(address(this),divAmount * 15 / 100);
                IPLGReward(factory.getAddr("plg_refreward")).rewardDistribute{ value: address(this).balance }(account,factory.getAddr("plg_user"),"ref");
            }
        }
        updateAccountDeleyedBlock(account,preventBlock);
        return true;
    }

    function _withdraw(address account,uint256 amount,uint256 cycle) internal {
        _clearStuckBalance(factory.getAddr("plg_pool"));
        if(amount>0){
            uint256 reward = IPLGData(factory.getAddr("plg_router")).getReward(account);
            IPLGPool(factory.getAddr("plg_pool")).depositFor{ value: amount+(reward*88/100) }(account);
            IPLGPool(factory.getAddr("plg_pool")).processETHRequest(account,reward*12/100);
            IPLGReward(factory.getAddr("plg_refreward")).rewardDistribute{ value: address(this).balance }(account,factory.getAddr("plg_user"),"matching");
            IPLGReward(factory.getAddr("plg_refreward")).increaseRecordData(account,"roi",cycle,reward);
        }
        IPLGData(factory.getAddr("plg_router")).clearWithPermit(account);
    }

    function updateAccountDeleyedBlock(address account,uint256 preventBlock) internal {
        if(preventBlock>deleyed_maximumed){ preventBlock = deleyed_maximumed; }
        (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGData(factory.getAddr("plg_router")).invest(account);
        if(d+preventBlock>g-259200){
            uint256[] memory data = new uint256[](7);
            data[0] = a;
            data[1] = s;
            data[2] = d;
            data[3] = f;
            data[4] = d+preventBlock+259200;
            data[5] = h;
            data[6] = j;
            IPLGData(factory.getAddr("plg_router")).updateWithPermit(account,data);
        }
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
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