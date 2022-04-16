/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

  
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract KingStake is Ownable{
    using SafeMath for uint256;
    
    IERC20 public KingToken;
    
    uint256 stakeID;
    uint256 public rewardBalance;

    struct _StakeingId{
        uint256[] stakingId;
    }
    
    struct PlanDetails{
        uint256 percentage;
        uint256 stakingDays;
    }
    
    struct User{
        uint256 stakeTime;
        uint256 lastClaim;
        uint256 rewardEndTime;
        uint256 planDays;
        uint256 planPercenrtage;
        uint256 amount;
        uint256 reward;
        bool claim;
    }
    
    mapping(address => _StakeingId) userStakings;
    mapping(uint256 => PlanDetails)public planDetails;
    mapping(address => mapping(uint256 => User))public userDetails;
    mapping(address => uint256)private claimed;

    event UpdatePlans(uint256 indexed planId, uint256 indexed stakingPeriod, uint256 indexed planPercenrtage);
    event Stake(address indexed staker,uint256 indexed amount,uint256 indexed planID);
    event AdminDeposit(address indexed owner, uint256 indexed amount);
    event FailSafe(address indexed to , uint256 indexed amount);
    event UnStake(address indexed staker, uint256 indexed amount);
    event Reward(address indexed staker, uint256 indexed rewrdAmount);
    
    
    constructor(IERC20 _kingToken){
        KingToken = _kingToken;
    }
    
    function updatePlans(uint256 _planId,uint256 _stakingPeriod,uint256 _stakingPcent)external onlyOwner returns(bool){
        require(_planId < 3 && _planId > 0,"KingStake:: Give correct plan ID");
        planDetails[_planId].percentage = _stakingPcent;
        planDetails[_planId].stakingDays = _stakingPeriod;
        
        emit UpdatePlans(_planId,_stakingPeriod,_stakingPcent);
        
        return true;
    }
    
    function stake(uint256 _planId, uint256 _amount)external{
        require(_planId < 3 && _planId > 0,"KingStake:: Give correct plan ID");
        require(_amount >= 333e18,"KingStake:: Deposit above 333 tokens");
        stakeID++;
        User storage user = userDetails[msg.sender][stakeID];
        
        user.amount = _amount;
        user.stakeTime = block.timestamp;
        user.lastClaim = block.timestamp;
        user.rewardEndTime = block.timestamp + (planDetails[_planId].stakingDays * 86400);
        user.planDays = planDetails[_planId].stakingDays;
        user.planPercenrtage = planDetails[_planId].percentage;

        userStakings[msg.sender].stakingId.push(stakeID);
        
        safeTransferFrom(msg.sender,address(this),_amount);
        
        emit Stake(msg.sender, _amount, _planId );
    }
    
    function viewReward(address _account,uint256 _stakingID)public view returns(uint256){
        User storage user = userDetails[_account][_stakingID];
        require(user.stakeTime != 0,"kingStake :: Account Not found");
        uint256 blockTime = block.timestamp;
        if(block.timestamp >= user.rewardEndTime) { blockTime = user.rewardEndTime; }
        
        uint256 stakingTime = blockTime.sub(user.lastClaim);
        uint256 stakingPercentage = user.planPercenrtage.mul(1e12).div(user.planDays).div(100);

        return user.amount.mul(stakingTime).mul(stakingPercentage).div(1e12).div(86400);
        
    }
    
    function claimedReward(address _account)external view returns(uint256 UserClaimed){
        return claimed[_account];
    }
    
    function claimReward(address _account,uint256[] memory _stakingID)public {
        require(_stakingID.length < 101,"kingStake :: only 100 id are claim at the time");
        
        for(uint256 i = 0; i < _stakingID.length; i++){
            User storage user = userDetails[_account][_stakingID[i]];
            require(user.stakeTime != 0,"KingStake :: Account Not found" );
            require(!user.claim,"KingStake:: User already UnStake");
            uint rewrdAmount = viewReward(_account, _stakingID[i] );
            user.lastClaim = block.timestamp;
            if(block.timestamp >= user.rewardEndTime) { user.lastClaim = user.rewardEndTime; }
            rewardBalance = rewardBalance.sub(rewrdAmount,"KingStake :: reward Balance exceed");
            user.reward += rewrdAmount;
            
            claimed[msg.sender] = claimed[msg.sender].add(rewrdAmount);
            
            safeTransfer(msg.sender,rewrdAmount);
            
            emit Reward(_account , rewrdAmount);
        } 
    }
    
    function unStake(uint256 _stakingID)external{
        User storage user = userDetails[msg.sender][_stakingID];
        require(user.stakeTime != 0,"KingStake :: Account Not found" );
        require(!user.claim,"KingStake:: User already UnStake");
        user.claim = true;
        
        safeTransfer(msg.sender,user.amount);

        emit UnStake(msg.sender,user.amount);
        user.amount = 0;
    }
    
    function userStakingId(address _staker) external view returns(uint256[] memory){
        return userStakings[_staker].stakingId;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _amount)internal{
        KingToken.transferFrom(_from,_to,_amount);
    }
    
    function safeTransfer(address _to, uint256 _amount)internal{
        KingToken.transfer(_to,_amount);
    }
    
    function adminDeposit(uint256 _amount)external onlyOwner{
        rewardBalance = rewardBalance.add(_amount);
        KingToken.transferFrom(msg.sender,address(this),_amount);
        emit AdminDeposit(msg.sender, _amount);
    }

    function failSafe(address _to,uint256 _amount)external onlyOwner{
        KingToken.transfer(_to,_amount);
        emit FailSafe(_to, _amount);
    }
    
}