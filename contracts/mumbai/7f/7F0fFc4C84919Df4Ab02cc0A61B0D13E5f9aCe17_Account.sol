// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/StringUtil.sol";

contract Account is Ownable {
    using StringUtil for string;

    mapping(address => UserInfo) public userInfo; // Info of each user that stakes tokens in each pool
    mapping(address => bool) public admin; // Admin of Contract

    event AddAdmin(address indexed _admin);
    event RemoveAdmin(address indexed _admin);
    event CreateUserInformation(address indexed _user, string _userID, string _bio);
    event UpdateUserInformation(address indexed _user, string _userID, string _bio);
    event DeleteUserInformation(address indexed _user);

    struct UserInfo {
        string userID;
        string bio;
        address userAddress;
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

    function updateUserInformation(
        address _user,
        string memory _userID,
        string memory _bio
    ) external canChange {
        require(_user != address(0), "USER:ADDRESS_NOT_FOUND");
        UserInfo storage info = userInfo[_user];
        info.userAddress = _user;

        if (!_userID.compareStrings("null") ) {
            info.userID = _userID;
        }
        if (!_bio.compareStrings("null")) {
            info.bio = _bio;
        }
        emit UpdateUserInformation(info.userAddress, info.userID, info.bio);
    }

    function deleteUserInformation(address _user) external isActive canChange {
        require(_user != address(0), "USER:ADDRESS_NOT_FOUND");
        UserInfo storage info = userInfo[_user];

        info.bio = "";
        info.userID = "";
        info.userAddress = address(0);

        emit DeleteUserInformation(_user);
    }

    modifier canChange() {
        address _sender = msg.sender;
        UserInfo storage info = userInfo[_sender];
        require(info.userAddress == address(0) || admin[_sender] == true || _sender == info.userAddress, "WALLET::NOT_ADMIN");
        _;
    }

    modifier isActive() {
        address _sender = msg.sender;
        UserInfo storage info = userInfo[_sender];
        require(info.userAddress != address(0), "USER:NOT_FOUND");
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

pragma solidity >=0.8.0;

library StringUtil {
    function isEmpty(string memory _s) internal pure returns (bool) {
        return bytes(_s).length == 0;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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