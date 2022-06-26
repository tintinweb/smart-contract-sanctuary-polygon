/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// SPDX-License-Identifier: MIT
/*
                                                                                                           
                                                                                                           
____      ___                                           ___                                                
`MM(      )M'                                           `MM                68b               68b           
 `MM.     d'                                             MM                Y89               Y89           
  `MM.   d' ___  __   _____     ____     ____     ____   MM  __      ___   ___ ___  __       ___   _____   
   `MM. d'  `MM 6MM  6MMMMMb   6MMMMb\  6MMMMb\  6MMMMb. MM 6MMb   6MMMMb  `MM `MM 6MMb      `MM  6MMMMMb  
    `MMd     MM69 " 6M'   `Mb MM'    ` MM'    ` 6M'   Mb MMM9 `Mb 8M'  `Mb  MM  MMM9 `Mb      MM 6M'   `Mb 
     dMM.    MM'    MM     MM YM.      YM.      MM    `' MM'   MM     ,oMM  MM  MM'   MM      MM MM     MM 
    d'`MM.   MM     MM     MM  YMMMMb   YMMMMb  MM       MM    MM ,6MM9'MM  MM  MM    MM      MM MM     MM 
   d'  `MM.  MM     MM     MM      `Mb      `Mb MM       MM    MM MM'   MM  MM  MM    MM      MM MM     MM 
  d'    `MM. MM     YM.   ,M9 L    ,MM L    ,MM YM.   d9 MM    MM MM.  ,MM  MM  MM    MM 68b  MM YM.   ,M9 
_M(_    _)MM_MM_     YMMMMM9  MYMMMM9  MYMMMM9   YMMMM9 _MM_  _MM_`YMMM9'Yb_MM__MM_  _MM_Y89 _MM_ YMMMMM9  
                                                                                                           

                                                                                 
https://ftm.xrosschain.io/                                                            
*/
pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts-old/math/[email protected]

pragma solidity ^0.6.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.6.2;

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File @openzeppelin/contracts-old/token/ERC20/[email protected]

pragma solidity ^0.6.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/distribution/Node.sol

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

