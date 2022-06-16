// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WalletInformation is Ownable {

    mapping (address => UserInfo) public userInfo; // Info of each user that stakes tokens in each pool
    mapping (address => bool) public admin; // Admin of Contract

    event AddAdmin(address indexed _admin);
    event RemoveAdmin(address indexed _admin);
    event CreateUserInformation(address indexed _user, string _userName, string _displayName, string _nickName, string _bio, string _IPFS);
    event UpdateUserInformation(address indexed _user, string _userName, string _displayName, string _nickName, string _bio, string _IPFS);
    event DeleteUserInformation(address indexed _user);
    
    struct UserInfo {
        string userName;
        string displayName;
        string nickName;
        string bio;
        string IPFS;
        address walletAddress;
    }

    constructor() {
        admin[msg.sender] = true;
    }

    function addAmin(address _admin) external onlyOwner {
        admin[_admin] = true;

        emit AddAdmin(_admin);
    }

    function removeAmin(address _admin) external onlyOwner {
        admin[_admin] = false;

        emit RemoveAdmin(_admin);
    }

    function createUserInformation(
        address _user,
        string memory _userName, 
        string memory _displayName, 
        string memory _nickName, 
        string memory _bio,
        string memory _IPFS
    ) external isAdmin(msg.sender) {
        UserInfo storage user = userInfo[_user];

        user.bio = _bio;
        user.userName = _userName;
        user.displayName = _displayName;
        user.nickName = _nickName;
        user.walletAddress = _user;
        user.IPFS = _IPFS;


        emit CreateUserInformation(_user, _userName, _displayName, _nickName, _bio, _IPFS);
    }

    function updateUserInformation(
        address _user,
        string memory _userName, 
        string memory _displayName, 
        string memory _nickName, 
        string memory _bio,
        string memory _IPFS
    ) external isAdmin(msg.sender) {
        UserInfo storage user = userInfo[_user];

        user.bio = _bio;
        user.userName = _userName;
        user.displayName = _displayName;
        user.nickName = _nickName;
        user.walletAddress = _user;
        user.IPFS = _IPFS;


        emit UpdateUserInformation(_user, _userName, _displayName, _nickName, _bio, _IPFS);
    }

    function deleteUserInformation(address _user) external isAdmin(msg.sender) {
        UserInfo storage user = userInfo[_user];

        user.bio = "";
        user.userName = "";
        user.displayName = "";
        user.nickName = "";
        user.walletAddress = address(0);
        user.IPFS = "";


        emit DeleteUserInformation(_user);
    }

    modifier isAdmin(address _user) {
        require(admin[_user] == true, "WALLET::NOT_ADMIN");
        _;
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