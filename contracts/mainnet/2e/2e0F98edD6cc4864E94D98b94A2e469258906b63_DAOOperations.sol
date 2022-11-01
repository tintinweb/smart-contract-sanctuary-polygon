// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "./IPoolV3.sol";
import "./ITreasury.sol";
import "./IDivsDistributor.sol";
import "./IHashStratDAOTokenFarm.sol";
import "./IOwnable.sol";

/**
 * This contract implements the DAO functions executable via DAO proposals.
 *
 * The Owner of this contact should be HashStratTimelockController
 * that will be the executor of all voted proposals.
 */

contract DAOOperations is Ownable, AutomationCompatibleInterface {


    uint public immutable PERC_DECIMALS = 4;
    uint public immutable MAX_POOL_FEE_PERC = 500; // 5% max fee

    uint public divsPerc = 1000; // 100% fees distributed as divs
    uint public totalFeesCollected;
    uint public totalFeesTransferred;

    uint public upkeepInterval = 1 * 24 * 60 * 60;
    uint public lastUpkeepTimestamp;

    bool public ownershipTransferEnabled = true;

    IERC20Metadata public feesToken;
    ITreasury public treasury;
    IDivsDistributor public divsDistributor;
    IHashStratDAOTokenFarm public tokenFarm;


    // the addresses of LP tokens of the HashStrat Pools and Indexes supported
    address[] private poolsArray;
    mapping(address => bool) private enabledPools;
    uint private enabledPoolsCount;

    address[] private indexesArray;
    mapping(address => bool) private enabledIndexes;
    uint private enabledIndexesCount;


    constructor(
        address feesTokenAddress, 
        address treasuryAddress, 
        address divsDistributorAddress,
        address tokenFarmAddress

        ) {

        treasury = ITreasury(treasuryAddress);
        feesToken = IERC20Metadata(feesTokenAddress);
        divsDistributor = IDivsDistributor(divsDistributorAddress);
        tokenFarm = IHashStratDAOTokenFarm(tokenFarmAddress);

        lastUpkeepTimestamp = block.timestamp;
    }


    //// Public View function ////

    function getPools() external view returns (address[] memory) {
        return poolsArray;
    }


    function getEnabledPools() external view returns (address[] memory) {
        address[] memory enabled = new address[] (enabledPoolsCount);
        uint count = 0;
        for (uint i=0; i<poolsArray.length; i++) {
            address poolAddress = poolsArray[i];
            if (enabledPools[poolAddress] == true) {
                enabled[count] = poolAddress;
                count++;
            }
        }

        return poolsArray;
    }

    function getEnabledIndexes() external view returns (address[] memory) {
        address[] memory enabled = new address[] (enabledIndexesCount);
        uint count = 0;
        for (uint i=0; i<indexesArray.length; i++) {
            address indexAddress = indexesArray[i];
            if (enabledIndexes[indexAddress] == true) {
                enabled[count] = indexAddress;
                count++;
            }
        }

        return indexesArray;
    }



    //// Public functions ////

    // Collect fees from all Pools and transfer them to the Treasury
    function collectFees() public {
        for (uint i=0; i<poolsArray.length; i++) {
            if (enabledPools[poolsArray[i]]) {
                IPoolV3 pool = IPoolV3(poolsArray[i]);
                uint before = feesToken.balanceOf(address(this));
                pool.collectFees(0);  // withdraw fees (converted to stable asset) to this contract
                uint collectedAmount = feesToken.balanceOf(address(this)) - before;
                if (collectedAmount > 0) {
                    totalFeesCollected += collectedAmount;
                    feesToken.transfer(address(treasury), collectedAmount);
                }
            }
        }
    }


    // Returns the value of the LP tokens held in the pools
    function collectableFees() public view returns (uint) {
        uint total = 0;
        for (uint i=0; i<poolsArray.length; i++) {
            if (enabledPools[poolsArray[i]]) {
                IPoolV3 pool = IPoolV3(poolsArray[i]);
                uint feeValue = pool.portfolioValue(address(pool));
                total += feeValue;
            }
        }

        return total;
    }



    //// DAO operations ////

    function setDivsPerc(uint divsPercentage) external onlyOwner {
        require(divsPercentage >= 0 && divsPercentage <= (10 ** PERC_DECIMALS), "invalid percentage");
        
        divsPerc = divsPercentage;
    }


    // DivsDistributor operations
    function setDivsDistributionInterval(uint blocks) external onlyOwner {
        divsDistributor.setDivsDistributionInterval(blocks);
    }


    // Treasury operations
    function transferFunds(address to, uint amount) external onlyOwner {
        require (amount <= feesToken.balanceOf(address(treasury)) , "Excessive amount");
        if (amount > 0) {
            totalFeesTransferred += amount;
            treasury.transferFunds(to, amount);
        }
    }


    // Pool operations
    function setFeesPerc(address poolAddress, uint feesPerc) external onlyOwner {
        require(feesPerc <= MAX_POOL_FEE_PERC, "Fee percentage too high");

        IPoolV3(poolAddress).setFeesPerc(feesPerc);
    }

    function setSlippageThereshold(address poolAddress, uint slippage) external onlyOwner {
        IPoolV3(poolAddress).setSlippageThereshold(slippage);
    }

    function setStrategy(address poolAddress, address strategyAddress) external onlyOwner {
        IPoolV3(poolAddress).setStrategy(strategyAddress);
    }

    function setPoolUpkeepInterval(address poolAddress, uint interval) external onlyOwner {
        IPoolV3(poolAddress).setUpkeepInterval(interval);
    }


    // Pools & Index management
    function addPools(address[] memory poolAddresses) external onlyOwner {
        for (uint i=0; i<poolAddresses.length; i++) {
            address poolAddress = poolAddresses[i];
            if (enabledPools[poolAddress] == false) {
                enabledPools[poolAddress] = true;
                poolsArray.push(poolAddress);
                enabledPoolsCount++;
            }
        }

        tokenFarm.addPools(poolAddresses);
    }

    function removePools(address[] memory poolAddresses) external onlyOwner {

        for (uint i=0; i<poolAddresses.length; i++) {
            address poolAddress = poolAddresses[i];
            if (enabledPools[poolAddress] == true) {
                enabledPools[poolAddress] = false;
                enabledPoolsCount--;
            }
        }

        tokenFarm.removePools(poolAddresses);
    }

    function addIndexes(address[] memory indexesAddresses) external onlyOwner {
        for (uint i=0; i<indexesAddresses.length; i++) {
            address indexAddress = indexesAddresses[i];
            if (enabledIndexes[indexAddress] == false) {
                enabledIndexes[indexAddress] = true;
                indexesArray.push(indexAddress);
                enabledIndexesCount++;
            }
        }

        tokenFarm.addPools(indexesAddresses);
    }

    function removeIndexes(address[] memory indexesAddresses) external onlyOwner {
        for (uint i=0; i<indexesAddresses.length; i++) {
            address indexAddress = indexesAddresses[i];
            if (enabledIndexes[indexAddress] == true) {
                enabledIndexes[indexAddress] = false;
                enabledIndexesCount--;
            }
        }

        tokenFarm.removePools(indexesAddresses);
    }


    //// AutomationCompatible

    function setUpkeepInterval(uint _upkeepInterval) public onlyOwner {
        upkeepInterval = _upkeepInterval;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        bool timeElapsed = (block.timestamp - lastUpkeepTimestamp) >= upkeepInterval;
        upkeepNeeded = (timeElapsed && collectableFees() > 0) || divsDistributor.canCreateNewDistributionInterval();
        
        return (upkeepNeeded, "");
    }


    // Transfer recent fees from Pools to Treasury and create a new distribution interval
    function performUpkeep(bytes calldata /* performData */) external override {
        bool timeElapsed = (block.timestamp - lastUpkeepTimestamp) >= upkeepInterval;
        if ( (timeElapsed && collectableFees() > 0) || divsDistributor.canCreateNewDistributionInterval() ) {
            
            // transfer new fees from pools to the Treasury
            uint trasuryBalanceBefore = feesToken.balanceOf(address(treasury));
            collectFees();
            uint collected = feesToken.balanceOf(address(treasury)) - trasuryBalanceBefore;

            // transfer % of fees to distribute to DivsDistributor
            uint divsToDistribute = collected * divsPerc / 10 ** PERC_DECIMALS;
            if (divsToDistribute > 0) {
                treasury.transferFunds(address(divsDistributor), divsToDistribute);
            }

            // create new distribution interval if possible
            if (divsDistributor.canCreateNewDistributionInterval() ) {
                divsDistributor.addDistributionInterval();
            }
        }

        lastUpkeepTimestamp = block.timestamp;
    }


    ///// Ownership transfer Functionality   /////

    function setOwnerships(address[] memory oldOwners, address newOwner) external onlyOwner {
        require(ownershipTransferEnabled, "DAOOperations: Ownership transfer is disabled");

        for (uint i=0; i<oldOwners.length; i++) {
            IOwnable(oldOwners[i]).transferOwnership(newOwner);
        }
    }

    function disableOwnershipTransfers() external onlyOwner {
        ownershipTransferEnabled = false;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
*  Pool's functionality required by DAOOperations and DAOFarm
*/

interface IPoolV3 {

    function lpToken() external view returns (IERC20Metadata);
    function lpTokensValue (uint lpTokens) external view returns (uint);

    function portfolioValue(address addr) external view returns (uint);
    function collectFees(uint amount) external;

    function setFeesPerc(uint feesPerc) external;
    function setSlippageThereshold(uint slippage) external;
    function setStrategy(address strategyAddress) external;
    function setUpkeepInterval(uint upkeepInterval) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ITreasury {

    function getBalance() external view returns (uint);
    function transferFunds(address to, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface IDivsDistributor {

    function canCreateNewDistributionInterval() external view returns (bool);
    function addDistributionInterval() external;
    function setDivsDistributionInterval(uint blocks) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IHashStratDAOTokenFarm {

    function addPools(address[] memory poolsAddresses) external;
    function removePools(address[] memory poolsAddresses) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}