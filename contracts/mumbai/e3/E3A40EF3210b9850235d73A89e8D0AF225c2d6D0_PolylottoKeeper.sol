//SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easilly be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol

pragma solidity ^0.8.0;

contract KeeperBase {
    error OnlySimulatedBackend();

    /**
     * @notice method that allows it to be simulated via eth_call by checking that
     * the sender is the zero address.
     */
    function preventExecution() internal view {
        if (tx.origin != address(0)) {
            revert OnlySimulatedBackend();
        }
    }

    /**
     * @notice modifier that allows it to be simulated via eth_call by checking
     * that the sender is the zero address.
     */
    modifier cannotExecute() {
        preventExecution();
        _;
    }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol

pragma solidity ^0.8.0;

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

//File: contracts/Interfaces/IRandomNumberGenerator.sol

pragma solidity ^0.8.4;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from vrf
     */
    function getWinningTickets(IPolyLottoRaffle.RaffleCategory _category)
        external;

    /**
     * View latest raffle Id numbers
     */
    function viewLatestRaffleId() external view returns (uint256);
}
// File: contracts/interfaces/IPolyLottoRaffle.sol
pragma solidity ^0.8.4;

interface IPolyLottoRaffle {
    enum RaffleCategory {
        BASIC,
        INVESTOR,
        WHALE
    }

    enum RaffleState {
        INACTIVE,
        WAITING_FOR_REBOOT,
        OPEN,
        PAYOUT,
        DEACTIVATED
    }

    struct RaffleStruct {
        uint256 ID; //Raffle ID
        uint256 noOfTicketsSold; // Tickets sold
        uint256 noOfPlayers;
        uint256 amountInjected;
        uint256[] winnersPayout; // Contains the % payouts of the winners
        address[] winners;
        uint256[] winningTickets; // Contains array of winning Tickets
        uint256 raffleStartTime;
        uint256 raffleEndTime;
    }

    struct RaffleData {
        uint256 ticketPrice;
        uint256 rafflePool;
        RaffleState raffleState;
    }

    /**
     * @notice Start raffle
     * @dev only callable by keeper address
     */

    function startRaffle() external;

    /**
     * @notice Buy tickets for the current lottery
     * @param _category: Raffle Category
     * @param _tickets: array of ticket numbers between 100,000 and 999,999
     * @dev Callable by users only, not contract!
     */
    function buyTickets(RaffleCategory _category, uint32[] calldata _tickets)
        external;

    /**
     * @notice gets the Winners of the current Raffle
     * @param _category: Raffle Category
     * @param _winningTicketsIDs: ticket IDs of the winning tickets
     * @dev Callable by randomGenerator contract
     */
    function getWinners(
        RaffleCategory _category,
        uint256[] calldata _winningTicketsIDs
    ) external;

    /**
     * @notice sends out winnings to the Raffle Winners
     * @param _category: Raffle Category
     * @dev Callable by keepers contract
     */
    function payoutWinners(RaffleCategory _category) external;

    /**
     * @notice rollovers user tickets, whenever a raffle is not valid
     * @param _category: Raffle Category
     * @param _deactivated: bool to show if function was called via deactivation
     * @dev Callable by keepers contracts
     */
    function rollover(RaffleCategory _category, bool _deactivated) external;

    /**
     * @notice Claim Rollover, move ticket spots to next raffle after initial raffle where tickets were bought was deactivated or rendered invalid
     * @param _category: Raffle Category
     * @dev Callable by users only, not contract
     */
    function claimRollover(RaffleCategory _category) external;

    /**
     * @notice Deactivates Raffle, can only be called if raffle is not valid
     * @dev Callable by operator
     */
    function deactivateRaffle() external;

    /**
     * @notice Activates Raffle, can only be called if raffle has been deactivated
     * @dev Callable by operator
     */
    function reactivateRaffle() external;

    /**
     * @notice Withdraw funds from raffle, if raffle has been deactivated
     * @param _category: Raffle Category
     * @dev Callable by users only, not contract!
     */
    function withdrawFundsDueToDeactivation(RaffleCategory _category) external;

    /**
     * @notice Updates Raffle Token, for tickets purchase, refunds old tokens balance to users with rollover
     * @param _newTokenAddress: new Token Address
     * @dev Callable by operator, and can be only called once.
     */
    function updateRaffleToken(address _newTokenAddress) external;

    /**
     * @notice Send backs token balances to users with rollovers.
     * @param _category: Raffle Category
     * @dev Callable by operator, and to be used when raffleToken is to be updated
     */

    function manualRefund(RaffleCategory _category) external;

    /**
     * @notice update router supplying raffle with price of token
     * @param _dexName: Name of Decentralised Exchange with liquidity pool
     * @param _routerAddress: router address of that Exchange
     * @dev Callable by operator.
     */
    function updateRouter(string memory _dexName, address _routerAddress)
        external;

