// A contract to track the modifications/maintenance of a vehicle
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// imports for ERC20 payment
import "./IERC20.sol";
import "./SafeERC20.sol";

// Enum to store user types
enum UserType {
    Unregistered,
    SuperAdmin,
    AutoShop,
    CarDealer,
    CarOwner
}

// Struct to store the details of subscription payment
struct SubscriptionPayment {
    address user;
    uint256 paymentTime;
    uint256 paymentAmount;
    uint256 subscriptionExpiry;
}

// Struct to store the details of a vehicle
struct Vehicle {
    string VIN;
    string color;
    string ownerName;
}

// Struct to store the details of auto shop / car dealer
struct Shop {
    string ownerNames;
    string name;
    string location;
    string contactNumber;
    string email;
    string website;
    uint256[] subscriptionReceipts;
    address payable shopWallet;
    string officialID;
}

// Struct to manage the dashboard of an auto shop / car dealer
struct Dashboard {
    uint256 totalCustomers;
    uint256 totalRevenue;
    uint256 completedServices;
    string[] vehicleVINs;
}

// Struct to store the details of a car owner
struct Owner {
    string name;
    string contactNumber;
    string email;
    string[] vehicleVINs;
    address payable ownerWallet;
}

// Struct to store the details of a vehicle modification
struct Modification {
    string VIN;
    string modificationType;
    string modificationDescription;
    uint256 modificationTime;
    uint256 modificationCost;
    string modificationLocation;
    address serviceProvider;
}

