/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ROIContract {
    address public adminAddr;
    address public projectAddr;
    address public developerAddr;
    address public maintenanceAddr;
    address public defaultReferralAddr;
    uint256 public referralLevel1Rate = 7;
    uint256 public referralLevel2Rate = 2;
    uint256 public referralLevel3Rate = 1;
    uint256 public monthlyPrecentage = 0;
    uint256 public adminFeeRate = 40;
    uint256 public maintenanceFee = 3;
    uint256 public developerFeeRate = 1;
    uint256 public capitalFee = 14;
    uint256 constant public DURATION = 30; //days

    struct MonthlyPercentage {
        uint256 percentage;
        uint256 timestamp;
    }
    MonthlyPercentage[] public monthlyPercentages;

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        bool active; // Indicates whether the deposit is active or withdrawn
    }

    struct Withdrawal {
        uint256 amount;
        uint256 timestamp;
    }

    struct User {
        uint256 balance;
        uint256 totalDeposits;
        uint256 totalEarned;
        uint256 totalWithdrawals;
        address referral;
        bool blocked;
        Deposit[] deposits;
        Withdrawal[] withdrawals;
    }
    
    mapping(address => User) public users;


    struct CapitalWithdrawalRequest {
        uint256 id;
        address user;
        uint256 amount;
        bool approved;
    }

    CapitalWithdrawalRequest[] public capitalWithdrawalRequests;

    ///
    struct Referral {   
        uint8 level;
        uint256 referralEarnings;
    }
    mapping(address => Referral) public referrals;


    modifier onlyAdmin() {
        require(msg.sender == adminAddr, "Only admin can perform this action");
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

    constructor(
        address _adminAddr,
        address _projectAddr,
        address _maintenanceAddr,
        address _developerAddr,
        address _refAdd
    ) {
        adminAddr = _adminAddr;
        projectAddr = _projectAddr;
        developerAddr = _developerAddr;
        maintenanceAddr = _maintenanceAddr;
        defaultReferralAddr = _refAdd;
    }

    function invest(address payable _referral) external payable notBlocked validReferral(_referral) {
    require(msg.value >= 0.01 ether, "Minimum amount for investing is 0.01 ether");

    User storage user = users[msg.sender];
    address userRef = _referral;
    if (user.referral == address(0)) {
        user.referral = _referral;
        userRef = _referral;
    }
    uint256 referralEarnings = 0;

    if (_referral != address(0)) {
        // First level referral earnings
        referralEarnings = (msg.value * referralLevel1Rate) / 100;
    
        if (user.referral == address(0)) {
            referrals[_referral].referralEarnings += referralEarnings;
            user.referral = _referral;
            referrals[_referral].level = 1;
        } else {
            // Second level referral earnings
            address referrer2 = users[_referral].referral;
            userRef = users[_referral].referral;
            if (referrer2 != address(0) && referrer2 != msg.sender) {

                // Third level referral earnings
                uint256 level = referrals[referrer2].level;
                if (level == 1) {
                    referralEarnings = (msg.value * referralLevel2Rate) / 100;
                    referrals[referrer2].referralEarnings += referralEarnings;
                    referrals[referrer2].level = 2;
                }
                if (level == 3 || level == 2) {
                    uint256 referralEarnings3 = (msg.value * referralLevel3Rate) / 100;
                    referrals[referrer2].referralEarnings += referralEarnings3;
                    referrals[referrer2].level = 3;
                }
            }
        }
    }

    uint256 maintenanceValue = (msg.value * maintenanceFee) / 100;
    uint256 adminFee = (msg.value * adminFeeRate) / 100;
    uint256 projectFee = msg.value - maintenanceValue - referralEarnings - adminFee;
    uint256 userVal = msg.value - maintenanceValue;
    user.balance += userVal;
    user.totalDeposits += userVal; // Update totalDeposits value
    user.deposits.push(Deposit({ amount: userVal, timestamp: block.timestamp, active: true }));
    
    // Transfer fees
    (bool success, ) = maintenanceAddr.call{value: maintenanceValue}("");
    require(success, "Transfer of maintenance fee failed");
    (success, ) = adminAddr.call{value: adminFee}("");
    require(success, "Transfer of admin fee failed");
    (success, ) = projectAddr.call{value: projectFee}("");
    require(success, "Transfer of project fee failed");
    (success, ) = userRef.call{value: referralEarnings}("");
    require(success, "Transfer of referral earnings failed");
}

    function getUserProfit(address userAddress) public view returns (uint256) {
        uint256 totalProfit = 0;
        User storage user = users[userAddress];
        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage deposit = user.deposits[i];
            if (deposit.active) {
                (uint256 day, uint256 month, uint256 year) = convertTimestampToDate(deposit.timestamp);
                totalProfit += calculateDepositProfit(day, month, year, deposit.amount);
            }
        }
        return totalProfit;
    }

    
    function calculateDepositProfit(uint256 day, uint256 month, uint256 year, uint256 depositAmount) internal view returns (uint256) {
    uint256 totalProfit = 0;
    uint256 remainingDays = 30; // Assuming each month has 30 days for simplicity

    for (uint256 j = 0; j < monthlyPercentages.length; j++) {
        MonthlyPercentage storage monthlyPercentage = monthlyPercentages[j];
        (uint256 day2, uint256 month2, uint256 year2) = convertTimestampToDate(monthlyPercentage.timestamp);

        if (year2 == year) {
            // Calculate the active days in the current month
            uint256 activeDays = 0;
            if (month == month2) {
                activeDays = (day2 - day) / DURATION + 1; // Include the start date
            } else {
                activeDays = remainingDays;
            }

            // Calculate the profit for the current month
            uint256 profitPercentage = monthlyPercentage.percentage;
            uint256 profitAmount = (depositAmount * profitPercentage / 100);
            uint256 profit = (profitAmount * activeDays) / 30;
            totalProfit += profit;

            remainingDays -= activeDays;
            if (remainingDays == 0) {
                break; // No more remaining days, exit the loop
            }
        }

        // Handle leap year: add one more day to February
        if (isLeapYear(year2) && month2 == 2) {
            remainingDays++;
        }
    }

    return totalProfit;
}
    

    function withdraw() payable public notBlocked  {
        User storage user = users[msg.sender];
        require(user.balance > 0, "Insufficient balance");
        uint256 amount = getUserProfit(msg.sender);
        require(amount > 0,"No profit yet!");
        // Calculate fees and transfer
        uint256 adminFee = (amount * adminFeeRate) / 100;
        uint256 devVal = (amount * developerFeeRate) / 100;
        uint256 projectFee = amount - adminFee - devVal;

        // Transfer fees
        payable(maintenanceAddr).transfer(adminFee);
        payable(developerAddr).transfer(devVal);
        payable(projectAddr).transfer(projectFee);

        // Mark the deposits as not active 
        if (amount >= user.balance) {
            for (uint256 i = 0; i < user.deposits.length; i++) {
                user.deposits[i].active = false;
            }
        } else {
            // Update the user's balance and total withdrawals
            user.balance -= amount;
        }

        user.totalWithdrawals += amount;
          // Add the withdrawal details to the withdrawals mapping
        user.withdrawals.push(Withdrawal({ amount: amount, timestamp: block.timestamp }));

        payable(msg.sender).transfer(amount - adminFee - devVal);
    }
    function getCapitalWithdrawalRequestById(uint256 requestId) public view returns (CapitalWithdrawalRequest memory) {
        for (uint256 i = 1; i < capitalWithdrawalRequests.length; i++) {
            if (capitalWithdrawalRequests[i].id == requestId) {
                return capitalWithdrawalRequests[i];
            }
        }

        // If the request with the specified id is not found, return an empty struct with default values
        return CapitalWithdrawalRequest(0, address(0), 0, false);
    }

    
    //
   function capitalWithdraw() payable public notBlocked {
    User storage user = users[msg.sender];
    require( user.balance > 0, "Insufficient balance");
    uint256 Id = capitalWithdrawalRequests.length == 0? 0 : capitalWithdrawalRequests.length+ 1;
    CapitalWithdrawalRequest memory request = CapitalWithdrawalRequest({id:Id, user:msg.sender , amount:user.balance, approved:false});
    capitalWithdrawalRequests.push(request);
   } 
   // Function to get withdrawal requests where approved is false
    function getWithdrawalRequests() public view returns (CapitalWithdrawalRequest[] memory) {
        uint256 count = 0;

        // Count the number of unapproved requests
        for (uint256 i = 0; i < capitalWithdrawalRequests.length; i++) {
            if (!capitalWithdrawalRequests[i].approved) {
                count++;
            }
        }

        // Create an array to hold the unapproved requests
        CapitalWithdrawalRequest[] memory unapprovedRequests = new CapitalWithdrawalRequest[](count);
        uint256 currentIndex = 0;

        // Populate the array with unapproved requests
        for (uint256 i = 0; i < capitalWithdrawalRequests.length; i++) {
            if (!capitalWithdrawalRequests[i].approved) {
                unapprovedRequests[currentIndex] = capitalWithdrawalRequests[i];
                currentIndex++;
            }
        }

        return unapprovedRequests;
    }

   /// 
   function getCapitalWithdrawalRequest(uint256 index) internal view returns (CapitalWithdrawalRequest storage) {
        return capitalWithdrawalRequests[index];
    }
    function approveCapitalWithdrawal(uint256 requestId) external onlyAdmin {
        ///
        CapitalWithdrawalRequest storage request = capitalWithdrawalRequests[requestId];
        require(!request.approved, "Request is already approved");
        
        // Calculate fees
        uint256 adminFee = (request.amount * capitalFee) / 100;
        uint256 devFee = (request.amount * developerFeeRate) / 100;
        uint256 projectFee = request.amount - adminFee - devFee;
        User storage user = users[msg.sender];
        uint256 userAmount = request.amount -adminFee - devFee;
        user.balance = 0;
        user.totalWithdrawals += userAmount ;
        user.withdrawals.push(Withdrawal({ amount: userAmount, timestamp: block.timestamp }));
        // update deposits
        for (uint256 i = 0; i < user.deposits.length; i++) 
        {
            Deposit storage deposit = user.deposits[i];
            if(deposit.active){
                deposit.active = false;
            }
        }
        // Update the request status to approved
        request.approved = true;
        // Transfer fees
        payable(projectAddr).transfer(projectFee);
        payable(developerAddr).transfer(devFee);

        // Transfer the remaining amount to the user
        payable(request.user).transfer(userAmount);
    }


    function RejectCapitalWithdrawal(uint256 requestId) external  onlyAdmin {
     CapitalWithdrawalRequest storage request = capitalWithdrawalRequests[requestId];
     request.approved = true;
    }


    ////
    function reinvest() external notBlocked {
        User storage user = users[msg.sender];

        uint256 profit = getUserProfit(msg.sender);
        require(profit > 0, "No profit available");

        uint256 reinvestAmount = profit;

        user.balance += reinvestAmount;
        user.totalDeposits += reinvestAmount;
        user.totalEarned += profit;
        for (uint256 i = 0; i < user.deposits.length; i++) 
        {
            Deposit storage deposit = user.deposits[i];
            if(deposit.active){
                deposit.active = false;
            }
        }
        user.deposits.push(Deposit({amount:reinvestAmount,timestamp: block.timestamp,active:true}));
        // Transfer
        payable(projectAddr).transfer(reinvestAmount);
    }
    function getUserBalance(address _user) external view returns (uint256) {
        return users[_user].balance;
    }

    function getReferralStatus(address _user) external view returns (Referral memory) {
        return referrals[_user];
    }
    // this function admin can use to deposit any amount at the end of the month
    function depositAdmin() public payable onlyAdmin {}

    function getUserStatus(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }
    function setPrecentage(uint256 Newpercentage) public  onlyAdmin {
        require(Newpercentage > 0,'Precentage should be more than 0');
        MonthlyPercentage memory newObj =MonthlyPercentage({percentage:Newpercentage,timestamp:block.timestamp});

        monthlyPercentages.push(newObj);
    }
    function getMonthlyPrecentage() public view returns (MonthlyPercentage memory) {
        require(monthlyPercentages.length > 0, "Array is empty"); // Check if the array is not empty

        // Access the last element by using length-1 as the index
        MonthlyPercentage storage lastObject = monthlyPercentages[monthlyPercentages.length - 1];
        return lastObject;
    }
    ///
    function getPastMonths() public view  returns (MonthlyPercentage[] memory) {
        require(monthlyPercentages.length > 0, "Array is empty"); // Check if the array is not empty

        return  monthlyPercentages;
    }
    function blockUser(address _user) external onlyAdmin {
        require(_user != developerAddr, "Can't block user");
        users[_user].blocked = true;
    }

    function unblockUser(address _user) external onlyAdmin {
        users[_user].blocked = false;
    }
    function getDateComponents() public payable returns (uint256 day,uint256 month, uint256 year) {
        // Call the convertTimestampToDate function to get the date components
        ( day,month, year) = convertTimestampToDate(block.timestamp);
        // Now you have the day, month, and year, and you can use them in this function or return them further if needed.
    }
    function isLeapYear(uint256 year) internal pure returns (bool) {
        return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
    }
    function convertTimestampToDate(uint256 timestamp) public pure returns (uint256 day, uint256 month, uint256 year) {
        // Calculate the number of days since the Unix Epoch
        uint256 daysSinceEpoch = timestamp / 86400; // 86400 seconds in a day

        // Estimate the number of years since the Unix Epoch
        uint256 numYears = daysSinceEpoch / 365;

        // Adjust for leap years
        uint256 numLeapYears = 0;
        for (year = 1970; year <= numYears + 1970; year++) {
            if (isLeapYear(year)) {
                numLeapYears++;
            }
        }

        // Calculate the remaining days after considering years
        uint256 remainingDays = daysSinceEpoch - (numYears * 365 + numLeapYears);

        // Array to hold the number of days in each month (non-leap year)
        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

        // If it's a leap year, update February's days to 29
        if (isLeapYear(numYears + 1970)) {
            daysInMonth[1] = 29;
        }

        // Find the month and day from the remaining days
        for (uint8 i = 0; i < 12; i++) {
            if (remainingDays < daysInMonth[i]) {
                day = remainingDays + 1;
                month = i + 1;
                break;
            }
            remainingDays -= daysInMonth[i];
        }

        // Calculate the year by adding the Unix Epoch offset (1970) to the number of years
        year = numYears + 1970;
    }
}