    /**
     * @notice Inject funds
     * @param _category: Raffle Cateogory
     * @param _amount: amount to inject in current Raffle Token
     * @dev Callable by operator
     */
    function injectFunds(RaffleCategory _category, uint256 _amount) external;

    /**
     * @notice View current raffle id
     */
    function getRaffleID() external returns (uint256);

    /**
     * @notice View Raffle Information
     */
    function getRaffle(RaffleCategory _category, uint256 _raffleID)
        external
        returns (RaffleStruct memory);

    /**
     * @notice View general raffle information
     */
    function getRaffleData(RaffleCategory _category)
        external
        returns (RaffleData memory);

    /**
     * @notice get number of winners
     */
    function getNoOfWinners() external returns (uint256);

    /**
     * @notice returns param that shows that all raffle categories are in sync
     */
    function getRebootChecker() external returns (uint256);

    /**
     * @notice returns the raffle end time
     */
    function getRaffleEndTime() external returns (uint256);

    /**
     * @notice returns the reboot end time
     */
    function getRebootEndTime() external returns (uint256);
}
//Keeper Contract

pragma solidity >=0.8.0 <0.9.0;

contract PolylottoKeeper is KeeperCompatibleInterface, Ownable {
    using SafeERC20 for IERC20;

    IPolyLottoRaffle public polyLotto;
    IRandomNumberGenerator public randomGenerator;
    uint256 latestRaffleId;

    constructor(address _randomGeneratorAddress, address _polylottoAddress) {
        polyLotto = IPolyLottoRaffle(_polylottoAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        IPolyLottoRaffle.RaffleCategory[3] memory categoryArray = [
            IPolyLottoRaffle.RaffleCategory.BASIC,
            IPolyLottoRaffle.RaffleCategory.INVESTOR,
            IPolyLottoRaffle.RaffleCategory.WHALE
        ];

        bool restart = false;

        uint256 rebootChecker = polyLotto.getRebootChecker();

        if (rebootChecker == 3) {
            restart = true;
        }

        for (uint256 i = 0; i < categoryArray.length; i++) {
            IPolyLottoRaffle.RaffleCategory _category = categoryArray[i];

            uint256 raffleID = polyLotto.getRaffleID();

            uint256 currentRaffleEndTime = polyLotto.getRaffleEndTime();
            uint256 currentRaffleRebootEndTime = polyLotto.getRebootEndTime();

            IPolyLottoRaffle.RaffleStruct memory _raffle = polyLotto.getRaffle(
                _category,
                raffleID
            );

            IPolyLottoRaffle.RaffleData memory _raffleData = polyLotto
                .getRaffleData(_category);

            if (
                (_raffleData.raffleState ==
                    IPolyLottoRaffle.RaffleState.WAITING_FOR_REBOOT) && !restart
            ) {
                continue;
            }

            if (
                ((block.timestamp > currentRaffleEndTime) &&
                    (_raffleData.raffleState ==
                        IPolyLottoRaffle.RaffleState.OPEN))
            ) {
                if (_raffle.noOfTicketsSold < 10 || _raffle.noOfPlayers < 5) {
                    upkeepNeeded = true;
                    performData = abi.encode(4, _category);
                    break;
                }
                upkeepNeeded = true;
                performData = abi.encode(1, _category);
                break;
            } else if (
                _raffleData.raffleState == IPolyLottoRaffle.RaffleState.PAYOUT
            ) {
                upkeepNeeded = true;
                performData = abi.encode(2, _category);
                break;
            } else if (
                !(_raffleData.raffleState ==
                    IPolyLottoRaffle.RaffleState.DEACTIVATED) &&
                (block.timestamp > currentRaffleRebootEndTime) &&
                (restart)
            ) {
                upkeepNeeded = true;
                performData = abi.encode(3, _category);
                break;
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        (int256 comment, IPolyLottoRaffle.RaffleCategory _category) = abi
            .decode(performData, (int256, IPolyLottoRaffle.RaffleCategory));
        if (comment == 1) {
            randomGenerator.getWinningTickets(_category);
        } else if (comment == 2) {
            polyLotto.payoutWinners(_category);
        } else if (comment == 3) {
            polyLotto.startRaffle();
        } else if (comment == 4) {
            polyLotto.rollover(_category, false);
        }
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice Set the address for the PolyLottoKeeper
     * @param _polylottoRaffle: address of the PancakeSwap lottery
     */
    function setPolylottoRaffle(address _polylottoRaffle) external onlyOwner {
        polyLotto = IPolyLottoRaffle(_polylottoRaffle);
    }

    /**
     * @notice Set the address for the PolyLotto Raffle
     * @param _randomGenAddress: address of the PolyLotto Raffle
     */
    function setRandomGenerator(address _randomGenAddress) external onlyOwner {
        randomGenerator = IRandomNumberGenerator(_randomGenAddress);
    }

    /**
     * @notice View latestLotteryId
     */
    function viewLatestRaffleId() external view returns (uint256) {
        return latestRaffleId;
    }
}