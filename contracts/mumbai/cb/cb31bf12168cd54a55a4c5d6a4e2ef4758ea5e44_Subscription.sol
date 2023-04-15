/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// File: Box.sol


pragma solidity 0.8.18;


contract Box is Ownable {
    uint256 immutable totalStorage;
    address immutable FactoryAddress;
    uint256 internal usedStorage;
    uint256 private id;

    address[] private requestedList;

    constructor(
        uint256 _totalStorage,
        address _owner,
        address _FactoryAddress
    ) {
        transferOwnership(_owner);
        totalStorage = _totalStorage;
        FactoryAddress = _FactoryAddress;
    }

    struct File {
        string uri;
        uint256 size;
        string fileName;
    }

    struct isRequestedInfo {
        bool isRequested;
        uint256 timeOfRequest;
        uint256 timePassedWithNoResponce;
    }

    mapping(uint256 => File) private files;
    mapping(address => bool) private allowedUsers;
    mapping(address => isRequestedInfo) public isRequested;
    mapping(address => uint8) private requestCount;
    mapping(address => uint8) private requestCountWithNoResponce;

    function addFile(
        string memory _uri,
        uint256 _size,
        string memory _fileName
    ) public onlyOwner {
        require(usedStorage + _size <= totalStorage, "Insuficient storage");
        id++;
        usedStorage += _size;
        files[id] = (File(_uri, _size, _fileName));
    }

    // - - - - -   G E T   S T O R E D   F I L E S   -   F U N C T I O N S   - - - - -

    // Function to get a file by its ID in box
    function getFileById(uint256 _id)
        public
        view
        returns (
            // allowedUser
            File memory
        )
    {
        return files[_id];
    }

    // Function to get all files available in box
    function getAllFile()
        public
        view
        returns (
            // allowedUser
            File[] memory
        )
    {
        File[] memory filesTemp = new File[](id);

        for (uint256 i = 1; i <= id; i++) {
            filesTemp[i - 1] = File(
                files[i].uri,
                files[i].size,
                files[i].fileName
            );
        }

        return filesTemp;
    }

    // - - - - -   C H E C K   S T O R A G E   I N F O   -   F U N C T I O N S   - - - - -

    // Function to get used storage of box
    function getUsedStorage()
        public
        view
        returns (
            // onlyOwner
            uint256
        )
    {
        return usedStorage;
    }

    // Function to get total available storage of box
    function getTotalStorage()
        public
        view
        returns (
            // onlyOwner
            uint256
        )
    {
        return totalStorage;
    }

    // - - - - -   A L L O W E D   U S E R   -   F U N C T I O N S   - - - - -

    // Function to set Allowed User
    function setAllowedUser(address user) public onlyOwner {
        allowedUsers[user] = true;
    }

    // Function to remove any Allowed User
    function removeAllowedUser(address user) public onlyOwner {
        require(allowedUsers[user], "user already not allowed");
        allowedUsers[user] = false;
    }

    // Function to check allowed user status
    function checkAllowedStatus(address user) public view returns (bool) {
        return allowedUsers[user];
    }

    // - - - - -   R E Q U E S T   A C C E S S   -   F U N C T I O N S   - - - - -

    // Function to Request Access
    function requestAccessForBox() public {
        require(!allowedUsers[msg.sender], "User Already Allowed");
        require(requestCount[msg.sender] < 3, "User Blocked");
        require(
            isRequested[msg.sender].timePassedWithNoResponce < block.timestamp,
            "Already Applied"
        );

        if (
            isRequested[msg.sender].timePassedWithNoResponce <= block.timestamp
        ) {
            requestCountWithNoResponce[msg.sender] += 1;
        }

        requestCount[msg.sender] += 1;
        isRequested[msg.sender].isRequested = true;
        isRequested[msg.sender].timeOfRequest = block.timestamp;
        isRequested[msg.sender].timePassedWithNoResponce =
            block.timestamp +
            1 minutes;
        requestedList.push(msg.sender);
    }

    // Function to accept Request
    function requestAccept(address user, uint256 index) public onlyOwner {
        require(isRequested[user].isRequested, "user not Request for Access");
        require(
            isRequested[user].timeOfRequest <
                isRequested[user].timeOfRequest + 1 minutes,
            "Request session expired"
        );
        require(requestedList[index] == user, "Index and user not match");
        allowedUsers[user] = true;
        isRequested[user].isRequested = false;
        isRequested[msg.sender].timePassedWithNoResponce = block.timestamp;
        requestedList[index] = requestedList[requestedList.length - 1];
        requestedList.pop();
    }

    function requestAutoAccept(address user, uint256 index)
        public
        callbyFactoryContract
    {
        require(
            isRequested[user].timePassedWithNoResponce < block.timestamp,
            "Time not completed yet"
        );

        require(
            requestCountWithNoResponce[user] >= 2,
            "Not allowed for approval yet"
        );
        allowedUsers[user] = true;
        isRequested[user].isRequested = false;
        isRequested[msg.sender].timePassedWithNoResponce = block.timestamp;
        requestedList[index] = requestedList[requestedList.length - 1];
        requestedList.pop();
    }

    // Function to Reject Request
    function requestReject(address user, uint256 index)
        public
        callbyFactoryContract
    {
        require(
            isRequested[msg.sender].timePassedWithNoResponce <
                isRequested[msg.sender].timeOfRequest + 1 minutes
        );
        require(isRequested[user].isRequested, "user not Request for Access");
        require(requestedList[index] == user, "Index and user not match");
        requestCount[user] += 1;
        isRequested[user].isRequested = false;
        isRequested[msg.sender].timePassedWithNoResponce = 0;

        requestedList[index] = requestedList[requestedList.length - 1];
        requestedList.pop();
    }

    // Function to check if Request Accepted
    function checkRequestAccessStatus(address user) public view returns (bool) {
        return allowedUsers[user];
    }

    // Function to check Requested address List
    function checkRequestedAccessList()
        public
        view
        returns (
            // callbyFactoryContract
            address[] memory
        )
    {
        return requestedList;
    }

    // - - - - -   M O D I F I E R   - - - - -

    // Modifier to call only by owner and Allowed User
    modifier allowedUser() {
        require(
            msg.sender == owner() || allowedUsers[msg.sender],
            "User not Allowed"
        );
        _;
    }

    modifier callbyFactoryContract() {
        require(
            msg.sender == owner() || msg.sender == FactoryAddress,
            "User not Allowed"
        );
        _;
    }
}
// File: Subscription.sol


