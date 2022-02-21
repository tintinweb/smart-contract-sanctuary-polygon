/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// SPDX-License-Identifier: MIT
// File: contracts/Context.sol


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

// File: contracts/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/HouseAdmin.sol



pragma solidity ^0.8.0;


contract HouseAdmin is Ownable {
    address private _signer;
    address private _croupier;

    event SignerTransferred(address indexed previousSigner, address indexed newSigner);
    event CroupierTransferred(address indexed previousCroupier, address indexed newCroupier);

    /**
     * @dev Returns the address of the current owner.
     */
    function signer() public view virtual returns (address) {
        return _signer;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function croupier() public view virtual returns (address) {
        return _croupier;
    }

    /**
    * @dev Throws if called by any account other than the signer or owner
    */
    modifier onlySigner() {
        require(msg.sender == _signer || msg.sender == owner());
        _;
    }

    /**
    * @dev Throws if called by any account other than the croupier or owner
    */
    modifier onlyCroupier() {
        require(msg.sender == _croupier || msg.sender == owner());
        _;
    }

    /**
    * @dev The Signable constructor sets the original `signer` of the contract to the sender
    *      account
    */
    constructor() {
        _signer = msg.sender;
        _croupier = msg.sender;
    }

    /**
    * @dev Allows the current signer to transfer control of the contract to a newSigner
    * @param _newSigner The address to transfer signership to
    */
    function transferSigner(address _newSigner) public virtual onlySigner {
        _transferSigner(_newSigner);
    }

    /**
    * @dev Allows the current croupier to transfer control of the contract to a newCroupier
    * @param _newCroupier The address to transfer croupiership to
    */
    function transferCroupier(address _newCroupier) public virtual onlyCroupier {
        _transferCroupier(_newCroupier);
    }

    /**
    * @dev Transfers control of the contract to a newSigner.
    * @param _newSigner The address to transfer signership to.
    */
    function _transferSigner(address _newSigner) internal virtual {
        require(_newSigner != address(0), "HouseAdmin: new signer is the zero address");
        emit SignerTransferred(_signer, _newSigner);
        _signer = _newSigner;
    }

    /**
    * @dev Transfers control of the contract to a newCroupier.
    * @param _newCroupier The address to transfer croupiership to.
    */
    function _transferCroupier(address _newCroupier) internal virtual {
        require(_newCroupier != address(0), "HouseAdmin: new croupier is the zero address");
        emit CroupierTransferred(_croupier, _newCroupier);
        _croupier = _newCroupier;
    }
}
// File: contracts/BoxStock.sol



pragma solidity ^0.8.0;


contract BoxStock is HouseAdmin {
    // A structure representing a single box.
    struct Box {
        uint64 bid;
        uint8 status;
        Collection[] items;
    }

    struct Collection {
        uint64 cid;
        string slug;
        uint8 rarity;
        uint64 odds;
    }

    mapping(uint64 => Box) private _boxes;
    uint64 private _count;

    event NewBox(uint64 indexed bid);

    function addNewBox(Box memory box) external virtual onlyCroupier {
        require(box.bid > 0, "BoxStock: bid should be greater than 0");
        Box storage _box = _boxes[box.bid];
        require (_box.bid == 0, "BoxStock: box already existed");
        _box.bid = box.bid;
        _box.status = box.status;

        for(uint i = 0; i < box.items.length; i++) {
            _box.items.push(box.items[i]);
        }

        _count++;
        emit NewBox(_box.bid);
    }

    function changeBoxStatus(uint64 bid, uint8 status) public virtual onlyCroupier {
        require(bid > 0, "BoxStock: bid should be greater than 0");
        Box storage _box = _boxes[bid];
        _box.status = status;
    }

    function count() public view virtual returns (uint64) {
        return _count;
    }

    function getBox(uint64 bid) public virtual returns (Box memory) {
        require(bid > 0, "BoxStock: bid should be greater than 0");
        return _boxes[bid];
    }

    function getRarityOdds(uint64 bid) public virtual returns (uint64[] memory) {
        
    }
}