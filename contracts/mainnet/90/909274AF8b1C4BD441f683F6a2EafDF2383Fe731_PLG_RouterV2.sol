/**
 *Submitted for verification at polygonscan.com on 2023-05-24
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

contract PLG_RouterV2 is permission {
    
    address public owner;

    address public plg_pool = 0x0f879A919B78348899389D99426E7c6E8875bE40;
    address public plg_user = 0xB4c2bd52a184DD0796c26e136891Fdb10d60A016;
    address public plg_refreward = 0x20dAE4a0D3D7566A8bd4Caf54552c37831666D02;
    address public plg_token = 0x919A5712057173C7334cc60E7657791fF9ca6E8d;
    address public usdc_token = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public plg_pair = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
    address public matic_pair = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
    address public quick_router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public implement = 0x7cE955BE760A5e1Ba49cc9b1bA948FE863359CC0;

    uint256 public minimam_deposit = 30 * 1e18;
    uint256 public maximum_deposit = 1000 * 1e18;
    uint256 public lockperiod = 86400*15;
    uint256 public breakperiod = 86400*3;
    bool locked;

    uint256 public rewardPerCycle = 225;
    uint256 denominator = 1000;

    IPLGPool private pool;
    IUserManager private manager;
    IRefReward private refreward;
    IERC20 private plg;
    IERC20 private usdc;
    IDEXRouter private router;

    struct Invest {   
        uint256 balance;
        uint256 repeat;
        uint256 block_deposit;
        uint256 block_withdraw;
        uint256 block_break;
        uint256 cycle;
        uint256 recycle;
    }

    mapping(address => Invest) invest;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        updateImplement();
    }

    function depositWithPLG(uint256 amount,address referral) public noReentrant() returns (bool) {
        require(amount>=minimam_deposit,"Revert By Minimum Deposit");
        require(amount>=maximum_deposit,"Revert By Maximum Deposit");
        require(amount>=invest[msg.sender].balance,"Must Be Deposit More or Equal Balance");
        require(amount<=invest[msg.sender].balance*150/100,"Must Be Deposit Below or Equal 1.5x Balance");
        uint256[] memory tokenAmount = getPLGAmountFromExactMATIC(amount);
        uint256 PLG_Amount = tokenAmount[0] * 95 / 100;
        plg.transferFrom(msg.sender,address(this),PLG_Amount);
        swapExactPLGForMATIC(PLG_Amount);
        _registeration(msg.sender,referral);
        _withdraw(msg.sender);
        _deposit(msg.sender,amount);
        return true;
    }

    function depositWithMATIC(address referral) public payable noReentrant() returns (bool) {
        require(msg.value>=minimam_deposit,"Revert By Minimum Deposit");
        require(msg.value>=maximum_deposit,"Revert By Maximum Deposit");
        require(msg.value>=invest[msg.sender].balance,"Must Be Deposit More or Equal Balance");
        require(msg.value<=invest[msg.sender].balance*150/100,"Must Be Deposit Below or Equal 1.5x Balance");
        _registeration(msg.sender,referral);
        _withdraw(msg.sender);
        _deposit(msg.sender,msg.value);
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
        (bool successA,) = plg_pool.call{ value: amount2rewardpool }("");
        (bool successB,) = implement.call{ value: amount2implement }("");
        require(successA && successB, "!fail to send eth");
        refreward.rewardDistribute{ value: amount2implement }(account,address(manager),"ref");
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
            pool.processETHRequest(account,balanceAmount);
            uint256 reward = getReward(account);
            pool.processETHRequest(account,reward*88/100);
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

    function getPLGAmountFromExactMATIC(uint256 amount) public view returns (uint256[] memory) {
        address[] memory path = new address[](2);
        path[0] = plg_token;
        path[1] = router.WETH();
        return router.getAmountsIn(amount,path);
    }

    function getBlock() public view returns (uint256) {
        return block.timestamp;
    }

    function updateImplement() internal {
        pool = IPLGPool(plg_pool);
        manager = IUserManager(plg_user);
        refreward = IRefReward(plg_refreward);
        plg = IERC20(plg_token);
        usdc = IERC20(usdc_token);
        router = IDEXRouter(quick_router);
    }

    function swapExactPLGForMATIC(uint256 amount) internal {
        uint256 allowance = plg.allowance(address(this),address(router));
        if(allowance<amount){ plg.approve(address(router),type(uint256).max); }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        amount,
        0,
        path,
        address(this),
        block.timestamp
        );
    }

    function factoryAddressSetting(address[] memory input) public forRole("owner") returns (bool) {
        plg_pool = input[0];
        plg_user = input[1];
        plg_refreward = input[2];
        plg_token = input[3];
        usdc_token = input[4];
        plg_pair = input[5];
        matic_pair = input[6];
        quick_router = input[7];
        implement = input[8];
        updateImplement();
        return true;
    }

    function changeDappVariables(uint256[] memory input) public forRole("owner") returns (bool) {
        minimam_deposit = input[0];
        maximum_deposit = input[1];
        lockperiod = input[2];
        rewardPerCycle = input[3];
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