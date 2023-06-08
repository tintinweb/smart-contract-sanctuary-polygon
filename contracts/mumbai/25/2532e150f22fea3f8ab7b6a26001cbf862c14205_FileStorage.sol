/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

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



contract FileStorage is Ownable {
    struct FileData {
        string url;
        bytes32 hash;
        string[] userList;
        mapping(string => bool) whitelist;
    }

    string[] private fileList;
    mapping(string => FileData) private files;
    mapping(string => string) private userDict;

    event DocumentCreated(string indexed id, string url, bytes32 hash);
    event DocumentModified(string indexed id, string url, bytes32 newHash);
    event WhitelistUpdated(
        string indexed id,
        string userId,
        bool isWhitelisted
    );

    function setFileData(
        string calldata _id,
        string calldata _userId,
        string calldata _userName,
        string calldata _url,
        bytes32 _hash
    ) public onlyOwner {
        require(bytes(_userId).length != 0, "User Id must not be empty");
        require(bytes(_userName).length != 0, "Username must not be empty");
        require(bytes(_url).length != 0, "URL must not be empty");
        require(_hash != bytes32(0), "Hash must not be empty");
        FileData storage fileData = files[_id];
        bool is_new = bytes(fileData.url).length == 0;
        fileData.url = _url;
        fileData.hash = _hash;
        if (is_new) {
            fileList.push(_id);
            updateWhitelist(_id, _userId, _userName, true);
            emit DocumentCreated(_id, _url, _hash);
        } else {
            require(
                fileData.whitelist[_userId],
                "Not whitelisted to modify this document"
            );
            emit DocumentModified(_id, _url, _hash);
        }
    }

    function getFileData(
        string calldata _id
    ) public view returns (string memory, bytes32) {
        FileData storage fileData = files[_id];
        return (fileData.url, fileData.hash);
    }

    function verifyFileHash(
        string calldata _id,
        bytes32 _hash
    ) public view returns (bool) {
        FileData storage fileData = files[_id];
        return (fileData.hash == _hash);
    }

    function getUsername(
        string calldata _userId
    ) public view onlyOwner returns (string memory) {
        return (userDict[_userId]);
    }

    function getAllFiles() public view onlyOwner returns (string[] memory) {
        return (fileList);
    }

    function getUsersByFileId(
        string calldata _id
    ) public view onlyOwner returns (string[] memory) {
        FileData storage fileData = files[_id];
        return (fileData.userList);
    }

    function existWhitelistedUser(
        string calldata _id,
        string calldata _userId
    ) internal view returns (bool, uint) {
        FileData storage fileData = files[_id];
        for (uint i = 0; i < fileData.userList.length; i++) {
            if (
                keccak256(abi.encodePacked(fileData.userList[i])) ==
                keccak256(abi.encodePacked(_userId))
            ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeUser(string calldata _id, uint256 index) internal {
        FileData storage fileData = files[_id];
        fileData.userList[index] = fileData.userList[
            fileData.userList.length - 1
        ];
        fileData.userList.pop();
    }

    function updateWhitelist(
        string calldata _id,
        string calldata _userId,
        string calldata _userName,
        bool _setWhitelisted
    ) public onlyOwner {
        FileData storage fileData = files[_id];
        require(bytes(fileData.url).length != 0, "File data does not exist");
        if (fileData.whitelist[_userId] == _setWhitelisted) return;
        bool isUserExist;
        uint indexWhitelist;
        (isUserExist, indexWhitelist) = existWhitelistedUser(_id, _userId);
        if ((_setWhitelisted) && (!isUserExist)) {
            fileData.userList.push(_userId);
            userDict[_userId] = _userName;
        } else if ((!_setWhitelisted) && (isUserExist)) {
            removeUser(_id, indexWhitelist);
        }
        fileData.whitelist[_userId] = _setWhitelisted;
        emit WhitelistUpdated(_id, _userId, _setWhitelisted);
    }
}