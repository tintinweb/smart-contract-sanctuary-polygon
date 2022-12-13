/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// File: SLX-Demo/IQRNGManager.sol


pragma solidity 0.8.11;

interface IQRNGManager {
    function makeRequestUint256(uint randomWords) external returns (bytes32);
}
// File: SLX-Demo/IHouse.sol


pragma solidity 0.8.11;

interface IHouse {
    function placeBet(uint amount,uint winnableAmount) payable external;
    function settleBet(address player, uint winnableAmount, bool win) external;
    function refundBet(address player, uint amount, uint winnableAmount) external;
    function placeCustomBet(address player, uint amount, uint winnableAmount, address _custom_token) external;
    function settleCustomBet(address player, uint winnableAmount, bool win, address _custom_token) external;
    function refundCustomBet(address player, uint amount, uint winnableAmount, address _custom_token) external;
    function balanceAvailableForCustomBet(address custom_token) external view returns (uint);
}
// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: SLX-Demo/DiceManager.sol


pragma solidity 0.8.11;





abstract contract DiceManager is Ownable {
    using SafeERC20 for IERC20;

    uint public constant MODULO = 6;

    // Variables
    bool public gameIsLive = true;
    uint public minBetAmount = 25 ether;
    uint public maxBetAmount = 1000 ether;
    mapping(address => uint) public minCustomBetAmount;
    mapping(address => uint) public maxCustomBetAmount;
    uint public houseEdgeBP = 250;

    IHouse house;


    struct Bet {
        bool rollUnder;
        uint40 choice;
        uint40[2] outcome;
        uint168 placeBlockNumber;
        uint128 amount;
        uint128 winAmount;
        address player;
        bool isSettled;
        bool isCustomToken;
        address custom_token;
    }

    Bet[] public bets;
    mapping(bytes32 => uint) public betMap;

    constructor(address houseAddress) {
        house = IHouse(houseAddress);
    }

    function setHouser(address houseAddress) external onlyOwner {
        house = IHouse(houseAddress);
    }


    function betsLength() external view returns (uint) {
        return bets.length;
    }

    // Events
    event BetPlaced(
        address indexed player,
        uint amount,
        uint indexed choice,
        bool indexed rollUnder
    );
    event BetSettled(
        address player,
        uint amount,
        bool rollUnder,
        uint choice,
        uint40 dice1,
        uint40 dice2,
        uint winAmount
    );
    event BetRefunded(uint indexed betId, address indexed player, uint amount);
    event CustomBetPlaced(
        address indexed player,
        uint amount,
        bool indexed rollUnder,
        uint choice,
        address custom_token,
        bytes32 indexed requestId
    );
    event CustomBetSettled(
        address player,
        uint amount,
        bool rollUnder,
        uint choice,
        uint40  dice1,
        uint40 dice2,
        uint winAmount,
        address custom_token,
        bytes32 requestId
    );
    event CustomBetRefunded(
        uint indexed betId,
        address indexed player,
        uint amount,
        address indexed custom_token
    );

    // Setter
    function setMinBetAmountNative(uint _minBetAmount) external onlyOwner {
        require(
            _minBetAmount < maxBetAmount,
            "Min amount must be less than max amount"
        );
        minBetAmount = _minBetAmount;
    }

    function setMaxBetAmountNative(uint _maxBetAmount) external onlyOwner {
        require(
            _maxBetAmount > minBetAmount,
            "Max amount must be greater than min amount"
        );
        maxBetAmount = _maxBetAmount;
    }

    function addCustomToken(address _token, uint minBet, uint maxBet) external onlyOwner {
        minCustomBetAmount[_token] = minBet;
        maxCustomBetAmount[_token] = maxBet;
    }

    function setCustomMinBet(address _token, uint minBet) external onlyOwner {
        minCustomBetAmount[_token] = minBet;
    }

    function setCustomMaxBet(address _token, uint maxBet) external onlyOwner {
        maxCustomBetAmount[_token] = maxBet;
    }

    function getCustomMinBet(address _token) external view returns(uint) {
        return minCustomBetAmount[_token];
    }

    function getCustomMaxBet(address _token) public view returns(uint) {
        return house.balanceAvailableForCustomBet(_token) < maxCustomBetAmount[_token] ? house.balanceAvailableForCustomBet(_token) : maxCustomBetAmount[_token];
    }


    function setHouseEdgeBP(uint _houseEdgeBP) external onlyOwner {
        require(gameIsLive == false, "Bets in pending");
        houseEdgeBP = _houseEdgeBP;
    }

    function toggleGameIsLive() external onlyOwner {
        gameIsLive = !gameIsLive;
    }

    // Converters
    function amountToBettableAmountConverter(uint amount)
        internal
        view
        returns (uint)
    {
        return (amount * (10000 - houseEdgeBP)) / 10000;
    }



    function amountToWinnableAmount(uint _amount, uint betChoice, bool rollUnder)
        internal
        pure
        returns (uint)
    {
        require(
            2 < betChoice && betChoice < 12,
            "Bet out of range"
        );
        uint multip;
        if(betChoice == 3) {
            if(rollUnder) {
                multip = 3509;
            }
            else {
                multip = 106;
            }
        }
        else if(betChoice == 4) {
            if(rollUnder) {
                multip = 1171;
            }
            else {
                multip = 117;
            }
        }
        else if(betChoice == 5) {
            if(rollUnder) {
                multip = 585;
            }
            else {
                multip = 135;
            }
        }
        else if(betChoice == 6) {
            if(rollUnder) {
                multip = 351;
            }
            else {
                multip = 167;
            }
        }
        else if(betChoice == 7) {
            multip = 234;
        }
        else if(betChoice == 8) {
            if(rollUnder) {
                multip = 167;
            }
            else {
                multip = 351;
            }
        }
        else if(betChoice == 9) {
            if(rollUnder) {
                multip = 135;
            }
            else {
                multip = 585;
            }
        }
        else if(betChoice == 10) {
            if(rollUnder) {
                multip = 117;
            }
            else {
                multip = 1171;
            }
        }
        else if(betChoice == 11) {
            if(rollUnder) {
                multip = 106;
            }
            else {
                multip = 3509;
            }
        }
        else {
            revert("Condition is out of bounds");
        }
        return (_amount * multip) / 100;
    }

    // Methods



    function withdrawCustomTokenFunds(
        address beneficiary,
        uint withdrawAmount,
        address token
    ) external onlyOwner {
        require(
            withdrawAmount <= IERC20(token).balanceOf(address(this)),
            "Withdrawal exceeds limit"
        );
        IERC20(token).safeTransfer(beneficiary, withdrawAmount);
    }
}

