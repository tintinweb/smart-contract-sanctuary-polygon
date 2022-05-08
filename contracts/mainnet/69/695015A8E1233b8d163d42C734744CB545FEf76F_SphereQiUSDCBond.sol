// SPDX-License-Identifier: ISC
/**
 * By using this software, you understand, acknowledge and accept that Tetu
 * and/or the underlying software are provided “as is” and “as available”
 * basis and without warranties or representations of any kind either expressed
 * or implied. Any use of this open source software released under the ISC
 * Internet Systems Consortium license is done at your own risk to the fullest
 * extent permissible pursuant to applicable law any and all liability as well
 * as all warranties, including any fitness for a particular purpose with respect
 * to Tetu and/or the underlying software and the use thereof are disclaimed.
 */

pragma solidity 0.8.4;

import './TetuBondDepo.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/ISmartVault.sol';

contract SphereQiUSDCBond is TetuBondDepo {
    using SafeERC20 for IERC20;

    uint256 public constant SLIPPAGE_TOLERANCE = 3;

    address internal immutable _router;
    address[] internal _usdcQiSwapPath;
    address public tetuQi; // address of tetuQi token
    address public qi; // address of Qi token

    constructor(
        address _rewardToken,
        address _principle,
        address _treasury,
        address _bondCalculator,
        address __router,
        address[] memory __usdcQiSwapPath,
        address _tetuQI,
        address _qi
    ) TetuBondDepo(_rewardToken, _principle, _treasury, _bondCalculator) {
        _router = __router;
        require(__router != address(0), "Router shouldn't be empty");
        _usdcQiSwapPath = __usdcQiSwapPath;
        require(__usdcQiSwapPath.length > 1, 'Swap path should be specified');
        tetuQi = _tetuQI;
        require(_tetuQI != address(0), 'tetuQI address should be specified');
        qi = _qi;
        require(_qi != address(0), 'qi address should be specified');
    }

    /**
     *  @notice in case of extra principle tokens conversions
     *  @param _amount of principle tokens
     *  @return treasuryToken address
     */
    function _convertPrinciple(uint256 _amount) internal override returns (address treasuryToken) {
        // swap principle USDC to QI
        IERC20(principle).safeTransferFrom(msg.sender, address(this), _amount);
        _swap(_amount);
        uint256 qiBalance = IERC20(qi).balanceOf(address(this));
        // invest Qi tokens to tetuQiVault
        IERC20(qi).safeIncreaseAllowance(tetuQi, qiBalance);
        ISmartVault(tetuQi).depositAndInvest(qiBalance);
        return tetuQi;
    }

    /// @param _amount Amount for swap
    /// @return Amounts after the swap
    function _swap(uint256 _amount) internal returns (uint256[] memory) {
        require(_amount <= IERC20(_usdcQiSwapPath[0]).balanceOf(address(this)), 'MS: not enough balance for swap');
        uint256 amountOutMin = _amount - ((_amount * SLIPPAGE_TOLERANCE) / 100);

        IERC20(_usdcQiSwapPath[0]).safeApprove(_router, 0);
        IERC20(_usdcQiSwapPath[0]).safeApprove(_router, _amount);
        return
            IUniswapV2Router02(_router).swapExactTokensForTokens(
                _amount,
                amountOutMin,
                _usdcQiSwapPath,
                address(this),
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: ISC
/**
 * By using this software, you understand, acknowledge and accept that Tetu
 * and/or the underlying software are provided “as is” and “as available”
 * basis and without warranties or representations of any kind either expressed
 * or implied. Any use of this open source software released under the ISC
 * Internet Systems Consortium license is done at your own risk to the fullest
 * extent permissible pursuant to applicable law any and all liability as well
 * as all warranties, including any fitness for a particular purpose with respect
 * to Tetu and/or the underlying software and the use thereof are disclaimed.
 */

import './openzeppelin/SafeERC20.sol';
import './openzeppelin/Ownable.sol';
import './openzeppelin/Math.sol';
import './interfaces/ITetuBondDepo.sol';
import './interfaces/IBondingCalculator.sol';
import './interfaces/IERC20Extended.sol';

pragma solidity 0.8.4;

contract TetuBondDepo is ITetuBondDepo, Ownable {
    using SafeERC20 for IERC20;
    // max adjustment is 5% of control variable
    uint8 public constant MAX_ADJUSTMENT_NOMINATOR = 50;
    uint16 public constant MAX_ADJUSTMENT_DENOMINATOR = 1000;
    uint16 public constant VESTING_SCALE = 1000;

    uint8 public constant BOND_PRICE_DECIMALS = 5;
    uint8 public constant CONTROL_VARIABLE_DECIMALS = 3;

    /* ======== STATE VARIABLES ======== */
    address public immutable rewardToken; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public treasury; // sends money to a multisig (preferably)

    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    address public immutable bondCalculator; // calculates value of LP tokens
    uint256 public immutable minBond; // minimum bond size in reward tokens

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // adjustment of control variable configuration

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint256 public lastDecay; // reference block for debt decay

    uint256 public lpBonded; // track all the LP tokens acquired by contract
    uint256 public tokenVested; // track the reward token vesting
    uint256 public paidOut; // amount of reward token claimed

    uint256 public availableDebt;

    /* ======== INITIALIZATION ======== */
    constructor(
        address _rewardToken,
        address _principle,
        address _treasury,
        address _bondCalculator
    ) {
        require(_rewardToken != address(0));
        rewardToken = _rewardToken;
        require(_principle != address(0));
        principle = _principle;
        require(_treasury != address(0));
        treasury = _treasury;

        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        isLiquidityBond = (_bondCalculator != address(0));
        minBond = 10**(IERC20Extended(_rewardToken).decimals() - 2);
    }

    /**
        @notice updates treasury account that receives principle token
        @param _treasury address
     */
    function updateTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), 'updateTreasury: cannot be address 0.');
        treasury = _treasury;
    }

    /**
     *  @notice updates bond parameters. updated over time but won't change already-issued bonds.
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function updateBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external override onlyOwner {
        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _target,
        uint256 _buffer
    ) external override onlyOwner {
        require(
            _increment <= Math.max((terms.controlVariable * MAX_ADJUSTMENT_NOMINATOR) / MAX_ADJUSTMENT_DENOMINATOR, 1),
            'Increment too large'
        );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTimestamp: block.timestamp
        });
    }

    /**
     *  @notice fund bonds
     *  @param _amount uint
     */
    function fund(uint256 _amount) external override onlyOwner {
        availableDebt = availableDebt + _amount;
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external override returns (uint256) {
        require(_depositor != address(0), 'Invalid address');

        _updateDebtDecay();
        require(totalDebt <= terms.maxDebt, 'Max capacity reached');

        uint256 nativePrice = _bondPrice();

        require(_maxPrice >= nativePrice, 'Slippage limit: more than max price');
        // slippage protection

        uint256 value = valueOfToken(_amount);

        uint256 payout = payoutFor(value);
        // payout to bonder is computed
        // must be > 0.01 rewardToken ( underflow protection )
        require(payout >= minBond, 'Bond too small');

        require(payout <= maxPayout(), 'Bond too large');
        // size protection because there is no slippage

        // **** check that
        // payout cannot exceed the balance deposited (in rewardToken)
        require(payout < availableDebt, 'Not enough reserves.');
        // leave 1 gwei for good luck.

        availableDebt = availableDebt - payout;
        // already checked if possible so it shouldn't underflow.

        // total debt is increased
        totalDebt = totalDebt + value;

        // depositor info is stored
        bondInfo[_depositor] = Bond({
            payout: bondInfo[_depositor].payout + payout,
            vesting: terms.vestingTerm,
            lastTimestamp: block.timestamp,
            pricePaid: nativePrice
        });

        // indexed events are emitted
        emit BondCreated(_amount, payout, block.timestamp + terms.vestingTerm, nativePrice);

        lpBonded = lpBonded + _amount;
        tokenVested = tokenVested + payout;

        // control variable is adjusted

        _adjust();

        address treasuryToken = _convertPrinciple(_amount);
        uint256 treasuryTokenBalance = IERC20(treasuryToken).balanceOf(address(this));

        IERC20(treasuryToken).safeIncreaseAllowance(treasury, treasuryTokenBalance);
        if (treasuryToken == principle) {
            IERC20(treasuryToken).safeTransferFrom(msg.sender, treasury, _amount);
        } else {
            uint256 treasuryTokenBal = IERC20(treasuryToken).balanceOf(address(this));
            IERC20(treasuryToken).safeTransfer(treasury, treasuryTokenBal);
        }
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @return uint
     */
    function redeem(address _recipient) external override returns (uint256) {
        Bond memory info = bondInfo[_recipient];

        // (blocks since last interaction / vesting term remaining)
        uint256 percentVested = percentVestedFor(_recipient);
        if (percentVested >= VESTING_SCALE) {
            // if fully vested
            delete bondInfo[_recipient];
            // delete user info
            emit BondRedeemed(_recipient, info.payout, 0);
            // emit bond data
            return _sendPayout(_recipient, info.payout);
            // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = (info.payout * percentVested) / VESTING_SCALE;

            // store updated deposit info
            bondInfo[_recipient] = Bond({
                payout: info.payout - payout,
                vesting: info.vesting - (block.timestamp - info.lastTimestamp),
                lastTimestamp: block.timestamp,
                pricePaid: info.pricePaid
            });

            emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
            return _sendPayout(_recipient, payout);
        }
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to get paid. no staking bc we don't do that rebase
     *  @param _recipient address
     *  @param _amount uint
     *  @return uint
     */
    function _sendPayout(address _recipient, uint256 _amount) internal returns (uint256) {
        paidOut = paidOut + _amount;
        // send payout
        IERC20(rewardToken).safeTransfer(_recipient, _amount);
        return _amount;
    }

    /**
     *  @notice in case of extra principle tokens conversions
     *  @param _amount of principle tokens
     *  @return treasuryToken address
     */
    function _convertPrinciple(uint256 _amount) internal virtual returns (address treasuryToken) {
        // default implementation do nothing with principle just uses principle as treasuryToken
        return principle;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function _adjust() internal {
        uint256 blockCanAdjust = adjustment.lastTimestamp + adjustment.buffer;
        if (adjustment.rate != 0 && block.timestamp >= blockCanAdjust) {
            uint256 initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable + adjustment.rate;
                if (terms.controlVariable >= adjustment.target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable - adjustment.rate;
                if (terms.controlVariable <= adjustment.target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTimestamp = block.timestamp;
            emit ControlVariableAdjustment(initial, terms.controlVariable, adjustment.rate, adjustment.add);
        }
    }

    /**
     *  @notice reduce total debt
     */
    function _updateDebtDecay() internal {
        totalDebt = totalDebt - debtDecay();
        lastDecay = block.timestamp;
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal view returns (uint256) {
        uint256 priceDelta = ((terms.controlVariable * debtRatio()) *
            (10**(BOND_PRICE_DECIMALS - CONTROL_VARIABLE_DECIMALS))) / _rewardTokenUnit();
        return terms.minimumPrice + priceDelta;
    }

    /**
     *  @notice units of reward token
     */
    function _rewardTokenUnit() internal view returns (uint256) {
        return 10**IERC20Extended(rewardToken).decimals();
    }

    /**
     *  @notice units of principle token
     */
    function _principleTokenUnit() internal view returns (uint256) {
        return 10**IERC20Extended(principle).decimals();
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
        @notice returns rewardToken valuation of asset
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken(uint256 _amount) public view override returns (uint256 value_) {
        // convert amount to match payout token decimals
        value_ = (_amount * _rewardTokenUnit()) / _principleTokenUnit();
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     *  @dev changed from original implementation to fixed configurable value
     */
    function maxPayout() public view override returns (uint256) {
        return terms.maxPayout;
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param value uint
     *  @return uint
     */
    function payoutFor(uint256 value) public view override returns (uint256) {
        uint256 result = (value * (10**BOND_PRICE_DECIMALS)) / _bondPrice();
        return result;
    }

    /**
     *  @notice calculate current bond price with BOND_PRICE_DECIMALS precision
     *          e.g BOND_PRICE_DECIMALS=5 and bondPrice=1039 => 0.01039
     *  @return price_ uint
     */
    function bondPrice() external view override returns (uint256 price_) {
        return _bondPrice();
    }

    /**
     *  @notice calculate current ratio of debt to rewardToken supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view override returns (uint256) {
        uint256 rewardTokensBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256 totalAvail = rewardTokensBalance + currentDebt();
        uint256 debtRatio_ = (currentDebt() * _rewardTokenUnit()) / totalAvail;
        return debtRatio_;
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view override returns (uint256) {
        if (isLiquidityBond) {
            return (debtRatio() * IBondingCalculator(bondCalculator).markdown(principle)) / _rewardTokenUnit();
        } else {
            return debtRatio();
        }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view override returns (uint256) {
        return totalDebt - debtDecay();
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view override returns (uint256 decay_) {
        uint256 secondsSinceLast = block.timestamp - lastDecay;
        decay_ = (totalDebt * secondsSinceLast) / terms.vestingTerm;
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor) public view override returns (uint256 percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint256 blocksSinceLast = block.timestamp - bond.lastTimestamp;
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = (blocksSinceLast * VESTING_SCALE) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of rewardToken available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor) external view override returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = bondInfo[_depositor].payout;

        if (percentVested >= VESTING_SCALE) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = (payout * percentVested) / VESTING_SCALE;
        }
    }

    /* ======= AUXILLIARY ======= */
    /**
     *  @notice allow owner to send lost tokens to the treasury.
     *  @param _token address
     */
    function recoverLostToken(address _token, uint256 _amount) external override onlyOwner {
        IERC20(_token).safeTransfer(treasury, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {
    function depositAndInvest(uint256 amount) external;
    function controller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.4;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: ISC
/**
 * By using this software, you understand, acknowledge and accept that Tetu
 * and/or the underlying software are provided “as is” and “as available”
 * basis and without warranties or representations of any kind either expressed
 * or implied. Any use of this open source software released under the ISC
 * Internet Systems Consortium license is done at your own risk to the fullest
 * extent permissible pursuant to applicable law any and all liability as well
 * as all warranties, including any fitness for a particular purpose with respect
 * to Tetu and/or the underlying software and the use thereof are disclaimed.
 */

pragma solidity 0.8.4;

interface ITetuBondDepo {

    event BondCreated(uint256 deposit, uint256 indexed payout, uint256 indexed expires, uint256 indexed price);
    event BondRedeemed(address indexed recipient, uint256 payout, uint256 remaining);
    event ControlVariableAdjustment(uint256 initialBCV, uint256 newBCV, uint256 adjustment, bool addition);

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 vestingTerm; // in seconds
        uint256 minimumPrice; // vs principle value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint256 buffer; // minimum length (in seconds) between adjustments
        uint256 lastTimestamp; // block when last adjustment made
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // rewardToken remaining to be paid
        uint256 vesting; // Blocks left to vest
        uint256 lastTimestamp; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
    }

    function updateTreasury(address _treasury) external;

    function updateBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external;

    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _target,
        uint256 _buffer
    ) external;

    function fund(uint256 _amount) external;

    function recoverLostToken(address _token, uint256 _amount) external;

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function redeem(address _recipient) external returns (uint256);

    /* ======== VIEW FUNCTIONS ======== */
    function valueOfToken(uint256 _amount) external view returns (uint256 value_);
    function maxPayout() external view returns (uint256);
    function payoutFor(uint256 value) external view returns (uint256);
    function bondPrice() external view returns (uint256 price_);
    function debtRatio() external view returns (uint256);
    function standardizedDebtRatio() external view returns (uint256);
    function currentDebt() external view returns (uint256);
    function debtDecay() external view returns (uint256 decay_);
    function percentVestedFor(address _depositor) external view returns (uint256 percentVested_);
    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBondingCalculator {
    function valuation(address _LP, uint256 _amount) external view returns (uint256);

    function markdown(address _LP) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20Extended {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);


  /**
    * @dev Returns the amount of tokens in existence.
    */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.4;

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