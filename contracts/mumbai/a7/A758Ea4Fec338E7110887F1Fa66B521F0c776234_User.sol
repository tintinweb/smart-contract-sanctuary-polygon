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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

/* This contract defines a User, who can be one of several types:
 - junior admins, who can perform certain actions on the contract
 - blacklisted users, who are not allowed to perform certain actions
 - users with contract access, who are allowed to access certain methods on the contract
 - users with a KYC level, which is a numeric value indicating their level of verification
 - staking users, who are eligible to participate in a staking program */

contract User is Ownable {
    // Maps to keep track of different types of users
    mapping(address => bool) private juniorAdmins;
    mapping(address => bool) private kycAdmins;
    mapping(address => bool) private blacklistedUsers;
    // mapping(address => bool) private contractAccessAddresses;
    mapping(address => uint8) private userKycLevel;
    mapping(address => bool) private stakingUsers;

    // Set the contract creator as a junior admin and give them access to contract methods
    constructor() {
        juniorAdmins[msg.sender] = true;
        // contractAccessAddresses[msg.sender] = true;
        kycAdmins[msg.sender] = true;
    }

    // Modifier to require caller to be a junior admin
    modifier atleastJrAdmin() {
        require(
            juniorAdmins[msg.sender] || owner() == msg.sender,
            "Need atleast jr admin status"
        );
        _;
    }

    modifier KYCAdmin() {
        require(
            kycAdmins[msg.sender] ||
                juniorAdmins[msg.sender] ||
                owner() == msg.sender,
            "Need access to update KYC level"
        );
        _;
    }

    // Events that can be emitted by this contract
    event jrAdminStatusUpdated(
        address _jrAdminAddress,
        bool _status,
        uint256 timeStamp
    );
    event kycAdminsUpdated(
        address kycAdminAddress,
        bool status,
        uint256 timeStamp
    );
    event userBlackListed(address _userAddress, uint256 timeStamp);
    event userBlackListRemoved(address _userAddress, uint256 timeStamp);
    event stakingUserAdded(address _userAddress, uint256 timeStamp);
    event stakingUserRemoved(address _userAddress, uint256 timeStamp);
    event userKYCLevelUpdated(
        address _userAddress,
        uint8 _kycLevel,
        uint256 timeStamp
    );

    /* This function allows the owner of the contract to update the junior admin status of a user
       The owner is not allowed to remove themselves as a junior admin */
    function updateJuniorAdminStatus(
        address _jrAdminAddress,
        bool _status
    ) public onlyOwner returns (bool) {
        require(
            _jrAdminAddress != owner(),
            "Cannot remove/add owner from junior admins"
        );
        juniorAdmins[_jrAdminAddress] = _status;
        emit jrAdminStatusUpdated(_jrAdminAddress, _status, block.timestamp);
        return true;
    }

    function updateKycAdminStatus(
        address _address,
        bool status
    ) public onlyOwner returns (bool) {
        require(
            _address != owner(),
            "Cannot remove/add owner from junior admins"
        );
        kycAdmins[_address] = status;
        emit kycAdminsUpdated(_address, status, block.timestamp);
        return true;
    }

    // Add a user to the blacklist
    function blackListUser(
        address _userAddress
    ) public atleastJrAdmin returns (bool) {
        require(_userAddress != owner(), "Cannot blacklist owner");
        blacklistedUsers[_userAddress] = true;
        emit userBlackListed(_userAddress, block.timestamp);
        return true;
    }

    function removeBlackListedUser(
        address _userAddress
    ) public atleastJrAdmin returns (bool) {
        // This function allows a junior admin to remove a user from the blacklisted users mapping
        blacklistedUsers[_userAddress] = false;

        // Emit an event to indicate that a user has been removed from the blacklisted users mapping
        emit userBlackListRemoved(_userAddress, block.timestamp);

        return true;
    }

    /**
     * This function allows a junior admin to update the KYC level of a user.
     *
     * @param _userAddress The address of the user to update.
     * @param _kycLevel The new KYC level for the user.
     * @return true if the KYC level was successfully updated, false otherwise.
     */

    function updateUserKYCLevel(
        address _userAddress,
        uint8 _kycLevel
    ) public KYCAdmin returns (bool) {
        require(
            !blacklistedUsers[_userAddress],
            "Cannot update KYC level for blacklisted user"
        );
        require(_kycLevel == 1 || _kycLevel == 2, "Invalid KYC level");
        require(
            userKycLevel[_userAddress] != _kycLevel,
            "User already have given KYC level"
        );

        // This function allows a junior admin to update the KYC level of a user
        userKycLevel[_userAddress] = _kycLevel;

        // Emit an event to indicate that the KYC level of a user has been updated
        emit userKYCLevelUpdated(_userAddress, _kycLevel, block.timestamp);

        return true;
    }

    function whitelistCreator(
        address _userAddress
    ) public atleastJrAdmin returns (bool) {
        require(
            !blacklistedUsers[_userAddress],
            "Cannot update KYC level for blacklisted user"
        );
        require(userKycLevel[_userAddress] != 3, "User already whitelisted");
        // This function allows a junior admin to update the KYC level 3 of a user
        userKycLevel[_userAddress] = 3;

        // Emit an event to indicate that the KYC level of a user has been updated
        emit userKYCLevelUpdated(_userAddress, 3, block.timestamp);

        return true;
    }

    function addStakingUser(
        address _userAddress
    ) public atleastJrAdmin returns (bool) {
        // This function allows a junior admin to add a user to the staking users mapping
        stakingUsers[_userAddress] = true;

        // Emit an event to indicate that a user has been added to the staking users mapping
        emit stakingUserAdded(_userAddress, block.timestamp);

        return true;
    }

    function removeStakingUser(
        address _userAddress
    ) public atleastJrAdmin returns (bool) {
        // This function allows a junior admin to remove a user from the staking users mapping
        stakingUsers[_userAddress] = false;

        // Emit an event to indicate that a user has been removed from the staking users mapping
        emit stakingUserRemoved(_userAddress, block.timestamp);

        return true;
    }

    // This function returns the blacklisted status of a user
    // If the user is blacklisted, it will return true
    // If the user is not blacklisted, it will return false
    function getUserBlackListStatus(
        address _userAddress
    ) public view returns (bool) {
        return blacklistedUsers[_userAddress];
    }

    // This function returns the staking status of a user
    // If the user is eligible to participate in the staking program, it will return true
    // If the user is not eligible to participate in the staking program, it will return false
    function getUserStakingStatus(
        address _userAddress
    ) public view returns(bool) {
        return stakingUsers[_userAddress];
    }

    // This function returns the junior admin status of a user
    // If the user is a junior admin, it will return true
    // If the user is not a junior admin

    function getjrAdminStatus(
        address _jrAdminAddress
    ) public view returns (bool) {
        // This function returns the junior admin status of a user
        // If the user is a junior admin, it will return true
        // If the user is not a junior admin, it will return false
        return juniorAdmins[_jrAdminAddress];
    }

    function getKycAdminStatus(address _address) public view returns (bool) {
        // This function returns the kyc admin status of a user
        // If the user is a junior admin, it will return true
        // If the user is not a junior admin, it will return false
        return kycAdmins[_address];
    }

    function getUserKYCLevel(address _userAddress) public view returns (uint8) {
        // This function returns the KYC level of a user
        return userKycLevel[_userAddress];
    }
}