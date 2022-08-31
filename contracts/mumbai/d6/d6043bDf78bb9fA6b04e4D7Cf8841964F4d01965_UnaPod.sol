/* SPDX-License-Identifier: MIT

UNA : https://www.unablockchain.io/
                                  ,,                      ,////((/°.
         /°,°(,               °°,,°./##%              /°,,,°.,°/////°°..
         /°,°/°              °,,°°.#(####,          /°,,°/#,     ,(/°°,°,
         /°°°/°              °,,°/,  ((((((       ./,,,(,           ,,,°,°,
         (°°°(°              °°,°/°   /////#      /,,,°,             ,°,,,/.
         //°°(/              /°,°(°    ,°°°°(.    /,,,(              .°,,,°.
         °/°°/(°            /°°,/#      .(,°°/°   /,,,(              .°,,,/.
          ,(///((/        /(°°°/#         (,,,°(  /,,,(              .°,,,/.
            ,/((((.####(#(°°°/#.           °,,,,°/°,,,#    .°°°°°°°°°..,,,/.
               °/,.,,,..°/((.                #/.,,,,/,    /,,,,,,,,°,,,,,(

Creators: Joseph Bedminster, UNA Blockchain

*/

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/*PoD*/
abstract contract PermissionedOnchainDatabase is Ownable {
    struct DelegationLink {
        address addr;
        string key;
    }
    struct Data {
        string key;
        string value;
        uint timestamp;
    }
    mapping (address => Data[]) internal _pod;
    mapping (address => DelegationLink[]) internal readDelegations;
    mapping (address => DelegationLink[]) internal writeDelegations;
    event DataAccessed(address indexed owner, string indexed key);
    event DataAdded(address indexed owner, string indexed key);
    event DataRemoved(address indexed owner, string indexed key);
    event DelegationReadAdded(address indexed addr, address indexed to);
    event DelegationWriteAdded(address indexed addr, address indexed to);
    event DelegationReadRemoved(address indexed addr, address indexed to);
    event DelegationWriteRemoved(address indexed addr, address indexed to);

    function _getPod(address addr) internal returns(Data[] memory) {
        //Reconstruct the data array with only data the requester can access
        Data[] memory data = new Data[](_getPodLength(addr));
        for (uint i = 0; i < _pod[addr].length; i++) {
            if (isAuthorized(addr, "READ", _pod[addr][i].key)) {
                emit DataAccessed(addr, _pod[addr][i].key);
                data[i] = _pod[addr][i];
            } else {
                //Avoid size mismatch, delete last case of the returned array
                //From : https://ethereum.stackexchange.com/a/51897
                if (data.length > 0) {
                    assembly { mstore(data, sub(mload(data), 1)) }
                }
            }
        }

        return data;
    }

    function _getPodLength(address addr) internal view returns(uint256 size) {
        return _pod[addr].length;
    }

    function _getPodLengthSeenBy(address addr, address requester) internal view returns(uint256 size) {
        uint256 resultCount;
        for (uint i = 0; i < _pod[addr].length; i++) {
            if (isAuthorized(requester, "READ", _pod[addr][i].key)) {
                resultCount++;
            }
        }

        return resultCount;
    }

    function _getDataLengthByKey(address addr, string memory _key) internal view returns(uint256 size) {
        uint256 resultCount;
        for (uint i = 0; i < _pod[addr].length; i++) {
            if (compare(_pod[addr][i].key, _key)) {
                resultCount++;
            }
        }

        return resultCount;
    }

    function _getDataLengthByKeySeenBy(address addr, address requester, string memory _key) internal view returns(uint256 size) {
        uint256 resultCount;
        for (uint i = 0; i < _pod[addr].length; i++) {
            if (compare(_pod[addr][i].key, _key) && isAuthorized(requester, "READ", _pod[addr][i].key)) {
                resultCount++;
            }
        }

        return resultCount;
    }

    function _getDataByKey(address addr, string memory _key) internal returns(Data[] memory) {
        Data[] memory data = new Data[](_getDataLengthByKey(addr, _key));
        uint256 j;
        for (uint i = 0; i < _pod[addr].length; i++) {
            if (compare(_pod[addr][i].key, _key)) {
                data[j] = _pod[addr][i];
                j++;
            }
        }
        emit DataAccessed(addr, _key);
        return data;
    }

    function _addData(address addr, string memory _key, string memory _value) internal {
        _pod[addr].push(Data(_key, _value, getBlockTimestamp()));
        emit DataAdded(addr, _key);
    }

    function _copyData(address addr, address to) internal {
        uint toLength = _getPodLength(addr);
        for (uint i = 0; i < _pod[addr].length; i++) {
            _pod[to][toLength] = _pod[addr][i];
            toLength++;
        }
    }

    function _removeDataByKey(address addr, string memory _key) internal {
        for (uint i = 0; i < _pod[addr].length; i++) {
            if (compare(_pod[addr][i].key, _key)) {
                delete _pod[addr][i];
            }
        }
        emit DataRemoved(addr, _key);
    }

    function _removeData(address addr) internal {
        for (uint i = 0; i < _pod[addr].length; i++) {
            delete _pod[addr][i];
        }
        emit DataRemoved(addr, "_ALL_");
    }

    function _addReadDelegation(address addr, address to, string memory _key) internal {
        readDelegations[addr].push(DelegationLink(to, _key));
        emit DelegationReadAdded(addr, to);
    }

    function _addWriteDelegation(address addr, address to, string memory _key) internal {
        writeDelegations[addr].push(DelegationLink(to, _key));
        emit DelegationWriteAdded(addr, to);
    }

    function _removeReadDelegation(address addr, address to, string memory _key) internal {
        for (uint i = 0; i < readDelegations[addr].length; i++) {
            if (readDelegations[addr][i].addr == addr
                && compare(readDelegations[addr][i].key, _key)) {
                delete readDelegations[addr][i];
            }
        }
        emit DelegationReadRemoved(addr, to);
    }

    function _removeWriteDelegation(address addr, address to, string memory _key) internal {
        for (uint i = 0; i < writeDelegations[addr].length; i++) {
            if (writeDelegations[addr][i].addr == addr
                && compare(writeDelegations[addr][i].key, _key)) {
                delete writeDelegations[addr][i];
            }
        }
        emit DelegationWriteRemoved(addr, to);
    }

    /* A user can only add its own data */
    function addData(address addr, string memory _key, string memory _value) public {
        require(isAuthorized(addr, "WRITE", _key), "This tuple address/key is not authorized to access the data.");
        return _addData(addr, _key, _value);
    }

    /* A user can only get its own data */
    function getData(address addr, string memory _key) public returns(Data[] memory) {
        require(isAuthorized(addr, "READ", _key), "This tuple address/key is not authorized to access the data.");
        return _getDataByKey(addr, _key);
    }

    /* A user can only get its own data */
    function getPod(address addr) public returns(Data[] memory) {
        return _getPod(addr);
    }

    /* A user can only edit its own data */
    function copyData(address addr, address to) public {
        require(isAuthorized(addr, "READ", ""), "This tuple address/key is not authorized to access the data.");
        require(isAuthorized(to, "WRITE", ""), "This tuple address/key is not authorized to write new data.");
        _copyData(addr, to);
    }

    function removeData(address addr) public {
        /* Only admin and user */
        require(msg.sender == owner() || msg.sender == addr, "You are not authorized to remove this data collection.");
        _removeData(addr);
    }

    function removeDataByKey(address addr, string memory _key) public {
        /* Only admin and user */
        require(msg.sender == owner() || msg.sender == addr,  "You are not authorized to remove this data key/val pair.");
        _removeDataByKey(addr, _key);
    }

    /* A user can delegate some access to its own data to another address */
    function addReadDelegation(address to, string memory _key) public {
        _addReadDelegation(msg.sender, to, _key);
    }

    /* A user can delegate some access to its own data to another address */
    function addWriteDelegation(address to, string memory _key) public {
        _addWriteDelegation(msg.sender, to, _key);
    }

    /* A user can remove a delegation */
    function removeReadDelegation(address to, string memory _key) public {
        _removeReadDelegation(msg.sender, to, _key);
    }

    /* A user can remove a delegation */
    function removeWriteDelegation(address to, string memory _key) public {
        _removeWriteDelegation(msg.sender, to, _key);
    }

    /* Return readDelegations for this address */
    function getReadDelegations(address addr) public view returns(DelegationLink[] memory) {
        return readDelegations[addr];
    }

    /* Return writeDelegations for this address */
    function getWriteDelegations(address addr) public view returns(DelegationLink[] memory) {
        return writeDelegations[addr];
    }

    function isAuthorized(address addr, string memory accessType, string memory _key) internal view returns(bool boolean) {
        /* Owner and User accessing its own data are authorized by default */
        if (msg.sender == owner() || msg.sender == addr) {
            return true;
        }
        return challengeDelegations(accessType, addr, _key);
    }

    /* Return readDelegations for this address */
    function challengeDelegations(string memory accessType, address addr, string memory _key) public view returns(bool boolean) {
        DelegationLink[] memory delegationsGranted;
        if (compare(accessType, "READ")) {
            delegationsGranted = getReadDelegations(addr);
        } else if (compare(accessType, "WRITE")) {
            delegationsGranted = getWriteDelegations(addr);
        }
        bool inGrantedList = false;
        for (uint i = 0; i < delegationsGranted.length; i++) {
            if (delegationsGranted[i].addr == msg.sender) {
                //Is in the list, let's check the _key now
                if (compare(accessType, "WRITE")) {
                    inGrantedList = true;
                } else {
                    if (compare(delegationsGranted[i].key, _key)) {
                        inGrantedList = true;
                    }
                }
            }
        }
        return inGrantedList;
    }

    function getPodLengthByUser(address addr) public view returns(uint count) {
        return _getPodLength(addr);
    }

    function getPodLengthSeenBy(address addr, address requester) public view returns(uint count) {
        return _getPodLengthSeenBy(addr, requester);
    }

    function getDataSizeByKey(address addr, string memory _key) public returns(uint count) {
        return _getDataByKey(addr, _key).length;
    }

    function getDataSizeByKeySeenBy(address addr, address requester, string memory _key) public view returns(uint count) {
        return _getDataLengthByKeySeenBy(addr, requester, _key);
    }

    function compare(string memory s1, string memory s2) internal pure returns(bool boolean) {
        return (keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2)));
    }

    function getBlockTimestamp() internal view returns (uint256){
        return block.timestamp;
    }

}

contract UnaPod is PermissionedOnchainDatabase {
}