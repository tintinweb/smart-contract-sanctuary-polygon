// SPDX-License-Identifier: MIT

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

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: EZContract.sol

pragma solidity ^0.8.0;

contract EZContract is Ownable {
    //declare struct of user .
    struct userInfo {
        string DID;
        string publicKey;
        uint256 atUpdate;
        string IPFSCid;
    }
    string private contractName;

    // constructor
    constructor(string memory _contractName) {
        contractName = _contractName;
    }

    mapping(string => userInfo[]) userDetails; //saving the user details
    event DepositUserInfo(
        string IPFSCid,
        string indexed DID,
        string publicKey,
        uint256 time
    ); // Declare an Event

    // to check string is empty or not
    function isEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    // write operation excuted by owner only to save data.
    function saveUserDetails(
        string memory IPFSCid,
        string memory DID,
        string memory publicKey
    ) external onlyOwner returns (bool) {
        require(!isEmptyString(DID), "passing DID is empty!");
        require(!isEmptyString(IPFSCid), "passing publicKey is empty!");
        require(!isEmptyString(publicKey), "passing publicKey is empty!");

        userDetails[DID].push(
            userInfo(DID, publicKey, block.timestamp, IPFSCid)
        );
        emit DepositUserInfo(IPFSCid, DID, publicKey, block.timestamp);

        return true;
    }

    // get all updated data of user
    function getUserInfoByDID(
        string memory DID
    ) external view returns (userInfo[] memory) {
        return userDetails[DID];
    }

    // get latest user data
    function getUserLastUpdatedInfoByDID(
        string memory DID
    ) external view returns (userInfo memory) {
        userInfo[] memory userData = userDetails[DID];
        return (userData[userData.length - 1]);
    }

    //get contract name
    function getContractName() external view returns (string memory) {
        return contractName;
    }
}