/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}




// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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



// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: NONE

pragma solidity 0.8.1;

interface IacPool {
    function setCallFee(uint256 _callFee) external;
    function totalShares() external returns (uint256);
    function totalVotesFor(uint256 proposalID) external returns (uint256);
    function setAdmin(address _admin, address _treasury) external;
    function setTreasury(address _treasury) external;
	function addAndExtendStake(address _recipientAddr, uint256 _amount, uint256 _stakeID, uint256 _lockUpTokensInSeconds) external;
    function giftDeposit(uint256 _amount, address _toAddress, uint256 _minToServeInSecs) external;
    function harvest() external;
	function calculateHarvestXVMCRewards() external view returns (uint256);
}

interface IMasterChef {
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external;
    function updateEmissionRate(uint256 _gajPerBlock) external;
    function setFeeAddress(address _feeAddress) external;
    function dev(address _devaddr) external;
    function transferOwnership(address newOwner) external;
    function XVMCPerBlock() external returns (uint256);
    function totalAllocPoint() external returns (uint256);
    function updatePool(uint256 _pid) external;
    function owner() external returns (address);
	function setGovernorFee(uint256 _amount) external;
    function pendingEgg(uint256 _pid, address _user) external view returns (uint256);
    function withdraw(uint256 _pid, uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IGovernor {
    function treasuryWallet() external view returns (address);
}


/**
 * MAITC vault
 * !!! Warning: !!! No license (copyrighted!)
 */
contract maticVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
		uint256 debt;
		uint256 feesPaid;
		address referredBy;
		uint256 lastAction;
    }

    struct PoolPayout {
        uint256 amount;
        uint256 minServe;
    }
	
	uint256 public constant maxFee = 250; // max 2.5%
	uint256 public constant maxFundingFee = 250; // max 0.025% per hour
	
    IERC20 public immutable token; // XVMC token
    
    IERC20 public immutable dummyToken; 

    IMasterChef public masterchef;  

    mapping(address => UserInfo[]) public userInfo;
    mapping(address => PoolPayout) public poolPayout; //determines the percentage received depending on withdrawal option
 
	uint256 public poolID = 11; 
	uint256 public accDtxPerShare;
    address public admin; //admin = governing contract!
    address public treasury = 0xA2e4728c89D6dCFc93dF4b2b438E49da823Fe181; // buyback & burn contract

    uint256 public defaultDirectPayout = 500; //5% if withdrawn into wallet
	
	uint256 public depositFee = 0; // 0% deposit fee
	uint256 public fundingRate = 25;// 0.025% per Hour (divided by 1M)
	
	
	uint256 public refShare1 = 5000; // 50% ; initial deposit 
	uint256 public refShare2 = 4000; // 40% ; recurring fee
	

    event Deposit(address indexed sender, uint256 amount, uint256 debt, uint256 depositFee, address referral);
    event Withdraw(address indexed sender, uint256 stakeID, uint256 harvestAmount, uint256 penalty);
    event UserSettingUpdate(address indexed user, address poolAddress, uint256 threshold, uint256 feeToPay);

    event Harvest(address indexed harvester, address indexed benficiary, uint256 stakeID, address harvestInto, uint256 harvestAmount, uint256 penalty, uint256 callFee); //harvestAmount contains the callFee
    event SelfHarvest(address indexed user, address harvestInto, uint256 harvestAmount, uint256 penalty);
	
	event CollectedFee(address ref, uint256 amount);