pragma solidity 0.8.18;



interface box {
    function requestReject(address user, uint256 index) external;

    function requestAutoAccept(address user, uint256 index) external;

    function checkRequestedAccessList()
        external
        view
        returns (address[] memory);
}

contract Subscription is Ownable {
    Box boxContract;

    // Subscription parameters
    struct subscriptionPlans {
        uint256 price;
        uint256 storageAvailable;
    }

    // User subscription details
    struct userBoxDetails {
        subscriptionPlans plan;
        address boxAddress;
    }

    subscriptionPlans[] public packages;

    // mappings
    mapping(address => bool) isSubscribed;
    mapping(address => subscriptionPlans[]) UserOwnedBoxes;
    mapping(address => userBoxDetails[]) subscriberToBox;
    mapping(address => bool) isAllowForBoxCall;

    // Define constructor to set subscription parameters
    constructor() {
        packages.push(subscriptionPlans(100, 10 * 1024));
        packages.push(subscriptionPlans(200, 50 * 1024));
        packages.push(subscriptionPlans(300, 100 * 1024));
    }

    //- - - - - S U B S C R I P T I O N   M A N A G E M E N T  -  F U N C T I O N S - - - - -

    // Function to get subscription plan details
    function getSubscriptionPlanDetails(uint256 package)
        public
        view
        returns (subscriptionPlans memory)
    {
        require(package < packages.length, "Package details not Available");
        return packages[package];
    }

    // Function to update subscription plan
    function updateSubscriptionPlan(
        uint256 index,
        uint256 newPrice,
        uint256 newStorage
    ) public onlyOwner {
        packages[index].price = newPrice;
        packages[index].storageAvailable = newStorage * 1024 * 1024;
    }

    // Function to create new subscription plan
    function createNewSubscriptionPlan(uint256 newPrice, uint256 newStorage)
        public
        onlyOwner
    {
        packages.push(subscriptionPlans(newPrice, newStorage * 1024 * 1024));
    }

    // Function to Remove subscription plan
    function removeSubscriptionPlan(uint256 index) public onlyOwner {
        packages[index] = packages[packages.length - 1];
        packages.pop();
    }

    // Function to return total subscription plans
    function totalSubscriptionPlans() public view returns (uint256) {
        return (packages.length);
    }

    // - - - - -   S U B S C R I B E  /  U N S U B S C R I B E  -  F U N C T I O N S   - - - - -

    // Subscription function
    function subscribe(uint256 package) public payable returns (address) {
        require(
            msg.value == packages[package].price,
            "Invalid subscription price"
        );
        if (!isSubscribed[msg.sender]) isSubscribed[msg.sender] = true;

        boxContract = new Box(
            packages[package].storageAvailable,
            msg.sender,
            address(this)
        );

        UserOwnedBoxes[msg.sender].push(
            subscriptionPlans(
                packages[package].price,
                packages[package].storageAvailable
            )
        );

        subscriberToBox[msg.sender].push(
            userBoxDetails(
                subscriptionPlans(
                    packages[package].price,
                    packages[package].storageAvailable
                ),
                address(boxContract)
            )
        );
        return (address(boxContract));
    }

    // Function to check subscription status of specific User
    function checkSubscriptionStatus(address user)
        public
        view
        returns (
            // allowedUser(user)
            bool
        )
    {
        return isSubscribed[user];
    }

    // - - - - -   U S E R   I N F O   -   F U N C T I O N S   - - - - -

    // Function to get All Owned Boxes of User
    function getUserAllBoxes(address user)
        public
        view
        returns (
            // allowedUser(user)
            subscriptionPlans[] memory
        )
    {
        return UserOwnedBoxes[user];
    }

    // Function to get All Owned Boxes Addresses of User
    function getUserAllBoxesInfo(address user)
        public
        view
        // allowedUser(user)
        returns (userBoxDetails[] memory)
    {
        return subscriberToBox[user];
    }

    // Function to get Owned Box of User by its Index
    function getUserBoxByIndex(address user, uint256 index)
        public
        view
        returns (
            // allowedUser(user)
            userBoxDetails memory
        )
    {
        require(index < UserOwnedBoxes[user].length, "Box info not available");
        return subscriberToBox[user][index];
    }

    // Function to get user owned Box storage by index
    function getBoxMemorybyIndex(address user, uint256 index)
        public
        view
        returns (
            // allowedUser(user)
            uint256
        )
    {
        require(index < UserOwnedBoxes[user].length, "Box info not available");
        return UserOwnedBoxes[user][index].storageAvailable;
    }

    // Function to Reject Request for specific box
    function autoAllowAccessForSpecificBox(
        address boxAddress,
        address user,
        uint256 index
    ) public AllowedForBoxCall {
        box(boxAddress).requestAutoAccept(user, index);
    }

    // Function to Auto Approve Request for specific box
    function rejectAllowAccessForSpecificBox(
        address boxAddress,
        address user,
        uint256 index
    ) public AllowedForBoxCall {
        box(boxAddress).requestReject(user, index);
    }

    // Function to Allow Users to call requestReject Function of specific box
    function allowToCallBoxFunctions(address allow) public onlyOwner {
        isAllowForBoxCall[allow] = true;
    }

    // Function to disAllow Users to call requestReject Function of specific box
    function disAllowToCallBoxFunctions(address allow) public onlyOwner {
        isAllowForBoxCall[allow] = false;
    }

    // Function to Get Requested List of specific box
    function getRequestedAccessListOfBox(address boxAddress)
        public
        view
        returns (
            // AllowedForBoxCall
            address[] memory
        )
    {
        return box(boxAddress).checkRequestedAccessList();
    }

    // Modifier to call only by owner and Allowed User
    modifier allowedUser(address user) {
        require(
            msg.sender == owner() || user == msg.sender,
            "User not Allowed"
        );
        _;
    }

    modifier AllowedForBoxCall() {
        require(
            msg.sender == owner() || isAllowForBoxCall[msg.sender],
            "user not allowed to call these functions"
        );
        _;
    }
}