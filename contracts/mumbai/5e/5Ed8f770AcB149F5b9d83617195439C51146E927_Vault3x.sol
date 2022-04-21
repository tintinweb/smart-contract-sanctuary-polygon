/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}





interface PRICEORACLE {
    function price() external view returns (uint256);
    function requestISAPrice() external returns (bytes32 requestId);
    function requestETYPrice() external returns (bytes32 requestId);
}

contract Vault3x is Ownable {
    using SafeMath for uint256;
    using Address for address;

    bool private active;
    address private eITY;
    address private eTY;
    IERC20 private isa;
    uint256 public leverage;
    uint256 private mintFee;
    address public treasury;
    uint256 private initialPrice;
    uint256 public MIN_BUY = 10 ether;
    PRICEORACLE public isaOracle;
    PRICEORACLE public priceOracle;
    mapping(address => uint256) private price;

    constructor(
        uint256 _initialPrice,
        uint256 _leverage,
        address _isa,
        address _treasury,
        address _isaOracle,
        address _priceOracle
    ) public {
        // 0.5% of 10000
        mintFee = 50;
        leverage = _leverage;
        treasury = _treasury;
        isa = IERC20(_isa);
        initialPrice = _initialPrice;
        isaOracle = PRICEORACLE(_isaOracle);
        priceOracle = PRICEORACLE(_priceOracle);
    }

    event PriceUpdate(uint256 eTYPrice, uint256 eITYPrice, bool updated);
    event TokenBuy(
        address account,
        address token,
        uint256 tokensMinted,
        uint256 ISAin,
        uint256 fees
    );

    modifier isActive() {
        require(active == true);
        updatePrice();
        _;
    }

    modifier updateIfActive() {
        if (active == true) {
            updatePrice();
        }
        _;
    }

    // 1 ISA = 3 USD
    // 5 ISA * 3 USD =  15 USD
    // 15 / 3 = 5 
    function tokenBuy(
        address token,
        uint256 amount
    ) public virtual isActive {
        require(token == eITY || token == eTY);
        IERC20 itkn = IERC20(token);
        IERC20 isatkn = IERC20(isa);
        (uint256 isaPerUSD, uint256 currentPrice1) = getLatestPrices();
        uint256 isaInUSD = isaPerUSD.mul(amount).div(1e18);
        uint256 minISA = isaPerUSD.mul(MIN_BUY);
        require(amount >= minISA, "NOT-ENOUGH-ISA");
        uint256 tokensToMint = isaInUSD.div(currentPrice1);
        require(isatkn.balanceOf(msg.sender) >= amount, "NOT-ENOUGH-BALANCE");
        require(isatkn.allowance(msg.sender, address(this)) >= amount,"NOT-ENOUGH-ALLOWANCE");
        isa.transferFrom(msg.sender, address(this), amount);
        uint256 fees = amount.mul(mintFee).div(10000);
        uint256 buyisa = amount.sub(fees);
        tokensToMint = buyisa.mul(1e18).div(price[token]);
        payFees(fees);
        itkn.mint(msg.sender, tokensToMint);
    }

    function getLatestPrices() public view returns (uint256, uint256) {
        uint256 price0 = isaOracle.price(); // ISA Price in USD
        uint256 price1 = priceOracle.price(); // ETY Price in USD

        return (price0,price1);
    }

    function updatePrice() public {
        require(active == true);
        uint256 denominator = 100;
        uint256 lastPrice = price[eTY];
        isaOracle.requestISAPrice();
        priceOracle.requestETYPrice();
        (uint256 currentPrice0, uint256 currentPrice1) = getLatestPrices();
        (uint256 changeInPrice, bool isIncreased) = priceChange(currentPrice1);
        if(changeInPrice < 33) {
          if(isIncreased) {
            price[eTY] = lastPrice.mul(leverage.mul(changeInPrice).add(denominator)).div(denominator);
            price[eITY] = lastPrice.mul(denominator.sub(leverage.mul(changeInPrice))).div(denominator);
          }
          if(!isIncreased && lastPrice != 0){
            price[eTY] = lastPrice.mul(denominator.sub(leverage.mul(changeInPrice))).div(denominator);
            price[eITY] = lastPrice.mul(leverage.mul(changeInPrice).add(denominator)).div(denominator);
          }
          if(lastPrice == 0){
                price[eTY] = currentPrice0;
                price[eITY] = currentPrice1;
          }
        } else {
            price[eTY] = lastPrice.mul(denominator.add(93)).div(denominator);
            // price[eITY] = lastPrice.mul(denominator.sub(93)).div(denominator);
            price[eITY] = price[eITY].mul(denominator.sub(7)).div(denominator);
        }
    }

    function priceChange(uint256 currentPrice)
        internal
        returns (uint256 changeInPrice, bool isIncreased)
    {
        uint256 lastPrice = price[eTY];
        if(lastPrice == 0) {
            changeInPrice = 0;
        }
        // decrease in price change
        else if (currentPrice < lastPrice) {
            changeInPrice = lastPrice
                .sub(currentPrice)
                .mul(1e18)
                .div(lastPrice)
                .mul(100)
                .div(1e18);
        } else if (currentPrice > lastPrice) {
            // % increase in price change
            changeInPrice = currentPrice
                .sub(lastPrice)
                .mul(1e18)
                .div(lastPrice)
                .mul(100)
                .div(1e18);
            isIncreased = true;
        } else {
            changeInPrice = 0;
        }
    }

    event Fee(address indexed from, uint256 fee);
    function payFees(uint256 amount) internal {
        // transfer fee to treasury
        isa.transferFrom(msg.sender, treasury, amount);
        emit Fee(msg.sender,amount);
    }

    function getActive() public view returns (bool) {
        return (active);
    }

    function geteITYToken() public view returns (address) {
        return (eITY);
    }

    function geteTYToken() public view returns (address) {
        return (eTY);
    }

    function getTokens() public view returns (address, address) {
        return (eTY, eITY);
    }

    function getPrice(address token) public view returns (uint256) {
        return (price[token]);
    }

    function getMintFee() public view returns (uint256) {
        return (mintFee);
    }

    function setTokens(address eTYAddress, address eITYAddress)
        public
        onlyOwner
    {
        require(eTY == address(0) || eITY == address(0));
        (eITY, eTY) = (eITYAddress, eTYAddress);
         price[eTY] = initialPrice;
         price[eITY] = initialPrice;
    }

    function setActive(bool state) public onlyOwner {
        active = state;
    }

    function setMintFee(uint256 amount) public onlyOwner {
        require(amount <= 10**9);
        mintFee = amount;
    }

    function getMinimumISA(uint256 amount) public view returns (uint256, uint256, uint256, bool){
       (uint256 isaPerUSD, uint256 currentPrice1) = getLatestPrices();
        uint256 isaInUSD = isaPerUSD.mul(amount).div(1e18);
        bool checker;
        if(isaInUSD >= MIN_BUY){
            checker = true;
        }
        else if(isaInUSD < MIN_BUY){
            checker = false;
        }
        return (isaInUSD, isaPerUSD, MIN_BUY, checker );
    }

    // 5 ISA per USD
    // 50ISA 10usd
    // 10*5 = 50 ISA minimum required for minting
    function getMinimumISA2(uint256 amount) public view returns (uint256, uint256, uint256, bool, uint256, uint256){
        (uint256 isaPerUSD, uint256 currentPrice1) = getLatestPrices();
        uint256 isaInUSD = isaPerUSD.mul(amount);
        uint256 minISAInWei = isaPerUSD.mul(MIN_BUY);
        uint256 minISAInEth = (isaPerUSD.mul(MIN_BUY)).div(1e18);
        bool checker;
        if(isaInUSD >= MIN_BUY){
            checker = true;
        }
        else if(isaInUSD < MIN_BUY){
            checker = false;
        }
        
        return (isaInUSD, isaPerUSD, MIN_BUY, checker, minISAInWei, minISAInEth );
    } 
    function getISAPrice() public view returns (uint256) {
        uint256 price0 = isaOracle.price(); // ISA Price in USD
        return price0;
    }
    function getETYPrice() public view returns (uint256) {
        uint256 price1 = priceOracle.price(); // ETY Price in USD
        return price1;
    } 

// 2 ISA per USD
// 8 ety per usd
// 10 ISA sent by user
// 10/2 = 5USD
// 5*8 = 40 ety

    function calculateTokensToMint(uint256 amount) public view returns (uint256, uint256, uint256){
        // f1
        (uint256 isaPerUSD, uint256 currentPrice1) = getLatestPrices();
        uint256 isaInUSD = isaPerUSD.mul(amount).div(1e18);
        uint256 tokensToMint = isaInUSD.div(currentPrice1);
        // f2
        uint256 tokensToMint2 = (amount.div(1e18).div(isaPerUSD)).mul(currentPrice1);
        return(tokensToMint, tokensToMint2, tokensToMint2*1e18);

    }
}