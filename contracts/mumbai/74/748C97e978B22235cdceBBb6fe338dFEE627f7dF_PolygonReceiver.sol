// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

    enum ScriptTypes {
        P2PK, // 32 bytes
        P2PKH, // 20 bytes        
        P2SH, // 20 bytes          
        P2WPKH, // 20 bytes          
        P2WSH // 32 bytes               
    }

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@teleportdao/btc-evm-bridge/contracts/types/ScriptTypesEnum.sol";

interface ICCBurnRouter {

	// Structures

    /// @notice Structure for recording cc burn requests
    /// @param amount of tokens that user wants to burn
    /// @param burntAmount that user will receive (after reducing fees from amount)
    /// @param sender Address of user who requests burning
    /// @param userScript Script hash of the user on Bitcoin
    /// @param deadline of locker for executing the request
    /// @param isTransferred True if the request has been processed
    /// @param scriptType The script type of the user
    /// @param requestIdOfLocker The index of the request for a specific locker
	struct burnRequest {
		uint amount;
		uint burntAmount;
		address sender;
		bytes userScript;
		uint deadline;
		bool isTransferred;
		ScriptTypes scriptType;
		uint requestIdOfLocker;
  	}

  	// Events

	/// @notice Emits when a burn request gets submitted
    /// @param userTargetAddress Address of the user
    /// @param userScript Script of user on Bitcoin
    /// @param scriptType Script type of the user (for bitcoin address)
    /// @param inputAmount Amount of input token (0 if input token is teleBTC)
    /// @param inputToken Address of token that will be exchanged for teleBTC (address(0) if input token is teleBTC)
	/// @param teleBTCAmount amount of teleBTC that user sent OR Amount of teleBTC after exchanging
    /// @param burntAmount that user will receive (after reducing fees)
	/// @param lockerTargetAddress Address of Locker
	/// @param requestIdOfLocker Index of request between Locker's burn requests
	/// @param deadline of Locker for executing the request (in terms of Bitcoin blocks)
  	event CCBurn(
		address indexed userTargetAddress,
		bytes userScript,
		ScriptTypes scriptType,
		uint inputAmount,
		address inputToken,
		uint teleBTCAmount, 
		uint burntAmount,
		address lockerTargetAddress,
		uint requestIdOfLocker,
		uint indexed deadline
	);

	/// @notice Emits when a burn proof is provided
    /// @param lockerTargetAddress Address of Locker
    /// @param requestIdOfLocker Index of paid request of among Locker's requests
    /// @param bitcoinTxId The hash of tx that paid a burn request
	/// @param bitcoinTxOutputIndex The output index in tx
	event PaidCCBurn(
		address indexed lockerTargetAddress,
		uint requestIdOfLocker,
		bytes32 bitcoinTxId,
		uint bitcoinTxOutputIndex
	);

	/// @notice  Emits when a locker gets slashed for withdrawing BTC without proper reason
	/// @param _lockerTargetAddress	Locker's address on the target chain
	/// @param _blockNumber	Block number of the malicious tx
	/// @param txId	Transaction ID of the malicious tx
	/// @param amount Slashed amount
	event LockerDispute(
        address _lockerTargetAddress,
		bytes lockerLockingScript,
    	uint _blockNumber,
        bytes32 txId,
		uint amount
    );

	event BurnDispute(
		address indexed userTargetAddress,
		address indexed _lockerTargetAddress,
		bytes lockerLockingScript,
		uint requestIdOfLocker
	);

	/// @notice Emits when relay address is updated
    event NewRelay(
        address oldRelay, 
        address newRelay
    );

	/// @notice Emits when treasury address is updated
    event NewTreasury(
        address oldTreasury, 
        address newTreasury
    );

	/// @notice Emits when lockers address is updated
    event NewLockers(
        address oldLockers, 
        address newLockers
    );

