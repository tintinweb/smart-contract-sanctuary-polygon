// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IWHITELIST.sol";

contract WhiteList is IWHITELIST, Ownable { 
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////

    address private s_signer;
    mapping(address => Status) private s_statusAddress; 

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor() {
        s_signer = msg.sender;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => View functions

    function status(address p_address) public view override returns(Status) { 
        return s_statusAddress[p_address];
    }

    // => Set functions

    function transferOwner(address p_newOwner) public onlyOwner override { 
        _transferOwnership(p_newOwner);
    }

    function transferSigner(address p_newSigner) public onlyOwner override {
        s_signer = p_newSigner;
    }

    function setStatus(
        address p_address, 
        Status p_status
    ) public onlyOwner override returns(bool) {
        s_statusAddress[p_address] = p_status;

        emit ChangeStatus(p_address, p_status);

        return true;
    }

    function setStatusWithSignature(
        address p_address, 
        Status p_status, 
        uint256 p_timeStamp,
        bytes memory sig
    ) public override {
        require(p_timeStamp + 5 minutes > block.timestamp, "Expired signature");

        bytes32 message = keccak256(abi.encodePacked(p_address, p_status, p_timeStamp, address(this)));
        require(_recoverSigner(message, sig) == s_signer, "Error signature");

        s_statusAddress[p_address] = p_status;

        emit ChangeStatus(p_address, p_status); 
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWHITELIST {
    enum Status {
        Inactive,
        Active,
        Frozen
    }

    // EVENTS

    event ChangeStatus(address indexed e_address, Status indexed e_status);
    
    // PUBLIC FUNCTIONS

        // View functions

        function status(address p_address) external view returns(Status);

        // Set functions

        function transferOwner(address p_newOwner) external;
        function transferSigner(address p_newSigner) external;
        function setStatus(
            address p_address, 
            Status p_status
        ) external returns(bool);
        function setStatusWithSignature(
            address p_address, 
            Status p_status, 
            uint256 p_timeStamp,
            bytes memory sig
        ) external;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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