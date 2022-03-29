// SPDX-License-Identifier: MIT

// // File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol

pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol

pragma solidity ^0.8.0;

contract VRFRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VRF coordinator
     *
     * @dev To prevent repetition of VRF output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VRF seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce))
            );
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vRFInputSeed The seed to be passed directly to the VRF
     * @return The id for this request
     *
     * @dev Note that _vRFInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVRFInputSeed
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol

pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee)
        internal
        returns (bytes32 requestId)
    {
        LINK.transferAndCall(
            vrfCoordinator,
            _fee,
            abi.encode(_keyHash, USER_SEED_PLACEHOLDER)
        );
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            USER_SEED_PLACEHOLDER,
            address(this),
            nonces[_keyHash]
        );
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

//Lottery Contract

pragma solidity >=0.8.0 <0.9.0;

//Contract Parameters
// Create three Raffle categories
// Basic category -- $1
// Investor category -- $10
// Whale category -- $100

// Duration -- Every 2 days
// For testnet every 3 hour
// For testnet payout happens every 1 hour

// Payouts -- Automatically
// Contract gets -- 50%
// 1 Winner -- 25%
// 2 Winner -- 15%
// 3 Winner -- 10%

// let signer = ethersProvider.getSigner();
// let contract = new ethers.Contract(address, abi, signer.connectUnchecked());
// let tx = await contract.method();

// // this will return immediately with tx.hash and tx.wait property

// console.log("Transaction hash is ", tx.hash);
// let receipt = await tx.wait();

