/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IPcv {
    // get the pcv settle assets address
    function getSettleAsset() external view returns(address);
    function totalSupply() external view returns (uint256);
}
interface Assets {
    function netAssets(address token, address pcv) external view returns (uint256 amount, uint256 debt);
}
interface PcvStruct {

    struct PcvStrategy{
        uint256 strategyId;
        address[] protocol;
        string[] methods; // method and params
        bool available;
        address[][] inputTokens;
        address[][] outputTokens;
        address initToken; // tokens of initial capital
        uint256[][] inputPercent;
        uint percentBase;
        bool[][] needAmount; 
        bool[][] needInvest;
        bool closePosition;
    }

    struct PcvInfo{
        address factory;
        address owner;
        bool available;
        address collectAccount;
        address settleAsset;
        uint256 minInvest;
        uint256 maxInvest;
    }

    struct StrategyExecVariable{
        address[] allOutputTokens;
        uint256[] oldOutputBalance;
        uint256[] outputAmount ;
        uint256[] usedOutputAmount;
        uint256 initAmount;
    }


    struct ProtocolMethodInfo{
        string method;
        bytes abiCode;
        uint inputParams;
        uint outputParams;
        bool available;
        bool [] needAmount;
        bool [] needInvest;
    }

}

interface IPcvStorage is PcvStruct{

    function addPcv(address pcvOwner,address pcv,address settleAsset,uint256 minInvest,uint256 maxInvest) external ;

    function addStrategy(
        address[] memory protocols,
        string[] memory methods,
        address[][] memory inputTokens,
        address[][] memory outputTokens,
        address initToken,
        uint[][] memory inputPercent,
        bool closePosition) external;

    function removeStrategy(uint256 stragegyId) external ;

    function getPcvInfo(address pcv) external view returns(PcvInfo memory);

    function getPcvAssets(address pcv) external view returns(address [] memory);

    function getStrategy(address pcv,uint256 id) external view returns(PcvStrategy memory);

    function isSupportOperate(address pcv,bytes memory method) external view returns(bool);

    function addSupportOperate(address protocal,string[] memory methods) external ;

    function removeSupportOperate(address protocal,bytes memory method) external ;

    function setProxyFactory(address newPcvFactory)external ;

    // PCV Proxy contract logic executor
    function setExecutor(address executor) external;

    function getExecutor() external view returns(address);

    function getCollectAccount(address PCV) external view returns(address);

    function getMaticToken() external view returns(address);

    function getWMatic() external view returns(address);

    function getETHER() external view returns(address);

    function getPercentBase() external view returns(uint);

    function getMetodInfo(address protocol,bytes memory methodAbi) external view returns(ProtocolMethodInfo memory);

    function pcvIsExsit(address owner,address pcv) external view returns(bool);

    // about token start
     function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function tokenAdd(address account, uint256 amount) external;
    
    function tokenSub(address account, uint256 amount) external;
    
    function allowance(address pcv,address owner,address spender) external view returns (uint256);
    
    function approve(address owner, address spender, uint256 amount) external ;
    
    function approveSub(address owner, address spender, uint256 amount) external;

    // about token end 

    function autoExecute(address pcv) external view returns(bool);

    function setAutoStrategy(uint strategyId) external ;

    function setAutoExecute(bool isAuto) external;

    function getAutoStrategy(address pcv) external view returns(uint);

    function isSupportAsset(address protocol,address token) external view returns(bool);

    function settlement() external returns(address); 

    function setSupportAssets(address protocol,address [] memory tokens) external;

    function getComtroller() external view returns(address);

    function getLogic() external view returns(address);

    function recordPcvAssets(address [] memory newAssets) external;

    function setInvestLimit(uint minInvest,uint maxInvest) external ;

    function liquidator() external view returns(address);

    }