    /**
     * @notice Constructor
     * @param _token: DTX token contract
     * @param _dummyToken: Dummy token contract
     * @param _masterchef: MasterChef contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _token,
        IERC20 _dummyToken,
        IMasterChef _masterchef,
        address _admin,
        address _treasury
    ) {
        token = _token;
        dummyToken = _dummyToken;
        masterchef = _masterchef;
        admin = _admin;
        treasury = _treasury;

        IERC20(_dummyToken).safeApprove(address(_masterchef), type(uint256).max);
		poolPayout[0xfFB71361dD8Fc3ef0831871Ec8dd51B413ed093C].amount = 750;
        poolPayout[0xfFB71361dD8Fc3ef0831871Ec8dd51B413ed093C].minServe = 864000;

        poolPayout[0x9a9AEF66624C3fa77DaACcA9B51DE307FA09bd50].amount = 1500;
        poolPayout[0x9a9AEF66624C3fa77DaACcA9B51DE307FA09bd50].minServe = 2592000;

        poolPayout[0x1F8a5D98f1e2F10e93331D27CF22eD7985EF6a12].amount = 2500;
        poolPayout[0x1F8a5D98f1e2F10e93331D27CF22eD7985EF6a12].minServe = 5184000;

        poolPayout[0x30019481FC501aFa449781ac671103Feb0d6363C].amount = 5000;
        poolPayout[0x30019481FC501aFa449781ac671103Feb0d6363C].minServe = 8640000;

        poolPayout[0x8c96105ea574727e94d9C199c632128f1cA584cF].amount = 7000;
        poolPayout[0x8c96105ea574727e94d9C199c632128f1cA584cF].minServe = 20736000;

        poolPayout[0x605c5AA14BdBf0d50a99836e7909C631cf3C8d46].amount = 10000;
        poolPayout[0x605c5AA14BdBf0d50a99836e7909C631cf3C8d46].minServe = 31536000; 
    }
    
    /**
     * @notice Checks if the msg.sender is the admin
     */
    modifier adminOnly() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }
	
    receive() external payable {}
    fallback() external payable {}

	
    /**
     * Creates a NEW stake
     * _poolInto is the pool to harvest into(time deposit option)
	 * threshold is the amount to allow another user to harvest 
	 * fee is the amount paid to harvester
     */
    function deposit(uint256 _amount, address referral) external payable nonReentrant {
        require(msg.value == _amount && _amount > 0, "invalid amount");
        harvest();
		
		uint256 _depositFee = _amount * depositFee / 10000;
		_amount = _amount - _depositFee;

        uint256 commission = 0;
		
		if(referral != msg.sender && _depositFee > 0) {
			commission = _depositFee * refShare1 / 10000;
			payable(referral).transfer(commission);
		}
		
		payable(treasury).transfer(_depositFee - commission);
        payable(address(this)).transfer(_amount);
		
		uint256 _debt = _amount * accDtxPerShare / 1e12;

        userInfo[msg.sender].push(
                UserInfo(_amount, _debt, _depositFee, referral, block.timestamp)
            );

        emit Deposit(msg.sender, _amount, _debt, _depositFee, referral);
    }

    /**
     * Harvests into pool
     */
    function harvest() public {
		uint256 _pending = IMasterChef(masterchef).pendingEgg(poolID, address(this));
        IMasterChef(masterchef).withdraw(poolID, 0);
		accDtxPerShare+= _pending * 1e12  / address(this).balance;
    }


    /**
     * Withdraws all tokens
     */
    function withdraw(uint256 _stakeID, address _harvestInto) public nonReentrant {
        harvest();
        require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
        UserInfo storage user = userInfo[msg.sender][_stakeID];
        
        payFee(user);

		uint256 userTokens = user.amount; 

		uint256 currentAmount = userTokens * accDtxPerShare / 1e12 - user.debt;
		
		_removeStake(msg.sender, _stakeID);

        uint256 _toWithdraw;      

        if(_harvestInto == msg.sender) { 
            _toWithdraw = currentAmount * defaultDirectPayout / 10000;
            currentAmount = currentAmount - _toWithdraw;
            token.safeTransfer(msg.sender, _toWithdraw);
         } else {
            require(poolPayout[_harvestInto].amount != 0, "incorrect pool!");
            _toWithdraw = currentAmount * poolPayout[_harvestInto].amount / 10000;
            currentAmount = currentAmount - _toWithdraw;
            IacPool(_harvestInto).giftDeposit(_toWithdraw, msg.sender, poolPayout[_harvestInto].minServe);
        }
        token.safeTransfer(treasury, currentAmount); //penalty goes to governing contract
		
		emit Withdraw(msg.sender, _stakeID, _toWithdraw, currentAmount);

		payable(msg.sender).transfer(userTokens);
    } 


	function selfHarvest(uint256[] calldata _stakeID, address _harvestInto) external {
        require(_stakeID.length <= userInfo[msg.sender].length, "incorrect Stake list");
        UserInfo[] storage user = userInfo[msg.sender];
        harvest();
        uint256 _toWithdraw = 0;
        uint256 _payout = 0;
 
        for(uint256 i = 0; i<_stakeID.length; i++) {
			payFee(user[_stakeID[i]]);
            _toWithdraw+= user[_stakeID[i]].amount * accDtxPerShare / 1e12 - user[_stakeID[i]].debt;
			user[_stakeID[i]].debt = user[_stakeID[i]].amount * accDtxPerShare / 1e12;
        }

        if(_harvestInto == msg.sender) {
            _payout = _toWithdraw * defaultDirectPayout / 10000;
            token.safeTransfer(msg.sender, _payout); 
		} else {
            require(poolPayout[_harvestInto].amount != 0, "incorrect pool!");
            _payout = _toWithdraw * poolPayout[_harvestInto].amount / 10000;
            IacPool(_harvestInto).giftDeposit(_payout, msg.sender, poolPayout[_harvestInto].minServe);
		}

        uint256 _penalty = _toWithdraw - _payout;
		token.safeTransfer(treasury, _penalty); //penalty to treasury

		emit SelfHarvest(msg.sender, _harvestInto, _payout, _penalty);        
    }
	

    function viewStakeEarnings(address _user, uint256 _stakeID) external view returns (uint256) {
		UserInfo storage _stake = userInfo[_user][_stakeID];
        uint256 _pending = _stake.amount * virtualAccDtxPerShare() / 1e12 - _stake.debt;
        return _pending;
    }

    function viewUserTotalEarnings(address _user) external view returns (uint256) {
        UserInfo[] storage _stake = userInfo[_user];
        uint256 nrOfUserStakes = _stake.length;

		uint256 _totalPending = 0;
		
		for(uint256 i=0; i < nrOfUserStakes; i++) {
			_totalPending+= _stake[i].amount * virtualAccDtxPerShare() / 1e12 - _stake[i].debt;
		}
		
		return _totalPending;
    }
	//we want user deposit, we want total deposited, we want pending rewards, 
	function multiCall(address _user, uint256 _stakeID) external view returns(uint256, uint256, uint256, uint256) {
		UserInfo storage user = userInfo[_user][_stakeID];
		uint256 _pending = user.amount * virtualAccDtxPerShare() / 1e12 - user.debt;
		return(user.amount, user.feesPaid, address(this).balance, _pending);
	}

	// emergency withdraw, without caring about rewards
	function emergencyWithdraw(uint256 _stakeID) public {
		require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
		UserInfo storage user = userInfo[msg.sender][_stakeID];

        payFee(user);

		uint256 _amount = user.amount;
		
		_removeStake(msg.sender, _stakeID); //delete the stake
        emit Withdraw(msg.sender, _stakeID, 0, _amount);
		payable(msg.sender).transfer(_amount);
	}

	function emergencyWithdrawAll() external {
		uint256 _stakeID = userInfo[msg.sender].length;
		while(_stakeID > 0) {
			_stakeID--;
			emergencyWithdraw(_stakeID);
		}
	}
	
	function collectCommission(address[] calldata _beneficiary, uint256[][] calldata _stakeID) external nonReentrant {
		for(uint256 i = 0; i< _beneficiary.length; i++) {
			for(uint256 j = 0; j< _stakeID[i].length; i++) {
                UserInfo storage user = userInfo[_beneficiary[i]][j];
                payFee(user);
            }
		}
	}
	
	function collectCommissionAuto(address[] calldata _beneficiary) external nonReentrant {
		for(uint256 i = 0; i< _beneficiary.length; i++) {
			
			uint256 _nrOfStakes = getNrOfStakes(_beneficiary[i]);
			
			for(uint256 j = 0; j < _nrOfStakes; j++) {
                UserInfo storage user = userInfo[_beneficiary[i]][j];
                payFee(user);
            }
		}
		
	}
	
	function payFee(UserInfo memory user) private {
		uint256 _lastAction = user.lastAction;
        uint256 secondsSinceLastaction = block.timestamp - _lastAction;
				
		if(secondsSinceLastaction >= 3600) {
			user.lastAction = block.timestamp - (secondsSinceLastaction % 3600);
			
			uint256 commission = (block.timestamp - _lastAction) / 3600 * fundingRate / 100000;
			uint256 refEarning = 0;
			address _ref = user.referredBy;
			
			if(_ref != msg.sender) {
				refEarning = commission * refShare2 / 10000;
				payable(_ref).transfer(refEarning);
			}
			
			payable(treasury).transfer(commission - refEarning);

            user.feesPaid = user.feesPaid + commission;
			
			user.amount = user.amount - commission;
			
			emit CollectedFee(_ref, commission);
		}
	}

	// With "Virtual harvest" for external calls
	function virtualAccDtxPerShare() public view returns (uint256) {
		uint256 _pending = IMasterChef(masterchef).pendingEgg(poolID, address(this));
		return (accDtxPerShare + _pending * 1e12  / address(this).balance);
	}

    //need to set pools before launch or perhaps during contract launch
    //determines the payout depending on the pool. could set a governance process for it(determining amounts for pools)
	//allocation contract contains the decentralized proccess for updating setting, but so does the admin(governor)
    function setPoolPayout(address _poolAddress, uint256 _amount, uint256 _minServe) external {
        require(msg.sender == admin, "must be set by allocation contract or admin");
		if(_poolAddress == address(0)) {
			require(_amount <= 10000, "out of range");
			defaultDirectPayout = _amount;
		} else {
			require(_amount <= 10000, "out of range"); 
			poolPayout[_poolAddress].amount = _amount;
        	poolPayout[_poolAddress].minServe = _minServe; //mandatory lockup(else stake for 5yr, withdraw with 82% penalty and receive 18%)
		}
    }
    
    function updateSettings(uint256 _defaultDirectHarvest) external adminOnly {
        defaultDirectPayout = _defaultDirectHarvest;
    }

    /**
    *
    */
    function setAdmin() external {
        admin = IMasterChef(masterchef).owner();
    }
	
	function setTreasury(address _newTreasury) external adminOnly {
		treasury = _newTreasury;
	}
	
	function setDepositFee(uint256 _depositFee) external adminOnly {
        require(_depositFee <= maxFee, "out of limit");
		depositFee = _depositFee;
	}

    function setFundingRate(uint256 _fundingRate) external adminOnly {
        require(_fundingRate <= maxFundingFee, "out of limit");
		fundingRate = _fundingRate;
	}

    function setRefShare1(uint256 _refShare1) external adminOnly {
        require(_refShare1 <= 7500, "out of limit");
		refShare1 = _refShare1;
	}

    function setRefShare2(uint256 _refShare2) external adminOnly {
        require(_refShare2 <= 7500, "out of limit");
		refShare2 = _refShare2;
	}


    /**
     * Returns number of stakes for a user
     */
    function getNrOfStakes(address _user) public view returns (uint256) {
        return userInfo[_user].length;
    }

    /**
     * @return Returns total pending dtx rewards
     */
    function calculateTotalPendingDTXRewards() external view returns (uint256) {
        return(IMasterChef(masterchef).pendingEgg(poolID, address(this)));
    }
	

	//public lookup for UI
    function publicBalanceOf() public view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this)); 
        return token.balanceOf(address(this)) + amount; 
    }
	
	/*
	 * Unlikely, but Masterchef can be changed if needed to be used without changing pools
	 * masterchef = IMasterChef(token.owner());
	 * Must stop earning first(withdraw tokens from old chef)
	*/
	function setMasterChefAddress(IMasterChef _masterchef, uint256 _newPoolID) external adminOnly {
		masterchef = _masterchef;
		poolID = _newPoolID; //in case pool ID changes
		
		uint256 _dummyAllowance = IERC20(dummyToken).allowance(address(this), address(masterchef));
		if(_dummyAllowance == 0) {
			IERC20(dummyToken).safeApprove(address(_masterchef), type(uint256).max);
		}
	}
	
    /**
     * When contract is launched, dummyToken shall be deposited to start earning rewards
     */
    function startEarning() external adminOnly {
		IMasterChef(masterchef).deposit(poolID, dummyToken.balanceOf(address(this)));
    }
	
    /**
     * Dummy token can be withdrawn if ever needed(allows for flexibility)
     */
	function stopEarning(uint256 _withdrawAmount) external adminOnly {
		if(_withdrawAmount == 0) { 
			IMasterChef(masterchef).withdraw(poolID, dummyToken.balanceOf(address(masterchef)));
		} else {
			IMasterChef(masterchef).withdraw(poolID, _withdrawAmount);
		}
	}
	
    /**
     * Withdraws dummyToken to owner(who can burn it if needed)
     */
    function withdrawDummy(uint256 _amount) external adminOnly {	
        if(_amount == 0) { 
			dummyToken.safeTransfer(admin, dummyToken.balanceOf(address(this)));
		} else {
			dummyToken.safeTransfer(admin, _amount);
		}
    }
	
	
	/**
	 * option to withdraw wrongfully sent tokens(but requires change of the governing contract to do so)
	 * If you send wrong tokens to the contract address, consider them lost. Though there is possibility of recovery
	 */
	function withdrawStuckTokens(address _tokenAddress) external {
		require(_tokenAddress != address(token), "illegal token");
		require(_tokenAddress != address(dummyToken), "illegal token");
		require(_tokenAddress != address(0) && _tokenAddress != 0x0000000000000000000000000000000000001010, "illegal token");
		
		IERC20(_tokenAddress).safeTransfer(IGovernor(admin).treasuryWallet(), IERC20(_tokenAddress).balanceOf(address(this)));
	}
    
    /**
     * removes the stake
     */
    function _removeStake(address _staker, uint256 _stakeID) private {
        UserInfo[] storage stakes = userInfo[_staker];
        uint256 lastStakeID = stakes.length - 1;
        
        if(_stakeID != lastStakeID) {
            stakes[_stakeID] = stakes[lastStakeID];
        }
        
        stakes.pop();
    }
}