// File: SLX-Demo/Dice.sol


pragma solidity 0.8.11;








contract Dice is DiceManager {

    IQRNGManager qrng;

    constructor(address houseAddress, address qrngManagerAddress, address test_token) DiceManager(houseAddress){
        qrng = IQRNGManager(qrngManagerAddress);
        minCustomBetAmount[test_token] = 1;
        maxCustomBetAmount[test_token] = 1 ether;
    }

    function placeCustomBet(uint betChoice, bool rollUnder, address custom_token, uint amount) external  {
        require(gameIsLive, "Game is not live");
        require(betChoice > 2 && betChoice < 12, "Bet not in range");


        require(amount >= minCustomBetAmount[custom_token], "Bet amount is lower than min bet");


        uint winnableAmount = amountToWinnableAmount(amount, betChoice,rollUnder);

        require(winnableAmount <= getCustomMaxBet(custom_token),"Win amount is higher than allowed");
        house.placeCustomBet(msg.sender, amount, winnableAmount, custom_token);
        
        Bet storage bet = bets.push();

        bet.rollUnder = rollUnder;
        bet.choice=uint40(betChoice);
        bet.outcome=[0,0];
        bet.placeBlockNumber=uint168(block.number);
        bet.amount=uint128(amount);
        bet.winAmount=0;
        bet.player=msg.sender;
        bet.isSettled=false;
        bet.isCustomToken=true;
        bet.custom_token=custom_token;
        bytes32 requestId = qrng.makeRequestUint256(2);
        betMap[requestId] = bets.length - 1;
        
        emit CustomBetPlaced( msg.sender, amount, rollUnder, betChoice, custom_token, requestId);   
    }

    function settleBet(bytes32 requestId, uint256[] memory expandedValues) external {
        require(msg.sender == address(qrng),"Only QRNG can settle");
        Bet storage bet = bets[betMap[requestId]];
        _settleBet(bet,expandedValues[0],expandedValues[1], requestId);
    }


    function _settleBet(Bet storage bet, uint256 dice1, uint256 dice2, bytes32 requestId) private {
        uint amount = bet.amount;
        if (amount == 0 || bet.isSettled == true) {
            return;
        }
        bool rollUnder = bet.rollUnder;

        uint winnableAmount = amountToWinnableAmount(amount, bet.choice, rollUnder);

        uint winAmount = _getResult(bet.choice,rollUnder, (( dice1 % MODULO + 1) + (dice2 % MODULO + 1))) ? winnableAmount : 0;

        bet.isSettled = true;
        bet.winAmount = uint128(winAmount);
        bet.outcome = [uint40( dice1 % MODULO + 1),uint40(dice2 % MODULO + 1)];

        if (bet.isCustomToken == true) {

            house.settleCustomBet(bet.player, winnableAmount, winAmount > 0, bet.custom_token);

            emit CustomBetSettled( bet.player, amount, rollUnder, bet.choice, bet.outcome[0],bet.outcome[1], winAmount, bet.custom_token, requestId);
        } else {

            house.settleBet(bet.player, winnableAmount, winAmount > 0);
            emit BetSettled( bet.player, amount, rollUnder, bet.choice, bet.outcome[0],bet.outcome[1], winAmount);
        }
    }

    function _getResult(uint betChoice, bool rollUnder, uint rollResult) internal pure returns(bool){
        if(rollUnder) {
            if(rollResult < betChoice) {
                return true;
            }
            else {
                return false;
            }
        }
        else {
            if(rollResult > betChoice) {
                return true;
            }
            else {
                return false;
            }
        }
    }
}