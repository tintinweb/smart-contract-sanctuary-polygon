// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev Contract module for user management.
 *
 * This module is used through inheritance. It will make available the contract
 * addresses of users, admin, whitelisting and blacklisting of users.
 */
contract Operations is Ownable, Pausable {
    // To Check and Balance the System Account.
    uint256 internal _totalIssued;
    uint256 internal _totalRedeemed;

    address[] private admins;
    address[] private authorizers;
    address[] private usersList;
    address[] private blackList;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isAuthorizer;
    mapping(address => bool) public isUserListed;
    mapping(address => bool) public isBlackListed;

    event AddedAdmin(address indexed _admin);
    event RemovedAdmin(address indexed _admin);
    event AddedAuthorizer(address indexed _authorizer);
    event RemovedAuthorizer(address indexed _authorizer);
    event SetAddressList(address indexed _user);
    event RemoveAddressList(address _user);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event DestroyedBlackFunds(address _User, uint256 _amount);

    modifier isAdminAddr(address _admin) {
        require(isAdmin[_admin], "Admin does not exist");
        _;
    }

    modifier notAdmin(address admin) {
        require(!isAdmin[admin], "Account already Admin");
        _;
    }

    modifier isAuthorizerAddr(address authorizer) {
        require(isAuthorizer[authorizer], "Account not Authorized");
        _;
    }

    modifier notAuthorizer(address authorizer) {
        require(!isAuthorizer[authorizer], "Account already authorized");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0), "No provided account");
        _;
    }

    modifier checkUserList(address _user) {
        require(isUserListed[_user], "Account not a User");
        _;
    }

    constructor()
    // public initializer
     {
        isUserListed[_msgSender()] = true;
        usersList.push(_msgSender());

        // SetUserList(_msgSender());
        AddAdmin(_msgSender());
        AddAuthorizer(_msgSender());
    }

    //adds address as admin and also authorizers the address
    function AddAdmin(address _AdminID)
        public
        onlyOwner
        notAdmin(_AdminID)
        checkUserList(_AdminID)
        whenNotPaused
        returns (bool)
    {
        admins.push(_AdminID);
        isAdmin[_AdminID] = true;

        emit AddedAdmin(_AdminID);

        return true;
    }

    //Removes and Admin
    function RemoveAdmin(address _addr)
        public
        onlyOwner
        isAdminAddr(_addr)
        returns (bool)
    {
        for (uint256 i = 0; i < admins.length - 1; i++)
            if (admins[i] == _addr) {
                admins[i] = admins[admins.length - 1];
                break;
            }
        admins.pop();
        isAdmin[_addr] = false;

        emit RemovedAdmin(_addr);

        return true;
    }

    //Get all listed Admins on the System
    function GetAdminList()
        public
        view
        isAdminAddr(_msgSender())
        returns (address[] memory)
    {
        return admins;
    }

    //Authorizer Rights and Functions
    function AddAuthorizer(address authorizer)
        public
        onlyOwner
        checkUserList(authorizer)
        notAuthorizer(authorizer)
        whenNotPaused
        returns (bool)
    {
        isAuthorizer[authorizer] = true;
        authorizers.push(authorizer);

        emit AddedAuthorizer(authorizer);

        return true;
    }

    // Remove authorizer
    function RemoveAuthorizer(address _authorizer)
        public
        onlyOwner
        isAuthorizerAddr(_authorizer)
        returns (bool)
    {
        for (uint256 i = 0; i < authorizers.length - 1; i++)
            if (authorizers[i] == _authorizer) {
                authorizers[i] = authorizers[authorizers.length - 1];
                break;
            }
        authorizers.pop();
        isAuthorizer[_authorizer] = false;

        emit RemovedAuthorizer(_authorizer);

        return true;
    }

    // Get all listed authorizers on the System
    function GetAuthorizerList()
        public
        view
        isAdminAddr(_msgSender())
        returns (address[] memory)
    {
        return authorizers;
    }

    // List users on the System
    function SetUserList(address _addr)
        public
        isAdminAddr(_msgSender())
        notNull(_addr)
        whenNotPaused
        returns (bool)
    {
        require(isUserListed[_addr] != true, "Address has been Whitelisted");
        isUserListed[_addr] = true;
        usersList.push(_addr);

        emit SetAddressList(_addr);

        return true;
    }

    // Remove users from whitelist
    function RemoveUserList(address _addr)
        public
        isAdminAddr(_msgSender())
        notNull(_addr)
        returns (bool)
    {
        require(isUserListed[_addr], "Address not a Listed User");

        if (isAdmin[_addr]) {
            RemoveAdmin(_addr);
        }

        for (uint256 i = 0; i < usersList.length - 1; i++)
            if (usersList[i] == _addr) {
                usersList[i] = usersList[usersList.length - 1];
                break;
            }
        usersList.pop();
        isUserListed[_addr] = false;

        emit RemoveAddressList(_addr);

        return true;
    }

    //check if user is listed
    function CheckUserList(address _addr)
        public
        view
        returns (bool)
    {
        return isUserListed[_addr];
    }

    //Get all listed users in the System
    function GetUsersList()
        public
        view
        isAdminAddr(_msgSender())
        returns (address[] memory)
    {
        return usersList;
    }

    // Add adress to BlackList
    function AddBlackList(address _evilUser)
        public
        isAdminAddr(_msgSender())
        checkUserList(_evilUser)
    {
        require(!isBlackListed[_evilUser], "User already BlackListed");

        if (isAdmin[_evilUser]) {
            RemoveAdmin(_evilUser);
        }
        if (isAuthorizer[_evilUser]) {
            RemoveAuthorizer(_evilUser);
        }

        blackList.push(_evilUser);
        isBlackListed[_evilUser] = true;

        emit AddedBlackList(_evilUser);
    }

    // Remove Address from BlackList
    function RemoveBlackList(address _clearedUser)
        public
        isAdminAddr(_msgSender())
        notNull(_clearedUser)
        returns (bool)
    {
        require(isBlackListed[_clearedUser], "Address not a Listed User");

        for (uint256 i = 0; i < usersList.length - 1; i++)
            if (blackList[i] == _clearedUser) {
                blackList[i] = blackList[blackList.length - 1];
                break;
            }
        blackList.pop();
        isBlackListed[_clearedUser] = false;

        emit RemovedBlackList(_clearedUser);

        return true;
    }

    //check if address is blacklisted
    function isBlackListedAddress(address _addr)
        public
        view
        returns (bool)
    {
        return isBlackListed[_addr];
    }

    //Get all who is blacklisted on the System
    function GetBlackListed()
        public
        view
        returns (address[] memory)
    {
        return blackList;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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