// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IPeronio.sol";
import "@openzeppelin/contracts_latest/access/Ownable.sol";

contract AutoCompounder is Ownable {
  IPeronio peronio;

  constructor(address _peronio) {
    peronio = IPeronio(_peronio);
  }

  uint256 public lastExecuted;

  function lastExec() internal view returns (bool) {
    return ((block.timestamp - lastExecuted) > 43200); // 12 hours
  }

  function autoCompound() public onlyOwner {
    require(lastExec(), "autoCompound: Time not elapsed");

    peronio.claimRewards();
    peronio.compoundRewards();

    lastExecuted = block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPeronio {
  function USDC_ADDRESS() external view returns (address);

  function MAI_ADDRESS() external view returns (address);

  function LP_ADDRESS() external view returns (address);

  function QUICKSWAP_ROUTER_ADDRESS() external view returns (address);

  function QIDAO_FARM_ADDRESS() external view returns (address);

  function QI_ADDRESS() external view returns (address);

  function QIDAO_POOL_ID() external view returns (uint256);

  // Markup
  function MARKUP_DECIMALS() external view returns (uint8);

  function markup() external view returns (uint256);

  function swapFee() external view returns (uint256);

  // Initialization can only be run once
  function initialized() external view returns (bool);

  // Roles
  function MARKUP_ROLE() external view returns (bytes32);

  function REWARDS_ROLE() external view returns (bytes32);

  // Events
  event Initialized(address owner, uint256 collateral, uint256 startingRatio);
  event Minted(
    address indexed to,
    uint256 collateralAmount,
    uint256 tokenAmount
  );
  event Withdrawal(
    address indexed to,
    uint256 collateralAmount,
    uint256 tokenAmount
  );
  event MarkupUpdated(address operator, uint256 markup);
  event CompoundRewards(uint256 qi, uint256 usdc, uint256 lp);
  event HarvestedMatic(uint256 wmatic, uint256 collateral);

  function decimals() external view returns (uint8);

  function initialize(uint256 usdcAmount, uint256 startingRatio) external;

  function setMarkup(uint256 markup_) external;

  function mint(
    address to,
    uint256 usdcAmount,
    uint256 minReceive
  ) external returns (uint256 peAmount);

  function withdraw(address to, uint256 peAmount) external;

  function claimRewards() external;

  function compoundRewards()
    external
    returns (uint256 usdcAmount, uint256 lpAmount);

  function stakedBalance() external view returns (uint256);

  function stakedValue() external view returns (uint256 totalUSDC);

  function usdcPrice() external view returns (uint256);

  function buyingPrice() external view returns (uint256);

  function collateralRatio() external view returns (uint256);

  function getPendingRewardsAmount() external view returns (uint256 amount);

  function getLpReserves()
    external
    view
    returns (uint112 usdcReserves, uint112 maiReserves);
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