contract Raffle is
    ReentrancyGuard,
    KeeperCompatibleInterface,
    VRFConsumerBase,
    Ownable
{
    using SafeERC20 for IERC20;

    //Raffle Address = 0x153480fEbAfc1C2890aDD521364FFD4C2128F4a2

    uint256 internal currentRaffleStartTime;
    uint256 internal currentRaffleEndTime;
    uint256 internal currentRaffleRebootEndTime;

    uint256 internal raffleID;

    uint256 internal immutable raffleInterval = 1 * 1 hours;
    uint256 internal immutable resetInterval = 30 * 1 minutes;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public rebootChecker;

    uint256 public noOfWinners = 3;
    uint256 public maxNumberTicketsPerBuy = 1000;

    address public injectorAddress;
    address public treasuryAddress;

    IERC20 public USDCtoken;

    enum RaffleState {
        INACTIVE,
        WAITING_FOR_REBOOT,
        OPEN,
        PAYOUT,
        DEACTIVATED
    }

    enum RaffleCategory {
        BASIC,
        INVESTOR,
        WHALE
    }

    struct RaffleStruct {
        uint256 ID; //Raffle ID
        address[] winners; // Winner address
        uint256[] tickets; // tickets id (tickets)
        uint256 noOfTicketsSold; // Tickets sold
        uint256[] winnersPayout; // Contains the % payouts of the winners
        uint256[] winningTickets; // Contains array of winning Tickets
        uint256 noOfPlayers;
        uint256 amountInjected;
        uint256 raffleStartTime;
        uint256 raffleEndTime;
        mapping(uint256 => address) ticketOwner; //a mapping that maps the tickets to their owners
        mapping(address => uint256) userTickets; // a mapping that stores the number of tickets bought by a user
    }

    struct Transaction {
        uint256 time;
        RaffleCategory raffleCategory;
        uint256 noOfTickets;
    }

    struct RaffleData {
        uint256 ticketPrice;
        uint256 rafflePool;
        RaffleState raffleState;
    }

    //Maps Raffle category to each Raffle indexes of each Raffle, for record keeping.
    mapping(RaffleCategory => mapping(uint256 => RaffleStruct)) private raffles;
    mapping(RaffleCategory => RaffleData) private rafflesData;
    mapping(bytes32 => RaffleCategory) private bytesCategoryMapping;
    //Mapping for users that qualify for r
    mapping(RaffleCategory => mapping(address => uint256)) private rollovers;
    // Users Transaction History
    mapping(address => Transaction[]) private userTransactionHistory;

    modifier stateCheck() {
        require(rebootChecker == 3, "Reboot check not complete");
        _;
    }
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyOwnerOrInjector() {
        require(
            (msg.sender == owner()) || (msg.sender == injectorAddress),
            "Not owner or injector"
        );
        _;
    }

    modifier hasRollovers(RaffleCategory _category) {
        require(rollovers[_category][msg.sender] != 0, "You have no rollover");
        _;
    }

    modifier raffleNotValid(RaffleCategory _category) {
        RaffleStruct storage _raffle = raffles[_category][raffleID];
        require(
            _raffle.noOfTicketsSold < 10 && _raffle.noOfPlayers < 5,
            "Sorry can not deactivate a valid raffle"
        );
        _;
    }

    modifier isRaffleDeactivated(RaffleCategory _category) {
        RaffleData storage _raffleData = rafflesData[_category];
        require(
            _raffleData.raffleState == RaffleState.DEACTIVATED,
            "Sorry can activate as raffle is not deactivated"
        );
        _;
    }

    event AdminTokenRecovery(address token, uint256 amount);
    event RaffleOpen(
        uint256 indexed raffleId,
        uint256 endTime,
        uint256 rebootEndTime,
        RaffleState raffleState
    );
    event TicketsPurchased(
        RaffleCategory raffleCategory,
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 numberTickets,
        uint256 rafflePool
    );
    event RolloverClaimed(
        RaffleCategory raffleCategory,
        uint256 indexed raffleId,
        address buyer,
        uint256 noOfTickets
    );
    event RaffleEnded(
        RaffleCategory category,
        uint256 indexed raffleId,
        RaffleState raffleState
    );
    event WinnersAwarded(
        RaffleCategory raffleCategory,
        address[] winners,
        uint256 amount,
        uint256 timestamp
    );
    event LotteryInjection(
        RaffleCategory raffleCategory,
        uint256 indexed raffleId,
        uint256 injectedAmount
    );
    event NewTreasuryAndInjectorAddresses(
        address treasuryAddress,
        address injectorAddress
    );
    event NewUserTransaction(
        uint256 txIndex,
        uint256 timestamp,
        RaffleCategory raffleCategory,
        uint256 noOfTickets
    );
    event RaffleDeactivated(
        uint256 raffleID,
        uint256 timeStamp,
        RaffleState raffleState
    );
    event RaffleReactivated(
        uint256 raffleID,
        uint256 timeStamp,
        RaffleState raffleState
    );
    event WithdrawalComplete(uint256 raffleID, uint256 amount);

    // values set are for the mumbai testnet
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _USDCtoken
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        fee = _fee;
        rebootChecker = 3;
        USDCtoken = IERC20(_USDCtoken);
        setRaffleData();
    }

    // Function to be called by the chainlink keepers that start the raffle
    function startRaffle() internal stateCheck {
        //initiating raffle
        raffleID++;

        currentRaffleStartTime = block.timestamp;
        currentRaffleEndTime = currentRaffleStartTime + raffleInterval;
        currentRaffleRebootEndTime = currentRaffleEndTime + resetInterval;

        // creating raffle sessions
        RaffleCategory[3] memory categoryArray = [
            RaffleCategory.BASIC,
            RaffleCategory.INVESTOR,
            RaffleCategory.WHALE
        ];
        for (uint256 i = 0; i < categoryArray.length; i++) {
            RaffleCategory _category = categoryArray[i];
            RaffleStruct storage _raffle = raffles[_category][raffleID];
            _raffle.ID = raffleID;
            _raffle.raffleStartTime = currentRaffleStartTime;
            _raffle.raffleEndTime = currentRaffleEndTime;

            setRaffleState(categoryArray[i], RaffleState.OPEN);
        }

        rebootChecker = 0;
        emit RaffleOpen(
            raffleID,
            currentRaffleEndTime,
            currentRaffleRebootEndTime,
            RaffleState.OPEN
        );
    }

    // This function sets the raffle initial data
    function setRaffleData() internal {
        RaffleData storage _basicRaffleData = rafflesData[RaffleCategory.BASIC];
        _basicRaffleData.ticketPrice = 1 * 10**18;

        RaffleData storage _investorRaffleData = rafflesData[
            RaffleCategory.INVESTOR
        ];
        _investorRaffleData.ticketPrice = 10 * 10**18;

        RaffleData storage _whaleRaffleData = rafflesData[RaffleCategory.WHALE];
        _whaleRaffleData.ticketPrice = 100 * 10**18;
    }

    // To help monitor the flow of the contract, this function allows the contract to change the state of each raffle
    function setRaffleState(RaffleCategory _category, RaffleState _state)
        internal
    {
        RaffleData storage _raffleData = rafflesData[_category];
        _raffleData.raffleState = _state;
    }

    function getRebootEndTime() public view returns (uint256) {
        return (currentRaffleRebootEndTime);
    }

    function getRaffleEndTime() public view returns (uint256) {
        return (currentRaffleEndTime);
    }

    function getRafflePool(RaffleCategory _category)
        external
        view
        returns (uint256)
    {
        RaffleData storage _raffleData = rafflesData[_category];
        return (_raffleData.rafflePool);
    }

    function getraffleID() external view returns (uint256) {
        return raffleID;
    }

    function getCurrentRaffleState(RaffleCategory _category)
        external
        view
        returns (RaffleState raffleState)
    {
        RaffleData storage _raffleData = rafflesData[_category];
        return _raffleData.raffleState;
    }

    function viewRaffle(RaffleCategory _category, uint256 _raffleID)
        external
        view
        returns (
            address[] memory winners,
            uint256 noOfTicketsSold,
            uint256[] memory winningTickets,
            uint256 raffleStartTime,
            uint256 raffleEndTime
        )
    {
        RaffleStruct storage _raffle = raffles[_category][_raffleID];
        return (
            _raffle.winners,
            _raffle.noOfTicketsSold,
            _raffle.winningTickets,
            _raffle.raffleStartTime,
            _raffle.raffleEndTime
        );
    }

    function buyTicket(RaffleCategory _category, uint256[] memory _tickets)
        external
        notContract
        nonReentrant
    {
        require(_tickets.length != 0, "No ticket specified");
        require(_tickets.length <= maxNumberTicketsPerBuy, "Too many tickets");
        require(
            rafflesData[_category].raffleState == RaffleState.OPEN,
            "Raffle not open"
        );
        //calculate amount to transfer
        RaffleData storage _raffleData = rafflesData[_category];
        uint256 amountToTransfer = _raffleData.ticketPrice * _tickets.length;
        USDCtoken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amountToTransfer
        );

        RaffleStruct storage _raffle = raffles[_category][raffleID];
        if (_raffle.userTickets[msg.sender] == 0) {
            _raffle.noOfPlayers++;
        }
        _raffleData.rafflePool += amountToTransfer;
        storeUserTransactions(_category, _tickets.length);
        assignTickets(_category, _tickets);
        updateWinnersPayouts(_category);
        emit TicketsPurchased(
            _category,
            raffleID,
            msg.sender,
            _tickets.length,
            _raffleData.rafflePool
        );
    }

    function storeUserTransactions(
        RaffleCategory _category,
        uint256 _noOfTickets
    ) internal {
        uint256 txIndex = userTransactionHistory[msg.sender].length;
        userTransactionHistory[msg.sender].push();
        Transaction storage _transaction = userTransactionHistory[msg.sender][
            txIndex
        ];
        _transaction.time = block.timestamp;
        _transaction.raffleCategory = _category;
        _transaction.noOfTickets = _noOfTickets;
        emit NewUserTransaction(
            txIndex,
            _transaction.time,
            _transaction.raffleCategory,
            _transaction.noOfTickets
        );
    }

    function assignTickets(RaffleCategory _category, uint256[] memory _tickets)
        internal
    {
        RaffleStruct storage _raffle = raffles[_category][raffleID];
        for (uint256 n = 0; n < _tickets.length; n++) {
            _raffle.tickets.push(_tickets[n]);
            _raffle.ticketOwner[_tickets[n]] = msg.sender;
        }
        _raffle.noOfTicketsSold += _tickets.length;
    }

    function updateWinnersPayouts(RaffleCategory _category) internal {
        RaffleStruct storage _raffle = raffles[_category][raffleID];
        uint256 _rafflePool = rafflesData[_category].rafflePool;
        uint256 _25percent = (_rafflePool * 25) / 100;
        uint256 _15percent = (_rafflePool * 15) / 100;
        uint256 _10percent = (_rafflePool * 10) / 100;
        _raffle.winnersPayout = [_25percent, _15percent, _10percent];
    }

    function getUserTransactionCount() external view returns (uint256) {
        return (userTransactionHistory[msg.sender].length);
    }

    function getuserTransactionHistory(uint256 txIndex)
        external
        view
        returns (
            uint256 timestamp,
            RaffleCategory raffleCategory,
            uint256 noOfTickets
        )
    {
        Transaction storage _transaction = userTransactionHistory[msg.sender][
            txIndex
        ];
        return (
            _transaction.time,
            _transaction.raffleCategory,
            _transaction.noOfTickets
        );
    }

    function getWinningTickets(RaffleCategory _category)
        internal
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestId = requestRandomness(keyHash, fee);
        bytesCategoryMapping[requestId] = _category;
        emit RaffleEnded(_category, raffleID, RaffleState.PAYOUT);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        RaffleCategory _category = bytesCategoryMapping[requestId];
        uint256[] memory winningTickets = expand(_category, randomness);
        getWinners(_category, winningTickets);
    }

    function expand(RaffleCategory _category, uint256 randomValue)
        internal
        view
        returns (uint256[] memory winningTickets)
    {
        RaffleStruct storage _raffle = raffles[_category][raffleID];

        winningTickets = new uint256[](noOfWinners);

        for (uint256 i = 0; i < noOfWinners; i++) {
            winningTickets[i] =
                uint256(keccak256(abi.encode(randomValue, i))) %
                _raffle.noOfTicketsSold;
        }
        return winningTickets;
    }

    function getWinners(
        RaffleCategory _category,
        uint256[] memory _winningTickets
    ) internal {
        RaffleStruct storage _raffle = raffles[_category][raffleID];
        for (uint256 i = 0; i < noOfWinners; i++) {
            uint256 ticketNos = _raffle.tickets[_winningTickets[i]];
            _raffle.winners[i] = _raffle.ticketOwner[ticketNos];
        }
        setRaffleState(_category, RaffleState.PAYOUT);
    }

    function payoutWinners(RaffleCategory _category) internal {
        RaffleStruct storage _raffle = raffles[_category][raffleID];
        RaffleData storage _raffleData = rafflesData[_category];
        uint256 amountPaidOut;

        for (uint256 i = 0; i < noOfWinners; i++) {
            USDCtoken.safeTransfer(
                _raffle.winners[i],
                _raffle.winnersPayout[i]
            );
            _raffleData.rafflePool -= _raffle.winnersPayout[i];
            amountPaidOut += _raffle.winnersPayout[i];
        }

        //Send half of remaining to Treasury
        USDCtoken.safeTransfer(treasuryAddress, ((_raffleData.rafflePool) / 2));

        setRaffleState(_category, RaffleState.WAITING_FOR_REBOOT);
        rebootChecker++;
        emit WinnersAwarded(
            _category,
            _raffle.winners,
            amountPaidOut,
            block.timestamp
        );
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        RaffleCategory[3] memory categoryArray = [
            RaffleCategory.BASIC,
            RaffleCategory.INVESTOR,
            RaffleCategory.WHALE
        ];

        bool restart = false;

        if (rebootChecker == 3) {
            restart = true;
        }

        for (uint256 i = 0; i < categoryArray.length; i++) {
            RaffleCategory _category = categoryArray[i];

            RaffleStruct storage _raffle = raffles[_category][raffleID];

            RaffleData storage _raffleData = rafflesData[_category];

            if (
                (_raffleData.raffleState == RaffleState.WAITING_FOR_REBOOT) &&
                !restart
            ) {
                continue;
            }

            if (
                ((block.timestamp > currentRaffleEndTime) &&
                    (_raffleData.raffleState == RaffleState.OPEN))
            ) {
                if (_raffle.noOfTicketsSold < 10 && _raffle.noOfPlayers < 5) {
                    upkeepNeeded = true;
                    performData = abi.encode(4, _category);
                    break;
                }
                upkeepNeeded = true;
                performData = abi.encode(1, _category);
                break;
            } else if (_raffleData.raffleState == RaffleState.PAYOUT) {
                upkeepNeeded = true;
                performData = abi.encode(2, _category);
                break;
            } else if (
                !(_raffleData.raffleState == RaffleState.DEACTIVATED) &&
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
        (int256 comment, RaffleCategory _category) = abi.decode(
            performData,
            (int256, RaffleCategory)
        );
        if (comment == 1) {
            getWinningTickets(_category);
        } else if (comment == 2) {
            payoutWinners(_category);
        } else if (comment == 3) {
            startRaffle();
        } else if (comment == 4) {
            rollover(_category);
        }
    }

    function SetInjectorAndTreasuryAdresses(
        address _injectorAddress,
        address _treasuryAddress
    ) external onlyOwner {
        require(_treasuryAddress != address(0), "Cannot be zero address");
        require(_injectorAddress != address(0), "Cannot be zero address");

        treasuryAddress = _treasuryAddress;
        injectorAddress = _injectorAddress;

        emit NewTreasuryAndInjectorAddresses(
            _treasuryAddress,
            _injectorAddress
        );
    }

    function injectFunds(RaffleCategory _category, uint256 _amount)
        external
        onlyOwnerOrInjector
    {
        require(
            rafflesData[_category].raffleState == RaffleState.OPEN,
            "Raffle not open"
        );

        USDCtoken.safeTransferFrom(address(msg.sender), address(this), _amount);

        raffles[_category][raffleID].amountInjected += _amount;

        emit LotteryInjection(_category, raffleID, _amount);
    }

    function rollover(RaffleCategory _category) internal {
        RaffleStruct storage _raffle = raffles[_category][raffleID];
        if (_raffle.noOfTicketsSold > 0) {
            for (uint256 i; i < _raffle.noOfTicketsSold; i++) {
                address player = _raffle.ticketOwner[i];
                rollovers[_category][player] = _raffle.userTickets[player];
            }
        }
        setRaffleState(_category, RaffleState.WAITING_FOR_REBOOT);
        rebootChecker++;
    }

    function viewRollovers(RaffleCategory _category)
        external
        view
        returns (uint256 ticketsToRollover)
    {
        return (rollovers[_category][msg.sender]);
    }

    function claimRollover(
        RaffleCategory _category,
        uint256 _ticketsToRollover,
        uint256[] memory _tickets
    ) external notContract hasRollovers(_category) nonReentrant {
        require(
            _ticketsToRollover == rollovers[_category][msg.sender],
            "no match in tickets to rollover"
        );
        require(
            rafflesData[_category].raffleState == RaffleState.OPEN,
            "Raffle not open"
        );
        assignTickets(_category, _tickets);
        storeUserTransactions(_category, _tickets.length);
        rollovers[_category][msg.sender] = 0;

        emit RolloverClaimed(
            _category,
            raffleID,
            msg.sender,
            _ticketsToRollover
        );
    }

    function checkLinkBalance() public view returns (uint256) {
        return (LINK.balanceOf(address(this)));
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAddress != address(USDCtoken), "Cannot be USDC token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function deactivateRaffle()
        external
        onlyOwner
        raffleNotValid(RaffleCategory.BASIC)
        raffleNotValid(RaffleCategory.INVESTOR)
        raffleNotValid(RaffleCategory.WHALE)
    {
        RaffleCategory[3] memory categoryArray = [
            RaffleCategory.BASIC,
            RaffleCategory.INVESTOR,
            RaffleCategory.WHALE
        ];
        for (uint256 i = 0; i < categoryArray.length; i++) {
            RaffleCategory _category = categoryArray[i];
            setRaffleState(_category, RaffleState.DEACTIVATED);
            rollover(_category);
        }
        rebootChecker = 0;
        currentRaffleEndTime = 0;
        currentRaffleRebootEndTime = 0;

        emit RaffleDeactivated(
            raffleID,
            block.timestamp,
            RaffleState.DEACTIVATED
        );
    }

    function reactivateRaffle()
        external
        onlyOwner
        isRaffleDeactivated(RaffleCategory.BASIC)
        isRaffleDeactivated(RaffleCategory.INVESTOR)
        isRaffleDeactivated(RaffleCategory.WHALE)
    {
        RaffleCategory[3] memory categoryArray = [
            RaffleCategory.BASIC,
            RaffleCategory.INVESTOR,
            RaffleCategory.WHALE
        ];
        for (uint256 i = 0; i < categoryArray.length; i++) {
            RaffleCategory _category = categoryArray[i];
            setRaffleState(_category, RaffleState.WAITING_FOR_REBOOT);
        }
        rebootChecker = 3;

        emit RaffleReactivated(
            raffleID,
            block.timestamp,
            RaffleState.WAITING_FOR_REBOOT
        );
    }

    function withdrawFundsDueToDeactivation(RaffleCategory _category)
        external
        notContract
        isRaffleDeactivated(_category)
        nonReentrant
    {
        RaffleData storage _raffleData = rafflesData[_category];
        uint256 tickets = rollovers[_category][msg.sender];
        uint256 amount = tickets * _raffleData.ticketPrice;
        USDCtoken.transfer(msg.sender, amount);
        rollovers[_category][msg.sender] = 0;

        emit WithdrawalComplete(raffleID, amount);
    }

    /**
     * @notice Check if an address is a contract
     */

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    //Odds of Winning is increased by the number of tickets a person buys, but it does not guarantee winning,
    // as the randomness is generated randomly using the chainlink vrf and not with any existing variable in the contract

    // Users are given indexes for each ticket bought, a mapping to store the each user to a ticket id.
    // So after the raffle is drawn lucky index number for raffle is chosen and the winners are awarded
    // Since there are 3 winners raffles will be drawn thrice.
    // first winner is the first person 25%
    // second is the 2nd person 15%
    // third is the 3rd person 10%
    // This is done by using the keccak function to alter the random value gotten from the vrf request.

    //The random values gotten for each Raffle are just basically indexes which are then looked up in the user-ticket mapping

    //PHASE TWO, Using keepers to automate the payout
}