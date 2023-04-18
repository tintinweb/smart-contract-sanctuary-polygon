/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity ^0.8.0;

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
pragma solidity ^0.8.11;
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StakeP2P is Pausable, Ownable, ReentrancyGuard {
    IERC20 public p2pptoken;
    uint8 public poolCount = 0;
    uint256 public stakeFee;
    struct StakeInfo {
        uint256 stakedAmount;
        uint256 totalReward;
        uint256 lastClaimed;
    }
    struct poolInfo {
        uint256 interestRate;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmountStaked;
        uint256 totalrewardClaimed;
        bool active;
    }
    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);
    mapping(uint256 => poolInfo) public poolInfos;
    mapping(address => mapping(uint256 => StakeInfo)) public stakeInfos;

    constructor(address _tokenAddress) {
        require(
            address(_tokenAddress) != address(0),
            "Token Address cannot be address 0"
        );
        p2pptoken = IERC20(_tokenAddress);
    }

    function addPool(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _interestRate
    ) public onlyOwner {
        poolInfos[poolCount].interestRate = _interestRate;
        poolInfos[poolCount].startTime = _startTime;
        poolInfos[poolCount].endTime = _endTime;
        poolInfos[poolCount].active = true;
        poolCount++;
    }

    function stakeToken(uint256 poolId, uint256 stakeAmount)
        external
        whenNotPaused
    {
        require(poolInfos[poolId].active == true, "this pool is inactive");
        require(poolInfos[poolId].endTime > block.timestamp, "Plan Expired");
        require(
            p2pptoken.balanceOf(msg.sender) >= stakeAmount,
            "Insufficient Balance"
        );
        claimReward(poolId);
        poolInfos[poolId].totalAmountStaked =
            poolInfos[poolId].totalAmountStaked +
            stakeAmount;
        stakeInfos[msg.sender][poolId].stakedAmount =
            stakeAmount +
            stakeInfos[msg.sender][poolId].stakedAmount;
        stakeInfos[msg.sender][poolId].lastClaimed = block.timestamp;
        p2pptoken.transferFrom(msg.sender, address(this), stakeAmount);
        emit Staked(msg.sender, stakeAmount);
    }

    function claimReward(uint256 poolId) public {
        require(
            poolInfos[poolId].endTime > block.timestamp,
            "reward period is over,please unstake"
        );
        uint256 stakeAmount = stakeInfos[msg.sender][poolId].stakedAmount;
        uint256 rewardPoolPerSecond = (stakeAmount *
            poolInfos[poolId].interestRate *
            1E20) / (poolInfos[poolId].endTime - poolInfos[poolId].startTime);
        uint256 reward = ((block.timestamp -
            stakeInfos[msg.sender][poolId].lastClaimed) * rewardPoolPerSecond) /
            1E22;
        stakeInfos[msg.sender][poolId].totalReward =
            stakeInfos[msg.sender][poolId].totalReward +
            reward;
        stakeInfos[msg.sender][poolId].lastClaimed = block.timestamp;
        p2pptoken.transfer(msg.sender, reward);
        emit Claimed(msg.sender, reward);
    }

    function unstake(uint256 poolId, uint256 unStakeAmount) external payable {
        require(stakeFee == msg.value);
        require(
            stakeInfos[msg.sender][poolId].stakedAmount >= unStakeAmount,
            " stake amount is insufficient "
        );
        uint256 rewardPoolPerSecond = (stakeInfos[msg.sender][poolId]
            .stakedAmount *
            poolInfos[poolId].interestRate *
            1E20) / (poolInfos[poolId].endTime - poolInfos[poolId].startTime);
        if (poolInfos[poolId].endTime > block.timestamp) {
            stakeInfos[msg.sender][poolId].stakedAmount -= unStakeAmount;
            uint256 reward = ((block.timestamp -
                stakeInfos[msg.sender][poolId].lastClaimed) *
                rewardPoolPerSecond) / 1E22;
            stakeInfos[msg.sender][poolId].totalReward =
                stakeInfos[msg.sender][poolId].totalReward +
                reward;
            p2pptoken.transfer(msg.sender, reward + unStakeAmount);
        }
        if (poolInfos[poolId].endTime < block.timestamp) {
            uint256 amount = stakeInfos[msg.sender][poolId].stakedAmount;
            uint256 reward1 = ((poolInfos[poolId].endTime -
                stakeInfos[msg.sender][poolId].lastClaimed) *
                rewardPoolPerSecond) / 1E22;
            stakeInfos[msg.sender][poolId].totalReward =
                stakeInfos[msg.sender][poolId].totalReward +
                reward1;
            p2pptoken.transfer(msg.sender, reward1 + amount);
            stakeInfos[msg.sender][poolId].stakedAmount = 0;
        }
        stakeInfos[msg.sender][poolId].lastClaimed = block.timestamp;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        stakeFee = _fee;
    }

    function emergencyWithdrawNative() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function emergencyWithdrawErc20(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}