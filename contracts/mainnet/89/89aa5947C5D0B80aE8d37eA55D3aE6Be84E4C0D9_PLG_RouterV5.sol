/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGv2 {
    function invest(address account) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}

interface IPLGData {
    function invest(address account) external view returns (uint256[] memory);
}

interface IPLGPool {
    function processETHRequest(address recipient,uint256 amount) external returns (bool);
}

interface IUserManager {
    function register(address referree,address referral) external returns (bool);
    function getUserRegistered(address account) external view returns (bool);
}

interface IRefReward {
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

contract PLG_RouterV5 is permission {
    
    address public owner;

    uint256 public minimam_deposit = 30 * 1e18;
    uint256 public maximum_deposit = 1000 * 1e18;
    uint256 public lockperiod = 86400 * 15;
    uint256 public breakperiod = 86400 * 3;
    bool locked;

    uint256 public rewardPerCycle = 225;
    uint256 public vipBlockPrice = 500 * 1e18;
    uint256 public vipperiod = 86400 * 31;
    uint256 denominator = 1000;

    IPLGPool private pool;
    IUserManager private manager;
    IRefReward private refreward;
    IERC20 private plg;
    IERC20 private usdc;
    IDEXRouter private router;

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
        updateImplement();
    }

    function depositWithPermit(address account,address referral,uint256 value) public forRole("permit") returns (bool) {
        _registeration(account,referral);
        _withdraw(account);
        _deposit(account,value);
        return true;
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

    function unlockVIP(address account) public returns (bool) {
        IERC20(factory.getAddr("plg_token")).transferFrom(msg.sender,address(0xdead),vipBlockPrice);
        refreward.updateVIPBlockWithPermit(account,block.timestamp+vipperiod);
        return true;
    }

    function _registeration(address account,address referral) internal {
        if(!manager.getUserRegistered(account)){
            require(manager.getUserRegistered(referral),"Referral Address Must Be Registered");
            manager.register(account,referral);
        }
    }

    function _deposit(address account,uint256 amount) internal {
        uint256 amount2implement = amount * 15 / 100;
        uint256 amount2rewardpool = amount * 70 / 100;
        (bool successA,) = factory.getAddr("plg_pool").call{ value: amount2rewardpool }("");
        (bool successB,) = factory.getAddr("implement").call{ value: amount2implement }("");
        require(successA, "!fail to send eth");
        require(successB, "!fail to send eth");
        if(amount>invest[account].balance){
            uint256 divAmount = amount - invest[account].balance;
            refreward.rewardDistribute{ value: divAmount * 15 / 100 }(account,address(manager),"ref");
        }
        invest[account].balance = amount;
        if(invest[account].balance==0){
            refreward.rewardDistribute{ value: amount2implement }(account,address(manager),"ref");
        }
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

    function _withdraw(address account) internal {
        uint256 balanceAmount = invest[account].balance;
        if(balanceAmount>0){
            uint256 reward = getReward(account);
            pool.processETHRequest(account,balanceAmount);
            pool.processETHRequest(account,reward*88/100);
            pool.processETHRequest(address(this),reward*12/100);
            refreward.rewardDistribute{ value: reward*12/100 }(account,address(manager),"matching");
            refreward.increaseRecordData(account,"roi",invest[account].cycle,reward);
        }
        _clear(account);
    }

    function _clear(address account) internal {
        invest[account].balance = 0;
        invest[account].repeat = 0;
        invest[account].block_deposit = 0;
        invest[account].block_withdraw = 0;
        invest[account].block_break = 0;
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
            (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGv2(oldRouter).invest(accounts[i]);
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
        updateImplement();
        return true;
    }

    function updateImplement() internal {
        pool = IPLGPool(factory.getAddr("plg_pool"));
        manager = IUserManager(factory.getAddr("plg_user"));
        refreward = IRefReward(factory.getAddr("plg_refreward"));
        plg = IERC20(factory.getAddr("plg_token"));
    }

    function changeDappVariables(uint256[] memory input) public forRole("owner") returns (bool) {
        minimam_deposit = input[0];
        maximum_deposit = input[1];
        lockperiod = input[2];
        rewardPerCycle = input[3];
        vipBlockPrice = input[4];
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