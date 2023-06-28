// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

struct TokenIdsWithKinship {
    uint256 tokenId;
    uint256 kinship;
    uint256 lastInteracted;
}

interface IAavegotchi {
    function isPetOperatorForAll(
        address _owner,
        address _operator
    ) external view returns (bool approved_);

    function tokenIdsWithKinship(
        address _owner,
        uint256 _count,
        uint256 _skip,
        bool all
    ) external view returns (TokenIdsWithKinship[] memory tokenIdsWithKinship_);

    function getLentTokenIdsOfLender(
        address _lender
    ) external view returns (uint32[] memory tokenIds_);

    function balanceOfLentGotchis(
        address _lender
    ) external view returns (uint256 balance_);
}

contract GWM is Ownable {
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed user, uint256 amount);
    event Start(address indexed user, uint256 amountGotchis);
    event Stop(address indexed user);
    event AdminUpdated(address indexed admin, bool status);
    event DailyCostUpdated(uint256 newDailyCost);
    event StartFeesUpdated(uint256 newStartFees);
    event ReceiverUpdated(address newReceiver);
    event FundsSentToReceiver(uint256 amount);
    event UserAdded(address indexed newUser);
    event UserRemoved(address indexed userLeaver);
    event BalanceBeforeUpdate(
        address indexed user,
        uint256 oldBalance,
        uint256 oldAmountGotchi,
        uint256 oldTimestamp
    );
    event BalanceAfterUpdate(
        address indexed user,
        uint256 newBalance,
        uint256 newAmountGotchi,
        uint256 newTimestamp
    );

    address constant diamond = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address petter = 0x290000C417a1DE505eb08b7E32b3e8dA878D194E;
    address receiver = 0xdC5b665e8135023F80BF4DbF85F65086c7aC3BB1;

    uint256 dailyCost; // X Matic per day per 1 gotchis
    uint256 startFees; // Fees when starting the petter

    uint256 contractBalance = 0;
    mapping(address => uint256) userToBalance;
    mapping(address => uint256) userToTimestamp;
    mapping(address => uint256) userToGotchiAmount;

    address[] users;
    mapping(address => uint256) usersToIndex;

    mapping(address => bool) isAdmin;

    bool public paused;

    constructor() {
        dailyCost = 11 * 10 ** 15;
        startFees = 10 ** 17;
        isAdmin[0x5ecf70427aA12Cd0a2f155acbB7d29e7d15dc771] = true;
        // Mandatory, index 0 cannot be empty
        _addUser(0x86935F11C86623deC8a25696E1C19a8659CbF95d);
        // Deploy the contract unpaused
        paused = false;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "GWM: Only Admins");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "GWM: Contract is paused");
        _;
    }

    /*************************************************
     * V I E W     F U N C T I O N S
     *************************************************/

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function getUserCount() external view returns (uint256) {
        return users.length - 1;
    }

    function getIsUser(address _user) public view returns (bool) {
        return usersToIndex[_user] > 0;
    }

    function getUsersToIndex(address _address) external view returns (uint256) {
        return usersToIndex[_address];
    }

    function getUserToBalance(address _user) external view returns (uint256) {
        return userToBalance[_user];
    }

    function getUserToGotchiAmount(
        address _user
    ) external view returns (uint256) {
        return userToGotchiAmount[_user];
    }

    function getUserToTimestamp(address _user) external view returns (uint256) {
        return userToTimestamp[_user];
    }

    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }

    function getDailyCost() external view returns (uint256) {
        return dailyCost;
    }

    function getStartFees() external view returns (uint256) {
        return startFees;
    }

    function getGotchiInteraction(address _user) public view returns (bool) {
        return IAavegotchi(diamond).isPetOperatorForAll(_user, petter);
    }

    function getSpentMatic(address _user) private view returns (uint256) {
        uint256 lastT = userToTimestamp[_user];
        uint256 lastG = userToGotchiAmount[_user];

        if (lastT == 0) return 0;

        uint256 duration = block.timestamp - lastT;
        uint256 realDailyCost = getCostPerDay(lastG);

        uint256 spent = (1 + (duration / 1 days)) * realDailyCost;

        if (spent > userToBalance[_user]) spent = userToBalance[_user];
        return spent;
    }

    function getUserBalance(address _user) public view returns (uint256) {
        uint256 spent = getSpentMatic(_user);
        if (spent > userToBalance[_user]) return 0;
        return userToBalance[_user] - spent;
    }

    function getCostPerDay(
        uint256 _amountGotchis
    ) public view returns (uint256) {
        return _amountGotchis * dailyCost;
    }

    function getDaysLeft(
        address _user,
        uint256 _amountGotchis
    ) public view returns (uint256) {
        uint256 balance = userToBalance[_user] - getSpentMatic(_user);
        uint256 cost = getCostPerDay(_amountGotchis);
        if (cost == 0) return 999;
        return balance / cost;
    }

    /*************************************************
     * U S E R    F U N C T I O N S
     *************************************************/

    function depositMatic() external payable whenNotPaused {
        require(msg.value != 0, "GWM: deposit can't be 0");
        userToBalance[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value, userToBalance[msg.sender]);
    }

    function withdrawMatic() external payable whenNotPaused {
        require(usersToIndex[msg.sender] == 0, "GWM: Stop petting first");
        require(userToBalance[msg.sender] != 0, "GWM: Balance is 0");
        uint256 toReturn = userToBalance[msg.sender];
        userToBalance[msg.sender] = 0;
        (bool sent, bytes memory data) = msg.sender.call{value: toReturn}("");
        require(sent, "GWM: Failed to send Matic");

        emit Withdraw(msg.sender, toReturn);
    }

    function start(uint256 _amountGotchis) external whenNotPaused {
        _start(msg.sender, _amountGotchis);
    }

    function stop() external whenNotPaused {
        _stop(msg.sender);
    }

    function startAndTransfer(uint256 _amountGotchis) external whenNotPaused {
        _start(msg.sender, _amountGotchis);
        if (contractBalance > 5 * 10 ** 18) _sendMaticToReceiver();
    }

    function stopAndTransfer() external whenNotPaused {
        _stop(msg.sender);
        if (contractBalance > 5 * 10 ** 18) _sendMaticToReceiver();
    }

    /*************************************************
     * A D M I N    F U N C T I O N S
     *************************************************/

    function batchRegulate(
        address[] memory _users,
        uint256[] memory _amountGotchis
    ) external onlyAdmin {
        uint256 len = _users.length;
        require(len == _amountGotchis.length, "GWM: Arrays length not equal");
        for (uint256 i = 0; i < len; ) {
            address user = _users[i];
            uint256 amountGotchis = _amountGotchis[i];
            regulate(user, amountGotchis);
            unchecked {
                ++i;
            }
        }
    }

    function regulate(address _user, uint256 _amountGotchis) public onlyAdmin {
        uint256 spent = getSpentMatic(_user);

        emit BalanceBeforeUpdate(
            _user,
            userToBalance[_user],
            _amountGotchis,
            userToTimestamp[_user]
        );

        userToBalance[_user] -= spent;
        contractBalance += spent;
        userToGotchiAmount[_user] = _amountGotchis;
        userToTimestamp[_user] = block.timestamp;

        emit BalanceAfterUpdate(
            _user,
            userToBalance[_user],
            _amountGotchis,
            userToTimestamp[_user]
        );
    }

    function batchRemoveUser(
        address[] memory _users,
        uint256[] memory _amountGotchis
    ) external onlyAdmin {
        uint256 len = _users.length;
        require(len == _amountGotchis.length, "GWM: Arrays length not equal");
        for (uint256 i = 0; i < len; ) {
            address user = _users[i];
            uint256 amountGotchis = _amountGotchis[i];
            removeUser(user, amountGotchis);
            unchecked {
                ++i;
            }
        }
    }

    function removeUser(
        address _user,
        uint256 _amountGotchis
    ) public onlyAdmin {
        require(
            getDaysLeft(_user, _amountGotchis) == 0 ||
                getGotchiInteraction(_user) == false,
            "GWM: Enough Balance and interaction == true"
        );
        _stop(_user);
    }

    function sendMaticToReceiver() external onlyAdmin {
        _sendMaticToReceiver();
    }

    function safeSendMaticToReceiver() external onlyAdmin {
        uint256 amount = contractBalance;
        contractBalance = 0;
        if (amount > address(this).balance) amount = address(this).balance;
        (bool sent, bytes memory data) = receiver.call{value: amount}("");
        require(sent, "GWM: Failed to send Matic to petter");

        emit FundsSentToReceiver(amount);
    }

    /*************************************************
     * I N T E R N A L   F U N C T I O N S
     *************************************************/

    function _sendMaticToReceiver() private {
        uint256 amount = contractBalance;
        contractBalance = 0;
        (bool sent, bytes memory data) = receiver.call{value: amount}("");
        require(sent, "GWM: Failed to send Matic to petter");

        emit FundsSentToReceiver(amount);
    }

    function _start(address _user, uint256 _amountGotchis) private {
        uint256 costPerDay = getCostPerDay(_amountGotchis);
        uint256 minMatic = startFees + (5 * costPerDay);
        require(
            userToBalance[_user] >= minMatic,
            "GWM: Need 5 days worth of matic to start + 0.1"
        );
        require(_amountGotchis != 0, "GWM: Can't start with 0 gotchis");

        userToBalance[_user] -= startFees;
        contractBalance += startFees;

        userToTimestamp[_user] = block.timestamp;
        userToGotchiAmount[_user] = _amountGotchis;
        _addUser(_user);

        emit Start(_user, _amountGotchis);
    }

    function _stop(address _user) private {
        uint256 spent = getSpentMatic(_user);

        userToBalance[_user] -= spent;
        contractBalance += spent;

        userToTimestamp[_user] = 0;
        userToGotchiAmount[_user] = 0;

        _removeUser(_user);
        emit Stop(_user);
    }

    function _addUser(address _newUser) private {
        // No need to add twice the same account
        require(usersToIndex[_newUser] == 0, "GWM: user already added");

        // Get the index where the new user is in the array (= last position)
        usersToIndex[_newUser] = users.length;

        // Add the user in the array
        users.push(_newUser);

        // Emit
        emit UserAdded(_newUser);
    }

    function _removeUser(address _userLeaver) private {
        // Cant remove an account that is not a user
        require(usersToIndex[_userLeaver] > 0, "GWM: user already removed");

        // Get the index of the leaver
        uint256 _indexLeaver = usersToIndex[_userLeaver];

        // Get last index
        uint256 lastElementIndex = users.length - 1;

        // Get Last address in array
        address lastAddressInArray = users[lastElementIndex];

        // Move the last address in the position of the leaver
        users[_indexLeaver] = users[lastElementIndex];

        // Change the moved address' index to the new one
        usersToIndex[lastAddressInArray] = _indexLeaver;

        // Remove last entry in the array and reduce length
        users.pop();
        usersToIndex[_userLeaver] = 0;

        // Emit
        emit UserRemoved(_userLeaver);
    }

    /*************************************************
     * O W N E R    F U N C T I O N S
     *************************************************/

    function getIsAdmin(address _address) external view returns (bool) {
        return isAdmin[_address];
    }

    function getReceiverAddress() external view returns (address) {
        return receiver;
    }

    function addRemoveAdmin(address _address, bool _state) external onlyOwner {
        isAdmin[_address] = _state;

        emit AdminUpdated(_address, _state);
    }

    function updateDailyCost(uint256 _newDailyCost) external onlyOwner {
        require(_newDailyCost > 10000000000, "GWM: Need all decimals");
        dailyCost = _newDailyCost;

        emit DailyCostUpdated(_newDailyCost);
    }

    function updateStartFees(uint256 _newStartFees) external onlyOwner {
        require(_newStartFees > 10000000000, "GWM: Need all decimals");
        startFees = _newStartFees;

        emit StartFeesUpdated(_newStartFees);
    }

    function updateReceiver(address _receiver) external onlyOwner {
        receiver = _receiver;
        emit ReceiverUpdated(_receiver);
    }

    function forceStop(address _user) external onlyOwner {
        _stop(_user);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }
}