	/// @notice Emits when TeleBTC address is updated
    event NewTeleBTC(
        address oldTeleBTC, 
        address newTeleBTC
    );

	/// @notice Emits when transfer deadline is updated
    event NewTransferDeadline(
        uint oldTransferDeadline, 
        uint newTransferDeadline
    );

	/// @notice Emits when percentage fee is updated
    event NewProtocolPercentageFee(
        uint oldProtocolPercentageFee, 
        uint newProtocolPercentageFee
    );

	/// @notice Emits when slasher percentage fee is updated
    event NewSlasherPercentageFee(
        uint oldSlasherPercentageFee, 
        uint newSlasherPercentageFee
    );

	/// @notice Emits when bitcoin fee is updated
    event NewBitcoinFee(
        uint oldBitcoinFee, 
        uint newBitcoinFee
    );

	// Read-only functions

    function startingBlockNumber() external view returns (uint);
	
	function relay() external view returns (address);

	function lockers() external view returns (address);

	function teleBTC() external view returns (address);

	function treasury() external view returns (address);

	function transferDeadline() external view returns (uint);

	function protocolPercentageFee() external view returns (uint);

	function slasherPercentageReward() external view returns (uint);

	function bitcoinFee() external view returns (uint); // Bitcoin transaction fee

	function isTransferred(address _lockerTargetAddress, uint _index) external view returns (bool);

	function isUsedAsBurnProof(bytes32 _txId) external view returns (bool);

	// State-changing functions

	function setRelay(address _relay) external;

	function setLockers(address _lockers) external;

	function setTeleBTC(address _teleBTC) external;

	function setTreasury(address _treasury) external;

	function setTransferDeadline(uint _transferDeadline) external;

	function setProtocolPercentageFee(uint _protocolPercentageFee) external;

	function setSlasherPercentageReward(uint _slasherPercentageReward) external;

	function setBitcoinFee(uint _bitcoinFee) external;

	function ccBurn(
		uint _amount, 
		bytes calldata _userScript,
		ScriptTypes _scriptType,
		bytes calldata _lockerLockingScript
	) external returns (uint);

    function ccExchangeAndBurn(
        address _exchangeConnector,
        uint[] calldata _amounts,
        bool _isFixedToken,
        address[] calldata _path,
        uint256 _deadline, 
        bytes memory _userScript,
        ScriptTypes _scriptType,
        bytes calldata _lockerLockingScript
	) external returns (uint);

	function burnProof(
		bytes4 _version,
		bytes memory _vin,
		bytes memory _vout,
		bytes4 _locktime,
		uint256 _blockNumber,
		bytes memory _intermediateNodes,
		uint _index,
		bytes memory _lockerLockingScript,
        uint[] memory _burnReqIndexes,
        uint[] memory _voutIndexes
	) external payable returns (bool);

	function disputeBurn(
		bytes calldata _lockerLockingScript,
		uint[] memory _indices
	) external;

