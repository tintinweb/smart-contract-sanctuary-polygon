/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

/*
KingOfDefi V0 game
Rules:
1) Users can subscribe to the game for free, it gives 100K virtual-USD to the player.
2) Players can use the v-USD to buy other virtual assets, the pair rate price is fetched via the related chainlink oracle.
3) Players can swap virtual asset for the entire game period, there is only a delay to wait between swaps by the same player.
4) At the end of the game period, a new crown dispute period begins and players can start to steal the crown from other players.
5) The crown can be steal ONLY IF the actual USD value of the total virtual assets bought is higher than the actual crown holder usd value.
6) At the end of the dispute period, the king can redeem the prize.

Perp Version
At every new week (midnight on thursday) a new match will start 
*/

interface ICLH {
    function getLastUSDPrice(uint256) external view returns(uint256);
    function getUSDForAmount(uint256, uint256) external view returns(uint256);
    function oracleNextIndex() external view returns(uint256);
    function assetDescription(uint256) external view returns(string memory);
}

// Perpetual weekly game
contract KingOfDefiV0Perp {
    using SafeERC20 for IERC20;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public balances; // week match => user => asset index => amount
    mapping(uint256 => mapping(address => bool)) public subscribed; // week match => user => subscribed
    mapping(uint256 => mapping(address => uint256)) public prizes; // week match => token
    mapping(address => uint256) public lastSwap;
    mapping(uint256 => address) public kings;
    mapping(uint256 => uint256) public numberOfPlayers; // players for each week match 
    uint256 public gameWeek = block.timestamp / 1 weeks;

    // Game Parameter
    uint256 public constant disputeDuration = 1 days;
    uint256 public constant swapDelay = 2 minutes;
    uint256 public constant initialVUSD = 100_000;
    address public chainlinkHub; // game assets oracle hub

    // Game Events 
    event Subscribed(address indexed player, uint256 indexed gameWeek);
    event Swapped(
        uint256 indexed gameWeek,
        uint256 indexed indexFrom,
        uint256 indexed indexTo,
        uint256 amountFrom,
        uint256 amountTo
    );
    event PrizeRedeemed(
        address indexed king,
        uint256 indexed gameWeek,
        address indexed token, 
        uint256 amount
    );
    event NewKing(
        uint256 indexed gameWeek,
        address indexed oldKing,
        address indexed newKing,
        uint256 oldKingUSD,
        uint256 newKingUSD
    );
    event RewardAdded(
        uint256 indexed gameWeek,
        address indexed token, 
        uint256 amount
    );

    constructor( 
        address _chainlinkHub
    ) {
        chainlinkHub = _chainlinkHub;
    }

    modifier updateWeek() {
        uint256 currentGameWeek = block.timestamp / 1 weeks;
        if (currentGameWeek > gameWeek) {
            gameWeek = currentGameWeek;
        }
        _;
    }
    
    /// @notice subscribe to the game, one subscription for each address for each week match
    /// @dev it will give to the player 100K virtual-USD (VUSD)
    function play() external updateWeek() {
        require(!subscribed[gameWeek][msg.sender], "already subscribed");
        subscribed[gameWeek][msg.sender] = true;
        balances[gameWeek][msg.sender][0] = initialVUSD; // 0 is VUSD
        unchecked{++numberOfPlayers[gameWeek];}
        emit Subscribed(msg.sender, gameWeek);
    }

    /// @notice swap virtual asset to another virtual asset (only during the game period)
    /// @dev the asset price will be fetched via chainlink oracles
	/// @param _fromIndex index of the token to swap from
    /// @param _toIndex index of the token to swap to
    /// @param _amount amount to swap
    function swap(uint256 _fromIndex, uint256 _toIndex, uint256 _amount) external updateWeek() {
        require(subscribed[gameWeek][msg.sender], "player not subscribed");
        require(block.timestamp < (gameWeek * 1 weeks) + 1 weeks - disputeDuration, "crown dispute period");
        require(block.timestamp > lastSwap[msg.sender] + swapDelay, "player swap delay not elapsed");
        require(_fromIndex != _toIndex, "same index");
        require(_amount > 0, "set an amount > 0");

        uint256 lastIndex = ICLH(chainlinkHub).oracleNextIndex();
        require(_fromIndex < lastIndex && _toIndex < lastIndex, "only existing indexes");
        require(balances[gameWeek][msg.sender][_fromIndex] >= _amount, "amount not enough");

        uint256 fromUSD;
        uint256 toUSD;
        if (_toIndex == 0) {
            // v-asset <-> v-usd
            fromUSD = ICLH(chainlinkHub).getUSDForAmount(_fromIndex, _amount);
            toUSD = 1e18;
        } else {
            toUSD = ICLH(chainlinkHub).getLastUSDPrice(_toIndex);
            if(_fromIndex == 0) {
                // v-usd <-> v-asset
                fromUSD = _amount;
            } else {
                // v-asset <-> v-asset
                fromUSD = ICLH(chainlinkHub).getUSDForAmount(_fromIndex, _amount);
            }  
        }

        uint256 amountToBuy = fromUSD * 1e18 / toUSD;

        // swap
        unchecked{balances[gameWeek][msg.sender][_fromIndex] -= _amount;}
        balances[gameWeek][msg.sender][_toIndex] += amountToBuy;

        // store the actual ts to manage the swap delay
        lastSwap[msg.sender] = block.timestamp;

        emit Swapped(gameWeek, _fromIndex, _toIndex, _amount, amountToBuy);
    }

    /// @notice redeem prize, only the king can do that or anyone if no one became the king
    /// @dev it can be called only for a week match elapsed
    /// @param _gameWeek game week to redeem the prize
	/// @param _token token to redeem
    /// @param _amount amount to redeem
    function redeemPrize(uint256 _gameWeek, address _token, uint256 _amount) external updateWeek() {
        require(_gameWeek < gameWeek, "Week not elapsed");
        require(msg.sender == kings[_gameWeek] || kings[_gameWeek] == address(0), "not allowed");
        require(prizes[_gameWeek][_token] >= _amount, "amount too high");
        IERC20(_token).safeTransfer(msg.sender, _amount);
        unchecked{prizes[_gameWeek][_token] -= _amount;}
        emit PrizeRedeemed(msg.sender, gameWeek, _token, _amount);
    }

    /// @notice steal the crown from the king, you can if you have more usd value
    /// @dev it can be called only during the crown dispute time
    function stealCrown() external updateWeek() {
        require(block.timestamp > (gameWeek * 1 weeks) + 1 weeks - disputeDuration, "only during dispute time");
        if (kings[gameWeek] == address(0)) {
            kings[gameWeek] = msg.sender;
            return;
        }
        uint256 actualKingUSD = calculateTotalUSD(kings[gameWeek]);
        uint256 rivalUSD = calculateTotalUSD(msg.sender);
        if (rivalUSD > actualKingUSD) {
            emit NewKing(gameWeek, kings[gameWeek], msg.sender, actualKingUSD, rivalUSD);
            kings[gameWeek] = msg.sender;
        }
    }

    /// @notice top up weekly prize with any ERC20 (until the game end)
    /// @dev approve the token before calling the function
	/// @param _token token to top up
    /// @param _amount amount to top up
    function topUpPrize(address _token, uint256 _amount) external updateWeek() {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        prizes[gameWeek][_token] += _amount;
        emit RewardAdded(gameWeek, _token, _amount);
    }

    /// @notice calculate usd value of an asset
    /// @dev approve the token before calling the function
	/// @param _player player address
    /// @param _assetIndex index of the asset 
    function balanceOfInUSD(address _player, uint256 _assetIndex) external view returns(uint256) {
        uint256 amount = balances[gameWeek][_player][_assetIndex];
        return ICLH(chainlinkHub).getUSDForAmount(_assetIndex, amount);
    }

    /// @notice calculate total usd value of the player for the current week
	/// @param _player player address
    function calculateTotalUSD(address _player) public view returns(uint256) {
        uint256 usdTotalAmount;
        uint256 nextIndex = ICLH(chainlinkHub).oracleNextIndex();
        usdTotalAmount += balances[gameWeek][_player][0]; // v-usd
        for(uint256 index = 1; index < nextIndex;) {
            uint256 amount = balances[gameWeek][_player][index];
            if (amount > 0) {
                usdTotalAmount += ICLH(chainlinkHub).getUSDForAmount(index, amount);
            }
            unchecked{++index;}
        }
        return usdTotalAmount;
    }

    /// @notice it returns the description of the asset (ETH / USD)
	/// @param _index index of the asset
    function getAssetFromIndex(uint256 _index) external view returns(string memory) {
        if (_index == 0) {
            return "VUSD";
        }
        return ICLH(chainlinkHub).assetDescription(_index);
    }
}