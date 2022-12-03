// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FixedPointMathLib} from "./lib/FixedPointMathLib.sol";

/** 
* @author Wonderlive
* @notice Implementation of the Vesting contract.
*/

contract VestingV2 is Ownable, ReentrancyGuard {

    using FixedPointMathLib for uint256;

    struct RoundInfo {
        uint256 totalAllocation; /// total amount of $WOND token available for each round
        uint256 currentAllocation; /// current amount already allocated
        uint256 price; /// $WOND price token for the round
        uint256 claimedAmount; /// amount of token already claim
        uint256 minBuy; /// amount minimum of $WOND to BUY
        uint256 maxBuy; /// amount minimum of $WOND to BUY
    }

    // Info of each user.
    struct UserInfo {
        uint128 userID; /// user identifier
        uint256 amountAllocated; /// Amount of $WOND allocated to the user
        uint256 amountDebt; // Reward debt
        uint256 lastClaim; /// timestamp
    }

    enum Round {
        CLOSE,
        PRIVATE,
        PRE
    }
    
    /// @notice reference to the $USDT token 
    IERC20 public USDT;
    /// @notice reference to the $USDC token 
    IERC20 public USDC;
    /// @notice reference to the $WOND token
    IERC20 public immutable WOND;
    /// @notice current round
    Round public currentRound;
    /// @notice amount of users who joined rounds 
    uint128 public numEntry; 
    /// represent the maximum amount of unlock for private
    uint16 public maxUnlock; 
    /// wallet where funds will be send 
    address private multisigWallet;
    /// wallet which store ICO token 
    address private icoWallet;

    mapping(Round => RoundInfo) public getRoundInfo;
    // Info of each user that enter into a round.
    mapping(address => UserInfo) public userInfo;


    /*** EVENTS ***/

    event AddInPrivateSale(address who, uint256 allocated);
    event AddInPresale(address who, uint256 allocated);
    event RewardsClaim(address who, uint256 amount);

    /*** ERRORS ***/

    error WrongAddress();
    error InvalidAmountToUnlock();
    error AmountExceed();
    error AmountTooSmall();


    /**
     * @dev Creates a vesting contract.
     * @param _token address of the $WOND token contract
     * @param _maxUnlock represent the max amount which can be unlock (20%)
     */
    constructor(
        address _token, 
        uint16 _maxUnlock,
        address _icoWallet
        ) {
        // safety check
        if(_token == address(0)) revert WrongAddress();
        
        /// TODO : add token (stable...)
        WOND = IERC20(_token);
        maxUnlock = _maxUnlock;
        icoWallet = _icoWallet;
        currentRound = Round.CLOSE;
    }

    /*** MODIFIERS ***/

    modifier onlyDuringPrivateSale(){
        require(currentRound == Round.PRIVATE, "VESTING : Private sale is closes");
        _;
    }

    modifier onlyDuringPreSale(){
        require(currentRound == Round.PRE, "VESTING : Pre sale is closes");
        _;
    }


    /*** SALES LOGIC ***/

    function addToPrivateSale (
        address who,
        uint256 allocation,
        uint256 unlock
    ) 
    public 
    onlyOwner 
    onlyDuringPrivateSale
    nonReentrant {

        RoundInfo storage round = getRoundInfo[Round.PRIVATE];
        uint256 roundAllocation = round.currentAllocation + allocation;
        /// if the allocation asked exceed, revert. 
        if (roundAllocation > round.totalAllocation) revert AmountExceed();
        /// if the amount of token to unlock is too high, revert. 
        if (unlock > maxUnlock) revert InvalidAmountToUnlock();
        /// calculate the amount to unlock
        uint256 amountToUnlock = (allocation * unlock)/100;
        if(userExist(who)){
            UserInfo storage user = userInfo[who];
            /// if user got more than the maximum, revert.
            if (allocation + user.amountAllocated > round.maxBuy) revert AmountExceed();
            /// tranfer WOND token to the recipient
            if(amountToUnlock > 0) WOND.transferFrom(icoWallet, who, amountToUnlock);

            user.amountDebt += amountToUnlock;
            user.amountAllocated += allocation - amountToUnlock;

            uint256 availableRewards = computeClaimableAmount(who);
            if (availableRewards > 0) {
                user.amountDebt += availableRewards;
                user.lastClaim = block.timestamp;
                round.claimedAmount += availableRewards;
                WOND.transferFrom(icoWallet, who, availableRewards);
                emit RewardsClaim(who, availableRewards);
            }
        }
        else {
            /// if user got more than the maximum, revert.
            if (allocation > round.maxBuy) revert AmountExceed();
            /// if user got less than the minimum, revert.
            if (allocation < round.minBuy) revert AmountTooSmall();
            /// if amount to unlock greater than 0, send the amount to unlock
            if(amountToUnlock > 0) WOND.transferFrom(icoWallet, who, amountToUnlock);
            /// TODO : check the ID attribution on Dashboard
            uint128 userID = numEntry+1;
            userInfo[who] = UserInfo(
                userID,
                allocation - amountToUnlock,
                amountToUnlock,
                block.timestamp
            );
            numEntry++;
        }
        /// updating data of the round storage
        round.currentAllocation += allocation;
        round.claimedAmount += amountToUnlock;

        emit AddInPrivateSale(who, allocation);

    }

    /**
     * @dev Add new user to the presale who paid w/ stablecoin.
     * @param _stable represent the token 1 = USDT , 2 = USDC
    */

    function addToPreSaleByStable (
        address who, 
        uint128 userID,
        uint256 allocation,
        uint8 _stable
    ) 
    external
    onlyDuringPreSale 
    nonReentrant {

        RoundInfo storage round = getRoundInfo[Round.PRE];
        uint256 roundAllocation = round.currentAllocation + allocation;
        /// if the allocation asked exceed, revert. 
        if (roundAllocation > round.totalAllocation) revert AmountExceed();
        /// amount to pay in stablecoin
        uint256 amountToPay = (allocation*getRoundInfo[Round.PRE].price);
        /// choose the right token according to the parameter
        IERC20 stableCoin = _stable == 1 ? USDT : USDC;
        /// transfer $stable directly to the multisig
        stableCoin.transferFrom(who, multisigWallet, amountToPay);

        if(userExist(who)){
            UserInfo storage user = userInfo[who];
            user.amountAllocated += allocation;
            user.lastClaim = block.timestamp;

            uint256 availableRewards = computeClaimableAmount(who);
            if (availableRewards > 0) {
                user.amountDebt += availableRewards;
                user.lastClaim = block.timestamp;
                round.claimedAmount += availableRewards;
                WOND.transferFrom(icoWallet, who, availableRewards);
                emit RewardsClaim(who, availableRewards);
            }
        }
        else {
            userInfo[who] = UserInfo(
                userID,
                allocation,
                0,
                block.timestamp
            );
             numEntry++;
        }
        /// updating data of the round storage
        round.currentAllocation += allocation;

        emit AddInPresale(who, allocation);
    }

    /*** VIEWS ***/

    function userExist(address _user) public view returns(bool) {
        return userInfo[_user].userID != 0 ? true : false;
    }

    function computeClaimableAmount(address user) public view returns(uint256) {
        /// TODO : ask for unlock method 
        return 1;
    }


    /*** UTILS ***/

    function launchPrivateSale() external onlyOwner {
        currentRound = Round.PRIVATE;
    }

    function launchPreSale() external onlyOwner {
        currentRound = Round.PRE;
    }

    function closeSale() external onlyOwner {
        currentRound = Round.CLOSE;
    }

    function setTotalInfoForPrivate(uint256 _totalAllocation, uint256 _price, uint256 _minBuy, uint256 _maxBuy) public onlyOwner {
        getRoundInfo[Round.PRIVATE] = RoundInfo(
            _totalAllocation,
            0,
            _price, 
            0,
            _minBuy,
            _maxBuy
        );
    }

    function setTotalAmountForPre(uint256 _totalAllocation, uint256 _price, uint256 _minBuy, uint256 _maxBuy) public onlyOwner {
        getRoundInfo[Round.PRE] = RoundInfo(
            _totalAllocation,
            0,
            _price, 
            0,
            _minBuy,
            _maxBuy
        );
    }
}

// File: contracts/imports/FixedPointMathLib.sol
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Modified from Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/math.sol)
/// and ABDK (https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant SAD = 1e6;
    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            if or(
                // Revert if y is zero to ensure we don't divide by zero below.
                iszero(y),
                // Equivalent to require(x == 0 || (x * baseUnit) / x == baseUnit)
                iszero(or(iszero(x), eq(div(z, x), baseUnit)))
            ) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := baseUnit
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := baseUnit
                }
                default {
                    z := x
                }
                let half := div(baseUnit, 2)
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, baseUnit)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;

        result = 1;

        uint256 xAux = x;

        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }

        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }

        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }

        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }

        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }

        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }

        if (xAux >= 0x8) result <<= 1;

        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            uint256 roundedDownResult = x / result;

            if (result > roundedDownResult) result = roundedDownResult;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x > y ? x : y;
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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