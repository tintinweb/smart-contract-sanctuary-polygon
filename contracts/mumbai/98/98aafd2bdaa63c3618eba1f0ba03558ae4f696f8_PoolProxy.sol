/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/model/PoolModel.sol

contract PoolModel {

    address public baseToken;

    struct PoolInfo {
        // Base token amount
        uint256 totalShare;
        uint256 pendingShare;
        uint256 amountPerShare;

        // Basic information.
        uint256 lastTime;
        uint256 waitDays;
        uint256 openDays;
        address admin;
        string name;
    }

    PoolInfo[] public poolInfoArray;

    // admin => poolIndex
    mapping(address => uint256) public poolIndexPlusOneMap;

    struct UserInfo {
        // Base token amount
        uint256 share;

        // Pending share (for withdraw)
        uint256 pendingShare;
    }

    // poolIndex => user => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfoMap;

    struct WithdrawRequest {
        uint256 share;
        uint256 time;
        bool executed;
    }

    // poolIndex => user => WithdrawRequest[]
    mapping(uint256 => mapping(address => WithdrawRequest[])) public
        withdrawRequestMap;
}

// File: contracts/proxy/PoolProxy.sol

contract PoolProxy is PoolModel, Ownable {

    address public pool;

    function setPool(address pool_) public onlyOwner {
        pool = pool_;
    }

    constructor(address baseToken_) public {
        baseToken = baseToken_;
    }

    fallback() external {
        address _impl = pool;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}