contract vehicleModificationTracker {
    // import SafeERC20 library
    using SafeERC20 for IERC20;

    // Owner of the contract
    address public owner;

    // Token used for payment
    IERC20 public secondaryToken;

    // Manage the payment options
    uint8 private paymentOption = 1; // 0 - ERC20, 1 - ETH (default)

    // Fee for the subscription
    uint256 public ethFee = 0.01 ether;
    uint256 public tokenFee = 100 * 10 ** 18;

    // Counters
    uint256 public totalAutoShops = 0;
    uint256 public totalCarDealers = 0;
    uint256 public totalCarOwners = 0;
    uint256 public totalVehicles = 0;

    // Analytics
    uint256 private totalPaymentEth;
    uint256 private totalPaymentToken;
    mapping(address => uint256) private totalPaymentEthByUser;
    mapping(address => uint256) private totalPaymentTokenByUser;

    // mapping user address to subscription payment details
    mapping(address => SubscriptionPayment) private subscriptionPayments;

    // mapping user address to user type
    mapping(address => UserType) private userTypes;

    // mapping user address to auto shop details
    mapping(address => Shop) private shops;

    // mapping user address to car owner details
    mapping(address => Owner) private owners;

    // mapping vehicle VIN to vehicle details
    mapping(string => Vehicle) private vehicles;

    // mapping vehicle VIN to vehicle modification details
    mapping(string => Modification[]) private modifications;

    // mapping user address to dashboard details
    mapping(address => Dashboard) private dashboards;

    // mapping to store the blacklisted users
    mapping(address => bool) private blacklistedUsers;

    // Events
    event SubscriptionPaymentEvent(address indexed _user, uint256 _paymentTime);
    event ShopRegistered(string name, string location);
    event CarDealerRegistered(string name, string location);
    event CarOwnerRegistered(string name, string location);
    event ShopDeleted(string name, string location);
    event UserBlacklisted(address indexed _user);

    // modifier to check if the user is a super admin
    modifier onlySuperAdmin() {
        require(
            userTypes[msg.sender] == UserType.SuperAdmin,
            "Only super admin can call this function"
        );
        _;
    }

    // modifier to check if the user is an auto shop
    modifier onlyAutoShop() {
        require(
            userTypes[msg.sender] == UserType.AutoShop,
            "Only auto shop can call this function"
        );
        _;
    }

    // modifier to check if the user is a car dealer
    modifier onlyCarDealer() {
        require(
            userTypes[msg.sender] == UserType.CarDealer,
            "Only car dealer can call this function"
        );
        _;
    }

    // modifier to check if the user is a car owner
    modifier onlyCarOwner() {
        require(
            userTypes[msg.sender] == UserType.CarOwner,
            "Only car owner can call this function"
        );
        _;
    }

    // modifier to check if the user is a super admin or auto shop or car dealer
    modifier onlySuperAdminOrAutoShopOrCarDealer() {
        require(
            userTypes[msg.sender] == UserType.SuperAdmin ||
                userTypes[msg.sender] == UserType.AutoShop ||
                userTypes[msg.sender] == UserType.CarDealer,
            "Wallet not authorized to call this function"
        );
        _;
    }

    // modifier to check if the user is a super admin or car owner
    modifier onlySuperAdminOrCarOwner() {
        require(
            userTypes[msg.sender] == UserType.SuperAdmin ||
                userTypes[msg.sender] == UserType.CarOwner,
            "Only super admin or car owner can call this function"
        );
        _;
    }

    // modifier to check if auto shop or car dealer has active subscription
    modifier onlyActiveSubscription() {
        // if the user is a super admin or owner, then no need to check for subscription
        if (
            userTypes[msg.sender] == UserType.SuperAdmin ||
            userTypes[msg.sender] == UserType.CarOwner
        ) {
            _;
        } else {
            require(
                subscriptionPayments[msg.sender].subscriptionExpiry >
                    block.timestamp,
                "Your subscription has expired"
            );
            _;
        }
    }

    // modifier to check if the user is registered
    modifier onlyRegisteredUser() {
        require(
            userTypes[msg.sender] != UserType.Unregistered,
            "You are not registered"
        );
        _;
    }

    // modifier to check if the car dealer / auto shop is registered
    modifier onlyRegistered() {
        require(
            userTypes[msg.sender] == UserType.AutoShop ||
                userTypes[msg.sender] == UserType.CarDealer,
            "You are not registered"
        );
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        userTypes[msg.sender] = UserType.SuperAdmin;
        secondaryToken = IERC20(0x0000000000000000000000000000000000000000);
    }

    // ------------------------- Payable Functions -------------------------

    // Function to pay for the subscription
    function payForSubscription() external payable onlyRegistered {
        require(
            subscriptionPayments[msg.sender].subscriptionExpiry == 0,
            "You already have an active subscription"
        );
        if (paymentOption == 0) {
            require(
                msg.value == 0,
                "You have selected ERC20 as payment option. Please pay using ERC20 tokens"
            );
            secondaryToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenFee
            );
            totalPaymentToken = totalPaymentToken + tokenFee;
            totalPaymentTokenByUser[msg.sender] =
                totalPaymentTokenByUser[msg.sender] +
                tokenFee;
        } else {
            require(
                msg.value == ethFee,
                "You have selected ETH as payment option. Please pay using ETH"
            );
            totalPaymentEth = totalPaymentEth + ethFee;
            totalPaymentEthByUser[msg.sender] =
                totalPaymentEthByUser[msg.sender] +
                ethFee;
        }
        // timestamp calculation for 365 days
        uint256 annum = 31536000;
        subscriptionPayments[msg.sender] = SubscriptionPayment(
            msg.sender,
            block.timestamp,
            msg.value,
            block.timestamp + annum
        );
    }

    // Function to pay for the subscription in advance
    function payForSubscriptionInAdvance() external payable onlyRegistered {
        require(
            subscriptionPayments[msg.sender].subscriptionExpiry != 0,
            "You do not have an active subscription"
        );
        if (paymentOption == 0) {
            require(
                msg.value == 0,
                "You have selected ERC20 as payment option. Please pay using ERC20 tokens"
            );
            secondaryToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenFee
            );
            totalPaymentToken = totalPaymentToken + tokenFee;
            totalPaymentTokenByUser[msg.sender] =
                totalPaymentTokenByUser[msg.sender] +
                tokenFee;
        } else {
            require(
                msg.value == ethFee,
                "You have selected ETH as payment option. Please pay using ETH"
            );
            totalPaymentEth = totalPaymentEth + ethFee;
            totalPaymentEthByUser[msg.sender] =
                totalPaymentEthByUser[msg.sender] +
                ethFee;
        }
        // timestamp calculation for 365 days
        uint256 annum = 31536000;
        subscriptionPayments[msg.sender].paymentTime = block.timestamp;
        subscriptionPayments[msg.sender].paymentAmount = msg.value;
        subscriptionPayments[msg.sender].subscriptionExpiry =
            subscriptionPayments[msg.sender].subscriptionExpiry +
            annum;
    }

    // ------------------------- Setters Functions -------------------------

    // Function to set the payment option
    function setEthFee(uint256 _ethFee) external onlySuperAdmin {
        require(_ethFee > 0, "ETH fee cannot be zero");
        ethFee = _ethFee;
    }

    // Function to set token fee
    function setTokenFee(uint256 _tokenFee) external onlySuperAdmin {
        require(_tokenFee > 0, "Token fee cannot be zero");
        tokenFee = _tokenFee;
    }

    // Function to set the payment option
    function setPaymentOption(uint8 _paymentOption) external onlySuperAdmin {
        require(
            _paymentOption == 0 || _paymentOption == 1,
            "Invalid payment option"
        );
        paymentOption = _paymentOption;
    }

    // Function to update the token address
    function updateTokenAddress(address _tokenAddress) external onlySuperAdmin {
        secondaryToken = IERC20(_tokenAddress);
    }

    // Function to register a new auto shop
    function registerAutoShop(
        string memory _ownerNames,
        string memory _name,
        string memory _location,
        string memory _contactNumber,
        string memory _email,
        string memory _website,
        address payable _shopWallet,
        string memory _officialID
    ) external onlySuperAdmin returns (bool) {
        require(
            userTypes[_shopWallet] == UserType.Unregistered,
            "Wallet already registered"
        );
        userTypes[_shopWallet] = UserType.AutoShop;
        shops[_shopWallet] = Shop(
            _ownerNames,
            _name,
            _location,
            _contactNumber,
            _email,
            _website,
            new uint256[](0),
            _shopWallet,
            _officialID
        );
        emit ShopRegistered(_name, _location);
        totalAutoShops += 1;
        return true;
    }

    // Function to register a new car dealer
    function registerCarDealer(
        string memory _ownerNames,
        string memory _name,
        string memory _location,
        string memory _contactNumber,
        string memory _email,
        string memory _website,
        address payable _shopWallet,
        string memory _officialID
    ) external onlySuperAdmin returns (bool) {
        require(
            userTypes[_shopWallet] == UserType.Unregistered,
            "Wallet already registered"
        );
        userTypes[_shopWallet] = UserType.CarDealer;
        shops[_shopWallet] = Shop(
            _ownerNames,
            _name,
            _location,
            _contactNumber,
            _email,
            _website,
            new uint256[](0),
            _shopWallet,
            _officialID
        );
        emit CarDealerRegistered(_name, _location);
        totalCarDealers += 1;
        return true;
    }

    // Function to register a new car owner
    function registerCarOwner(
        string memory _name,
        string memory _contactNumber,
        string memory _email,
        address payable _ownerWallet
    ) external onlySuperAdmin returns (bool) {
        require(
            userTypes[_ownerWallet] == UserType.Unregistered,
            "Wallet already registered"
        );
        userTypes[_ownerWallet] = UserType.CarOwner;
        owners[_ownerWallet] = Owner(
            _name,
            _contactNumber,
            _email,
            new string[](0),
            payable(_ownerWallet)
        );
        emit CarOwnerRegistered(_name, _email);
        totalCarOwners += 1;
        return true;
    }

    // Function to add a new vehicle
    function addVehicle(
        string memory _VIN,
        string memory _color,
        string memory _ownerName,
        address _ownerWallet
    ) external onlySuperAdminOrCarOwner returns (bool) {
        checkAndRegisterVehicle(_VIN);
        vehicles[_VIN] = Vehicle(_VIN, _color, _ownerName);
        owners[_ownerWallet].vehicleVINs.push(_VIN);
        totalVehicles += 1;
        return true;
    }

    // Function to add a new vehicle modification
    function addModification(
        string memory _VIN,
        string memory _modificationType,
        string memory _modificationDescription,
        uint256 _modificationCost,
        string memory _modificationLocation,
        address _serviceProvider
    )
        external
        onlySuperAdminOrAutoShopOrCarDealer
        onlyActiveSubscription
        returns (bool)
    {
        checkAndRegisterVehicle(_VIN);
        modifications[_VIN].push(
            Modification(
                _VIN,
                _modificationType,
                _modificationDescription,
                block.timestamp,
                _modificationCost,
                _modificationLocation,
                _serviceProvider
            )
        );
        // update the dashboard of auto shop / car dealer
        if (
            userTypes[msg.sender] == UserType.AutoShop ||
            userTypes[msg.sender] == UserType.CarDealer
        ) {
            bool isVehiclePresent = false;
            for (
                uint256 i = 0;
                i < dashboards[msg.sender].vehicleVINs.length;
                i++
            ) {
                if (
                    keccak256(bytes(dashboards[msg.sender].vehicleVINs[i])) ==
                    keccak256(bytes(_VIN))
                ) {
                    dashboards[msg.sender].totalRevenue += _modificationCost;
                    dashboards[msg.sender].completedServices += 1;
                    return true;
                }
            }
            if (!isVehiclePresent) {
                dashboards[msg.sender].totalCustomers += 1;
                dashboards[msg.sender].totalRevenue += _modificationCost;
                dashboards[msg.sender].completedServices += 1;
                dashboards[msg.sender].vehicleVINs.push(_VIN);
            }
        }
        return true;
    }

    // Function to check and register a vehicle internally
    function checkAndRegisterVehicle(string memory _VIN) internal {
        if (keccak256(bytes(vehicles[_VIN].VIN)) != keccak256(bytes(_VIN))) {
            vehicles[_VIN] = Vehicle(_VIN, "", "");
            totalVehicles += 1;
        }
    }

    // ------------------------- Getters Functions -------------------------

    // Function to get last payment details of a user
    function getLastPaymentDetails(
        address _user
    ) external view returns (SubscriptionPayment memory) {
        return subscriptionPayments[_user];
    }

    // Function to get the payment option
    function getPaymentOption() external view returns (uint8) {
        return paymentOption;
    }

    // Function to check user type
    function getUserType(address _user) external view returns (UserType) {
        return userTypes[_user];
    }

    // Function to get the dashboard details of an auto shop / car dealer onlySuperAdmin or shop itself
    function getDashboard(
        address _shop
    )
        external
        view
        onlySuperAdminOrAutoShopOrCarDealer
        returns (Dashboard memory)
    {
        if (
            _shop == msg.sender || userTypes[msg.sender] == UserType.SuperAdmin
        ) {
            return dashboards[_shop];
        } else {
            revert("You are not authorized to view this dashboard");
        }
    }

    // Function to check if a user is blacklisted
    function isBlacklisted(address _user) external view returns (bool) {
        return blacklistedUsers[_user];
    }

    // Function to get the details and all vehicle history
    function getVehicleDetails(
        string memory _VIN
    ) external view returns (Vehicle memory, Modification[] memory) {
        return (vehicles[_VIN], modifications[_VIN]);
    }

    // Function to get details of a shop
    function getShopDetails(address _shop)
        external
        view
        returns (Shop memory)
    {
        return shops[_shop];
    }

    // Function to get details of a car owner
    function getOwnerDetails(address _owner)
        external
        view
        returns (Owner memory)
    {
        return owners[_owner];
    }

    // ------------------------- Owner Specific Functions -------------------------

    // Function to withdraw the ETH balance
    function withdrawEthBalance() external onlySuperAdmin {
        payable(owner).transfer(address(this).balance);
    }

    // Function to withdraw the token balance
    function withdrawTokenBalance(
        address _tokenAddress
    ) external onlySuperAdmin {
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    // Function to blacklist a user
    function blacklistUser(address _user) external onlySuperAdmin {
        blacklistedUsers[_user] = true;
        emit UserBlacklisted(_user);
    }

    // Function to unblacklist a user
    function unBlacklistUser(address _user) external onlySuperAdmin {
        blacklistedUsers[_user] = false;
    }

    // Function to delete a vehicle from owner's struct
    function deleteVehicleFromOwner(
        address _owner,
        string memory _VIN
    ) external onlySuperAdmin {
        for (uint256 i = 0; i < owners[_owner].vehicleVINs.length; i++) {
            if (
                keccak256(bytes(owners[_owner].vehicleVINs[i])) ==
                keccak256(bytes(_VIN))
            ) {
                for (
                    uint256 j = i;
                    j < owners[_owner].vehicleVINs.length - 1;
                    j++
                ) {
                    owners[_owner].vehicleVINs[j] = owners[_owner].vehicleVINs[
                        j + 1
                    ];
                }
                break;
            }
        }
    }

    // Function to delete a vehicle from vehicle's struct
    function deleteVehicleFromVehicle(
        string memory _VIN
    ) external onlySuperAdmin {
        delete vehicles[_VIN];
    }

    // Function to delete a shop and usertype
    function deleteShop(address _shop) external onlySuperAdmin {
        delete userTypes[_shop];
        emit ShopDeleted(shops[_shop].name, shops[_shop].location);
        delete shops[_shop];
        totalAutoShops -= 1;
    }

    // Function to transfer the ownership of the contract
    function transferOwnership(address _newOwner) external onlySuperAdmin {
        userTypes[owner] = UserType.Unregistered;
        userTypes[_newOwner] = UserType.SuperAdmin;
        owner = _newOwner;
    }

    // Function to get total ETH payment
    function getTotalEthPayment()
        external
        view
        onlySuperAdmin
        returns (uint256)
    {
        return totalPaymentEth;
    }

    // Function to get total ETH payment by user
    function getTotalEthPaymentByUser(
        address _user
    ) external view onlySuperAdmin returns (uint256) {
        return totalPaymentEthByUser[_user];
    }

    // Function to get total token payment
    function getTotalTokenPayment()
        external
        view
        onlySuperAdmin
        returns (uint256)
    {
        return totalPaymentToken;
    }

    // Function to get total token payment by user
    function getTotalTokenPaymentByUser(
        address _user
    ) external view onlySuperAdmin returns (uint256) {
        return totalPaymentTokenByUser[_user];
    }

    // Allow smart contract to receive ETH
    receive() external payable {}
}