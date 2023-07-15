/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

pragma solidity ^0.8.18;
//SPDX-License-Identifier: MIT

contract StakeSHR {
    address public adminAddr;
    address public projectAddr;
    address public developerAddr;
    address public maintenanceAddr;
    uint256 public referralLevel1Rate = 7;
    uint256 public referralLevel2Rate = 2;
    uint256 public referralLevel3Rate = 1;
    uint256 public monthlyPrecentage = 7;
    uint256 public adminFeeRate = 40;
    uint256 public maintenanceFee = 5;
    uint256 public developerFeeRate = 1;
    uint256 public  withdrawFees = 3; // 1 for developer 2 mantaince 
    
    uint256 public capitalzcWithdrawalFeeRate = 15; // 1 developer 14 mataince

    struct User {
        uint256 balance;
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        address referral;
        uint256 referralEarnings;
        bool blocked;
    }

    struct CapitalWithdrawalRequest {
        address user;
        uint256 amount;
        bool approved;
    }

    mapping(address => User) public users;
    CapitalWithdrawalRequest[] public capitalWithdrawalRequests;

    constructor(address _adminAddr, address _projectAddr, address _maintenanceAddr,address _developerAddr) {
        adminAddr = _adminAddr;
        projectAddr = _projectAddr;
        developerAddr = _developerAddr;
        maintenanceAddr = _maintenanceAddr;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddr, "Only admin can call this function");
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == developerAddr, "Only developer can call this function");
        _;
    }

    modifier notBlocked() {
        require(!users[msg.sender].blocked, "User is blocked");
        _;
    }

    modifier validReferral(address _referral) {
        require(_referral != msg.sender, "Cannot set self as upline partner");
        _;
    }

    function invest(address _referral) external payable notBlocked validReferral(_referral) {
    require(msg.value >= 0.01 ether, "Minimum amount for investing is 0.01 ether");

    User storage user = users[msg.sender];
    if (user.referral == address(0)) {
        user.referral = _referral;
    }

    uint256 referralEarnings = (msg.value * referralLevel1Rate) / 100;
    users[user.referral].referralEarnings += referralEarnings;

    address referrer2 = users[user.referral].referral;
    if (referrer2 != address(0)) {
        uint256 referralEarnings2 = (msg.value * referralLevel2Rate) / 100;
        users[referrer2].referralEarnings += referralEarnings2;

        address referrer3 = users[referrer2].referral;
        if (referrer3 != address(0)) {
            uint256 referralEarnings3 = (msg.value * referralLevel3Rate) / 100;
            users[referrer3].referralEarnings += referralEarnings3;
        }
    }
    uint256 maintenanceValue = (msg.value * maintenanceFee)/1000;
    uint256 adminFee = (msg.value - maintenanceValue * adminFeeRate) / 1000;
    uint256 projectFee = msg.value - referralEarnings - adminFee ;

    // Transfer fees
    payable(maintenanceAddr).transfer(maintenanceValue);
    payable(adminAddr).transfer(adminFee);
    payable(projectAddr).transfer(projectFee);

    user.balance += msg.value - maintenanceFee;
    user.totalDeposits += msg.value - maintenanceFee; // Update totalDeposits value
}


    function withdraw(uint256 _amount) external notBlocked {
        require(_amount > 0, "Invalid withdrawal amount");
        User storage user = users[msg.sender];

        uint256 profit = calculateProfit(msg.sender);
            require(profit >= _amount, "Insufficient profit for withdrawal");
        require(user.balance >= profit, "Insufficient balance for withdrawal");

        uint256 adminFee = (profit * 2) / 100;
        uint256 devVal = (profit * 1) / 1000;
        uint256 withdrawAmount = _amount - adminFee - devVal;

        user.balance -= _amount;
        user.totalWithdrawals += withdrawAmount;

        // Transfer fees
        payable(maintenanceAddr).transfer(adminFee);
        payable(developerAddr).transfer(devVal);
        payable(msg.sender).transfer(withdrawAmount);
    }
    ///
    function reinvest() external notBlocked {
        User storage user = users[msg.sender];

        uint256 profit = calculateProfit(msg.sender);
        require(profit > 0, "No profit available");

        uint256 reinvestAmount = profit;

        user.balance += reinvestAmount;
        user.totalDeposits += reinvestAmount;

        // Transfer
        payable(projectAddr).transfer(reinvestAmount);
    }
    function capitalWithdraw(uint256 _amount) external notBlocked {
        User storage user = users[msg.sender];
        require(user.balance >= _amount, "Insufficient balance for capital withdrawal");

        CapitalWithdrawalRequest memory request = CapitalWithdrawalRequest(msg.sender, _amount, false);
        capitalWithdrawalRequests.push(request);
    }

    function approveCapitalWithdrawal(uint256 _requestIndex) external onlyAdmin {
    require(_requestIndex < capitalWithdrawalRequests.length, "Invalid request index");

    CapitalWithdrawalRequest storage request = capitalWithdrawalRequests[_requestIndex];
    require(!request.approved, "Request already approved");

    User storage user = users[request.user];
    require(user.balance >= request.amount, "Insufficient balance for capital withdrawal");

    uint256 projectFee = (request.amount * 14) / 1000;
    uint256 developerFee = (request.amount * developerFeeRate) / 1000;

    user.balance -= request.amount;
    user.totalWithdrawals += request.amount;

    // Transfer fees and amount
    payable(projectAddr).transfer(projectFee);
    payable(developerAddr).transfer(developerFee);
    payable(request.user).transfer(request.amount  - projectFee - developerFee);

    request.approved = true;
}

    function calculateProfit(address _user) internal view returns (uint256) {
        User storage user = users[_user];
        uint256 daysSinceLastDeposit = (block.timestamp - user.totalDeposits) / 86400;
        uint256 monthlyInterest = (monthlyPrecentage * user.balance) / 100;
        uint256 profit = (monthlyInterest * daysSinceLastDeposit) / 30;
        return profit;
    }

    function setMonthlyPrecentage(uint256 _Rate) external onlyAdmin {
        monthlyPrecentage = _Rate;
    }

    function blockUser(address _user) external onlyAdmin {
        users[_user].blocked = true;
    }

    function unblockUser(address _user) external onlyAdmin {
        users[_user].blocked = false;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return users[_user].balance;
    }

    function getUserProfit(address _user) external view returns (uint256) {
    User storage user = users[_user];
    uint256 daysSinceLastDeposit = (block.timestamp - user.totalDeposits) / 86400;

    // Check if user has made any deposits
    if (user.totalDeposits == 0 || daysSinceLastDeposit < 30) {
        return 0;
    }

    uint256 monthlyInterest = (monthlyPrecentage * user.balance) / 100;
    uint256 profit = (monthlyInterest * daysSinceLastDeposit) / 30;

    // Ensure profit doesn't exceed balance
    if (profit > user.balance) {
        profit = user.balance;
    }

    return profit;
}


    function getReferralEarnings(address _user) external view returns (uint256) {
        return users[_user].referralEarnings;
    }

    function getTotalDeposits(address _user) external view returns (uint256) {
        return users[_user].totalDeposits;
    }

    function getTotalWithdrawals(address _user) external view returns (uint256) {
        return users[_user].totalWithdrawals;
    }

    function deposit() external payable onlyAdmin {}

    function getReferralAddress(address _user) external view returns (address) {
        return users[_user].referral;
    }
}