/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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




contract Identity is Ownable {
    //Id counter, starts from 1 so that 0 can be the default value for any unmapped address. Similar to address(0)
    uint256 internal currentId = 1;

    // mapping that returns the User Id of any address, returns 0 if not currently mapped yet.
    mapping(address => uint256) internal _resolveId;

    // mapping that returns the address that owns a user Id, returns adress(0) if not currently mapped. This doesn't necessarily serve any function except
    // for on chain verification by other contracts and off chain accesibility
    mapping(uint256 => address) internal _resolveAddress;

    // mapping that resolves if an address has been linked anytime in the past even if its access is currently revoked.
    mapping(address => bool) internal _isUsedAddress;

    //mapping that resolves if a user id has been revoked and is yet to be reAssigned, returns address(0) if false and the address it was revoked from if true.
    // once an address is mapped here it can't be unmapped.
    mapping(uint256 => address) internal _reAssignWaitlist;

    event Verified(address indexed userAddress, uint256 indexed userId);

    event Revoked(address indexed userAddress, uint256 indexed userId);

    event ReAssigned(address indexed userAddress, uint256 indexed userId);

    // verifes an address @params user and maps it.
    // checks to make sure it is not a revoked address
    function verify(address user) public onlyOwner {
        require(user != address(0), "Cannot verify address 0");
        require(!_isUsedAddress[user], "Address has previously been linked");
        _isUsedAddress[user] = true;
        _resolveId[user] = currentId;
        _resolveAddress[currentId] = user;
        emit Verified(user, currentId);
        unchecked {
            currentId++;
        }
    }

    // verifes an array of addresses @params user and maps them.
    // checks to make sure it is not a revoked address
    function verifyBatch(address[] calldata user) external {
        for (uint256 i = 0; i < user.length; i++) {
            verify(user[i]);
        }
    }

    // revokes an address @params user's map id
    // checks to make sure the address is an existing map
    // checks to make sure the address is not on the reAssign waitlist
    function revoke(address user) public onlyOwner {
        uint256 userId = _resolveId[user];
        require(userId != 0, "Address is not mapped");
        require(
            _reAssignWaitlist[userId] == address(0),
            "Id is on waitlist already"
        );
        _resolveId[user] = 0;
        _resolveAddress[userId] = address(0);
        _reAssignWaitlist[userId] = user;
        emit Revoked(user, userId);
    }

    // revokes an array of addresses @params user's map id
    // checks to make sure each address is an existing map
    // checks to make sure each address is not on the reAssign waitlist
    function revokeBatch(address[] calldata user) external {
        for (uint256 i = 0; i < user.length; i++) {
            revoke(user[i]);
        }
    }

    // reassigns an Id @params userId to an address @params user
    // checks to make sure the user is on the reAssign waitlist
    // to enable re assignment to its last address it checks if the last address is the same as the input @params user and remaps it to its old Id
    // else, it reverts if a previously mapped or/and revoked address is being mapped to another Id than its last (and only)
    function reAssign(uint256 userId, address user) public onlyOwner {
        require(user != address(0), "Cannot reAssign ID to address 0");
        address userIdWaitlistResolve = _reAssignWaitlist[userId];
        require(
            userIdWaitlistResolve != address(0),
            "Id not on reassign waitlist"
        );
        if (user == userIdWaitlistResolve) {
            _reAssignWaitlist[userId] = address(0);
            _resolveId[user] = userId;
            _resolveAddress[userId] = user;
        } else {
            require(!_isUsedAddress[user], "Address has been linked");
            _isUsedAddress[user] = true;
            _reAssignWaitlist[userId] = address(0);
            _resolveId[user] = userId;
            _resolveAddress[userId] = user;
        }
        emit ReAssigned(user, userId);
    }

    // reassigns an array of Ids @params userId to an array of addresses @params user respectively
    // checks to make sure each user is on the reAssign waitlist
    // to enable re assignment to its last address it checks if the last address is the same as the input @params user and remaps it to its old Id
    // else, it reverts if a previously mapped or/and revoked address is being mapped to another Id than its last (and only)
    function reAssignBatch(uint256[] calldata userId, address[] calldata user)
        external
        
    {
        require(
            userId.length == user.length,
            "UserID and User of different lengths"
        );
        for (uint256 i = 0; i < user.length; i++) {
            reAssign(userId[i], user[i]);
        }
    }

    function resolveId(address user) external view returns (uint256 userId) {
        userId = _resolveId[user];
    }

    function resolveAddress(uint256 userId)
        external
        view
        returns (address user)
    {
        user = _resolveAddress[userId];
    }

    function reAssignWaitlist(uint256 userId)
        external
        view
        returns (address userIdWaitlistResolve)
    {
        userIdWaitlistResolve = _reAssignWaitlist[userId];
    }

    function isUsedAddress(address user) external view returns (bool isUsed) {
        isUsed = _isUsedAddress[user];
    }
}