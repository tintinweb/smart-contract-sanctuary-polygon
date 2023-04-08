/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MineMatic {
    address payable public owner;
    
    // Define a struct to represent a user in the MLM network
    struct User {
        address payable upline;
        uint256 referrals;
        uint256 payout;
        bool exists;
        bool verified;
    }

    
    // Define a mapping to store the MLM network
    mapping (address => User) public users;
    mapping (uint256 => address) public idToAddress;
    uint256 public lastId = 0;

    constructor() {
        owner = payable(msg.sender);
    }
    // Define an array of payout levels as a percentage of the user's registration fee
    uint256[] public payoutLevels = [10, 5, 3, 2, 1];
    uint256 public minDeposit = 0;
function register(address payable _upline) public payable {
    // Make sure the user isn't already registered
    require(!users[msg.sender].verified, "User already registered");

    // If the user has no upline, set their upline to the contract owner
    if (_upline == address(0) || !users[_upline].verified) {
        _upline = owner;
    }

    // Add the user to the MLM network
    users[msg.sender] = User({
        upline: _upline,
        referrals: 0,
        payout: 0,
        exists: true,
        verified: true
    });

    // Update the upline's referral count
    users[_upline].referrals++;

    // Pay out the upline and their upline's upline
    address payable up = _upline;
    for (uint i = 0; i < payoutLevels.length; i++) {
        if (up == address(0)) {
            break;
        }
        uint256 payoutAmount = msg.value * payoutLevels[i] / 100;
        up.transfer(payoutAmount);
        users[up].payout += payoutAmount;
        up = users[up].upline;
    }
}

    // Task 2: Business plan with team, 7 package plan, sponsor, upline, net income, turnover
    struct Package {
        uint256 price;
        uint256 commission;
    }
    
    mapping (uint256 => Package) public packages;
    mapping (address => uint256) public userPackages;
    mapping (address => address) public sponsors;
    mapping (address => address[]) public downlines;
    mapping (address => uint256) public totalSales;
    uint256 public commissionRate = 10; // 10% commission rate
    
    function addPackage(uint256 _packageId, uint256 _price, uint256 _commission) public {
        packages[_packageId] = Package(_price, _commission);
    }
    
    function buyPackage(uint256 _packageId, address _sponsor) public payable {
        require(users[msg.sender].verified && users[_sponsor].verified, "Users must be registered.");
        require(msg.value == packages[_packageId].price, "Incorrect package price.");
        userPackages[msg.sender] = _packageId;
        sponsors[msg.sender] = _sponsor;
        downlines[_sponsor].push(msg.sender);
        totalSales[_sponsor] += msg.value;
        distributeCommission(_sponsor, msg.value);
    }
    
    function distributeCommission(address _user, uint256 _amount) internal {
        address upline = sponsors[_user];
        uint256 commission = (_amount * packages[userPackages[_user]].commission) / 100;
        while (upline != address(0)) {
            totalSales[upline] += commission;
            upline = sponsors[upline];
        }
    }
    
    function getNetIncome() public view returns (uint256) {
        uint256 totalCommission = 0;
        for (uint256 i = 1; i <= lastId; i++) {
            totalCommission += totalSales[idToAddress[i]];
        }
        return address(this).balance - totalCommission;
    }
    
    function getTurnover() public view returns (uint256) {
        uint256 totalTurnover = 0;
        for (uint256 i = 1; i <= lastId; i++) {
            totalTurnover += packages[userPackages[idToAddress[i]]].price;
        }
        return totalTurnover;
    }
    
    // Other functions
    
function withdraw() public {
    require(users[msg.sender].verified, "User must be registered.");
    uint256 amount = totalSales[msg.sender];
    totalSales[msg.sender] = 0;
    users[msg.sender].upline.transfer(amount);
}
    
    function getDownlines(address _user) public view returns (address[] memory) {
        return downlines[_user];
    }
    
    function getTotalSales(address _user) public view returns (uint256) {
        return totalSales[_user];
    }

    // Define an admin role and a mapping to store the admin accounts
address public adminRole;
mapping (address => bool) public admins;

// Define a modifier to restrict access to admin-only functions
modifier onlyAdmin() {
    require(msg.sender == adminRole || admins[msg.sender], "Unauthorized access");
    _;
}

// Define a function to add a new admin account
function addAdmin(address _admin) public onlyAdmin {
    require(_admin != address(0), "Invalid address");
    admins[_admin] = true;
}

// Define a function to remove an admin account
function removeAdmin(address _admin) public onlyAdmin {
    require(_admin != address(0), "Invalid address");
    admins[_admin] = false;
}

// Define a function to set the payout percentages
function setPayoutLevels(uint256[] memory _payoutLevels) public onlyAdmin {
    payoutLevels = _payoutLevels;
}

// Define a function to set the minimum deposit amount
function setMinDeposit(uint256 _minDeposit) public onlyAdmin {
    minDeposit = _minDeposit;
}

// Define a function to withdraw the contract balance
function withdrawBalance() public onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
}

    
}