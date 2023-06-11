/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

contract TokenInvestmentContract {
    address public owner;
    address public tokenAddress;
    uint public minDeposit;
    uint public dailyProfitPercentage;
    uint public profitFeePercentage;
    uint public capitalFeePercentage;
    uint public referralCommissionPercentage;
    uint public profitDistributionInterval = 1 days;

    struct Investor {
        uint initialCapital;
        uint profit;
        uint lastProfitDistributionTime;
    }

    mapping(address => Investor) public investors;
    mapping(address => address) public referrals;

    event Deposit(address indexed investor, uint amount);
    event WithdrawProfit(address indexed investor, uint amount);
    event WithdrawCapital(address indexed investor, uint amount);

    constructor(address _tokenAddress, uint tokenDecimals) {
        owner = msg.sender;
        dailyProfitPercentage = 1;
        profitFeePercentage = 5;
        capitalFeePercentage = 15;
        referralCommissionPercentage = 3;
        tokenAddress = _tokenAddress;
        minDeposit = 30 * (10 ** tokenDecimals);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    function changeMinDeposit(uint newAmount) external onlyOwner {
        minDeposit = newAmount;
    }

    function changeDailyProfitPercentage(
        uint newPercentage
    ) external onlyOwner {
        dailyProfitPercentage = newPercentage;
    }

    function changeProfitFeePercentage(uint newPercentage) external onlyOwner {
        profitFeePercentage = newPercentage;
    }

    function changeCapitalFeePercentage(uint newPercentage) external onlyOwner {
        capitalFeePercentage = newPercentage;
    }

    function changeReferralCommissionPercentage(
        uint newPercentage
    ) external onlyOwner {
        referralCommissionPercentage = newPercentage;
    }

    function deposit(uint tokenAmount, address referral) external {
        require(tokenAmount >= minDeposit, "Amount less than minimum required");

        distributeProfit(msg.sender);

        uint depositAmount = tokenAmount;
        uint referralCommission = 0;

        if (referral != address(0) && referral != msg.sender) {
            referrals[msg.sender] = referral;
            referralCommission =
                (depositAmount * referralCommissionPercentage) /
                100;
            investors[referral].profit += referralCommission;
        }

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );

        investors[msg.sender].initialCapital +=
            depositAmount -
            referralCommission;
        investors[msg.sender].lastProfitDistributionTime = block.timestamp;
        emit Deposit(msg.sender, depositAmount);
    }

    function withdrawProfit() external {
        distributeProfit(msg.sender);

        uint profitAmount = investors[msg.sender].profit;
        require(profitAmount > 0, "No profit available for withdrawal.");

        uint feeAmount = (profitAmount * profitFeePercentage) / 100;
        uint withdrawAmount = profitAmount - feeAmount;

        investors[msg.sender].profit = 0;
        IERC20(tokenAddress).transfer(msg.sender, withdrawAmount);
        emit WithdrawProfit(msg.sender, withdrawAmount);
    }

    function withdrawCapital() external {
        distributeProfit(msg.sender);

        uint initialCapital = investors[msg.sender].initialCapital;
        require(initialCapital > 0, "No capital available for withdrawal.");

        uint feeAmount = (initialCapital * capitalFeePercentage) / 100;
        uint withdrawAmount = initialCapital - feeAmount;

        investors[msg.sender].initialCapital = 0;

        IERC20(tokenAddress).transfer(msg.sender, withdrawAmount);
        emit WithdrawCapital(msg.sender, withdrawAmount);
    }

    function distributeProfit(address investor) internal {
        uint lastDistributionTime = investors[investor]
            .lastProfitDistributionTime;
        uint timePassed = block.timestamp - lastDistributionTime;

        if (timePassed >= profitDistributionInterval) {
            uint numProfitDistributions = timePassed /
                profitDistributionInterval;
            uint profitAmount = (investors[investor].initialCapital *
                dailyProfitPercentage) / 100;

            if (numProfitDistributions > 0 && profitAmount > 0) {
                investors[investor].profit +=
                    profitAmount *
                    numProfitDistributions;
                investors[investor].lastProfitDistributionTime +=
                    profitDistributionInterval *
                    numProfitDistributions;
            }
        }
    }

    function withdrawTokens(uint amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }

    function getContractTokenBalance() public view returns (uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}