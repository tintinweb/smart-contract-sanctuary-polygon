/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

pragma solidity >= 0.8.11;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

contract ClientStore is Ownable {

    struct ClientRecord {
        bytes data;
        bool isDeleted;
    }

    mapping(address => bool) public authoritys;
    //mapping(address => mapping(address => bool)) public authoritys;
    mapping(address => ClientRecord) private clients;

    constructor () {
        authoritys[msg.sender] = true;
    }

    function addClient(address client_address, bytes memory data) public {
        require(authoritys[msg.sender] == true);
        require(data.length > 0);
        require(clients[client_address].data.length == 0 || clients[client_address].isDeleted);

        clients[client_address] = ClientRecord(data, false);
    }

    function modifyClient(address client_address, bytes memory data) public {
        require(authoritys[msg.sender] == true);
        require(data.length > 0);
        require(clients[client_address].data.length > 0);
        require(!clients[client_address].isDeleted);

        clients[client_address].data = data;
    }

    function deleteClient(address client_address) public {
        require(authoritys[msg.sender] == true);
        require(clients[client_address].data.length > 0);
        require(!clients[client_address].isDeleted);

        clients[client_address].data = bytes("");
        clients[client_address].isDeleted = true;
    }

    function getClient(address client_address) public view returns (ClientRecord memory) { 
        require(clients[client_address].data.length > 0, "Invalid Address.");
        require(!clients[client_address].isDeleted, "Client is deleted.");

        return clients[client_address];
    }

    function setAuthority(address authority_address, bool authorized) public onlyOwner {
        authoritys[authority_address] = authorized;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}