//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./BaseJumpRateModel.sol";

/**
 * @title Modified Compound's JumpRateModel Contract V2 for V2 cTokens
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
contract JumpRateModel is BaseJumpRateModel {
  /// @notice this corresponds to 1.0.0
  uint256 public constant version = 1_000_000;

  /**
   * @notice Calculates the current borrow rate per block
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves
  ) external view returns (uint256) {
    return getBorrowRateInternal(_cash, _borrows, _reserves);
  }

  /**
   * @notice Construct an interest rate model
   * @param _baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param _multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param _jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param _kink The utilization point at which the jump multiplier is applied
   */
  constructor(
    uint256 _baseRatePerYear,
    uint256 _multiplierPerYear,
    uint256 _jumpMultiplierPerYear,
    uint256 _kink
  ) {
    _updateJumpRateModel(_baseRatePerYear, _multiplierPerYear, _jumpMultiplierPerYear, _kink);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Logic for Modified Version of Compound's JumpRateModel Contract V2.
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
contract BaseJumpRateModel is Ownable {
  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2102400;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice The multiplierPerBlock after hitting a specified utilization point
   */
  uint256 public jumpMultiplierPerBlock;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public kink;

  event NewInterestParams(uint256 _baseRatePerBlock, uint256 _multiplierPerBlock, uint256 _jumpMultiplierPerBlock, uint256 _kink);

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (_borrows == 0) {
      return 0;
    }

    uint256 util = (_borrows * 1e18) / (_cash + _borrows - _reserves);
    return util;
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @param _reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves,
    uint256 _reserveFactorMantissa
  ) external view returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18) - _reserveFactorMantissa;
    uint256 borrowRate = getBorrowRateInternal(_cash, _borrows, _reserves);
    uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
    uint256 supplyRate = (utilizationRate(_cash, _borrows, _reserves) * rateToPool) / 1e18;
    return supplyRate;
  }

  /**
   * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
   * @param _baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param _multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param _jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param _kink The utilization point at which the jump multiplier is applied
   */
  function _updateJumpRateModel(
    uint256 _baseRatePerYear,
    uint256 _multiplierPerYear,
    uint256 _jumpMultiplierPerYear,
    uint256 _kink
  ) public onlyOwner {
    uint256 newBaseRatePerBlock = _baseRatePerYear / blocksPerYear;
    uint256 newMultiplierPerBlock = (_multiplierPerYear * 1e18) / (blocksPerYear * _kink);
    uint256 newJumpMultiplierPerBlock = _jumpMultiplierPerYear / blocksPerYear;
    uint256 newKink = _kink;
    baseRatePerBlock = newBaseRatePerBlock;
    multiplierPerBlock = newMultiplierPerBlock;
    jumpMultiplierPerBlock = newJumpMultiplierPerBlock;
    kink = newKink;

    emit NewInterestParams(newBaseRatePerBlock, newMultiplierPerBlock, newJumpMultiplierPerBlock, newKink);
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRateInternal(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves
  ) internal view returns (uint256) {
    uint256 util = utilizationRate(_cash, _borrows, _reserves);
    uint256 cachedKink = kink;

    if (util <= cachedKink) {
      return ((util * multiplierPerBlock) / 1e18) + baseRatePerBlock;
    } else {
      uint256 normalRate = ((cachedKink * multiplierPerBlock) / 1e18) + baseRatePerBlock;
      uint256 excessUtil;
      unchecked { excessUtil = util - cachedKink; }
      return ((excessUtil * jumpMultiplierPerBlock) / 1e18) + normalRate;
    }
  }
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