// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MoveHelper.sol";

// import "hardhat/console.sol";

contract ChessWager is MoveHelper {
    using SafeERC20 for IERC20;

    struct GameWager {
        address player0;
        address player1;
        address wagerToken;
        uint wager;
        uint numberOfGames;
        bool hasPlayerAccepted;
        uint timeLimit;
        uint timeLastMove;
        uint timePlayer0;
        uint timePlayer1;
    }

    struct WagerStatus {
        bool isPlayer0White;
        uint winsPlayer0;
        uint winsPlayer1;
    }

    struct Game {
        uint16[] moves;
    }

    // address wager => GameWager
    mapping(address => GameWager) public gameWagers;

    // address wager => gameID => Game
    mapping(address => mapping(uint => Game)) games;

    // address wager => gameIDs
    mapping(address => uint[]) gameIDs;

    // addres wager => Player Wins
    mapping(address => WagerStatus) public wagerStatus;

    // @dev player can see game challenges
    mapping(address => address[]) public userGames;

    address[] public allWagers;

    // Dividend Token Address
    address public ChessFishToken;

    constructor(address moveVerificationAddress, address _ChessFishToken) {
        moveVerification = MoveVerification(moveVerificationAddress);
        initPieces();

        ChessFishToken = _ChessFishToken;
        deployer = msg.sender;
    }

    /* 
    //// EVENTS ////
    */
    event createGameWagerEvent(
        address wager,
        address player1,
        address wagerToken,
        uint wagerAmount,
        uint timeLimit,
        uint numberOfGames
    );
    event acceptWagerEvent(address wagerAddress, address userAddress);
    event playMoveEvent(address wagerAddress, uint16 move);
    event payoutWagerEvent(address wagerAddress, address winner);
    event cancelWagerEvent(address wagerAddress, address userAddress);

    /* 
    //// VIEW FUNCTIONS ////
    */
    function getAllWagersCount() external view returns (uint) {
        return allWagers.length;
    }

    function getAllWagerAddresses() external view returns (address[] memory) {
        return allWagers;
    }

    function getAllUserGames(
        address player
    ) external view returns (address[] memory) {
        return userGames[player];
    }

    function getGameLength(address wagerAddress) external view returns (uint) {
        return gameIDs[wagerAddress].length;
    }

    function getGameMoves(
        address wagerAddress,
        uint gameID
    ) external view returns (Game memory) {
        return games[wagerAddress][gameID];
    }

    function getWagerAddress(
        GameWager memory wager
    ) internal view returns (address) {
        require(wager.player0 != wager.player1, "players must be different");
        require(wager.numberOfGames % 2 == 1, "number of games must be odd");

        uint blockNumber = block.number;
        bytes32 blockHash = blockhash(blockNumber);

        bytes32 salt = keccak256(
            abi.encodePacked(
                wager.player0,
                wager.player1,
                wager.wagerToken,
                wager.wager,
                wager.timeLimit,
                wager.numberOfGames,
                blockHash
            )
        );

        address wagerAddress = address(uint160(bytes20(salt)));

        return wagerAddress;
    }

    // using int to quickly check if game lost on time and to prevent underflow revert
    function checkTimeRemaining(
        address wagerAddress
    ) public view returns (int, int) {
        address player0 = gameWagers[wagerAddress].player0;
        // address player1 = gameWagers[wagerAddress].player1;

        uint player0Time = gameWagers[wagerAddress].timePlayer0;
        uint player1Time = gameWagers[wagerAddress].timePlayer1;

        uint elapsedTime = block.timestamp -
            gameWagers[wagerAddress].timeLastMove;
        int timeLimit = int(gameWagers[wagerAddress].timeLimit);

        address player = getPlayerMove(wagerAddress);

        int timeRemainingPlayer0;
        int timeRemainingPlayer1;

        if (player == player0) {
            timeRemainingPlayer0 = timeLimit - int(elapsedTime + player0Time);
            timeRemainingPlayer1 = timeLimit - int(player1Time);
        } else {
            timeRemainingPlayer0 = timeLimit - int(player0Time);
            timeRemainingPlayer1 = timeLimit - int(elapsedTime + player1Time);
        }

        return (timeRemainingPlayer0, timeRemainingPlayer1);
    }

    function getPlayerMove(address wagerAddress) public view returns (address) {
        uint gameID = gameIDs[wagerAddress].length;
        uint moves = games[wagerAddress][gameID].moves.length;

        bool isPlayer0White = wagerStatus[wagerAddress].isPlayer0White;

        if (isPlayer0White) {
            if (moves % 2 == 1) {
                return gameWagers[wagerAddress].player1;
            } else {
                return gameWagers[wagerAddress].player0;
            }
        } else {
            if (moves % 2 == 1) {
                return gameWagers[wagerAddress].player0;
            } else {
                return gameWagers[wagerAddress].player1;
            }
        }
    }

    function isPlayerWhite(
        address wagerAddress,
        address player
    ) public view returns (bool) {
        if (gameWagers[wagerAddress].player0 == player) {
            return wagerStatus[wagerAddress].isPlayer0White;
        } else {
            return !wagerStatus[wagerAddress].isPlayer0White;
        }
    }

    function getGameStatus(
        address wagerAddress
    ) public view returns (uint8, uint256, uint32, uint32) {
        uint gameID = gameIDs[wagerAddress].length;
        uint16[] memory moves = games[wagerAddress][gameID].moves;

        (
            uint8 outcome,
            uint256 gameState,
            uint32 player0State,
            uint32 player1State
        ) = moveVerification.checkGameFromStart(moves);

        return (outcome, gameState, player0State, player1State);
    }

    /* 
    //// WRITE FUNCTIONS ////
    */
    function createGameWager(
        address player1,
        address wagerToken,
        uint wager,
        uint timeLimit,
        uint numberOfGames
    ) external returns (address wagerAddress) {
        GameWager memory gameWager = GameWager(
            msg.sender, // player0
            player1,
            wagerToken,
            wager,
            numberOfGames,
            false,
            timeLimit,
            0, // timeLastMove
            0, // timePlayer0
            0 // timePlayer1
        );

        IERC20(wagerToken).safeTransferFrom(msg.sender, address(this), wager);

        wagerAddress = getWagerAddress(gameWager);
        gameWagers[wagerAddress] = gameWager;

        // first player to challenge is black since randomness is impossible
        // but each subsequent game players switch colors
        WagerStatus memory status = WagerStatus(false, 0, 0);
        wagerStatus[wagerAddress] = status;

        userGames[msg.sender].push(wagerAddress);
        userGames[player1].push(wagerAddress);

        // update global state
        allWagers.push(wagerAddress);

        emit createGameWagerEvent(
            wagerAddress,
            player1,
            wagerToken,
            wager,
            timeLimit,
            numberOfGames
        );

        return wagerAddress;
    }

    // player1 calls if they accept challenge
    function acceptWager(address wagerAddress) external {
        address player1 = gameWagers[wagerAddress].player1;

        if (player1 == address(0)) {
            gameWagers[wagerAddress].player1 = msg.sender;
            userGames[msg.sender].push(wagerAddress);
        } else {
            require(
                gameWagers[wagerAddress].player1 == msg.sender,
                "msg.sender != player1"
            );
        }

        address wagerToken = gameWagers[wagerAddress].wagerToken;
        uint wager = gameWagers[wagerAddress].wager;

        IERC20(wagerToken).safeTransferFrom(msg.sender, address(this), wager);

        gameWagers[wagerAddress].hasPlayerAccepted = true;
        gameWagers[wagerAddress].timeLastMove = block.timestamp;

        emit acceptWagerEvent(wagerAddress, msg.sender);
    }

    function playMove(
        address wagerAddress,
        uint16 move
    ) external returns (bool) {
        require(getPlayerMove(wagerAddress) == msg.sender, "Not your turn");

        // checking if time ran out
        updateTime(wagerAddress, msg.sender);
        bool isEndgameTime = updateWagerStateTime(wagerAddress);
        if (isEndgameTime) {
            return true;
        }

        uint gameID = gameIDs[wagerAddress].length;
        uint size = games[wagerAddress][gameID].moves.length;

        uint16[] memory moves = new uint16[](size + 1);

        // @dev copy array
        for (uint i = 0; i < size; i++) {
            moves[i] = games[wagerAddress][gameID].moves[i];
        }

        // @dev append move to last place in array
        moves[size] = move;

        // @dev optimistically write to state
        games[wagerAddress][gameID].moves = moves;

        // @dev fails on invalid move
        moveVerification.checkGameFromStart(moves);
        bool isEndgame = updateWagerState(wagerAddress);

        emit playMoveEvent(wagerAddress, move);

        return isEndgame;
    }

    // smallest wager amount is 18 wei before fees => 0
    // allows double spend at the moment...
    function payoutWager(address wagerAddress) external returns (bool) {
        require(
            gameWagers[wagerAddress].player0 == msg.sender ||
                gameWagers[wagerAddress].player1 == msg.sender,
            "not listed"
        );
        require(
            gameIDs[wagerAddress].length ==
                gameWagers[wagerAddress].numberOfGames,
            "wager not finished yet"
        );

        address winner;
        if (
            wagerStatus[wagerAddress].winsPlayer0 >
            wagerStatus[wagerAddress].winsPlayer1
        ) {
            winner = gameWagers[wagerAddress].player0;
        } else {
            winner = gameWagers[wagerAddress].player1;
        }

        address token = gameWagers[wagerAddress].wagerToken;
        uint wagerAmount = gameWagers[wagerAddress].wager * 2;

        gameWagers[wagerAddress].wager = 0;

        // 3% dev fee, 3% shareholder fee
        uint adminFee = (wagerAmount * 2 * 300) / 10000;
        uint shareHolderFee = (wagerAmount * 2 * 300) / 10000;
        uint wagerPayout = wagerAmount - (adminFee + shareHolderFee);

        IERC20(token).safeTransfer(deployer, adminFee);
        IERC20(token).safeTransfer(ChessFishToken, shareHolderFee);
        IERC20(token).safeTransfer(winner, wagerPayout);

        emit payoutWagerEvent(wagerAddress, winner);

        return true;
    }

    function cancelWager(address wagerAddress) external returns (bool) {
        require(
            gameWagers[wagerAddress].hasPlayerAccepted == false,
            "wager in progress"
        );
        require(
            gameWagers[wagerAddress].player0 == msg.sender ||
                gameWagers[wagerAddress].player1 == msg.sender,
            "not listed"
        );

        address token = gameWagers[wagerAddress].wagerToken;
        uint wagerAmount = gameWagers[wagerAddress].wager;

        gameWagers[wagerAddress].wager = 0;

        IERC20(token).safeTransfer(msg.sender, wagerAmount);

        emit cancelWagerEvent(wagerAddress, msg.sender);

        return true;
    }

    // this is public so that anyone can update the time
    function updateWagerStateTime(address wagerAddress) public returns (bool) {
        (int timePlayer0, int timePlayer1) = checkTimeRemaining(wagerAddress);

        if (timePlayer0 < 0) {
            wagerStatus[wagerAddress].winsPlayer1 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[
                wagerAddress
            ].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        if (timePlayer1 < 0) {
            wagerStatus[wagerAddress].winsPlayer0 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[
                wagerAddress
            ].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        return false;
    }

    // @dev if != 0 initialize new game
    // if wins are majority of games in wager handle payout
    function updateWagerState(address wagerAddress) private returns (bool) {
        uint gameID = gameIDs[wagerAddress].length;
        uint16[] memory moves = games[wagerAddress][gameID].moves;

        (uint8 outcome, , , ) = moveVerification.checkGameFromStart(moves);

        if (outcome == 0) {
            return false;
        }
        if (outcome == 1) {
            wagerStatus[wagerAddress].winsPlayer0 += 1;
            wagerStatus[wagerAddress].winsPlayer1 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[
                wagerAddress
            ].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        if (outcome == 2) {
            if (isPlayerWhite(wagerAddress, gameWagers[wagerAddress].player0)) {
                wagerStatus[wagerAddress].winsPlayer0 += 1;
            } else {
                wagerStatus[wagerAddress].winsPlayer1 += 1;
            }
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[
                wagerAddress
            ].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        if (outcome == 3) {
            if (isPlayerWhite(wagerAddress, gameWagers[wagerAddress].player0)) {
                wagerStatus[wagerAddress].winsPlayer1 += 1;
            } else {
                wagerStatus[wagerAddress].winsPlayer0 += 1;
            }
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[
                wagerAddress
            ].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        return false;
    }

    function updateTime(address wagerAddress, address player) private {
        bool isPlayer0 = gameWagers[wagerAddress].player0 == player;
        uint startTime = gameWagers[wagerAddress].timeLastMove;
        uint currentTime = block.timestamp;
        uint dTime = currentTime - startTime;

        if (isPlayer0) {
            gameWagers[wagerAddress].timePlayer0 += dTime;
            gameWagers[wagerAddress].timeLastMove = currentTime; // Update the start time for the next turn
        } else {
            gameWagers[wagerAddress].timePlayer1 += dTime;
            gameWagers[wagerAddress].timeLastMove = currentTime; // Update the start time for the next turn
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint8 a, uint8 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint8 a, uint8 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./MoveVerification.sol";

contract MoveHelper {
    // @dev uint pieces => letter pieces
    mapping(uint8 => string) pieces;

    // @dev algebraic chess notation string => uint (0-63)
    mapping(string => uint) public coordinates;
    mapping(uint => string) public squareToCoordinate;

    // @dev address deployer
    address public deployer;

    // @dev MoveVerification contract
    MoveVerification public moveVerification;

    modifier OnlyDeployer() {
        require(msg.sender == deployer, "only deployer");
        _;
    }

    uint devFee = 300; // 3 percent

    function updateFee(uint _fee) external OnlyDeployer {
        devFee = _fee;
    }

    // This increases the size of the compiled bytecode...
    function initPieces() internal {
        // blank square
        pieces[0] = ".";

        // white pieces
        pieces[1] = "P";
        pieces[2] = "B";
        pieces[3] = "N";
        pieces[4] = "R";
        pieces[5] = "Q";
        pieces[6] = "K";

        // black pieces
        pieces[9] = "p";
        pieces[10] = "b";
        pieces[11] = "n";
        pieces[12] = "r";
        pieces[13] = "q";
        pieces[14] = "k";
    }

    // @dev get letter
    function getLetter(uint8 piece) public view returns (string memory) {
        string memory letter = pieces[piece];
        return letter;
    }

    // @dev called from ts since hardcoding the mapping makes the contract too large
    function initCoordinates(
        string[64] memory coordinate,
        uint[64] memory value
    ) external OnlyDeployer {
        for (int i = 0; i < 64; i++) {
            coordinates[coordinate[uint(i)]] = value[uint(i)];
            squareToCoordinate[value[uint(i)]] = coordinate[uint(i)];
        }
    }

    /**
        @dev Converts a move from a 16-bit integer to a 2 8-bit integers.
        @param move is the move to convert
        @return fromPos and toPos
    */
    function convertFromMove(uint16 move) public pure returns (uint8, uint8) {
        uint8 fromPos = (uint8)((move >> 6) & 0x3f);
        uint8 toPos = (uint8)(move & 0x3f);

        return (fromPos, toPos);
    }

    /**
        @dev Converts two 8-bit integers to a 16-bit integer
        @param fromPos is the position to move a piece from.
        @param toPos is the position to move a piece to.
        @return move
    */
    function convertToMove(
        uint8 fromPos,
        uint8 toPos
    ) public pure returns (uint16) {
        uint16 move = (uint16)(fromPos);
        move = move << 6;
        move = move + (uint16)(toPos);

        return move;
    }

    // @dev convert move i.e. e2e4 to hex move
    function moveToHex(
        string memory move
    ) external view returns (uint16 hexMove) {
        bytes memory byteString = bytes(move);

        bytes memory bFromPos = "00";
        bytes memory bToPos = "00";

        bFromPos[0] = byteString[0];
        bFromPos[1] = byteString[1];

        bToPos[0] = byteString[2];
        bToPos[1] = byteString[3];

        string memory sFromPos = string(bFromPos);
        string memory sToPos = string(bToPos);

        uint8 fromPos = uint8(coordinates[sFromPos]);
        uint8 toPos = uint8(coordinates[sToPos]);

        hexMove = convertToMove(fromPos, toPos);

        return hexMove;
    }

    function hexToMove(
        uint16 hexMove
    ) public view returns (string memory move) {
        uint8 fromPos = uint8(hexMove >> 6);
        uint8 toPos = uint8(hexMove & 0x3f);

        string memory fromCoord = squareToCoordinate[fromPos];
        string memory toCoord = squareToCoordinate[toPos];

        move = string(abi.encodePacked(fromCoord, toCoord));

        return move;
    }

    // @dev returns string of letters representing the board
    // @dev only to be called by user or ui
    function getBoard(
        uint gameState
    ) external view returns (string[64] memory) {
        string[64] memory board;
        uint j = 0;

        for (uint i = 0; i <= 7; i++) {
            int pos = ((int(i) + 1) * 8) - 1;
            int last = pos - 7;
            for (pos; pos >= last; pos--) {
                uint8 piece = moveVerification.pieceAtPosition(
                    gameState,
                    uint8(uint(pos))
                );

                board[j] = getLetter(piece);

                j++;
            }
        }
        return board;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "contracts/libraries/Math.sol";

contract MoveVerification {
    uint8 constant empty_const = 0x0;
    uint8 constant pawn_const = 0x1; // 001
    uint8 constant bishop_const = 0x2; // 010
    uint8 constant knight_const = 0x3; // 011
    uint8 constant rook_const = 0x4; // 100
    uint8 constant queen_const = 0x5; // 101
    uint8 constant king_const = 0x6; // 110
    uint8 constant type_mask_const = 0x7;
    uint8 constant color_const = 0x8;

    uint8 constant piece_bit_size = 4;
    uint8 constant piece_pos_shift_bit = 2;

    uint32 constant en_passant_const = 0x000000ff;
    uint32 constant king_pos_mask = 0x0000ff00;
    uint32 constant king_pos_zero_mask = 0xffff00ff;
    uint16 constant king_pos_bit = 8;

    /**
        @dev For castling masks, mask only the last bit of an uint8, to block any under/overflows.
    */
    uint32 constant rook_king_side_move_mask = 0x00800000;
    uint16 constant rook_king_side_move_bit = 16;
    uint32 constant rook_queen_side_move_mask = 0x80000000;
    uint16 constant rook_queen_side_move_bit = 24;
    uint32 constant king_move_mask = 0x80800000;

    uint16 constant pieces_left_bit = 32;

    uint8 constant king_white_start_pos = 0x04;
    uint8 constant king_black_start_pos = 0x3c;

    uint16 constant pos_move_mask = 0xfff;

    uint16 constant request_draw_const = 0x1000;
    uint16 constant accept_draw_const = 0x2000;
    uint16 constant resign_const = 0x3000;

    uint8 constant inconclusive_outcome = 0x0;
    uint8 constant draw_outcome = 0x1;
    uint8 constant white_win_outcome = 0x2;
    uint8 constant black_win_outcome = 0x3;

    uint256 constant game_state_start =
        0xcbaedabc99999999000000000000000000000000000000001111111143265234;

    uint256 constant full_long_word_mask =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 constant invalid_move_constant =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /** @dev    Initial white state:
                0f: 15 (non-king) pieces left
                00: Queen-side rook at a1 position
                07: King-side rook at h1 position
                04: King at e1 position
                ff: En-passant at invalid position
    */
    uint32 constant initial_white_state = 0x000704ff;

    /** @dev    Initial black state:
                0f: 15 (non-king) pieces left
                38: Queen-side rook at a8 position
                3f: King-side rook at h8 position
                3c: King at e8 position
                ff: En-passant at invalid position
    */
    uint32 constant initial_black_state = 0x383f3cff;

    // @dev chess game from start using hex moves
    // @dev returns outcome, gameState, player0State, player1State
    function checkGameFromStart(
        uint16[] memory moves
    ) public pure returns (uint8, uint256, uint32, uint32) {
        return
            checkGame(
                game_state_start,
                initial_white_state,
                initial_black_state,
                false,
                moves
            );
    }

    /**
        @dev Calculates the outcome of a game depending on the moves from a starting position.
             Reverts when an invalid move is found.
        @param startingGameState Game state from which start the movements
        @param startingPlayerState State of the first playing player
        @param startingOpponentState State of the other playing player
        @param startingTurnBlack Whether the starting player is the black pieces
        @param moves is the input array containing all the moves in the game
        @return outcome can be 0 for inconclusive, 1 for draw, 2 for white winning, 3 for black winning
     */
    function checkGame(
        uint256 startingGameState,
        uint32 startingPlayerState,
        uint32 startingOpponentState,
        bool startingTurnBlack,
        uint16[] memory moves
    )
        public
        pure
        returns (
            uint8 outcome,
            uint256 gameState,
            uint32 playerState,
            uint32 opponentState
        )
    {
        gameState = startingGameState;

        playerState = startingPlayerState;
        opponentState = startingOpponentState;

        outcome = inconclusive_outcome;

        bool currentTurnBlack = startingTurnBlack;

        require(moves.length > 0, "inv moves");

        if (moves[moves.length - 1] == accept_draw_const) {
            // Check
            require(moves.length >= 2, "inv draw");
            require(moves[moves.length - 2] == request_draw_const, "inv draw");
            outcome = draw_outcome;
        } else if (moves[moves.length - 1] == resign_const) {
            // Assumes that signatures have been checked and moves are in correct order
            outcome = ((moves.length % 2) == 1) != currentTurnBlack
                ? black_win_outcome
                : white_win_outcome;
        } else {
            // Check entire game
            for (uint256 i = 0; i < moves.length; i++) {
                (gameState, opponentState, playerState) = verifyExecuteMove(
                    gameState,
                    moves[i],
                    playerState,
                    opponentState,
                    currentTurnBlack
                );

                require(!checkForCheck(gameState, opponentState), "inv check");
                //require (outcome == 0 || i == (moves.length - 1), "Excesive moves");
                currentTurnBlack = !currentTurnBlack;
            }

            uint8 endgameOutcome = checkEndgame(
                gameState,
                playerState,
                opponentState
            );

            if (endgameOutcome == 2) {
                outcome = currentTurnBlack
                    ? white_win_outcome
                    : black_win_outcome;
            } else if (endgameOutcome == 1) {
                outcome = draw_outcome;
            }
        }
    }

    /**
        @dev Calculates the outcome of a single move given the current game state.
             Reverts for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param move is the move to execute: 16-bit var, high word = from pos, low word = to pos
                move can also be: resign, request draw, accept draw.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteMove(
        uint256 gameState,
        uint16 move,
        uint32 playerState,
        uint32 opponentState,
        bool currentTurnBlack
    )
        public
        pure
        returns (
            uint256 newGameState,
            uint32 newPlayerState,
            uint32 newOpponentState
        )
    {
        // TODO: check resigns and other stuff first
        uint8 fromPos = (uint8)((move >> 6) & 0x3f);
        uint8 toPos = (uint8)(move & 0x3f);

        require(fromPos != toPos, "inv move stale");

        uint8 fromPiece = pieceAtPosition(gameState, fromPos);

        require(
            ((fromPiece & color_const) > 0) == currentTurnBlack,
            "inv move color"
        );

        uint8 fromType = fromPiece & type_mask_const;

        newPlayerState = playerState;
        newOpponentState = opponentState;

        if (fromType == pawn_const) {
            (newGameState, newPlayerState) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                (uint8)(move >> 12),
                currentTurnBlack,
                playerState,
                opponentState
            );
        } else if (fromType == knight_const) {
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
        } else if (fromType == bishop_const) {
            newGameState = verifyExecuteBishopMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
        } else if (fromType == rook_const) {
            newGameState = verifyExecuteRookMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            // Reset playerState if necessary when one of the rooks move

            if (fromPos == (uint8)(playerState >> rook_king_side_move_bit)) {
                newPlayerState = playerState | rook_king_side_move_mask;
            } else if (
                fromPos == (uint8)(playerState >> rook_queen_side_move_bit)
            ) {
                newPlayerState = playerState | rook_queen_side_move_mask;
            }
        } else if (fromType == queen_const) {
            newGameState = verifyExecuteQueenMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
        } else if (fromType == king_const) {
            (newGameState, newPlayerState) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
        } else {
            revert("inv move type");
        }
        require(newGameState != invalid_move_constant, "inv move");

        // Check for en passant only if the piece moving is a pawn... smh
        if (
            pawn_const == pieceAtPosition(gameState, fromPos) ||
            pawn_const + color_const == pieceAtPosition(gameState, fromPos)
        ) {
            if (toPos == (opponentState & en_passant_const)) {
                if (currentTurnBlack) {
                    newGameState = zeroPosition(newGameState, toPos + 8);
                } else {
                    newGameState = zeroPosition(newGameState, toPos - 8);
                }
            }
        }
        newOpponentState = opponentState | en_passant_const;
    }

    /**
        @dev Calculates the outcome of a single move of a pawn given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecutePawnMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        uint8 moveExtra,
        bool currentTurnBlack,
        uint32 playerState,
        uint32 opponentState
    ) public pure returns (uint256 newGameState, uint32 newPlayerState) {
        newPlayerState = playerState;
        // require ((currentTurnBlack && (toPos < fromPos)) || (!currentTurnBlack && (fromPos < toPos)), "inv move");
        if (currentTurnBlack != (toPos < fromPos)) {
            // newGameState = invalid_move_constant;
            return (invalid_move_constant, 0x0);
        }
        uint8 diff = (uint8)(
            Math.max(fromPos, toPos) - Math.min(fromPos, toPos)
        );
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (diff == 8 || diff == 16) {
            if (pieceToPosition != 0) {
                //newGameState = invalid_move_constant;
                return (invalid_move_constant, 0x0);
            }
            if (diff == 16) {
                if (
                    (currentTurnBlack && ((fromPos >> 3) != 0x6)) ||
                    (!currentTurnBlack && ((fromPos >> 3) != 0x1))
                ) {
                    return (invalid_move_constant, 0x0);
                }
                uint8 posToInBetween = toPos > fromPos
                    ? fromPos + 8
                    : toPos + 8;
                if (pieceAtPosition(gameState, posToInBetween) != 0) {
                    return (invalid_move_constant, 0x0);
                }
                newPlayerState =
                    (newPlayerState & (~en_passant_const)) |
                    (uint32)(posToInBetween);
            }
        } else if (diff == 7 || diff == 9) {
            if (getVerticalMovement(fromPos, toPos) != 1) {
                return (invalid_move_constant, 0x0);
            }
            if ((uint8)(opponentState & en_passant_const) != toPos) {
                if (
                    (pieceToPosition == 0) || // Must be moving to occupied square
                    (currentTurnBlack ==
                        ((pieceToPosition & color_const) == color_const)) // Must be different color
                ) {
                    return (invalid_move_constant, 0x0);
                }
            }
        } else return (invalid_move_constant, 0x0);

        newGameState = commitMove(gameState, fromPos, toPos);
        if (
            (currentTurnBlack && ((toPos >> 3) == 0x0)) ||
            (!currentTurnBlack && ((toPos >> 3) == 0x7))
        ) {
            // @dev Handling Promotion:
            // Currently Promotion is set to autoqueen
            /*   
            require ((moveExtra == bishop_const) || (moveExtra == knight_const) ||
                     (moveExtra == rook_const) || (moveExtra == queen_const), "inv prom");
            */
            // auto queen promote
            moveExtra = queen_const;

            newGameState = setPosition(
                zeroPosition(newGameState, toPos),
                toPos,
                currentTurnBlack ? moveExtra | color_const : moveExtra
            );
        }

        require(newPlayerState != 0, "pawn");
    }

    /**
        @dev Calculates the outcome of a single move of a knight given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteKnightMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (
                ((pieceToPosition & color_const) == color_const) ==
                currentTurnBlack
            ) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (!((h == 2 && v == 1) || (h == 1 && v == 2))) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of a bishop given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteBishopMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (
                ((pieceToPosition & color_const) == color_const) ==
                currentTurnBlack
            ) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (
            (h != v) || ((gameState & getInBetweenMask(fromPos, toPos)) != 0x00)
        ) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of a rook given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteRookMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);
        if (pieceToPosition > 0) {
            if (
                ((pieceToPosition & color_const) == color_const) ==
                currentTurnBlack
            ) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (
            ((h > 0) == (v > 0)) ||
            (gameState & getInBetweenMask(fromPos, toPos)) != 0x00
        ) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of the queen given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteQueenMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);
        if (pieceToPosition > 0) {
            if (
                ((pieceToPosition & color_const) == color_const) ==
                currentTurnBlack
            ) {
                return invalid_move_constant;
            }
        }
        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);
        if (
            ((h != v) && (h != 0) && (v != 0)) ||
            (gameState & getInBetweenMask(fromPos, toPos)) != 0x00
        ) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of the king given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from. Behavior is undefined for values >= 0x40.
        @param toPos is position moving to. Behavior is undefined for values >= 0x40.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
     */
    function verifyExecuteKingMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack,
        uint32 playerState
    ) public pure returns (uint256 newGameState, uint32 newPlayerState) {
        newPlayerState =
            ((playerState | king_move_mask) & king_pos_zero_mask) |
            ((uint32)(toPos) << king_pos_bit);
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (
                ((pieceToPosition & color_const) == color_const) ==
                currentTurnBlack
            ) {
                return (invalid_move_constant, newPlayerState);
            }
        }
        if (toPos >= 0x40 || fromPos >= 0x40) {
            return (invalid_move_constant, newPlayerState);
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if ((h <= 1) && (v <= 1)) {
            return (commitMove(gameState, fromPos, toPos), newPlayerState);
        } else if ((h == 2) && (v == 0)) {
            if (!pieceUnderAttack(gameState, fromPos)) {
                // TODO: must we check king's 'from' position?
                // Reasoning: castilngRookPosition resolves to an invalid toPos when the rook or the king have already moved.
                uint8 castilngRookPosition = (uint8)(
                    playerState >> rook_queen_side_move_bit
                );
                if (castilngRookPosition + 2 == toPos) {
                    // Queen-side castling
                    // Spaces between king and rook original positions must be empty
                    if (
                        (getInBetweenMask(castilngRookPosition, fromPos) &
                            gameState) == 0
                    ) {
                        // Move King 1 space to the left and check for attacks (there must be none)
                        newGameState = commitMove(
                            gameState,
                            fromPos,
                            fromPos - 1
                        );
                        if (!pieceUnderAttack(newGameState, fromPos - 1)) {
                            return (
                                commitMove(
                                    commitMove(
                                        newGameState,
                                        fromPos - 1,
                                        toPos
                                    ),
                                    castilngRookPosition,
                                    fromPos - 1
                                ),
                                newPlayerState
                            );
                        }
                    }
                } else {
                    castilngRookPosition = (uint8)(
                        playerState >> rook_king_side_move_bit
                    );
                    if (castilngRookPosition - 1 == toPos) {
                        // King-side castling
                        // Spaces between king and rook original positions must be empty
                        if (
                            (getInBetweenMask(castilngRookPosition, fromPos) &
                                gameState) == 0
                        ) {
                            // Move King 1 space to the left and check for attacks (there must be none)
                            newGameState = commitMove(
                                gameState,
                                fromPos,
                                fromPos + 1
                            );
                            if (!pieceUnderAttack(newGameState, fromPos + 1)) {
                                return (
                                    commitMove(
                                        commitMove(
                                            newGameState,
                                            fromPos + 1,
                                            toPos
                                        ),
                                        castilngRookPosition,
                                        fromPos + 1
                                    ),
                                    newPlayerState
                                );
                            }
                        }
                    }
                }
            }
        }

        return (invalid_move_constant, 0x00);
    }

    /**
        @dev Checks if a move is valid for the queen in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the queen is moving.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkQueenValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Queen's movement */

        unchecked {
            // Check left
            for (
                toPos = fromPos - 1;
                (toPos & 0x7) < (fromPos & 0x7);
                toPos--
            ) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check right
            for (
                toPos = fromPos + 1;
                (toPos & 0x7) > (fromPos & 0x7);
                toPos++
            ) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check up
            for (toPos = fromPos + 8; toPos < 0x40; toPos += 8) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check down
            for (toPos = fromPos - 8; toPos < fromPos; toPos -= 8) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check up-right
            for (
                toPos = fromPos + 9;
                (toPos < 0x40) && ((toPos & 0x7) > (fromPos & 0x7));
                toPos += 9
            ) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check up-left
            for (
                toPos = fromPos + 7;
                (toPos < 0x40) && ((toPos & 0x7) < (fromPos & 0x7));
                toPos += 7
            ) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check down-right
            for (
                toPos = fromPos - 7;
                (toPos < fromPos) && ((toPos & 0x7) > (fromPos & 0x7));
                toPos -= 7
            ) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check down-left
            for (
                toPos = fromPos - 9;
                (toPos < fromPos) && ((toPos & 0x7) < (fromPos & 0x7));
                toPos -= 9
            ) {
                newGameState = verifyExecuteQueenMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the bishop in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the bishop is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkBishopValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Bishop's movement */

        unchecked {
            // Check up-right
            for (
                toPos = fromPos + 9;
                (toPos < 0x40) && ((toPos & 0x7) > (fromPos & 0x7));
                toPos += 9
            ) {
                newGameState = verifyExecuteBishopMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check up-left
            for (
                toPos = fromPos + 7;
                (toPos < 0x40) && ((toPos & 0x7) < (fromPos & 0x7));
                toPos += 7
            ) {
                newGameState = verifyExecuteBishopMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check down-right
            for (
                toPos = fromPos - 7;
                (toPos < fromPos) && ((toPos & 0x7) > (fromPos & 0x7));
                toPos -= 7
            ) {
                newGameState = verifyExecuteBishopMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check down-left
            for (
                toPos = fromPos - 9;
                (toPos < fromPos) && ((toPos & 0x7) < (fromPos & 0x7));
                toPos -= 9
            ) {
                newGameState = verifyExecuteBishopMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the rook in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the rook is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkRookValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Rook's movement */

        unchecked {
            // Check left
            for (
                toPos = fromPos - 1;
                (toPos & 0x7) < (fromPos & 0x7);
                toPos--
            ) {
                newGameState = verifyExecuteRookMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check right
            for (
                toPos = fromPos + 1;
                (toPos & 0x7) > (fromPos & 0x7);
                toPos++
            ) {
                newGameState = verifyExecuteRookMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check up
            for (toPos = fromPos + 8; toPos < 0x40; toPos += 8) {
                newGameState = verifyExecuteRookMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );

                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }

            // Check down
            for (toPos = fromPos - 8; toPos < fromPos; toPos -= 8) {
                newGameState = verifyExecuteRookMove(
                    gameState,
                    fromPos,
                    toPos,
                    currentTurnBlack
                );
                if (
                    (newGameState != invalid_move_constant) &&
                    (!pieceUnderAttack(newGameState, kingPos))
                ) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0)
                    break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the knight in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the knight is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkKnightValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by knight's movement */

        unchecked {
            toPos = fromPos + 6;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos - 6;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos + 10;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos - 10;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos - 17;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos + 17;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos + 15;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = fromPos - 15;
            newGameState = verifyExecuteKnightMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the pawn in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the knight is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkPawnValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        uint32 opponentState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 moveExtra = queen_const; /* Since this is supposed to be endgame, movement of promoted piece is irrelevant. */
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by pawn's movement */

        unchecked {
            toPos = currentTurnBlack ? fromPos - 7 : fromPos + 7;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 8 : fromPos + 8;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 9 : fromPos + 9;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 16 : fromPos + 16;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, kingPos))
            ) {
                return true;
            }
        }

        return false;
    }

    function checkKingValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;

        unchecked {
            toPos = fromPos - 9;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos - 8;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos - 7;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos - 1;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos + 1;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos + 7;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos + 8;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }

            toPos = fromPos + 9;
            (newGameState, ) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
            if (
                (newGameState != invalid_move_constant) &&
                (!pieceUnderAttack(newGameState, toPos))
            ) {
                return true;
            }
        }

        /* TODO: Check castling */

        return false;
    }

    /**
        @dev Performs one iteration of recursive search for pieces. 
        @param gameState Game state from which start the movements
        @param playerState State of the player
        @param opponentState State of the opponent
        @return returns true if any of the pieces in the current offest has legal moves
    */
    function searchPiece(
        uint256 gameState,
        uint32 playerState,
        uint32 opponentState,
        uint8 color,
        uint16 pBitOffset,
        uint16 bitSize
    ) public pure returns (bool) {
        if (bitSize > piece_bit_size) {
            uint16 newBitSize = bitSize / 2;
            uint256 m = ~(full_long_word_mask << newBitSize);
            uint256 h = (gameState >> (pBitOffset + newBitSize)) & m;

            if (h != 0) {
                if (
                    searchPiece(
                        gameState,
                        playerState,
                        opponentState,
                        color,
                        pBitOffset + newBitSize,
                        newBitSize
                    )
                ) {
                    return true;
                }
            }

            uint256 l = (gameState >> pBitOffset) & m;

            if (l != 0) {
                if (
                    searchPiece(
                        gameState,
                        playerState,
                        opponentState,
                        color,
                        pBitOffset,
                        newBitSize
                    )
                ) {
                    return true;
                }
            }
        } else {
            uint8 piece = (uint8)((gameState >> pBitOffset) & 0xF);

            if ((piece > 0) && ((piece & color_const) == color)) {
                uint8 pos = uint8(pBitOffset / piece_bit_size);
                bool currentTurnBlack = color != 0;
                uint8 pieceType = piece & type_mask_const;

                if (
                    (pieceType == king_const) &&
                    checkKingValidMoves(
                        gameState,
                        pos,
                        playerState,
                        currentTurnBlack
                    )
                ) {
                    return true;
                } else if (
                    (pieceType == pawn_const) &&
                    checkPawnValidMoves(
                        gameState,
                        pos,
                        playerState,
                        opponentState,
                        currentTurnBlack
                    )
                ) {
                    return true;
                } else if (
                    (pieceType == knight_const) &&
                    checkKnightValidMoves(
                        gameState,
                        pos,
                        playerState,
                        currentTurnBlack
                    )
                ) {
                    return true;
                } else if (
                    (pieceType == rook_const) &&
                    checkRookValidMoves(
                        gameState,
                        pos,
                        playerState,
                        currentTurnBlack
                    )
                ) {
                    return true;
                } else if (
                    (pieceType == bishop_const) &&
                    checkBishopValidMoves(
                        gameState,
                        pos,
                        playerState,
                        currentTurnBlack
                    )
                ) {
                    return true;
                } else if (
                    (pieceType == queen_const) &&
                    checkQueenValidMoves(
                        gameState,
                        pos,
                        playerState,
                        currentTurnBlack
                    )
                ) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
        @dev Checks the endgame state and determines whether the last user is checkmate'd or
             stalemate'd, or neither.
        @param gameState Game state from which start the movements
        @param playerState State of the player
        @return outcome can be 0 for inconclusive/only check, 1 stalemate, 2 checkmate
     */
    function checkEndgame(
        uint256 gameState,
        uint32 playerState,
        uint32 opponentState
    ) public pure returns (uint8) {
        uint8 kingPiece = (uint8)(
            gameState >>
                ((uint8)(playerState >> king_pos_bit) << piece_pos_shift_bit)
        ) & 0xF;

        require((kingPiece & (~color_const)) == king_const, "934");

        bool legalMoves = searchPiece(
            gameState,
            playerState,
            opponentState,
            color_const & kingPiece,
            0,
            256
        );

        // If the player is in check but also
        if (checkForCheck(gameState, playerState)) {
            return legalMoves ? 0 : 2;
        }
        return legalMoves ? 0 : 1;
    }

    /**
        @dev Gets the mask of the in-between squares.
             Basically it performs bit-shifts depending on the movement.
             Down: >> 8
             Up: << 8
             Right: << 1
             Left: >> 1
             UpRight: << 9
             DownLeft: >> 9
             DownRight: >> 7
             UpLeft: << 7
             Reverts for invalid movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @return mask of the in-between squares, can be bit-wise-and with the game state to check squares
     */
    function getInBetweenMask(
        uint8 fromPos,
        uint8 toPos
    ) public pure returns (uint256) {
        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);
        require((h == v) || (h == 0) || (v == 0), "inv move");

        // TODO: Remove this getPositionMask usage
        uint256 startMask = getPositionMask(fromPos);
        uint256 endMask = getPositionMask(toPos);
        int8 x = (int8)(toPos & 0x7) - (int8)(fromPos & 0x7);
        int8 y = (int8)(toPos >> 3) - (int8)(fromPos >> 3);
        uint8 s = 0;

        if (((x > 0) && (y > 0)) || ((x < 0) && (y < 0))) {
            s = 9 * 4;
        } else if ((x == 0) && (y != 0)) {
            s = 8 * 4;
        } else if (((x > 0) && (y < 0)) || ((x < 0) && (y > 0))) {
            s = 7 * 4;
        } else if ((x != 0) && (y == 0)) {
            s = 1 * 4;
        }

        uint256 outMask = 0x00;

        while (endMask != startMask) {
            if (startMask < endMask) {
                startMask <<= s;
            } else {
                startMask >>= s;
            }
            if (endMask != startMask) outMask |= startMask;
        }

        return outMask;
    }

    /**
        @dev Gets the mask (0xF) of a square
        @param pos square position.
        @return mask
    */
    function getPositionMask(uint8 pos) public pure returns (uint256) {
        return
            (uint256)(0xF) << ((((pos >> 3) & 0x7) * 32) + ((pos & 0x7) * 4));
    }

    /**
        @dev Calculates the horizontal movement between two positions on a chessboard.
        @param fromPos The starting position from which the movement is measured.
        @param toPos The ending position to which the movement is measured.
        @return The horizontal movement between the two positions.
    */
    function getHorizontalMovement(
        uint8 fromPos,
        uint8 toPos
    ) public pure returns (uint8) {
        return
            (uint8)(
                Math.max(fromPos & 0x7, toPos & 0x7) -
                    Math.min(fromPos & 0x7, toPos & 0x7)
            );
    }

    /**
        @dev Calculates the vertical movement between two positions on a chessboard.
        @param fromPos The starting position from which the movement is measured.
        @param toPos The ending position to which the movement is measured.
        @return The vertical movement between the two positions.
    */
    function getVerticalMovement(
        uint8 fromPos,
        uint8 toPos
    ) public pure returns (uint8) {
        return
            (uint8)(
                Math.max(fromPos >> 3, toPos >> 3) -
                    Math.min(fromPos >> 3, toPos >> 3)
            );
    }

    /**
        @dev Checks if the king in the given game state is under attack (check condition).
        @param gameState The current game state to analyze.
        @param playerState The player's state containing information about the king position.
        @return A boolean indicating whether the king is under attack (check) or not.
    */
    function checkForCheck(
        uint256 gameState,
        uint32 playerState
    ) public pure returns (bool) {
        uint8 kingsPosition = (uint8)(playerState >> king_pos_bit);

        require(
            king_const == (pieceAtPosition(gameState, kingsPosition) & 0x7),
            "NOT KING"
        );

        return pieceUnderAttack(gameState, kingsPosition);
    }

    /**
    @dev Checks if a piece at the given position is under attack in the given game state.
    @param gameState The current game state to analyze.
    @param pos The position of the piece to check for attack.
    @return A boolean indicating whether the piece at the given position is under attack.
    */
    function pieceUnderAttack(
        uint256 gameState,
        uint8 pos
    ) public pure returns (bool) {
        // When migrating from 0.7.6 to 0.8.17 tests would fail when calling this function
        // this is why this code is left unchecked
        // should find exactly where it phantom overflows / underflows
        // hint: its where things get multiplied...

        unchecked {
            uint8 currPiece = (uint8)(gameState >> (pos * piece_bit_size)) &
                0xf;
            uint8 enemyPawn = pawn_const |
                ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyBishop = bishop_const |
                ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyKnight = knight_const |
                ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyRook = rook_const |
                ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyQueen = queen_const |
                ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyKing = king_const |
                ((currPiece & color_const) > 0 ? 0x0 : color_const);

            currPiece = 0x0;

            uint8 currPos;
            bool firstSq;
            // Check up
            firstSq = true;
            currPos = pos + 8;
            while (currPos < 0x40) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyRook ||
                        currPiece == enemyQueen ||
                        (firstSq && (currPiece == enemyKing))
                    ) return true;
                    break;
                }
                currPos += 8;
                firstSq = false;
            }

            // Check down
            firstSq = true;
            currPos = pos - 8;
            while (currPos < pos) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyRook ||
                        currPiece == enemyQueen ||
                        (firstSq && (currPiece == enemyKing))
                    ) return true;
                    break;
                }
                currPos -= 8;
                firstSq = false;
            }

            // Check right
            firstSq = true;
            currPos = pos + 1;
            while ((pos >> 3) == (currPos >> 3)) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyRook ||
                        currPiece == enemyQueen ||
                        (firstSq && (currPiece == enemyKing))
                    ) return true;
                    break;
                }
                currPos += 1;
                firstSq = false;
            }

            // Check left
            firstSq = true;
            currPos = pos - 1;
            while ((pos >> 3) == (currPos >> 3)) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyRook ||
                        currPiece == enemyQueen ||
                        (firstSq && (currPiece == enemyKing))
                    ) return true;
                    break;
                }
                currPos -= 1;
                firstSq = false;
            }

            // Check up-right
            firstSq = true;
            currPos = pos + 9;
            while ((currPos < 0x40) && ((currPos & 0x7) > (pos & 0x7))) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) &&
                                    ((enemyPawn & color_const) ==
                                        color_const))))
                    ) return true;
                    break;
                }
                currPos += 9;
                firstSq = false;
            }

            // Check up-left
            firstSq = true;
            currPos = pos + 7;
            while ((currPos < 0x40) && ((currPos & 0x7) < (pos & 0x7))) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) &&
                                    ((enemyPawn & color_const) ==
                                        color_const))))
                    ) return true;
                    break;
                }
                currPos += 7;
                firstSq = false;
            }

            // Check down-right
            firstSq = true;
            currPos = pos - 7;
            while ((currPos < 0x40) && ((currPos & 0x7) > (pos & 0x7))) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) &&
                                    ((enemyPawn & color_const) == 0x0))))
                    ) return true;
                    break;
                }
                currPos -= 7;
                firstSq = false;
            }

            // Check down-left
            firstSq = true;
            currPos = pos - 9;
            while ((currPos < 0x40) && ((currPos & 0x7) < (pos & 0x7))) {
                currPiece =
                    (uint8)(gameState >> (currPos * piece_bit_size)) &
                    0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) &&
                                    ((enemyPawn & color_const) == 0x0))))
                    ) return true;
                    break;
                }
                currPos -= 9;
                firstSq = false;
            }

            // Check knights
            // 1 right 2 up
            currPos = pos + 17;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;
            // 1 left 2 up
            currPos = pos + 15;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;
            // 2 right 1 up
            currPos = pos + 10;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;
            // 2 left 1 up
            currPos = pos + 6;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;

            // 1 left 2 down
            currPos = pos - 17;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;

            // 2 left 1 down
            currPos = pos - 10;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;

            // 1 right 2 down
            currPos = pos - 15;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;
            // 2 right 1 down
            currPos = pos - 6;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) ==
                    enemyKnight)
            ) return true;
        }

        return false;
    }

    /**
        @dev Commits a move into the game state. Validity of the move is not checked.
        @param gameState current game state
        @param fromPos is the position to move a piece from.
        @param toPos is the position to move a piece to.
        @return newGameState
    */
    function commitMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos
    ) public pure returns (uint) {
        uint8 bitpos = fromPos * piece_bit_size;
        uint8 piece = (uint8)((gameState >> bitpos) & 0xF);
        uint newGameState = gameState & ~(0xF << bitpos);

        newGameState = setPosition(newGameState, toPos, piece);

        return newGameState;
    }

    /**
        @dev Zeroes out a piece position in the current game state.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to zero out: 6-bit var, 3-bit word, high word = row, low word = column.
        @return newGameState
    */
    function zeroPosition(
        uint256 gameState,
        uint8 pos
    ) public pure returns (uint256) {
        return gameState & ~(0xF << (pos * piece_bit_size));
    }

    /**
        @dev Sets a piece position in the current game state.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to set the piece: 6-bit var, 3-bit word, high word = row, low word = column.
        @param piece to set, including color
        @return newGameState
    */
    function setPosition(
        uint256 gameState,
        uint8 pos,
        uint8 piece
    ) public pure returns (uint256 newGameState) {
        uint8 bitpos;

        unchecked {
            bitpos = pos * piece_bit_size;

            newGameState =
                (gameState & ~(0xF << bitpos)) |
                ((uint256)(piece) << bitpos);
        }

        return newGameState;
    }

    /**
        @dev Gets the piece at a given position in the current gameState.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to get the piece: 6-bit var, 3-bit word, high word = row, low word = column.
        @return piece value including color
    */
    function pieceAtPosition(
        uint256 gameState,
        uint8 pos
    ) public pure returns (uint8) {
        uint8 piece;

        unchecked {
            piece = (uint8)((gameState >> (pos * piece_bit_size)) & 0xF);
        }

        return piece;
    }
}