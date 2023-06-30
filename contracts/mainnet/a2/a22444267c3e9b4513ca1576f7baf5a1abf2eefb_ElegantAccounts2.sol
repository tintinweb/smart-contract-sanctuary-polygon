/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/elegantaccounts.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


error AdminUserOnly();
error NameCannotBeBlank();
error NameAlreadyInUse();
error RacerOwnershipIssues();

struct captaininfo{
    uint16 captainid;
    address capcontract;
}

interface RacerInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract ElegantAccounts2 is Ownable {
    
    mapping(address => string)  nameByAddress;
    mapping(string => bool) nameTaken;
    mapping(address => captaininfo) captainMyCaptain;

    address public admin;
    address public racerAddy;

    constructor() {
        admin = msg.sender;
        racerAddy = 0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C;
    }

    //  //
    function nameUpdate(string calldata _name, address _addy) public {
        if (compareStrings(_name,"")) revert NameCannotBeBlank();
        if (nameTaken[_name]) revert NameAlreadyInUse();
        if (msg.sender != _addy && msg.sender != admin) revert AdminUserOnly();

        string memory _old = nameByAddress[msg.sender];
        nameByAddress[msg.sender] = _name;
        nameTaken[_name] = true;
        nameTaken[_old] = false;
    }

    function captainUpdate(uint16 _cap, address _addy, address _racercontract) public {
        if (msg.sender != _addy && msg.sender != admin) revert AdminUserOnly();

        address _owner;
        _owner = RacerInterface(_racercontract).ownerOf(_cap);
        if (_owner != _addy) revert RacerOwnershipIssues();
        captaininfo memory _tempcapinfo;
        _tempcapinfo.captainid = _cap;
        _tempcapinfo.capcontract = _racercontract;
        captainMyCaptain[_addy] = _tempcapinfo;
    }
    
    function updateRacerAddress(address _new) public onlyOwner {
        racerAddy = _new;
    }

    function getName(address _wallet) external view returns (string memory){
        string memory _name = nameByAddress[_wallet];
        return _name;
    }

    function getCaptain(address _wallet) external view returns (captaininfo memory){
        return captainMyCaptain[_wallet];
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
}