interface IPriceOracle {
    /**
     * @notice Get the underlying price of a asset
     * @param _pToken The asset to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address _pToken) external view returns (uint);
}
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}


/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }


    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }

    function mulPrice(uint a, uint b) pure internal returns (uint) {
        uint mul = mul_(a, b, "multiplication overflow");
        return div_(mul, expScale);
    }

    function mulPcv(uint a, uint b) pure internal returns (uint) {
        uint amount = a * 1e12;
        (MathError err0, uint doubleScaledProduct) = mulUInt(amount, b);
        if (err0 != MathError.NO_ERROR) {
            return 0;
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return 0;
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return product;
    }
}


contract PcvExchangeRate is Ownable, Exponential{

    event NewPriceOracle(IPriceOracle oldPriceOracle, address newPriceOracle);

    event NewPcvStorage(IPcvStorage old, address newPcvStorage);

    event NewAssetsProtocolList(address token, string belong);

    event NewTokenConfig(address token, string symbol, string source, uint baseUnit, uint exchangeRateMantissa, bool available);

    // max commission factor
    uint internal constant commissionFactorMaxMantissa = 9e17;

    IPriceOracle public oracle;

    IPcvStorage public pcvStorage;

    //address[] public tokenAssetsList;

    mapping(address => TokenConfig) public tokenConfig;

    Protocol[] public assetsProtocolList;

    // initial pcv net worth
    uint256 public exchangeRateMantissa = 1e18;

    // function initialize(uint _exchangeRateMantissa) public initializer {
    //     exchangeRateMantissa = _exchangeRateMantissa;
    //     require(exchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

    // }

    function getTokenConfig(address token) external view returns (TokenConfig memory){
        return tokenConfig[token];
    }

    // set price oracle
    function setPriceOracle(address newOracle) external onlyOwner {
        IPriceOracle oldOracle = oracle;
        oracle = IPriceOracle(newOracle);
        emit NewPriceOracle(oldOracle, newOracle);
    }
    
    // set pcv storage contract
    function setPcvStorage(address newPcvStorage) external onlyOwner {
        IPcvStorage old = pcvStorage;
        pcvStorage = IPcvStorage(newPcvStorage);
        emit NewPcvStorage(old, newPcvStorage);
    }

    struct Protocol {
        address token;
        string belong;
    }

    // set protocol list
    function setAssetsProtocolList(address token, string memory belong) public onlyOwner {
        for (uint i = 0; i < assetsProtocolList.length; i++) {
            Protocol memory asset = assetsProtocolList[i];
            require(asset.token != token, "The token already exists");
        }
        assetsProtocolList.push(Protocol({
        token : token,
        belong : belong
        }));
        emit NewAssetsProtocolList(token, belong);
    }

    // remove assets protocol list
    function removeAssetsProtocolList(address token) public onlyOwner {
        uint len = assetsProtocolList.length;
        uint assetIndex = len;
        for (uint i = 0; i < assetsProtocolList.length; i++) {
            Protocol memory asset = assetsProtocolList[i];
            if (asset.token == token) {
                assetIndex = i;
                break;
            }
        }
        assetsProtocolList[assetIndex] = assetsProtocolList[len - 1];
        assetsProtocolList.pop();
    }


    struct TokenConfig {
        address token;  // token address
        string symbol;  // token symbol
        string source;  // from
        uint baseUnit;  // base unit
        uint exchangeRateMantissa; // pledge rate
        bool available; // available
    }

    struct AssetField {
        uint256 totalAmount;
        uint256 netAssets;
        uint256 totalDebt;
        //uint debt;          
        uint256 netWorth;
        uint256 availableAmount;
        uint256 fundsUtilization;
        uint256 singleAmount;
        uint256 singleDebt;
    }

    // set token assets list
    function addTokenAssetsList(address token, string memory symbol, string memory source, uint baseUnit, uint exchangeMantissa) public onlyOwner {
        require(exchangeMantissa <= commissionFactorMaxMantissa, "The pledge rate exceeds the specified value");
        TokenConfig storage config = tokenConfig[token];
        require(config.token != token, "The token already exists");
        config.token = token;
        config.symbol = symbol;
        config.source = source;
        config.baseUnit = baseUnit;
        config.exchangeRateMantissa = exchangeMantissa;
        config.available = true;

        //tokenAssetsList.push(token);
        emit NewTokenConfig(token, symbol, source, baseUnit, exchangeMantissa, config.available);
    }

    // update token assets config
    function updataTokenConfig(address token, string memory source, uint baseUnit, uint exchangeMantissa, bool available) public onlyOwner {
        require(exchangeMantissa <= commissionFactorMaxMantissa, "The pledge rate exceeds the specified value");
        TokenConfig storage config = tokenConfig[token];
        require(config.token == token, "token does not exist");
        config.token = token;
        //config.symbol = symbol;
        config.source = source;
        config.baseUnit = baseUnit;
        config.exchangeRateMantissa = exchangeMantissa;
        config.available = available;
        emit NewTokenConfig(token, config.symbol, source, baseUnit, exchangeMantissa, available);
    }


    function netAssetValue(address pcv) public view returns (uint netAssets, uint totalDebt, uint netWorth) {
        (, netAssets, totalDebt, netWorth) = exchangeRateStoredInternal(pcv);
    }

    function exchangeRateStoredInternal(address pcv) internal view returns (uint, uint, uint, uint) {
        uint256 totalSupply = IPcv(pcv).totalSupply();
        if (totalSupply == 0) {
            /// if no token is minted, return the default exchange rate: 1e18
            return (0, 0, 0, exchangeRateMantissa);
        } else {
            AssetField memory vars;
            vars.totalAmount = 0;
            vars.totalDebt = 0;
            address[] memory assetsList = pcvStorage.getPcvAssets(pcv);
            for (uint i = 0; i < assetsList.length; i++) {
                TokenConfig memory config = tokenConfig[assetsList[i]];
                if (config.available == true) {
                    for (uint j = 0; j < assetsProtocolList.length; j++) {
                        Protocol memory asset = assetsProtocolList[j];
                        if (compareStrings(config.source, asset.belong)) {
                            (vars.singleAmount, vars.singleDebt) = Assets(asset.token).netAssets(config.token, pcv);
                            if (vars.singleAmount > 0) {
                                vars.totalAmount = add_(vars.totalAmount, vars.singleAmount);
                            }
                            if (vars.singleDebt > 0) {
                                vars.totalDebt = add_(vars.totalDebt, vars.singleDebt);
                            }
                        }
                    }
                }
            }

            vars.netAssets = sub_(vars.totalAmount, vars.totalDebt);
            // network
            vars.netWorth = div_(mul_(vars.netAssets, 1e18), totalSupply);
            address investToken = IPcv(pcv).getSettleAsset();
            uint investTokenPrice = oracle.getUnderlyingPrice(investToken);
            vars.netWorth = div_(mul_(vars.netWorth, 1e18), investTokenPrice);
            return (vars.totalAmount, vars.netAssets, vars.totalDebt, vars.netWorth);
        }
    }

    // get pcv available amount and debt
    function pcvAssetsAndDebt(address pcv) public view returns (uint, uint) {
        uint amount = 0;
        uint debt = 0;
        address[] memory assetsList = pcvStorage.getPcvAssets(pcv);
        for (uint i = 0; i < assetsList.length; i++) {
            address token = assetsList[i];
            TokenConfig memory config = tokenConfig[token];
            if (config.available == true) {
                for (uint j = 0; j < assetsProtocolList.length; j++) {
                    Protocol memory asset = assetsProtocolList[j];
                    if (compareStrings(config.source, asset.belong)) {
                        (uint tokenAmount, uint tokenDebt) = Assets(asset.token).netAssets(token, pcv);
                        if (tokenAmount > 0) {
                            tokenAmount = mul_(tokenAmount, config.exchangeRateMantissa);
                            tokenAmount = div_(tokenAmount, config.baseUnit);
                            amount = add_(amount, tokenAmount);
                        }
                        if (tokenDebt > 0) {
                            debt = add_(debt, tokenDebt);
                        }
                    }

                }
            }

        }

        return (amount, debt);
    }

    // get total amount, net assets, total debt, net worth, available amount, funds utilization
    function getTokenAssetsData(address pcv) external view returns(uint, uint, uint, uint, uint, uint) {
        AssetField memory vars;
        (vars.totalAmount, vars.netAssets, vars.totalDebt, vars.netWorth) = exchangeRateStoredInternal(pcv);
        (vars.availableAmount, ) = pcvAssetsAndDebt(pcv);
        if (vars.availableAmount == 0) {
            vars.fundsUtilization = 0;
        } else {
            vars.fundsUtilization = div_(mul_(vars.totalDebt, 1e18), vars.availableAmount);
        }
        return (vars.totalAmount, vars.netAssets, vars.totalDebt, vars.netWorth, vars.availableAmount, vars.fundsUtilization);
    }

    // pcv max borrow and max withdraw
    function pcvMaxBorrowAndRedeem(address pcv, address token) external view returns(uint maxBorrowAmount, uint maxBorrow, uint maxRedeemAmount, uint maxRedeem){
        AssetField memory vars;
        TokenConfig memory config = tokenConfig[token];
        (vars.availableAmount, vars.totalDebt) = pcvAssetsAndDebt(pcv);
        uint amount = sub_(vars.availableAmount, vars.totalDebt);
        maxBorrowAmount = div_(amount, sub_(1e18, config.exchangeRateMantissa));
        (maxRedeemAmount, , , ) = exchangeRateStoredInternal(pcv);
        uint price = oracle.getUnderlyingPrice(token);
        maxBorrow = div_(mul_(maxBorrowAmount, 1e18), price);
        maxRedeem = div_(mul_(maxRedeemAmount, 1e18), price);
        return (maxBorrowAmount, maxBorrow, maxRedeemAmount, maxRedeem);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}