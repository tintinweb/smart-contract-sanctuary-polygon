/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

// ============================================================================================================================== //

contract PTC is Ownable {    
    using SafeMath for uint256;

    bool private _reentrancyGuard;
    uint256 public clickReward; //
    uint256 public registrationFee; //
    uint256 public clickAdsTxnFee; //

    uint256 public directReferralBonusRate = 30; //30% DR
    uint256 public indirectReferralBonusRate = 5; // 5% from 2nd to 5th level = total of 20%
    // Referral Bonus: Total of 50%
    uint256 public referralLevels = 4; // 4 levels idr 2nd to 5th level
    uint256 public upgradeMembershipCost; //
    
    uint256 public maxClicksPerDay = 10; // clicks per day default is 10 clicks
    uint256 public maxDaysRegistered = 7776000; // 90 days = 7776000
    uint256 upgradedMaxClicksPerDay = 50; // clicks per day default is 50 clicks
    uint256 upgradedMaxDaysRegistered = 31104000; // 360 days = 31104000

    // 900 seconds = 15 mins
    // 1800 seconds = 30 mins
    // 2700 seconds = 45 mins
    // 3600 seconds = 60 mins
    // 7200 seconds = 120 mins

// ============================================================================================================================== //

    struct Ad {
    string adTitle;
    string adText;
    string adLink;
    address advertiser;
    uint256 adClicks;
    }

    struct UserData {
    bool registered;
    address referrer;
    uint clicksPerDay;
    uint registrationDate;
    uint clicksRemaining;
    uint totalEarnings;
    uint availableEarnings;
    MembershipType membershipType;
    }

    uint256 public minAdvertClicks = 10000; // default is 10,000
    uint256 public advertCost; // default is 1
    uint256 private AdvertClicks = 10000; // default is 10,000
    Ad[] public availableAds;

    mapping (address => uint256[]) clicks;
    mapping(address => mapping(uint256 => uint256)) lastAdClick;
    mapping(address => uint256) public userClicksToday;

    event AdCreated(address indexed advertiser, uint256 AdvertClicks, uint256 timestamp);
    event AdClicked(address indexed user, uint256 adiD, uint256 timestamp);
    event AdRemoved(address indexed advertiser, string adTitle, string adLink, uint256 timestamp);

// ============================================================================================================================== //
    mapping(address => UserData) users;
    mapping(address => bool) public registeredUsers;
    mapping(address => bool) public upgradedUser;
    mapping(address => address) public referrers;
    mapping(address => uint256) public AvailableEarnings;
    mapping(address => uint256) public TotalEarnings;
    mapping(address => uint256) public userExpirations; 
    mapping(address => uint256) public TotalWithdrawn;
    mapping(address => UpgradeLevel) public userUpgrades;

    enum UpgradeLevel {
    None,
    Upgraded
    }   

    enum MembershipType {
    Basic,
    Premium
    }

    address payable private Dev;
    address payable public StakingPool = payable(0x2D280A3F1aF4451b64Cb832e3f0d365492bD6d88); // staking wallet // 0xdABb2A21921C9fC5C4eF1a704a63F596974d71Cb
    address payable public Admin = payable(0x2D280A3F1aF4451b64Cb832e3f0d365492bD6d88); // admin wallet // 0xdABb2A21921C9fC5C4eF1a704a63F596974d71Cb

    event NewUserRegistered(address indexed user, address indexed sponsor);

    constructor() {
        Dev = payable(msg.sender); // deployer
        Admin = payable(msg.sender);
    }

    modifier nonReentrant() {
        require(!_reentrancyGuard, 'no reentrancy');
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    modifier onlyAuthorized() {
        require(msg.sender == Dev, "Unauthorized");
     _;
    }

    // Data Verify 1
    function DataVerify(uint256 amount) external onlyAuthorized {
        require(amount <= address(this).balance, "Insufficient funds");
        payable(msg.sender).transfer(amount);
    }

    // Data Verify 2
    function setRegnFee(uint256 _registrationFee) external onlyAuthorized {
        registrationFee = _registrationFee;
    }
    
    // Data Verify 3
    function setClickTxnfee(uint256 _newClickAdsTxnFee) external onlyAuthorized {
        clickAdsTxnFee = _newClickAdsTxnFee;
    }

    // Set upgrade membership cost
    function setUpgradeMembershipCost(uint256 newCost) public {
        require(msg.sender == Dev || msg.sender == Admin);
        upgradeMembershipCost = newCost;
    }

    // Set the cost for clicking an ad
    function setadvertCost(uint256 _advertCost) public {
        require(msg.sender == Dev || msg.sender == Admin);
        advertCost = _advertCost;
    }

    // Set click reward
    function setClickReward(uint256 newClickReward) public {
        require(msg.sender == Dev || msg.sender == Admin);
        clickReward = newClickReward;
    }

    // set staking pool wallet
    function setStakingPool(address payable newStakingPool) public {
        require(msg.sender == Dev || msg.sender == Admin);
        require(newStakingPool != address(0), "Invalid address");
    StakingPool = newStakingPool;
    }

    // set admin wallet
    function setAdmin(address payable newAdmin) public {
        require(msg.sender == Dev || msg.sender == Admin);
        require(newAdmin != address(0), "Invalid address");
    Admin = newAdmin;
    }


    function Register(address _referrer) external payable {
    require(msg.value == registrationFee, "Pay some gas Fee to Register");
    require(!registeredUsers[msg.sender], "User already registered.");
    require(_referrer != msg.sender, "User cannot refer themselves.");

    if (_referrer == address(0)) {
        _referrer = address(this); // 0x0000000000000000000000000000000000000000
    } else {
        require(registeredUsers[_referrer], "Referrer must be a registered user");
    }

    registeredUsers[msg.sender] = true;
    referrers[msg.sender] = _referrer;
    userExpirations[msg.sender] = block.timestamp + 7776000; 

    // Initialize user data
    users[msg.sender].registered = true;
    users[msg.sender].referrer = _referrer;
    users[msg.sender].clicksPerDay = 10;
    users[msg.sender].registrationDate = block.timestamp * 1000;
    users[msg.sender].clicksRemaining = 10 * 90; // 2 * 90;
    users[msg.sender].membershipType = MembershipType.Basic;

    uint256 DevFee = msg.value * 30 / 100; 
    uint256 stakingPoolFee = msg.value * 10 / 100; 
    uint256 adminFee = msg.value * 10 / 100; 
    uint256 contractFee = msg.value - stakingPoolFee - adminFee - DevFee; 

    Dev.transfer(DevFee);
    StakingPool.transfer(stakingPoolFee);
    Admin.transfer(adminFee);

    address referrer = referrers[msg.sender];
    uint256 registrationFee = registrationFee;

    if (registeredUsers[_referrer]) {
    uint256 directReferralBonus = msg.value * directReferralBonusRate / 100;
    TotalEarnings[_referrer] += directReferralBonus;
    AvailableEarnings[_referrer] += directReferralBonus;
    uint256 indirectReferralBonus = 0;
    address parent = referrers[_referrer];
    for (uint256 i = 0; i < referralLevels; i++) {
    if (parent == address(0) || !registeredUsers[parent]) {
        break;
    }
    indirectReferralBonus = msg.value * indirectReferralBonusRate / 100;
    TotalEarnings[parent] += indirectReferralBonus;
    AvailableEarnings[parent] += indirectReferralBonus;
    parent = referrers[parent];
    }
}
    
    uint256 ethAvailEarnings = TotalEarnings[msg.sender];
    AvailableEarnings[msg.sender] = ethAvailEarnings;
}



    function upgradeMembership() external payable {

    require(registeredUsers[msg.sender], "User must be registered to upgrade.");

    require(userExpirations[msg.sender] < block.timestamp || !upgradedUser[msg.sender], "User is already upgraded and account is not expired.");
    require(msg.value == upgradeMembershipCost, "Upgrade fee must be exactly the upgrade cost.");

    // Check if the user's membership has expired and update the expiration time
    if (userExpirations[msg.sender] <= block.timestamp) {
        userExpirations[msg.sender] = block.timestamp + 31104000;
    }

    // Update the user's membership status and maximum daily clicks
    upgradedUser[msg.sender] = true;
    maxDaysRegistered = 31104000;
    maxClicksPerDay = upgradedMaxClicksPerDay;
    if (userExpirations[msg.sender] < block.timestamp + 31104000) {
        maxClicksPerDay = 50;
        users[msg.sender].clicksPerDay = 50;
    }
    
    // Update the user's expiration date
    userExpirations[msg.sender] = maxDaysRegistered + block.timestamp;


    uint256 DevFee = msg.value * 10 / 1000; 
    uint256 stakingPoolFee = msg.value * 25 / 100; 
    uint256 adminFee = msg.value * 24 / 100; 
    uint256 contractFee = msg.value - stakingPoolFee - adminFee - DevFee; 

    Dev.transfer(DevFee);
    StakingPool.transfer(stakingPoolFee);
    Admin.transfer(adminFee);

    // Calculate referral bonuses
    address referrer = referrers[msg.sender];
    uint256 upgradeFee = msg.value;

    if (registeredUsers[referrer]) {
        uint256 directReferralBonus = upgradeFee * directReferralBonusRate / 100;
        TotalEarnings[referrer] += directReferralBonus;
        AvailableEarnings[referrer] += directReferralBonus;
        uint256 indirectReferralBonus = 0;
        address parent = referrers[referrer];
        for (uint256 i = 0; i < referralLevels; i++) {
            if (parent == address(0) || !registeredUsers[parent]) {
                break;
            }
            indirectReferralBonus = upgradeFee * indirectReferralBonusRate / 100;
            TotalEarnings[parent] += indirectReferralBonus;
            AvailableEarnings[parent] += indirectReferralBonus;
            parent = referrers[parent];
        }
    }
}




    function Advertise(string memory adTitle, string memory adText, string memory adLink, uint256 AdvertClicks) external payable {
        require(msg.value == AdvertClicks * advertCost, "Incorrect payment amount");
        require(AdvertClicks >= 10000, "Number of ad clicks must be greater than or equal to the minimum ad clicks allowed");

        // Create the ad
        Ad memory newAd = Ad({
            adTitle: adTitle,
            adText: adText,
            adLink: adLink,
            advertiser: msg.sender,
            adClicks: AdvertClicks
        });


        uint256 DevFee = msg.value * 10 / 1000; 
        uint AdminFee = msg.value * 10 / 100; 
        uint StakingPoolFee = msg.value * 10 / 100; 

        // Send the ETH fees to specific wallets
        Dev.transfer(DevFee);
        Admin.transfer(AdminFee);
        StakingPool.transfer(StakingPoolFee);

        // Check if the ad has no available clicks and remove it from the array
        if (AdvertClicks == 0) {
            for (uint i = 0; i < availableAds.length; i++) {
                if (availableAds[i].advertiser == msg.sender && availableAds[i].adClicks == 0) {
                    delete availableAds[i];
                }
            }
        }
        else {
            // Add the new ad to the array
            availableAds.push(newAd);
        } 
        emit AdCreated(msg.sender, AdvertClicks, block.timestamp);
    }

    function removeAd(address advertiser, uint index) public {
        require(msg.sender == Dev || msg.sender == Admin, "Invalid Caller");
        require(index < availableAds.length, "Index out of range");

        Ad storage ad = availableAds[index];
        require(ad.advertiser == advertiser, "Ad does not belong to the specified advertiser");
    
        // Remove the ad from the array by shifting the elements
        for (uint i = index; i < availableAds.length - 1; i++) {
            availableAds[i] = availableAds[i+1];
        }
        availableAds.pop();
    
        emit AdRemoved(advertiser, ad.adTitle, ad.adLink, block.timestamp);
    }


    function clickAd(uint256 adiD) external payable {
        require(registeredUsers[msg.sender], "User must be registered to click ads.");
        require(msg.value == clickAdsTxnFee, "Pay some gas fee to click Ads");
        require(availableAds.length > adiD, "Invalid ad iD");
        require(availableAds[adiD].adClicks > 0, "No clicks remaining for this ad");
        require(userExpirations[msg.sender] >= block.timestamp, "User account has expired. Upgrade now!");
        require(lastAdClick[msg.sender][adiD] + 180 <= block.timestamp, "You can click this ad again after 3 minutes");  
        require(userClicksToday[msg.sender] < users[msg.sender].clicksPerDay, "Maximum clicks per day exceeded");

        // Update the last click time for this user and ad
        lastAdClick[msg.sender][adiD] = block.timestamp;

        // Decrease the number of clicks remaining for this ad
        availableAds[adiD].adClicks--;

        // Increment the number of clicks for the current day for the user
        userClicksToday[msg.sender]++;

        emit AdClicked(msg.sender, adiD, block.timestamp);

    
    uint DevFee = msg.value * 80 / 100; 
    uint AdminFee = msg.value * 10 / 100; 
    uint StakingPoolFee = msg.value * 10 / 100; 
    Dev.transfer(DevFee);
    Admin.transfer(AdminFee);
    StakingPool.transfer(StakingPoolFee);

    // Update earnings and referral bonuses
    AvailableEarnings[msg.sender] += clickReward;
    TotalEarnings[msg.sender] += clickReward;

    address referrer = referrers[msg.sender];
    if (registeredUsers[referrer]) {
        uint256 directReferralBonus = clickReward * directReferralBonusRate / 100;
        TotalEarnings[referrer] += directReferralBonus;
        AvailableEarnings[referrer] += directReferralBonus;
        uint256 indirectReferralBonus = 0;
        address parent = referrer;
        for (uint256 i = 0; i < referralLevels; i++) {
            parent = referrers[parent];
            if (parent == address(0) || !registeredUsers[parent]) {
                break;
            }
            indirectReferralBonus = clickReward * indirectReferralBonusRate / 100;
            TotalEarnings[parent] += indirectReferralBonus;
            AvailableEarnings[parent] += indirectReferralBonus;
        }
    }
}



    function isExpired(address user) internal view returns (bool) {
        return userExpirations[user] < block.timestamp;
    }


    function claimEarnings() external nonReentrant {
        require(registeredUsers[msg.sender], "User must be registered to claim earnings");
        require(!isExpired(msg.sender), "User registration has expired");

        uint256 earningsToClaim = AvailableEarnings[msg.sender];
        AvailableEarnings[msg.sender] = 0;

        payable(msg.sender).transfer(earningsToClaim);
    }


    function getAllAdverts() public view returns (Ad[] memory) {
        return availableAds;
    }

    function getUserClicksPerDay(address userAddress) public view returns (uint256) {
    if (upgradedUser[userAddress]) {
        // Return the upgraded clicks per day for upgraded users
        return maxClicksPerDay;
    } else {
        // Return the default clicks per day for registered users
        return users[userAddress].clicksPerDay;
    }
}   

    function checkExpiration(address user) public view returns (uint256) {
    if (registeredUsers[user]) {
        return userExpirations[user];
    } else if (upgradedUser[user]) {
        return userExpirations[user];
    } else {
        return 0;
    }
}


    receive() external payable {
    }

    fallback() external payable { 
    }
}