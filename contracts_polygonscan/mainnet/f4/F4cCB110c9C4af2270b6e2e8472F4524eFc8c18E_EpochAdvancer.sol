// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISmartAlpha.sol";

contract EpochAdvancer is Ownable {
    address[] public pools;
    uint256 public numberOfPools;

    constructor(address[] memory addrs) {
        if (addrs.length > 0) {
            addPools(addrs);
        }
    }

    function addPool(address poolAddress) public onlyOwner {
        require(poolAddress != address(0), "invalid address");

        pools.push(poolAddress);
        numberOfPools++;
    }

    function addPools(address[] memory addrs) public onlyOwner {
        require(addrs.length > 0, "invalid array");

        for (uint256 i = 0; i < addrs.length; i++) {
            addPool(addrs[i]);
        }
    }

    function advanceEpochs() public {
        for (uint256 i = 0; i < pools.length; i++) {
            ISmartAlpha sa = ISmartAlpha(pools[i]);

            if (sa.getCurrentEpoch() > sa.epoch()) {
                if (gasleft() < 400_000) {
                    break;
                }

                sa.advanceEpoch();
            }
        }
    }

    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool, bytes memory) {
        bool upkeepNeeded;

        for (uint256 i = 0; i < pools.length; i++) {
            ISmartAlpha sa = ISmartAlpha(pools[i]);

            if (sa.getCurrentEpoch() > sa.epoch()) {
                upkeepNeeded = true;
                break;
            }
        }

        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        advanceEpochs();
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface ISmartAlpha {
    function epoch() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256);
    function advanceEpoch() external;
}

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

