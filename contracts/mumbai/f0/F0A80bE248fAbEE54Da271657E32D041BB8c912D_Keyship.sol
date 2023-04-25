/**
 *Submitted for verification at polygonscan.com on 2023-04-24
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

// SPDX-License-Identifier: MIT
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

// File: contracts/Keyship.sol


// 888                                 888      d8b          
// 888                                 888      Y8P          
// 888                                 888                   
// 888  888  .d88b.  888  888 .d8888b  88888b.  888 88888b.  
// 888 .88P d8P  Y8b 888  888 88K      888 "88b 888 888 "88b 
// 888888K  88888888 888  888 "Y8888b. 888  888 888 888  888 
// 888 "88b Y8b.     Y88b 888      X88 888  888 888 888 d88P 
// 888  888  "Y8888   "Y88888  88888P' 888  888 888 88888P"  
//                        888                       888      
//                   Y8b d88P                       888      
//  


contract Keyship is Ownable {
    mapping(string => uint256) public CountPerUser;
    mapping(string => uint256) public CountPerRecord;
    mapping(address => bool) public KeyshipContracts;
    event NewRecord(string id, string mid);
    event NewContract(address _contract);


    constructor() {}

    function saveRecord(string memory _id, string memory _mid) public {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        require(isValid(msg.sender), "Error !");
        if (CountPerUser[_id] > 0) {
            CountPerUser[_id] = CountPerUser[_id] + 1;
            CountPerRecord[_mid] = CountPerRecord[_mid] + 1;
        } else {
            CountPerUser[_id] = 1;
            CountPerRecord[_mid] = 1;
        }
        emit NewRecord(_id, _mid);
    }

    function isValid(address _contract) private view returns (bool) {
        if (KeyshipContracts[_contract]) {
            return true;
        }
        return false;
    }

    function addContract(address _contract) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        KeyshipContracts[_contract] = true;
        emit NewContract(_contract);
    }

    function switchContract(address _contract, bool _boolValue)
        public
        onlyOwner
    {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        KeyshipContracts[_contract] = _boolValue;
    }

    function removeContract(address _contract) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        delete KeyshipContracts[_contract];
    }
}