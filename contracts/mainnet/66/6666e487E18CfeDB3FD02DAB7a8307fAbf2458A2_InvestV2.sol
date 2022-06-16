/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20{
    function decimals() external view returns (uint8);
    function transferFrom(address _from, address _to, uint _value) external;
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _addr)external view returns(uint256);
}

contract InvestV2{
    using SafeMath for uint256;
    
    event AddMember(address newMember, string group, uint256 amount);
    event ReceiveToken(address member, string group, uint256 amount);
    event DepositToken(address member, string group, uint256 amount);
    
  
    struct UnlockMod{
        uint256 first; 
        uint256 periods; 
        uint256 price; 
        uint256 pool; 
    }
    
    struct MemberInfo{
        bool isMember;
        bool isReceivefirst;
        uint256 deposit;
        uint256 limit;
        uint256 everyUnlock;
        uint256 received;
        uint256 receivePeriods;
    }
    
    address public owner;
    string private ERR_LACK_OF_CREDIT = "Insufficient amount of remaining tokens.";
    mapping (string => UnlockMod) public UNLOCK_MODS;
    string[] public groups;
    uint256 public ISSUE_TIME;
    uint256 public timeMod = 60 * 60 * 24 * 30;
    address public dpAddress = 0x4d59249877CfFf9aaa3aE572d06c5B71a79B6215;
    address public immutable usdtAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public receivingAddress = 0x528Fb5b659e45dc0A35aC22234E7a7511Be44b43;
    bool public isOpenReturn;
    
    mapping(address => mapping(string => MemberInfo)) public memberAsset;
    
    constructor(){
        owner = msg.sender;
        isOpenReturn = false;
        UNLOCK_MODS["first"] = UnlockMod(8, 18, uint256(72 * 10 ** 4), 363300000 * 10**18);
        UNLOCK_MODS["second"] = UnlockMod(10, 18, uint256(166 * 10 ** 4), 315000000 * 10**18);
        UNLOCK_MODS["three"] = UnlockMod(12, 18, uint256(238 * 10 ** 4), 315000000 * 10**18);
        UNLOCK_MODS["liquidity"] = UnlockMod(100, 0, 0, 105000000 * 10**18);
        UNLOCK_MODS["ido"] = UnlockMod(100, 0, 0, 4200000 * 10**18);
        UNLOCK_MODS["team"] = UnlockMod(4, 48, 0, 420000000 * 10**18);
        UNLOCK_MODS["dao"] = UnlockMod(4, 48, 0, 157500000 * 10**18);
        UNLOCK_MODS["develop"] = UnlockMod(4, 48, 0, 157500000 * 10**18);
        UNLOCK_MODS["community"] = UnlockMod(4, 48, 0, 157500000 * 10**18);
        UNLOCK_MODS["award"] = UnlockMod(100, 0, 0, 105000000 * 10**18);
        
        groups.push("first");
        groups.push("second");
        groups.push("three");
        groups.push("liquidity");
        groups.push("ido");
        groups.push("team");
        groups.push("dao");
        groups.push("develop");
        groups.push("community");
        groups.push("award");
    } 

    function addMember(address _newMember, string memory _group, uint256 _limit)external existGroup(_group) onlyOwner{
        require(UNLOCK_MODS[_group].pool >= _limit, ERR_LACK_OF_CREDIT);
        if(memberAsset[_newMember][_group].isMember){
            memberAsset[_newMember][_group].limit = memberAsset[_newMember][_group].limit.add(_limit);
        }else{
            memberAsset[_newMember][_group]= MemberInfo(true, false, 0, _limit, 0, 0, 0);
        }
        UNLOCK_MODS[_group].pool = UNLOCK_MODS[_group].pool.sub(_limit);
        
        emit AddMember(_newMember, _group, _limit);
    }
  
    function removedMember(address _member, string memory _group)external existGroup(_group) onlyOwner{
        require(memberAsset[_member][_group].isMember, "The address is not a member.");
        memberAsset[_member][_group].isMember = false;
    }

    function depositForMember(address _member, string memory _group, uint256 _amount)external existGroup(_group) onlyOwner{
        // require(ISSUE_TIME == 0, "token has been issued.");
        IERC20 usdt = IERC20(usdtAddress);
        uint256 usdtAmount = _amount.mul(UNLOCK_MODS[_group].price).div(10**20);
        require(memberAsset[_member][_group].isMember, "You are not a member of the group!");
        require(memberAsset[_member][_group].deposit.add(_amount) <= memberAsset[_member][_group].limit, ERR_LACK_OF_CREDIT);
        uint256 newDeposit = memberAsset[_member][_group].deposit.add(_amount);
        memberAsset[_member][_group].deposit = newDeposit;
        if(UNLOCK_MODS[_group].periods == 0){
            memberAsset[msg.sender][_group].everyUnlock = 0;
        }else{
            memberAsset[msg.sender][_group].everyUnlock = (newDeposit.sub(newDeposit.mul(UNLOCK_MODS[_group].first).div(100)).div(UNLOCK_MODS[_group].periods));
        }
        if(UNLOCK_MODS[_group].price != 0){
            usdt.transferFrom(msg.sender, receivingAddress, usdtAmount);
        }
        
        emit DepositToken(msg.sender, _group, _amount);
    }
    
    function depositToken(string memory _group, uint256 _amount)external existGroup(_group){
        require(ISSUE_TIME == 0, "Token has been issued.");
        IERC20 usdt = IERC20(usdtAddress);
        uint256 usdtAmount = _amount.mul(UNLOCK_MODS[_group].price).div(10**20);
        require(memberAsset[msg.sender][_group].isMember, "You are not a member of the group!");
        require(memberAsset[msg.sender][_group].deposit.add(_amount) <= memberAsset[msg.sender][_group].limit, ERR_LACK_OF_CREDIT);
        uint256 newDeposit = memberAsset[msg.sender][_group].deposit.add(_amount);
        memberAsset[msg.sender][_group].deposit = newDeposit;
        if(UNLOCK_MODS[_group].periods == 0){
            memberAsset[msg.sender][_group].everyUnlock = 0;
        }else{
            memberAsset[msg.sender][_group].everyUnlock = (newDeposit.sub(newDeposit.mul(UNLOCK_MODS[_group].first).div(100)).div(UNLOCK_MODS[_group].periods));
        }
        if(UNLOCK_MODS[_group].price != 0){
            usdt.transferFrom(msg.sender, receivingAddress, usdtAmount);
        }
        
        emit DepositToken(msg.sender, _group, _amount);
    }
    
    function receiveToken(string memory _group) external existGroup(_group) checkIssue {
        IERC20 dp = IERC20(dpAddress);
        uint256 unlocks;
        uint256 receivePeriods;
        if(isOpenReturn){
            unlocks = memberAsset[msg.sender][_group].deposit.sub(memberAsset[msg.sender][_group].received);
            require(memberAsset[msg.sender][_group].received.add(unlocks) <= memberAsset[msg.sender][_group].deposit, "The number of unlocks exceeds expectations.");
            memberAsset[msg.sender][_group].received = memberAsset[msg.sender][_group].deposit;
        }else{
            (unlocks, receivePeriods) =_countUnlockAndPeriods(msg.sender, _group);
            require(memberAsset[msg.sender][_group].received.add(unlocks) <= memberAsset[msg.sender][_group].deposit, "The number of unlocks exceeds expectations.");
            memberAsset[msg.sender][_group].isReceivefirst = true;
            memberAsset[msg.sender][_group].receivePeriods = receivePeriods;
            memberAsset[msg.sender][_group].received = memberAsset[msg.sender][_group].received.add(unlocks);
        }
        assert(unlocks > 0);
        dp.transfer(msg.sender, unlocks);
        
        emit ReceiveToken(msg.sender, _group, unlocks);
    }
    
    function countUnlock(address _addr, string memory _group)external view  existGroup(_group) returns(uint256 amount){
        (amount, ) = _countUnlockAndPeriods(_addr, _group);
        return amount;
    }
    
    function _countUnlockAndPeriods(address _addr, string memory _group)internal view returns(uint256 amount, uint256 receivePeriods){
        MemberInfo memory info = memberAsset[_addr][_group];
        if(block.timestamp <= ISSUE_TIME || ISSUE_TIME == 0){
            return (0, 0);
        }
        if(info.isMember){
            if(!info.isReceivefirst){
                amount = amount.add(info.deposit.mul(UNLOCK_MODS[_group].first).div(100));
            }
            if(UNLOCK_MODS[_group].periods != 0){
                uint256 spendPeriods = (block.timestamp.sub(ISSUE_TIME)).div(timeMod);
                if(spendPeriods >= UNLOCK_MODS[_group].periods){
                    amount = amount.add(info.deposit.sub(info.received));
                    uint256 max = info.deposit.sub(info.received);
                    if(amount > max){
                        amount = max;
                    }
                    return(amount, UNLOCK_MODS[_group].periods);
                }else{
                    amount = amount.add(spendPeriods.sub(info.receivePeriods).mul(info.everyUnlock));
                    uint256 max = info.deposit.sub(info.received);
                    if(amount > max){
                        amount = max;
                    }
                    return(amount, spendPeriods);
                }
            }
            return (amount, 0);
        }
    }
    
    function memberInfo(address _member, string memory _group) external view existGroup(_group) returns(uint256 deposit, uint256 received, uint256 limit){
        return (memberAsset[_member][_group].deposit,
                memberAsset[_member][_group].received,
                memberAsset[_member][_group].limit);
    }
    
    function roles(address _member)external view returns(string memory){
        string memory rolesLlistStr = "";
        uint256 count = 0;
        for(uint256 i = 0; i < groups.length; i++){
            if(memberAsset[_member][groups[i]].isMember){
                count = count+1;
                if (count == 1){
                    rolesLlistStr = groups[i];
                }else{
                    rolesLlistStr = string(abi.encodePacked(rolesLlistStr,",", groups[i]));
                }
            }
        }
        return rolesLlistStr;
    }

    function dpBalance()external view returns(uint256){
        IERC20 dp = IERC20(dpAddress);
        return dp.balanceOf(address(this));
    }
    
    //manager
    function setReceivingAddress(address _newReceivingAddress)external onlyOwner{
        receivingAddress = _newReceivingAddress;
    }

    function setOwner(address _newOwner)external onlyOwner{
        owner = _newOwner;
    }

    function setDpAddr(address _newDpAddr)external onlyOwner{
        dpAddress = _newDpAddr;
    }
    
    function switchOpenReturn()external onlyOwner{
        isOpenReturn = !isOpenReturn;
    }

    function _toWei(uint256 _amount)internal pure returns(uint256){
        return _amount.mul(10 ** 18);
    }
    
    function issue()external onlyOwner{
        ISSUE_TIME = block.timestamp;
    }
    
    modifier existGroup(string memory _group) {
        bool exist = false;
        bytes32 a = keccak256(abi.encodePacked(_group));
        for(uint256 i = 0; i < groups.length; i++){
            bytes32 b = keccak256(abi.encodePacked(groups[i]));
            if(b == a){
                exist = true;
            }
        }
        require(exist, "The group is not exist!");
        _;
    }
    
    modifier checkIssue(){
        require(block.timestamp >= ISSUE_TIME && ISSUE_TIME != 0, "The token is not issued.");
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }

}