/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IRouter.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/FeeTransfer.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;




contract FeeTransfer is Ownable {
    using SafeMath for uint256;

    uint constant public DIV_PERCENTAGE = 100000;
    uint constant public MAX_VALUE = uint(0-1);

    struct FeeRange{
        uint minRange;  // 10^18 range
        uint maxRange;  
        uint fee;       // 1fee = 0,01%; 10fee = 0,1%
    }
    
    uint public maxFee = 1 ether;
    uint public totalRanges;
    address public feeReceiver;
    address[] public tokenToETHPath;
    address[] public ETHToTokenPath;
    address[] public USDTToETHPath;
    address[] public USDTToTokenPath;
    mapping(uint => FeeRange) public feeRanges;
    IRouter public router;
    address public feeRouter;
    uint public minimumAmountToSwapInUSDT = 0;
    uint public fixedFeeInUSDT = 0;

    constructor(IRouter _router, address[] memory _tokenToETHPath, address[] memory _ethToTokenPath, address[] memory _USDTToETHPath, address[] memory _USDTToTokenPath, address _feeReceiver) public {
        router = _router;
        tokenToETHPath = _tokenToETHPath;
        ETHToTokenPath = _ethToTokenPath;
        USDTToETHPath = _USDTToETHPath;
        USDTToTokenPath = _USDTToTokenPath;
        feeReceiver = _feeReceiver;
    }

    function setMinimumAmountToSwapInUSDT(uint _minimumAmountToSwapInUSDT) public onlyOwner {
        minimumAmountToSwapInUSDT = _minimumAmountToSwapInUSDT;
    }

    function setFixedFeeInUSDT(uint _fixedFeeInUSDT) public onlyOwner {
        require(minimumAmountToSwapInUSDT >= _fixedFeeInUSDT, "FeeTransfer: fixedFee needs to be less or equal to minimumAmountToSwap");
        fixedFeeInUSDT = _fixedFeeInUSDT;
    }

    function setRouter(IRouter _router) public onlyOwner {
        router = _router;
    }

    function setFeeRouter(address _feeRouter) public onlyOwner {
        feeRouter = _feeRouter;
    }

    function addFeeRange(uint[] memory ranges, uint[] memory fee) public onlyOwner {
        require(ranges.length > 0, "FeeTransfer: Invalid ranges length");
        require(ranges.length == (fee.length - 1), "FeeTransfer: Invalid ranges and fee length");
        for(uint i = 0; i < (ranges.length - 1); i++) {
            require(ranges[i] < ranges[i+1], "FeeTransfer: Invalid ranges");
        }
        uint prevMax = 0;
        for(uint i = 0; i < (ranges.length); i++) {
            require(fee[i] < 1000 && fee[i] > 0, "FeeTransfer: Invalid fee");
            feeRanges[i] = FeeRange(prevMax, ranges[i], fee[i]);
            prevMax = ranges[i];
        }
        totalRanges = ranges.length + 1;
        feeRanges[ranges.length] = FeeRange(prevMax, MAX_VALUE, fee[fee.length - 1]);
    }

    function setETHToTokenPath(address[] memory _path) public onlyOwner {
        ETHToTokenPath = _path;
    }

    function setTokenToETHPath(address[] memory _path) public onlyOwner {
        tokenToETHPath = _path;
    }

    function setUSDTToETHPath(address[] memory _path) public onlyOwner {
        USDTToETHPath = _path;
    }

    function setUSDTToTokenPath(address[] memory _path) public onlyOwner {
        USDTToTokenPath = _path;
    }

    function setMaxFee(uint _maxFee) public onlyOwner {
        maxFee = _maxFee;
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function convertTokenToETH(uint tokenAmount) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(tokenAmount, tokenToETHPath);
        return amounts[amounts.length-1];
    }
    
    function convertETHToToken(uint ethAmount) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(ethAmount, ETHToTokenPath);
        return amounts[amounts.length-1];
    }

    function convertUSDTToToken(uint amount) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(amount, USDTToTokenPath);
        return amounts[amounts.length-1];
    }

    function convertUSDTToETH(uint amount) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(amount, USDTToETHPath);
        return amounts[amounts.length-1];
    }
    
    function getAmountInTokensWithFee(uint amountInNoFee) external view returns (uint) {
        uint amount = 0;
        for(uint i = 0; i < totalRanges; i++) {
            if(amountInNoFee > feeRanges[i].minRange && amountInNoFee <= feeRanges[i].maxRange) {
                uint mulFactor = DIV_PERCENTAGE.sub(feeRanges[i].fee);
                uint amountWithFee = amountInNoFee.mul(DIV_PERCENTAGE).div(mulFactor);
                if(amountWithFee > amountInNoFee.add(maxFee)) {
                    amountWithFee = amountInNoFee.add(maxFee);
                }
                amount = amountWithFee;
            }
        }
        if (msg.sender == feeRouter && minimumAmountToSwapInUSDT > 0 && fixedFeeInUSDT > 0  ) {
            uint minimumToSwapInToken = convertUSDTToToken(minimumAmountToSwapInUSDT);
            require(amountInNoFee >= minimumToSwapInToken, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInToken = convertUSDTToToken(fixedFeeInUSDT);
            amount = amount.add(fixedFeeInToken);
        }
        return amount;
    }
    
    function getAmountInTokensNoFee(uint amountInWithFee) external view returns (uint){
        uint amount = 0;
        for(uint i = 0; i < totalRanges; i++) {
            uint mulFactor = DIV_PERCENTAGE.sub(feeRanges[i].fee);
            uint maxRange = i < (totalRanges - 1) ? feeRanges[i].maxRange.mul(DIV_PERCENTAGE).div(mulFactor) : MAX_VALUE;
            uint minRange = feeRanges[i].minRange.mul(DIV_PERCENTAGE).div(mulFactor);
            if(amountInWithFee > minRange && amountInWithFee <= maxRange) {
                amount = amountInWithFee.mul(mulFactor).div(DIV_PERCENTAGE);
                if(amountInWithFee.sub(amount) > maxFee) {
                    amount = amountInWithFee.sub(maxFee);
                }
            }
        }
        if (msg.sender == feeRouter && minimumAmountToSwapInUSDT > 0 && fixedFeeInUSDT > 0  ) {
            uint minimumToSwapInToken = convertUSDTToToken(minimumAmountToSwapInUSDT);
            require(amountInWithFee >= minimumToSwapInToken, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInToken = convertUSDTToToken(fixedFeeInUSDT);
            amount = amount.sub(fixedFeeInToken);
        }
        return amount;  
    }

    function getAmountInETHWithFee(uint amountInNoFee) external view returns (uint) {
        uint amount = 0;
        uint tokensWithNoFee = convertETHToToken(amountInNoFee);
        for(uint i = 0; i < totalRanges; i++) {
            if(tokensWithNoFee > feeRanges[i].minRange && tokensWithNoFee <= feeRanges[i].maxRange) {
                uint mulFactor = DIV_PERCENTAGE.sub(feeRanges[i].fee);
                uint amountWithFee = amountInNoFee.mul(DIV_PERCENTAGE).div(mulFactor);
                if(amountWithFee > amountInNoFee.add(maxFee)) {
                    amountWithFee = amountInNoFee.add(maxFee);
                }
                amount = amountWithFee;
            }
        }
        if (msg.sender == feeRouter && minimumAmountToSwapInUSDT > 0 && fixedFeeInUSDT > 0  ) {
            uint minimumToSwapInETH = convertUSDTToETH(minimumAmountToSwapInUSDT);
            require(amountInNoFee >= minimumToSwapInETH, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInETH = convertUSDTToETH(fixedFeeInUSDT);
            amount = amount.add(fixedFeeInETH);
        }
        return amount;
    }

    function getAmountInETHNoFee(uint amountInWithFee) external view returns (uint) {
        uint amount = 0;
        uint tokensWithFee = convertETHToToken(amountInWithFee);
        for(uint i = 0; i < totalRanges; i++) {
            uint mulFactor = DIV_PERCENTAGE.sub(feeRanges[i].fee);
            uint maxRange = i < (totalRanges - 1) ? feeRanges[i].maxRange.mul(DIV_PERCENTAGE).div(mulFactor) : MAX_VALUE;
            uint minRange = feeRanges[i].minRange.mul(DIV_PERCENTAGE).div(mulFactor);
            if(tokensWithFee > minRange && tokensWithFee <= maxRange) {
                amount = amountInWithFee.mul(mulFactor).div(DIV_PERCENTAGE);
                if(amountInWithFee.sub(amount) > maxFee) {
                    amount = amountInWithFee.sub(maxFee);
                }
            }
        }
        if (msg.sender == feeRouter && minimumAmountToSwapInUSDT > 0 && fixedFeeInUSDT > 0  ) {
            uint minimumToSwapInETH = convertUSDTToETH(minimumAmountToSwapInUSDT);
            require(amountInWithFee >= minimumToSwapInETH, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInETH = convertUSDTToETH(fixedFeeInUSDT);
            amount = amount.sub(fixedFeeInETH);
        }
        return amount; 
    }
}