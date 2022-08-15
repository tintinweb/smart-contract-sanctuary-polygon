// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAavegotchi {
    function getOwnerGotchiLendingsLength(address _lender, bytes32 _status)
        external
        view
        returns (uint256);

    function isPetOperatorForAll(address _owner, address _operator)
        external
        view
        returns (bool approved_);

    function tokenIdsOfOwner(address _owner)
        external
        view
        returns (uint32[] memory tokenIds_);
}

contract Feeer is Ownable {
    address constant diamond = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant petter = 0x290000C417a1DE505eb08b7E32b3e8dA878D194E;

    uint256 gotchisPerMatic = 5;
    uint256 minProRata = 9;
    // wmaticReceiver has to be different than owner in case of wallet hack
    address constant wmaticReceiver =
        0xdC5b665e8135023F80BF4DbF85F65086c7aC3BB1;

    address[] private users;
    mapping(address => uint256) private usersToIndex;
    mapping(address => uint256) private userToLastFeeTimestamp;
    mapping(address => uint256) private userToWmaticPaid;
    mapping(address => uint256) private userToGotchiAmount;

    constructor() {
        // Mandatory, index 0 cannot be empty
        _addUser(0x86935F11C86623deC8a25696E1C19a8659CbF95d);
    }

    /*************************************************
     * G E T T E R S
     *************************************************/

    function getIsSignedUp(address _user) public view returns (bool) {
        return usersToIndex[_user] > 0;
    }

    function getUserLastFeeTimestamp(address _user)
        external
        view
        returns (uint256)
    {
        return userToLastFeeTimestamp[_user];
    }

    function getUserWmaticPaid(address _user) external view returns (uint256) {
        return userToWmaticPaid[_user];
    }

    function hasApprovedGotchiInteraction(address _user)
        public
        view
        returns (bool)
    {
        return IAavegotchi(diamond).isPetOperatorForAll(_user, petter);
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function getUsersIndexed(uint256 _pointer, uint256 _amount)
        external
        view
        returns (address[] memory)
    {
        address[] memory addresses = new address[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 pointer = _pointer + i;
            if (pointer > users.length) break;
            addresses[i] = users[pointer];
        }
        return addresses;
    }

    function getUsersCount() external view returns (uint256) {
        return users.length - 1;
    }

    function getUsersToIndex(address _user) external view returns (uint256) {
        return usersToIndex[_user];
    }

    /**
     * returns true if need to be removed
     * returns false if everything is fine
     */
    function getNeedRemoveUser(address _user) public view returns (bool) {
        // Needs to be a user
        if (!getIsSignedUp(_user)) return false;

        // If has remove isPetOperatorForAll
        if (!hasApprovedGotchiInteraction(_user)) return true;

        // If it's time to pay and doesn't have enough wmatic
        uint256 balanceUser = IERC20(wmatic).balanceOf(_user);
        if (balanceUser < getWmaticPayPerUser(_user) && getIsTimeToPay(_user))
            return true;

        // // If needs regulation and doesn't have enough matic
        uint256 amountToRegulate = getWmaticRegPerUser(_user);
        if (amountToRegulate > 0 && amountToRegulate > balanceUser) return true;

        return false;
    }

    function getBatchNeedRemoveUser(address[] calldata _users)
        external
        view
        returns (bool[] memory status_)
    {
        uint256 length = _users.length;
        status_ = new bool[](length);
        for (uint256 i = 0; i < length; ) {
            address user = _users[i];
            status_[i] = getNeedRemoveUser(user);
            unchecked {
                ++i;
            }
        }
    }

    function getWmaticPayPerGotchis(uint256 _amountGochis)
        public
        view
        returns (uint256)
    {
        return ((_amountGochis / gotchisPerMatic) + 1) * 10**18;
    }

    function getAmountGotchis(address _user) public view returns (uint256) {
        // Amount of gotchis in the wallet
        uint32[] memory tokenIds = IAavegotchi(diamond).tokenIdsOfOwner(_user);
        // Amount of gotchis lent
        uint256 lentGotchis = IAavegotchi(diamond).getOwnerGotchiLendingsLength(
            _user,
            "agreed"
        );
        return tokenIds.length + lentGotchis;
    }

    /**
        @dev not checking if needs to be removed because
        the bot will always check needs to be removed first
     */
    function getIsTimeToPay(address _user) public view returns (bool) {
        uint256 lastFeeTimestamp = userToLastFeeTimestamp[_user];
        return lastFeeTimestamp + 30 days < block.timestamp;
    }

    function getBatchNeedsToPay(address[] calldata _users)
        external
        view
        returns (bool[] memory status_)
    {
        uint256 length = _users.length;
        status_ = new bool[](length);
        for (uint256 i = 0; i < length; ) {
            address user = _users[i];
            status_[i] = getIsTimeToPay(user);
            unchecked {
                ++i;
            }
        }
    }

    function getWmaticPayPerUser(address _user) public view returns (uint256) {
        uint256 amountGotchis = getAmountGotchis(_user);
        return ((amountGotchis / gotchisPerMatic) + 1) * 10**18;
    }

    function getWmaticRegPerUser(address _user) public view returns (uint256) {
        // Get timings.
        uint256 lastFeeTimestamp = userToLastFeeTimestamp[_user];

        // Pro rata calc
        uint256 daysPassed = (block.timestamp - lastFeeTimestamp) / 1 days;

        // Can't regulate after 30 days
        if (daysPassed > 30) return 0;

        uint256 proRata = ((100 * (30 - daysPassed)) / 30);

        // No need to regulate if amount is low
        if (proRata < minProRata) return 0;

        // Get number of gotchis
        uint256 newAmountGotchis = getAmountGotchis(_user);

        // Get Wmatic amounts
        uint256 paidWmatic = userToWmaticPaid[_user];
        uint256 estimation = getWmaticPayPerGotchis(newAmountGotchis);

        // If the new estimation is higher than the paid or regulated one
        if (estimation > paidWmatic) {
            uint256 wmaticToPay = (proRata * estimation) / 100;
            return wmaticToPay;
        } else return 0;
    }

    function getBatchWmaticRegPerUser(address[] calldata _users)
        external
        view
        returns (uint256[] memory status_)
    {
        uint256 length = _users.length;
        status_ = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            address user = _users[i];
            status_[i] = getWmaticRegPerUser(user);
            unchecked {
                ++i;
            }
        }
    }

    /*************************************************
     * U S E R   F U N C T I O N S
     *************************************************/

    /**
     * @dev no need to check if approved enough matic
     * it is done when trying to transfer in _pay()
     */
    function signUp() external {
        // Make sure user is not already signed up
        require(usersToIndex[msg.sender] == 0, "Feeer: Already user");

        // Make sure user has set petOperatorForAll
        require(
            hasApprovedGotchiInteraction(msg.sender),
            "Feeer: Hasn't set petOperatorForAll"
        );

        // Make him pay
        _pay(msg.sender);

        // Add to the user array
        _addUser(msg.sender);
    }

    function leave() external {
        // Check if the user is a user
        require(
            usersToIndex[msg.sender] > 0,
            "Feeer: Can't leave, not registered as user"
        );

        // Remove from user array
        _removeUser(msg.sender);
    }

    /*************************************************
     * B O T   F U N C T I O N S
     * @notice Anyone can call the Both Functions
     * The functions will revert if the conditions are not met
     *************************************************/

    function pay(address _user) public {
        require(getIsSignedUp(_user), "Feeer: Can't charge non-users");
        _pay(_user);
    }

    function batchPay(address[] calldata _users) external {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; ) {
            address user = _users[i];
            pay(user);
            unchecked {
                ++i;
            }
        }
    }

    function regulate(address _user) public {
        require(getIsSignedUp(_user), "Feeer: Can't regulate non-users");

        uint256 amountGotchis = getAmountGotchis(_user);
        uint256 wmaticToPay = getWmaticRegPerUser(_user);
        require(wmaticToPay > 0, "Feeer: No regulation needed");

        // Transfer the funds
        bool success = IERC20(wmatic).transferFrom(
            _user,
            wmaticReceiver,
            wmaticToPay
        );
        require(success, "Feeer: transferFrom failed");

        /**
        this is not the amount actually paid
        This is the amount that should have been paid for 30 days
        It is necessary to no regulate multiple times a user
         */
        userToWmaticPaid[_user] = getWmaticPayPerGotchis(amountGotchis);

        // Save amount of gotchis when paid regulation
        userToGotchiAmount[_user] = amountGotchis;
    }

    function batchRegulate(address[] calldata _users) external {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; ) {
            address user = _users[i];
            regulate(user);
            unchecked {
                ++i;
            }
        }
    }

    function removeUser(address _user) public {
        // Check if the user is a user
        require(
            usersToIndex[_user] > 0,
            "Feeer: Can't remove, not registered as user"
        );

        // Has removed gotchi interaction OR can't pay
        require(getNeedRemoveUser(_user), "Feeer: Shouldn't be removed");

        _removeUser(_user);
    }

    function batchRemoveUsers(address[] calldata _users) external {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; ) {
            address user = _users[i];
            removeUser(user);
            unchecked {
                ++i;
            }
        }
    }

    /*************************************************
     * I N T E R N A L   F U N C T I O N S
     *************************************************/

    function _pay(address _user) internal {
        // Checking that it has been at least 30 days
        require(getIsTimeToPay(_user), "Feeer: 2soon2pay");

        // Get number of gotchis
        uint256 amountGotchis = getAmountGotchis(_user);

        // User must have at least 1 gotchi
        require(amountGotchis > 0, "Feeer: Doesn't own a gotchi");

        // Pay amount
        uint256 amount = getWmaticPayPerGotchis(amountGotchis);

        // pay
        bool success = IERC20(wmatic).transferFrom(
            _user,
            wmaticReceiver,
            amount
        );
        require(success, "Feeer: transferFrom failed");

        // Save timestamp
        userToLastFeeTimestamp[_user] = block.timestamp;

        // Save wmatic amount
        userToWmaticPaid[_user] = amount;

        // Save amount of gotchis
        userToGotchiAmount[_user] = amountGotchis;
    }

    function _addUser(address _newUser) private {
        // No need to add twice the same account
        require(usersToIndex[_newUser] == 0, "Feeer: user already added");

        // Get the index where the new user is in the array (= last position)
        usersToIndex[_newUser] = users.length;

        // Add the user in the array
        users.push(_newUser);
    }

    function _removeUser(address _userLeaver) private {
        // Cant remove an account that is not a user
        require(usersToIndex[_userLeaver] > 0, "Feeer: user already removed");

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
    }

    /*************************************************
     * A D M I N   F U N C T I O N S
     *************************************************/
    function updateGotchisPerMatic(uint256 _amount) external onlyOwner {
        gotchisPerMatic = _amount;
    }

    function updateMinProRata(uint256 _amount) external onlyOwner {
        minProRata = _amount;
    }

    // If you read the whole contract : <3
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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