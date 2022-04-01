// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "Ownable.sol";

interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/// @dev This is portal that just execute the bridge from L1 <-> L2
contract PolylandPortal is Ownable {

     /*///////////////////////////////////////////////////////////////
                    PORTAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    address public fxChild;
    address public mainlandPortal;

    mapping(address => bool) public auth;

    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);
    event CallMade(address target, bool success, bytes data);

    /*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address fxChild_,address mainlandPortal_) external onlyOwner {

        fxChild        = fxChild_;
        mainlandPortal = mainlandPortal_;
    }

    function setAuth(address[] calldata adds_, bool status) external onlyOwner {
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }


    /*///////////////////////////////////////////////////////////////
                    PORTAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function sendMessage(bytes calldata message_) virtual external {
        require(auth[msg.sender], "not authorized to use portal");
        emit MessageSent(message_);
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external {
        require(msg.sender         == fxChild,        "PolylandPortal: INVALID_SENDER");
        require(rootMessageSender == mainlandPortal, "PolylandPortal: INVALID_PORTAL" );

        _processMessageFromRoot(data);
    }

    function _processMessageFromRoot(bytes memory data) internal {
        (address target, bytes[] memory calls ) = abi.decode(data, (address, bytes[]));
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = target.call(calls[i]);
            emit CallMade(target, success, calls[i]);
        }
    }

    function replayCall(address target, bytes memory data, bool reqSuccess) external onlyOwner {
        (bool succ, ) = target.call(data);
        if (reqSuccess) require(succ, "call failed");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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