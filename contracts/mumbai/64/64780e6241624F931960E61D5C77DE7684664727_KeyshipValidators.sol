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

// File: contracts/keyshipValidators.sol

// SPDX-License-Identifier: GPL-3.0

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

pragma solidity 0.8.19;

contract KeyshipValidators is Ownable {
    struct Validator {
        address payoutAddress;
        bool isActive;
    }
    mapping(address => Validator) public Validators;
    event NewValidator(address _validator);

    constructor(
        address[] memory _signAddresses,
        address[] memory _payoutAddresses
    ) {
        require(
            _signAddresses.length == _payoutAddresses.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < _signAddresses.length; i++) {
            Validators[_signAddresses[i]] = Validator(
                _payoutAddresses[i],
                true
            );
        }
    }

    function isValidator(address _validator) public view returns (bool) {
        if (Validators[_validator].isActive) {
            return true;
        }
        return false;
    }

    function getPayoutAddress(
        address _validator
    ) public view returns (address) {
        require(Validators[_validator].isActive, "Error !");
        return Validators[_validator].payoutAddress;
    }

    function addValidators(
        address[] memory _signAddresses,
        address[] memory _payoutAddresses
    ) public onlyOwner {
        require(
            _signAddresses.length == _payoutAddresses.length,
            "Length mismatch"
        );
        for (uint i = 0; i < _signAddresses.length; i++) {
            Validators[_signAddresses[i]] = Validator(
                _payoutAddresses[i],
                true
            );
        }
    }

    function removeContract(address _validator) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        delete Validators[_validator];
    }

    function switchValidator(
        address _validator,
        bool _boolValue
    ) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        Validators[_validator].isActive = _boolValue;
    }

    function addValidator(
        address _signAddress,
        address _payoutAddress
    ) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        Validators[_signAddress] = Validator(_payoutAddress, true);
        emit NewValidator(_signAddress);
    }
}