contract Node {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public constant TOKEN = IERC20(0x5DB59F9cE5D832013faF387F609875311e433ABD);
    uint256[] public tierAllocPoints = [1 ether, 1 ether, 1 ether];
    uint256[] public tierAmounts = [50 ether, 500 ether, 5000 ether];
    struct User {
        uint256 total_deposits;
        uint256 total_claims;
        uint256 last_distPoints;
    }

    event CreateNode(uint256 timestamp, address account, uint256 num);

    address private dev;
    
    mapping(address => User) public users;
    mapping(address => mapping(uint256 => uint256)) public nodes;
    mapping(uint256 => uint256) public totalNodes;
    address[] public userIndices;

    uint256 public total_deposited;
    uint256 public total_claimed;
    uint256 public total_rewards;
    uint256 public treasury_rewards;
    uint256 public treasuryFeePercent;
    uint256 public totalDistributeRewards;
    uint256 public totalDistributePoints;
    uint256 public maxReturnPercent;
    uint256 public dripRate;
    uint256 public lastDripTime;
    uint256 public startTime;
    bool public enabled;
    uint256 public constant MULTIPLIER = 10e18;


    constructor(uint256 _startTime) public {
        maxReturnPercent = 500; 
        dripRate = 2400000; 
        treasuryFeePercent = 20; 

        lastDripTime = _startTime > block.timestamp ? _startTime : block.timestamp;
        startTime = _startTime;
        enabled = true;
        dev = msg.sender;
    }

    receive() external payable {
        revert("Do not send FTM.");
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function changeDev(address payable newDev) external onlyDev {
        require(newDev != address(0), "Zero address");
        dev = newDev;
    }

    function claimTreasuryRewards() external {
        if (treasury_rewards > 0) {
            TOKEN.safeTransfer(dev, treasury_rewards);
            treasury_rewards = 0;
        }   
    }

    function setStartTime(uint256 _startTime) external onlyDev {
        startTime = _startTime;
    }
    
    function setEnabled(bool _enabled) external onlyDev {
        enabled = _enabled;
    }

    function setTreasuryFeePercent(uint256 percent) external onlyDev {
        treasuryFeePercent = percent;
    }

    function setDripRate(uint256 rate) external onlyDev {
        dripRate = rate;
    }
    
    function setLastDripTime(uint256 timestamp) external onlyDev {
        lastDripTime = timestamp;
    }

    function setMaxReturnPercent(uint256 percent) external onlyDev {
        maxReturnPercent = percent;
    }

    function setTierValues(uint256[] memory _tierAllocPoints, uint256[] memory _tierAmounts) external onlyDev {
        require(_tierAllocPoints.length == _tierAmounts.length, "Length mismatch");
        tierAllocPoints = _tierAllocPoints;
        tierAmounts = _tierAmounts;
    }

    function setUser(address _addr, User memory _user) external onlyDev {
        total_deposited = total_deposited.sub(users[_addr].total_deposits).add(_user.total_deposits);
        total_claimed = total_claimed.sub(users[_addr].total_claims).add(_user.total_claims);
        users[_addr].total_deposits = _user.total_deposits;
        users[_addr].total_claims = _user.total_claims;
    }

    function setNodes(address _user, uint256[] memory _nodes) external onlyDev {
        for(uint256 i = 0; i < _nodes.length; i++) {
            totalNodes[i] = totalNodes[i].sub(nodes[_user][i]).add( _nodes[i]);
            nodes[_user][i] = _nodes[i];
        }
    }

    function totalAllocPoints() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            total = total.add(tierAllocPoints[i].mul(totalNodes[i]));
        }
        return total;
    }

    function allocPoints(address account) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            total = total.add(tierAllocPoints[i].mul(nodes[account][i]));
        }
        return total;
    }

    function getDistributionRewards(address account) public view returns (uint256) {
        if (isMaxPayout(account)) return 0;

        uint256 newDividendPoints = totalDistributePoints.sub(users[account].last_distPoints);
        uint256 distribute = allocPoints(account).mul(newDividendPoints).div(MULTIPLIER);
        return distribute > total_rewards ? total_rewards : distribute;
    }
    
    function getTotalRewards(address _sender) public view returns (uint256) {
        if (users[_sender].total_deposits == 0) 
            return 0;

        uint256 rewards = getDistributionRewards(_sender).add(getRewardDrip().mul(allocPoints(_sender)).div(totalAllocPoints()));
        uint256 totalClaims = users[_sender].total_claims;
        uint256 maxPay = maxPayout(_sender);

        // Payout remaining if exceeds max payout
        return totalClaims.add(rewards) > maxPay ? maxPay.sub(totalClaims) : rewards;
    }

    function create(uint256 nodeTier, uint256 numNodes) external {
        address _sender = msg.sender;
        require(enabled && block.timestamp >= startTime, "Disabled");
        require(nodeTier < tierAllocPoints.length && nodeTier < tierAmounts.length, "Invalid nodeTier");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && isMaxPayout(_sender)) {
            users[_sender].last_distPoints = totalDistributePoints;
        }

        uint256 tierPrice = tierAmounts[nodeTier].mul(numNodes);

        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice);

        total_deposited = total_deposited.add(tierPrice);
        treasury_rewards = treasury_rewards.add(
            tierPrice.mul(treasuryFeePercent).div(100)
        );

        nodes[_sender][nodeTier] = nodes[_sender][nodeTier].add(numNodes);
        totalNodes[nodeTier] = totalNodes[nodeTier].add(numNodes);

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function claim() public {
        dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getDistributionRewards(_sender);
        
        if (_rewards > 0) {
            
            total_rewards = total_rewards.sub(_rewards);
            uint256 totalClaims = users[_sender].total_claims;
            uint256 maxPay = maxPayout(_sender);

            // Payout remaining if exceeds max payout
            if(totalClaims.add(_rewards) > maxPay) {
                _rewards = maxPay.sub(totalClaims);
            }

            users[_sender].total_claims = users[_sender].total_claims.add(_rewards);
            total_claimed = total_claimed.add(_rewards);

            IERC20(TOKEN).safeTransfer(_sender, _rewards);

            users[_sender].last_distPoints = totalDistributePoints;
        }
    }

    function _compound(uint256 nodeTier, uint256 numNodes) internal {
        address _sender = msg.sender;
        require(enabled && block.timestamp >= startTime, "Disabled");
        require(nodeTier < tierAllocPoints.length && nodeTier < tierAmounts.length, "Invalid nodeTier");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && isMaxPayout(_sender)) {
            users[_sender].last_distPoints = totalDistributePoints;
        }

        uint256 tierPrice = tierAmounts[nodeTier].mul(numNodes);
        
        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice);
        
        total_deposited = total_deposited.add(tierPrice);
        treasury_rewards = treasury_rewards.add(
            tierPrice.mul(treasuryFeePercent).div(100)
        );
        
        nodes[_sender][nodeTier] = nodes[_sender][nodeTier].add(numNodes);
        totalNodes[nodeTier] = totalNodes[nodeTier].add(numNodes);

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function compound() public {
      uint256 rewardsPending = getTotalRewards(msg.sender);  
      require(rewardsPending >= tierAmounts[0], "Not enough to compound");  
      uint256 numPossible = rewardsPending.div(tierAmounts[0]);
      claim();
      _compound(0, numPossible);
    }


    function maxPayout(address _sender) public view returns (uint256) {
        return users[_sender].total_deposits.mul(maxReturnPercent).div(100);
    }

    function isMaxPayout(address _sender) public view returns (bool) {
        return users[_sender].total_claims >= maxPayout(_sender);
    }

    function _disperse(uint256 amount) internal {
        if (amount > 0 ) {
            totalDistributePoints = totalDistributePoints.add(amount.mul(MULTIPLIER).div(totalAllocPoints()));
            totalDistributeRewards = totalDistributeRewards.add(amount);
            total_rewards = total_rewards.add(amount);
        }
    }

    function dripRewards() public {
        uint256 drip = getRewardDrip();

        if (drip > 0) {
            _disperse(drip);
            lastDripTime = block.timestamp;
        }
    }

    function getRewardDrip() public view returns (uint256) {
        if (lastDripTime < block.timestamp) {
            uint256 poolBalance = getBalancePool();
            uint256 secondsPassed = block.timestamp.sub(lastDripTime);
            uint256 drip = secondsPassed.mul(poolBalance).div(dripRate);

            if (drip > poolBalance) {
                drip = poolBalance;
            }

            return drip;
        }
        return 0;
    }

    function getDayDripEstimate(address _user) external view returns (uint256) {
        return
            allocPoints(_user) > 0 && !isMaxPayout(_user)
                ? getBalancePool()
                    .mul(86400)
                    .mul(allocPoints(_user))
                    .div(totalAllocPoints())
                    .div(dripRate)
                : 0;
    }

    function total_users() external view returns (uint256) {
        return userIndices.length;
    }

    function numNodes(address _sender, uint256 _nodeId) external view returns (uint256) {
        return nodes[_sender][_nodeId];
    }

    function getNodes(address _sender) external view returns (uint256[] memory) {
        uint256[] memory userNodes = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            userNodes[i] = userNodes[i].add(nodes[_sender][i]);
        }
        return userNodes;
    }
    
    function getTotalNodes() external view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](tierAllocPoints.length);
        for (uint256 i = 0; i < tierAllocPoints.length; i++) {
            totals[i] = totals[i].add(totalNodes[i]);
        }
        return totals;
    }

    function getBalance() public view returns (uint256) {
        return IERC20(TOKEN).balanceOf(address(this));
    }

     function getBalancePool() public view returns (uint256) {
        return getBalance().sub(total_rewards).sub(treasury_rewards);
    }

    function emergencyWithdraw(IERC20 token, uint256 amnt) external onlyDev {
        token.safeTransfer(dev, amnt);
    }
}