    function disputeLocker(
        bytes memory _lockerLockingScript,
        bytes4[] memory _versions, // [inputTxVersion, outputTxVersion]
        bytes memory _inputVin,
        bytes memory _inputVout,
        bytes memory _outputVin,
        bytes memory _outputVout,
        bytes4[] memory _locktimes, // [inputTxLocktime, outputTxLocktime]
        bytes memory _inputIntermediateNodes,
        uint[] memory _indexesAndBlockNumbers 
		// ^ [inputIndex, inputTxIndex, outputTxIndex, inputTxBlockNumber, outputTxBlockNumber]
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@teleportdao/btc-evm-bridge/contracts/types/ScriptTypesEnum.sol";

interface IPolygonReceiver {

    // Structs
    
    /// @notice Structure for recording failed requests
    /// @param user Address of user who sent request from Ethereum
	struct failedReq {
        address user;
        address exchangeConnector;
        uint[] amounts;
        bool isFixedToken; 
        address[] path;
        uint deadline;
        bytes userScript; 
        ScriptTypes scriptType; 
        bytes lockerLockingScript;
  	}

	// Events

	/// @notice Emits when a request from Ethereum received
	/// @param user Address of request sender
    /// @param token Adress of token to be exchanged for teleBTC
    /// @param amount Amount of input token
	/// @param reqData Data needed to call ccExchangeAndBurn of CcBurnRouter 
	event ExchangeAndBurnReceived(
		address user,
		address token,
		uint256 amount,
		bytes reqData
	);

	/// @notice Emits when exchange is successful
    /// @param user Address of request sender
    /// @param amount Amount of input token
    /// @param path Exchanging path from input token to teleBTC
    /// @param burntAmount Amount of teleBTC that user receives
	event ExchangeAndBurnExecuted(
        address user,
        uint amount,
        address[] path,
        uint burntAmount
	);

	/// @notice Emits when exchange failed (due to price movements, etc.)
    /// @param user Address of request sender
    /// @param amount Amount of input token
    /// @param token Address of input token that is sent back to user
	event ExchangeAndBurnFailed(
        address user,
        uint amount,
        address token
	);

	/// @notice Emits when exchange failed (due to delay in transmitting tokens)
    /// @param user Address of request sender
    /// @param amount Amount of input token
    /// @param token Address of input token
    /// @param reqIdx Id of failed request
	event TokensNotReceived(
        address user,
        uint amount,
        address token,
        uint reqIdx
	);

	/// @notice Emits when EthereumSender is updated
    event NewFxRootTunnel(
        address oldFxRootTunnel, 
        address newFxRootTunnel
    );
    
    /// @notice Emits when burn router is updated
    event NewCcBurnRouter(
        address oldCcBurnRouter, 
        address newCcBurnRouter
    );

	// Read-only functions
	
	function ccBurnRouter() external view returns (address);

	// State-changing functions

	function setCcBurnRouter(address _ccBurnRouter) external;

    function processFailedReq(uint _index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IPolygonReceiver.sol";
import "./interfaces/ICCBurnRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

contract PolygonReceiver is IPolygonReceiver, Ownable, ReentrancyGuard, FxBaseChildTunnel {

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "PolygonReceiver: zero address");
        _;
    }

    // Public variables
    address public override ccBurnRouter;
    failedReq[] public failedRequests; // Stores requests that corresponding tokens have not been received yet

    /// @notice This contract processes ExchangeAndBurn requests coming from Ethereum
    constructor(address _fxChild, address _ccBurnRouter) FxBaseChildTunnel(_fxChild) {
        setCcBurnRouter(_ccBurnRouter);
    }

    receive() external payable {}

    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice Setter for EthereumSender
    function setFxRootTunnel(
        address _fxRootTunnel
    ) external override nonZeroAddress(_fxRootTunnel) onlyOwner {
        emit NewFxRootTunnel(fxRootTunnel, _fxRootTunnel);
        fxRootTunnel = _fxRootTunnel;
    }

    /// @notice Setter for CcBurnRouter
    function setCcBurnRouter(
        address _ccBurnRouter
    ) public override nonZeroAddress(_ccBurnRouter) onlyOwner {
        emit NewCcBurnRouter(ccBurnRouter, _ccBurnRouter);
        ccBurnRouter = _ccBurnRouter;
    }

    /// @notice Processes a request that been failed before (bcz tokens have not been received)
    /// @dev First checks the balance of contract (to see if tokens been received)
    /// @param _index of failed request
    function processFailedReq(uint _index) external nonReentrant override {
        if (
            IERC20(failedRequests[_index].path[0]).balanceOf(address(this)) >= 
                failedRequests[_index].amounts[0]
        ) {
            _ccExchangeAndBurn(
                failedRequests[_index].user,
                failedRequests[_index].exchangeConnector, 
                failedRequests[_index].amounts, 
                failedRequests[_index].isFixedToken, 
                failedRequests[_index].path, 
                failedRequests[_index].deadline, 
                failedRequests[_index].userScript, 
                failedRequests[_index].scriptType, 
                failedRequests[_index].lockerLockingScript
            );

            // Deletes failed req
            delete failedRequests[_index];
        }
    }

    /// @notice Processes an ExchangeAndBurn request coming from Ethereum 
    /// @dev If exchanging was unsuccessful (due to price movements, low deadline, etc.),
    ///      sends tokens to user
    /// @param sender Address of contract that sends this request (only EthereumSender can call this function)
    /// @param data Message that sent from Ethereum
    function _processMessageFromRoot(
        uint256 /*stateId*/,
        address sender,
        bytes memory data
    ) internal nonReentrant override {
        // Checks the validity of sender
        require(sender == fxRootTunnel, "PolygonReceiver: no permit");

        // Decodes data
        (
            address user, 
            address token, 
            uint amount, 
            bytes memory reqData
        ) = abi.decode(data, (address, address, uint, bytes));
        emit ExchangeAndBurnReceived(user, token, amount, reqData);
        
        (
            address _exchangeConnector, 
            uint[] memory _amounts, 
            bool _isFixedToken, 
            address[] memory _path, 
            uint _deadline,
            bytes memory _userScript,
            ScriptTypes _scriptType,
            bytes memory _lockerLockingScript
        ) = abi.decode(reqData, (address, uint[], bool, address[], uint, bytes, ScriptTypes, bytes));
        
        // Checks that data is valid
        require(_amounts[0] == amount, "PolygonReceiver: wrong amount");
        require(_path[0] == token, "PolygonReceiver: wrong token");

        // Gives allowance to ccBurnRouter
        if (IERC20(token).balanceOf(address(this)) >= amount) {
            _ccExchangeAndBurn(
                user,
                _exchangeConnector, 
                _amounts, 
                _isFixedToken, 
                _path, 
                _deadline, 
                _userScript, 
                _scriptType, 
                _lockerLockingScript
            );
        } else { // Handles the case that request is received, but tokens have not been transferred yet
            // Stores the request
            failedReq memory _req;
            _req.user = user;
            _req.exchangeConnector = _exchangeConnector;
            _req.amounts = _amounts;
            _req.isFixedToken = _isFixedToken;
            _req.path = _path;
            _req.deadline = _deadline;
            _req.userScript = _userScript;
            _req.scriptType = _scriptType;
            _req.lockerLockingScript = _lockerLockingScript;
            failedRequests.push(_req);
            emit TokensNotReceived(user, amount, token, failedRequests.length - 1);
        }
    }

    /// @notice Calls CcBurnRouter contract for exchanging and then burning exchanged teleBTC
    /// @dev Sends tokens to user if the ExchangeAndBurn call fails
    function _ccExchangeAndBurn(
        address _user,
        address _exchangeConnector,
        uint[] memory _amounts,
        bool _isFixedToken, 
        address[] memory _path,
        uint _deadline,
        bytes memory _userScript, 
        ScriptTypes _scriptType, 
        bytes memory _lockerLockingScript
    ) internal {
        IERC20(_path[0]).approve(ccBurnRouter, _amounts[0]);
        try ICCBurnRouter(ccBurnRouter).ccExchangeAndBurn(
            _exchangeConnector, 
            _amounts, 
            _isFixedToken, 
            _path, 
            _deadline, 
            _userScript, 
            _scriptType, 
            _lockerLockingScript
        ) returns (uint burntAmount) {
            emit ExchangeAndBurnExecuted(
                _user,
                _amounts[0],
                _path,
                burntAmount
            );
        } catch {
            // Sends tokens to user if exchange fails
            IERC20(_path[0]).transfer(_user, _amounts[0]);
            emit ExchangeAndBurnFailed(
                _user,
                _amounts[0],
                _path[0]
            );
        }
    }

}