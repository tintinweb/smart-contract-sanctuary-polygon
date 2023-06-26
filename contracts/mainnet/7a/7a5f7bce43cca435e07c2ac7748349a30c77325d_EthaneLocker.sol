/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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

interface IEthaneLocker {

    struct LockInfo {
        uint256 amount;
        uint256 duration;
    }

    function getLocks(address owner, address token) external returns (LockInfo[] memory);

    function lockTokens(address token, uint256 amount, uint duration) external;

    function extendLock(address token, uint duration, uint index) external;

    function withdraw(address token, uint256 amount, uint index) external;
}

contract EthaneLocker is IEthaneLocker {

    uint baseDuration = 1 minutes;
    address payable private immutable deployer;
    IERC20 public gETH = IERC20(0xa109dA08b3e79E553E97A8dB1BE4995a90f8932f);

    uint256 public rate = 4 * 10**16; // 0.04 gETH
    uint256 public lockEventIndex;
    uint256 public lastLockEventIndexUpdate;
    uint256 public leftSummation;
    uint256 public totalStaked;
    IERC20 public token;

    struct TokenInfo {
        address creator;
        uint256 amount;
        uint256 duration;
    }

    mapping(address => uint256) public rightSummation;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;

    mapping(address => mapping(address => LockInfo[])) private lockedTokens; // Owner -> (Token -> LockInfo)

    mapping(address => TokenInfo[]) private tokenRecords; // Token -> TokenInfo

    constructor(address payable _deployer, uint256 _lockEventIndex, address _token) {
        deployer = _deployer;
        lockEventIndex = _lockEventIndex;
        token = IERC20(_token);
    }

    /* STAKING */

    function stake(uint256 amount) external updateInfo(msg.sender) {
        require((token.balanceOf(msg.sender) - (balances[msg.sender] + amount)) >= 0, "Exceeds Balance.");
        totalStaked += amount;
        balances[msg.sender] += amount;
    }

    function unstake(uint256 amount) external updateInfo(msg.sender) {
        require(balances[msg.sender] - amount >= 0, "Insufficient Balance.");
        totalStaked -= amount;
        balances[msg.sender] -= amount;

    }

    function claim() external updateInfo(msg.sender) {
        require(token.balanceOf(msg.sender) >= balances[msg.sender], "Insufficient Balance.");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        gETH.transfer(msg.sender, reward);
    }

    function amountEarned(address account) public view returns (uint256) {
        return (balances[account] * (leftSum() - rightSummation[account]) / 1e18) + rewards[account];
    }

    function leftSum() public view returns (uint256) {
        if(totalStaked == 0) return 0;

        return leftSummation + (rate * (lockEventIndex - lastLockEventIndexUpdate) * 1e18 / totalStaked);
    }

    modifier updateInfo(address account) {
        leftSummation = leftSum();
        lastLockEventIndexUpdate = lockEventIndex;
        rewards[account] = amountEarned(account);
        rightSummation[account] = leftSummation;
        _;
    }

    /* TOKEN LOCKING */

    function getTokenRecords(address _token) public view returns (TokenInfo[] memory) {
        return tokenRecords[_token];
    }

    function getLocks(address owner, address _token) public view returns (LockInfo[] memory) {
        return lockedTokens[owner][_token];
    }

    function lockTokens(address _token, uint256 amount, uint duration) public {
        require(duration > 0, "You must lock for at least 1 day.");
        require(gETH.transferFrom(msg.sender, address(this), 4 * 10**16), "It costs 0.04 gETH to lock LP.");
        require(IERC20(_token).balanceOf(msg.sender) >= amount);

        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        gETH.transfer(deployer, 1 * 10**16);

        LockInfo memory newLock = LockInfo(amount, (block.timestamp + (baseDuration*duration)));
        lockedTokens[msg.sender][_token].push(newLock);
        lockEventIndex++;

        TokenInfo memory newInfo = TokenInfo(msg.sender, amount, (block.timestamp + (baseDuration*duration)));
        tokenRecords[_token].push(newInfo);
    }

    function extendLock(address _token, uint duration, uint index) public {
        require(index > 0, "You must extend the lock by at least 1 day.");
        require(gETH.transferFrom(msg.sender, address(this), 4 * 10**16), "It costs 0.04 gETH to extend the lock.");
        require(((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration)) > lockedTokens[msg.sender][_token][index].duration, "New duration must exceed current one.");
        
        gETH.transfer(deployer, 1 * 10**16);
        uint256 amount = lockedTokens[msg.sender][_token][index].amount;
        LockInfo memory extendedLock = LockInfo(amount, ((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration)));
        lockedTokens[msg.sender][_token][index] = extendedLock;
        lockEventIndex++;

        TokenInfo memory newInfo = TokenInfo(msg.sender, amount, ((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration)));
        tokenRecords[_token].push(newInfo);
    }

    function splitLock(address _token, uint256 amount, uint duration, uint index) public {
        require(gETH.transferFrom(msg.sender, address(this), 4 * 10**16), "It costs 0.04 gETH to split the lock.");
        require(amount > 0 && amount < (lockedTokens[msg.sender][_token][index].amount), "Invalid amount.");

        gETH.transfer(deployer, 1 * 10**16);
        uint256 oldAmount = lockedTokens[msg.sender][_token][index].amount;
        uint256 newSplitDuration = ((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration));
        LockInfo memory firstSplit = LockInfo(oldAmount - amount, (lockedTokens[msg.sender][_token][index].duration));
        LockInfo memory otherSplit = LockInfo(amount, newSplitDuration);
        lockedTokens[msg.sender][_token][index] = firstSplit;
        lockedTokens[msg.sender][_token].push(otherSplit);
        lockEventIndex++;

        TokenInfo memory firstSplitInfo = TokenInfo(msg.sender, oldAmount - amount, (lockedTokens[msg.sender][_token][index].duration));
        TokenInfo memory otherSplitInfo = TokenInfo(msg.sender, amount, newSplitDuration);
        tokenRecords[_token].push(firstSplitInfo);
        tokenRecords[_token].push(otherSplitInfo);
    }

    function withdraw(address _token, uint amount, uint index) public {
        require(block.timestamp > lockedTokens[msg.sender][_token][index].duration, "Cannot unlock before deadline.");
        IERC20(_token).transfer(msg.sender, amount);
    }
}