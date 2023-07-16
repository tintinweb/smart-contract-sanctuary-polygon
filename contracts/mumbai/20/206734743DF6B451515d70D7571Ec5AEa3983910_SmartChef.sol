/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeBEP20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IBEP20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IBEP20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeApprove(
    IBEP20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeBEP20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IBEP20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IBEP20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance =
      token.allowance(address(this), spender).sub(
        value,
        "SafeBEP20: decreased allowance below zero"
      );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IBEP20 token, bytes memory data) private {
    bytes memory returndata =
      address(token).functionCall(data, "SafeBEP20: low-level call failed");
    if (returndata.length > 0) {
      require(
        abi.decode(returndata, (bool)),
        "SafeBEP20: BEP20 operation did not succeed"
      );
    }
  }
}

contract SmartChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IBEP20 public _stakedToken;
    IBEP20 public _rewardToken;

    uint256 public _rewardPerBlock;
    uint256 public _intervalPerBlock;
    uint256 public _lockPeriod;

    uint256 public _startTime;
    uint256 public _endTime;
    
    uint256 public _totalHashRate;
    uint256 public _totalStakingHashRate;
    uint256 public _totalPromoteHashRate;
    
    struct BlockRecord {
        uint256 height;
        uint256 accReward;
        uint256 totalHashRate;
    }
    
    struct Order {
        uint256 amount;
        uint256 hashRate;
        uint256 time;
        uint256 height;
        uint256 offsetProfit;
        uint256 status; 
        uint256 start;
        uint256 end;
    }

    struct Info {
        uint256 lastStakingHeight;
        uint256 lastPromoteHeight;
        uint256 stakingNum;
        uint256 promoteNum;
        uint256 stakingHashrate;
        uint256 promoteHashrate;
        uint256 pendingProfit;
    }
    
    BlockRecord[] private _records;
    mapping(address => mapping(uint256 => Order)) private _stakingOrders;
    mapping(address => mapping(uint256 => Order)) private _promoteOrders;
    
    mapping(address => Info) private _infos;
    mapping(address => uint256) private _accTakeProfit;

    uint256[] public generationRewards;
    uint256 public Denominator;
    mapping(address => address) public _inviters;
    
    constructor (
        address stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 intervalPerBlock,
        uint256 lockPeriod,
        uint256[] memory genRewards,
        uint256 startTime,
        uint256 endTime,
        address service
    ) payable {
        _stakedToken = IBEP20(stakedToken);
        _rewardToken = IBEP20(rewardToken);
        
        _rewardPerBlock = rewardPerBlock;
        _intervalPerBlock = intervalPerBlock;
        _lockPeriod = lockPeriod;
        _startTime = startTime;
        _endTime = endTime;
        Denominator = 1000;
        if (genRewards.length > 0) generationRewards = genRewards;
        payable(service).transfer(msg.value);
    }
    
    function deposit(address inviter, uint256 amount) external nonReentrant {
        require(amount > 0, "staking amount is 0");
        require(block.timestamp >= _startTime && block.timestamp < _endTime, "is disable");
        
        uint256 newHashRate = amount;
        if (generationRewards.length > 0) {
            _inviteHashrate(inviter, address(msg.sender), newHashRate);
        }
        
        uint256 blockHeight = _blockHeight();
        uint256 len = _records.length;
        uint256 accReward = blockHeight.mul(_rewardPerBlock);
        
         _totalHashRate = _totalHashRate.add(newHashRate);
         _totalStakingHashRate = _totalStakingHashRate.add(newHashRate);
        if (len >0 && _records[len-1].height == blockHeight){
            BlockRecord storage record = _records[len-1];
            record.totalHashRate = record.totalHashRate.add(newHashRate);
            record.accReward = accReward;
        }else{
            _records.push(BlockRecord(blockHeight,accReward,_totalHashRate));
        }
        
        uint256 num = _infos[msg.sender].stakingNum;
        len = _records.length;
        if (num > 0 && _infos[msg.sender].lastStakingHeight == blockHeight){
            Order storage order=_stakingOrders[msg.sender][num-1];
            order.amount = order.amount.add(amount);
            order.hashRate = order.hashRate.add(newHashRate);
        }else{
            _stakingOrders[msg.sender][num].amount = amount;
            _stakingOrders[msg.sender][num].hashRate = newHashRate;
            _stakingOrders[msg.sender][num].time = block.timestamp;
            _stakingOrders[msg.sender][num].height = blockHeight;
            _stakingOrders[msg.sender][num].start = len-1;
            _stakingOrders[msg.sender][num].end = block.timestamp.add(_lockPeriod);
            num++;
        }
        
        _infos[msg.sender].lastStakingHeight = blockHeight;
        _infos[msg.sender].stakingNum = num;
        _infos[msg.sender].stakingHashrate = _infos[msg.sender].stakingHashrate.add(newHashRate);
        
        _stakedToken.transferFrom(address(msg.sender), address(this), amount);
    }

    function _inviteHashrate(address sharer, address from, uint256 hashrate) internal {
        uint256 rewardHashrate;
        address invitee = from;
        if (_inviters[from] == address(0) && _infos[from].stakingNum == 0) {
            _inviters[from] = sharer;
        }
        for (uint i=0; i<generationRewards.length; i++) {
            address inviter = _inviters[invitee];

            if (inviter == address(0) || inviter == invitee){
                return;
            }
            if (_infos[inviter].stakingHashrate == 0){
                invitee = inviter;
                continue;
            } 

            rewardHashrate = hashrate.mul(generationRewards[i]).div(Denominator);

            uint256 blockHeight = _blockHeight();
            uint256 len = _records.length;
            uint256 accReward = blockHeight.mul(_rewardPerBlock);

            _totalHashRate = _totalHashRate.add(rewardHashrate);
            _totalPromoteHashRate = _totalPromoteHashRate.add(rewardHashrate);

            if (len > 0 && _records[len-1].height == blockHeight){
                BlockRecord storage record = _records[len-1];
                record.totalHashRate = record.totalHashRate.add(rewardHashrate);
                record.accReward = accReward;
            }else{
                _records.push(BlockRecord(blockHeight,accReward,_totalHashRate));
            }

            uint256 num = _infos[inviter].promoteNum;
            len = _records.length;
            if (num == 0) {
                _promoteOrders[inviter][num].hashRate = rewardHashrate;
                _promoteOrders[inviter][num].time = block.timestamp;
                _promoteOrders[inviter][num].height = blockHeight;
                _promoteOrders[inviter][num].start = len-1;
                num++;
            }else {
                Order storage order=_promoteOrders[inviter][num-1];
                uint256 orderHashrate = order.hashRate.add(rewardHashrate); 
                
                if (_infos[inviter].lastPromoteHeight == blockHeight){
                    order.hashRate = orderHashrate;
                }else{
                    order.end = len-1;
                    order.status = 1;
                    if (orderHashrate > 0){
                        _promoteOrders[inviter][num].hashRate = orderHashrate;
                        _promoteOrders[inviter][num].time = block.timestamp;
                        _promoteOrders[inviter][num].height = blockHeight;
                        _promoteOrders[inviter][num].start = len-1;
                        num++;
                    }
                }
            }

            _infos[inviter].lastPromoteHeight = blockHeight;
            _infos[inviter].promoteNum = num;
            _infos[inviter].promoteHashrate = _infos[inviter].promoteHashrate.add(rewardHashrate);

            invitee = inviter;
        }
    }
    
    function releaseHeight() external view returns(uint256){
        return _blockHeight();
    }
    
    function _blockHeight() internal view returns(uint256){
        uint256 nowTime = block.timestamp;
        if (nowTime < _startTime){
            return 0;
        }
        if (nowTime > _endTime){
            nowTime = _endTime;
        }
        uint256 blockHeight = nowTime.sub(_startTime).div(_intervalPerBlock);
        return blockHeight;
    }
    
    function queryPreBlockReward()external view returns(uint256){
        uint256 stakingNum = _infos[msg.sender].stakingNum;
        uint256 promoteNum = _infos[msg.sender].promoteNum;
        if (stakingNum == 0 && promoteNum == 0){
            return 0;
        }
        uint256 blockHeight = _blockHeight();
        uint256 len = _records.length;
        if (blockHeight == 0 || len == 0){
            return 0;
        }
        uint256 profit;
        uint256 preHashrate;
        uint256 preBlockHeight = blockHeight - 1;
        for(uint i=0; i<stakingNum; i++){
            Order storage order = _stakingOrders[msg.sender][i];
            if (order.height > preBlockHeight || order.status == 2 && order.end <= preBlockHeight){
                continue;
            }
            preHashrate = preHashrate.add(order.hashRate);
        }
        for(uint i=0; i<promoteNum; i++){
            Order storage order = _promoteOrders[msg.sender][i];
            if (order.height > preBlockHeight || order.status == 1 && order.end <= preBlockHeight){
                continue;
            }
            preHashrate = preHashrate.add(order.hashRate);
        }
        if (preHashrate == 0){
            return 0;
        }
        uint256 totalHashRate;
        uint256 accReward = blockHeight.mul(_rewardPerBlock);
        uint256 rewardDiff;
        uint256 blockDiff;
        if (len == 1){
            if (_records[0].height == blockHeight){
                return 0;
            }
            totalHashRate = _records[0].totalHashRate;
            rewardDiff = accReward.sub(_records[0].accReward);
            blockDiff = blockHeight.sub(_records[0].height);
            profit = preHashrate.mul(rewardDiff).div(blockDiff).div(totalHashRate);
            return profit;
        }
        if (_records[len-1].height == blockHeight){
            totalHashRate = _records[len-2].totalHashRate;
            rewardDiff = _records[len-1].accReward.sub(_records[len-2].accReward);
            blockDiff = _records[len-1].height.sub(_records[len-2].height);
            profit = preHashrate.mul(rewardDiff).div(blockDiff).div(totalHashRate);
        }else{
            totalHashRate = _records[len-1].totalHashRate;
            rewardDiff = accReward.sub(_records[len-1].accReward);
            blockDiff = blockHeight.sub(_records[len-1].height);
            profit = preHashrate.mul(rewardDiff).div(blockDiff).div(totalHashRate);
        }
        return profit;
    }
    
    function queryAccReward(address account) public view returns(uint256){
        return _accTakeProfit[account].add(pendingReward(account));
    }
    
    function pendingReward(address account) public view returns(uint256){
        uint256 stakingNum = _infos[account].stakingNum;
        uint256 promoteNum = _infos[account].promoteNum;
        if (stakingNum == 0 && promoteNum == 0){
            return 0;
        }
        uint256 profit;
        uint256 totalProfit;
        uint256 blockHeight = _blockHeight();
        uint256 accReward = blockHeight.mul(_rewardPerBlock);
        uint len = _records.length;
        for(uint i=0; i<stakingNum; i++){
            Order storage order = _stakingOrders[account][i];
            if (order.status == 2){
                continue;
            }
            profit = _queryProfit(order,blockHeight,accReward,len);
            totalProfit = totalProfit.add(profit);
        }
        for(uint i=0; i<promoteNum; i++){
            Order storage order = _promoteOrders[account][i];
            if (order.status == 2){
                continue;
            }else if (order.status == 1){
                profit = _queryPromoteProfit(order);
            }else{
                profit = _queryProfit(order,blockHeight,accReward,len);
            }
            totalProfit = totalProfit.add(profit);
        }
        uint256 pendingProfit = _infos[account].pendingProfit;
        totalProfit = totalProfit.add(pendingProfit);
        return totalProfit;
    }
    
    function _queryPromoteProfit(Order storage order)internal view returns(uint256){
        uint256 profit;
        for(uint j=order.start; j<order.end; j++){
            uint256 totalHashRate = _records[j].totalHashRate;
            uint256 rewardDiff = _records[j+1].accReward.sub(_records[j].accReward);
            profit = rewardDiff.mul(order.hashRate).div(totalHashRate).add(profit);
        }
        if (profit > order.offsetProfit){
            profit = profit.sub(order.offsetProfit);
        }else {
            profit = 0;
        }
        return profit;
    }
    
    function _queryProfit(Order storage order, uint256 blockHeight, uint256 accReward, uint len)internal view returns(uint256){
        uint256 profit;
        uint256 totalHashRate;
        uint256 rewardDiff;
        uint start = order.start;
        for(uint j=start; j<len-1; j++){
            totalHashRate = _records[j].totalHashRate;
            rewardDiff = _records[j+1].accReward.sub(_records[j].accReward);
            profit = rewardDiff.mul(order.hashRate).div(totalHashRate).add(profit);
        }
        if (blockHeight > _records[len-1].height){
            totalHashRate = _records[len-1].totalHashRate;
            rewardDiff = accReward.sub(_records[len-1].accReward);
            profit = rewardDiff.mul(order.hashRate).div(totalHashRate).add(profit);
        }
        if (profit > order.offsetProfit){
            profit = profit.sub(order.offsetProfit);
        }else {
            profit = 0;
        }
        return profit;
    }
    
    function _calculateProfit(Order storage order, uint256 blockHeight, uint256 accReward, uint len)internal returns(uint256){
        uint start = order.start;
        uint256 profit;
        uint256 totalHashRate;
        uint256 rewardDiff;
        uint256 offsetProfit;
        for(uint j=start; j<len-1; j++){
            totalHashRate = _records[j].totalHashRate;
            rewardDiff = _records[j+1].accReward.sub(_records[j].accReward);
            profit = rewardDiff.mul(order.hashRate).div(totalHashRate).add(profit);
        }
        if (profit > 0){
            order.start = len-1;
        }
        offsetProfit = order.offsetProfit;
        if (blockHeight > _records[len-1].height){
            totalHashRate = _records[len-1].totalHashRate;
            rewardDiff = accReward.sub(_records[len-1].accReward);
            order.offsetProfit = rewardDiff.mul(order.hashRate).div(totalHashRate);
            profit = profit.add(order.offsetProfit);
        }
        if (profit > offsetProfit){
            profit = profit.sub(offsetProfit);
        }else{
            profit = 0;
        }
        
        return profit;
    }
    
    function redeemAllToken() external nonReentrant {
        bool canRedeem = canRedeemAllToken(address(msg.sender));
        require(canRedeem, "no free tokens");
        uint256 profit;
        uint256 totalProfit;
        
        uint256 blockHeight = _blockHeight();
        uint256 accReward = blockHeight.mul(_rewardPerBlock);
        uint len = _records.length;
        
        uint256 stakingNum = _infos[msg.sender].stakingNum;
        for(uint i=0; i<stakingNum; i++){
            Order storage order = _stakingOrders[msg.sender][i];
            if (order.status == 2 || block.timestamp < order.end){
                continue;
            }
            profit = _calculateProfit(order,blockHeight,accReward,len);
            totalProfit = totalProfit.add(profit);
        }
        require(totalProfit > 0);
        uint256 pendingProfit = _infos[msg.sender].pendingProfit;
        totalProfit = totalProfit.add(pendingProfit);
        
        uint256 allAmount;
        uint256 allHashRate;
        for(uint i=0; i<stakingNum; i++){
            Order storage order = _stakingOrders[msg.sender][i];
            if (order.status == 0 && block.timestamp >= order.end){
                allAmount = allAmount.add(order.amount);
                allHashRate = allHashRate.add(order.hashRate);
                order.status = 2;
                order.end = blockHeight;
            }
        }
        if (allAmount > 0){
            _stakedToken.safeTransfer(address(msg.sender),allAmount);
        }
        _infos[msg.sender].pendingProfit = totalProfit;
        _infos[msg.sender].stakingHashrate = _infos[msg.sender].stakingHashrate.sub(allHashRate);
            
        _totalHashRate = _totalHashRate.sub(allHashRate);
        _totalStakingHashRate = _totalStakingHashRate.sub(allHashRate);
        if (len > 0 && _records[len-1].height == blockHeight){
            BlockRecord storage record = _records[len-1];
            record.totalHashRate = record.totalHashRate.sub(allHashRate);
            record.accReward = accReward;
        }else{
            _records.push(BlockRecord(blockHeight,accReward,_totalHashRate));
        }
    }
    
    function canRedeemAllToken(address account) public view returns(bool) {
        uint256 stakingNum = _infos[account].stakingNum;
        if (stakingNum == 0) return false;
        uint256 redeemedNum; 
        for(uint i=0; i<stakingNum; i++){
            Order storage order = _stakingOrders[account][i];
            if (order.status == 0 && block.timestamp < order.end){
                return false;
            }
            if (order.status == 2) {
                redeemedNum++;
            }
        }
        if (redeemedNum == stakingNum) {
            return false;
        }
        return true;
    }
    
    function withdraw() external nonReentrant {
        uint256 stakingNum = _infos[msg.sender].stakingNum;
        uint256 promoteNum = _infos[msg.sender].promoteNum;
        require(stakingNum > 0 || promoteNum > 0);
        uint256 profit;
        uint256 totalProfit;
        
        uint256 blockHeight = _blockHeight();
        uint256 accReward = blockHeight.mul(_rewardPerBlock);
        uint len = _records.length;
        for(uint i=0; i<stakingNum; i++){
            Order storage order = _stakingOrders[msg.sender][i];
            if (order.status == 2){
                continue;
            }
            profit = _calculateProfit(order,blockHeight,accReward,len);
            totalProfit = totalProfit.add(profit);
        }
        for(uint i=0; i<promoteNum; i++){
            Order storage order = _promoteOrders[msg.sender][i];
            if (order.status == 2){
                continue;
            }else if (order.status == 1){
                profit = _queryPromoteProfit(order);
                order.status = 2;
            }else {
                profit = _calculateProfit(order,blockHeight,accReward,len);
            }
            totalProfit = totalProfit.add(profit);
        }
        uint256 pendingProfit = _infos[msg.sender].pendingProfit;
        totalProfit = totalProfit.add(pendingProfit);
        require(totalProfit > 0);
        _rewardToken.safeTransfer(address(msg.sender),totalProfit);
        _accTakeProfit[msg.sender] = _accTakeProfit[msg.sender].add(totalProfit);
        _infos[msg.sender].pendingProfit = 0;
    }
    
    function redeemToken(uint256 index) external nonReentrant {
        uint256 num = _infos[msg.sender].stakingNum;
        require(num > 0 && num > index);
        Order storage order = _stakingOrders[msg.sender][index];
        require(order.status == 0 && block.timestamp >= order.end);

        uint256 len = _records.length;
        uint256 blockHeight = _blockHeight();
        uint256 accReward = blockHeight.mul(_rewardPerBlock);
        uint256 profit = _calculateProfit(order,blockHeight,accReward,len);
      
        _stakedToken.safeTransfer(address(msg.sender),order.amount);
        order.status = 2;
        order.end = blockHeight;
        _infos[msg.sender].pendingProfit = _infos[msg.sender].pendingProfit.add(profit);
        _infos[msg.sender].stakingHashrate = _infos[msg.sender].stakingHashrate.sub(order.hashRate);
        
        _totalHashRate = _totalHashRate.sub(order.hashRate);
        _totalStakingHashRate = _totalStakingHashRate.sub(order.hashRate);
        if (len > 0 && _records[len-1].height == blockHeight){
            BlockRecord storage record = _records[len-1];
            record.totalHashRate = record.totalHashRate.sub(order.hashRate);
            record.accReward = accReward;
        }else{
            _records.push(BlockRecord(blockHeight,accReward,_totalHashRate));
        }
    }

    function getStakedNum(address account) public view returns(uint256){
        return _infos[account].stakingNum;
    }

    function getPromoteNum(address account) public view returns(uint256){
        return _infos[account].promoteNum;
    }
    
     function getAllTokenOrder(address account) public view returns(uint256[]memory){
        uint256 num = _infos[account].stakingNum;
        if (num == 0){
            uint256[] memory nullArray = new uint256[](1);
            nullArray[0] = 0;
            return nullArray;
        }
        uint256 size = 4;
        uint256 len = num*size+1;
        uint256[] memory orderArray = new uint256[](len);
        orderArray[0] = num;
        uint j;
        for(uint i=num; i>0;){
            j = i-1;
            Order storage order = _stakingOrders[account][j];
            orderArray[size*j+1] = order.amount;
            orderArray[size*j+2] = 0;
            if (order.status == 0){
                if (block.timestamp >= order.end) {
                    orderArray[size*j+2] = 1;
                } 
            } if (order.status == 2){
              orderArray[size*j+2] = 2;  
            }
            orderArray[size*j+3] = order.time;
            orderArray[size*j+4] = order.end;
            if (i == 1) break;
            i--;
        }
        return orderArray;
    }
    
    function getAllPromoteOrder(address account) public view returns(uint256[]memory){
        uint256 num = _infos[account].promoteNum;
        if (num == 0){
            uint256[] memory nullArray = new uint256[](1);
            nullArray[0] = 0;
            return nullArray;
        }
        uint256 size = 2;
        uint256 len = num*size+1;
        uint256 lastNum = 30;
        if (num > lastNum) {
            len = lastNum*size+1;
        }
        uint256[] memory orderArray = new uint256[](len);
        orderArray[0] = num;
        if (num > lastNum) {
            orderArray[0] = lastNum;
        }
        uint j;
        uint count;
        for(uint i=num; i>0;){
            j = i-1;
            Order storage order = _promoteOrders[account][j];
            orderArray[size*j+1] = order.hashRate;
            orderArray[size*j+2] = order.time;

            count++;
            if (count == lastNum) break;
            if (i == 1) break;
            i--;
        }
        return orderArray;
    }
    
    function getAllOrder(address account) external view returns(uint256[]memory, uint256[]memory){
        return (getAllTokenOrder(account), getAllPromoteOrder(account));
    }

    function userTotalHashRate(address account) public view returns(uint256){
        uint256 stakingHashrate = _infos[account].stakingHashrate;
        uint256 promoteHashrate = _infos[account].promoteHashrate;
        return stakingHashrate.add(promoteHashrate);
    }
    
    function userStakingHashRate(address account) public view returns(uint256){
        return _infos[account].stakingHashrate;
    }

    function userPromoteHashRate(address account) public view returns(uint256){
        return _infos[account].promoteHashrate;
    }

    function userStakingToken(address account) public view returns(uint256){
        uint256 num = _infos[account].stakingNum;
        if (num == 0){
            return 0;
        }
        uint256 totalToken;
        for(uint i=0; i<num; i++){
           Order storage order = _stakingOrders[account][i];
           if (order.status == 2){
                continue;
           }
           totalToken = totalToken.add(order.amount);
        }
        return totalToken;
    }
    
    function userHashrateRatio(address account) public view returns(uint256){
        if (_totalHashRate > 0){
            return userTotalHashRate(account).mul(10**18).div(_totalHashRate);
        }
        return 0;
    }
    
    function emergencyRewardWithdraw(uint256 amount) external onlyOwner {
        _rewardToken.safeTransfer(address(msg.sender), amount);
    }

    function recoverWrongTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(_stakedToken), "Cannot be staked token");
        require(tokenAddress != address(_rewardToken), "Cannot be reward token");

        IBEP20(tokenAddress).safeTransfer(address(msg.sender), tokenAmount);
    }

    function stopReward() external onlyOwner {
        _endTime = block.timestamp;
    }

    function updateRewardPerBlock(uint256 rewardPerBlock) external onlyOwner {
        require(_totalHashRate == 0, "Pool has started");
        _rewardPerBlock = rewardPerBlock;
    }

    function updateIntervalPerBlock(uint256 intervalPerBlock) external onlyOwner {
        require(_totalHashRate == 0, "Pool has started");
        _intervalPerBlock = intervalPerBlock;
    }

    function updateLockPeriod(uint256 lockPeriod) external onlyOwner {
        require(_totalHashRate == 0, "Pool has started");
        _lockPeriod = lockPeriod;
    }

    function updateStartAndEndTime(uint256 startTime, uint256 endTime) external onlyOwner {
        require(_totalHashRate == 0, "Pool has started");
        require(startTime < endTime, "New startTime must be lower than new endTime");
        require(block.timestamp < startTime, "New startTime must be higher than current time");

        _startTime = startTime;
        _endTime = endTime;
    }

    function updateGenerationRewards(uint256 [] memory genRewards) external onlyOwner {
        require(_totalHashRate == 0, "Pool has started");
        generationRewards = genRewards;
    }

    function getGenerationRewards() external view returns (uint256[] memory) {
        return generationRewards;
    }

    function getBaseInfos() external view returns(uint256[] memory, string[] memory, address[] memory, uint256[] memory){
        uint256[] memory array = new uint256[](11);
        array[0] = _totalStakingHashRate;
        array[1] = _intervalPerBlock;
        array[2] = _rewardPerBlock;
        array[3] = _startTime;
        array[4] = _endTime;
        array[5] = _stakedToken.decimals();
        array[6] = _rewardToken.decimals();
        array[7] = _lockPeriod;
        array[8] = _totalHashRate;
        array[9] = _totalStakingHashRate;
        array[10] = _totalPromoteHashRate;
        string[] memory strs = new string[](2);
        strs[0] = _stakedToken.symbol();
        strs[1] = _rewardToken.symbol();
        address[] memory addresses = new address[](2);
        addresses[0] = address(_stakedToken);
        addresses[1] = address(_rewardToken);
        return (array, strs, addresses, generationRewards);
    }

    function getUserInfos(address account) external view returns(uint256[] memory, uint256[] memory, uint256[] memory){
        uint256[] memory array = new uint256[](10);
        array[0] = _stakedToken.balanceOf(account);
        array[1] = _stakedToken.allowance(account, address(this));
        array[2] = userStakingToken(account);
        array[3] = pendingReward(account);
        array[4] = queryAccReward(account);
        array[5] = userHashrateRatio(account);
        array[6] = userTotalHashRate(account);
        array[7] = _infos[account].stakingHashrate;
        array[8] = _infos[account].promoteHashrate;
        array[9] = _totalHashRate > 0 ? userTotalHashRate(account).mul(_rewardPerBlock).div(_totalHashRate) : 0;
        
        return (array, getAllTokenOrder(account), getAllPromoteOrder(account));
    }
}