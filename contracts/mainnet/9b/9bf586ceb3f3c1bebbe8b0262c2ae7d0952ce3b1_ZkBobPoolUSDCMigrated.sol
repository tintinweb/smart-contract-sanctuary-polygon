// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ZkBobPool.sol";
import "./ZkBobTokenSellerMixin.sol";
import "./ZkBobUSDCPermitMixin.sol";

/**
 * @title ZkBobPoolUSDCMigrated
 * Shielded transactions pool for USDC tokens supporting USDC transfer authorizations
 */
contract ZkBobPoolUSDCMigrated is ZkBobPool, ZkBobTokenSellerMixin, ZkBobUSDCPermitMixin {
    constructor(
        uint256 __pool_id,
        address _token,
        ITransferVerifier _transfer_verifier,
        ITreeVerifier _tree_verifier,
        IBatchDepositVerifier _batch_deposit_verifier,
        address _direct_deposit_queue
    )
        ZkBobPool(
            __pool_id,
            _token,
            _transfer_verifier,
            _tree_verifier,
            _batch_deposit_verifier,
            _direct_deposit_queue,
            1,
            1_000_000_000
        )
    {}

    function migrationToUSDC() external {
        require(msg.sender == address(this), "Incorrect invoker");
        require(token == address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174), "Incorrect token");

        address bob_addr = address(0xB0B195aEFA3650A6908f15CdaC7D92F8a5791B0B);
        uint256 cur_bob_balance = IERC20(bob_addr).balanceOf(address(this));
        uint256 bob_decimals = IERC20Metadata(bob_addr).decimals();

        // uint256 prev_usdc_balance = IERC20(token).balanceOf(address(this));
        uint256 usdc_decimals = IERC20Metadata(token).decimals();

        IBobVault bobswap = IBobVault(0x25E6505297b44f4817538fB2d91b88e1cF841B54);
        bool retval = IERC20(bob_addr).approve(address(bobswap), cur_bob_balance);
        uint256 usdc_received = bobswap.sell(token, cur_bob_balance);
        require(IERC20(bob_addr).balanceOf(address(this)) == 0, "Incorrect swap");

        // uint256 usdc_received = IERC20(token).balanceOf(address(this)) - prev_usdc_balance;
        uint256 spent_on_fees = (cur_bob_balance / (10 ** (bob_decimals - usdc_decimals))) - usdc_received;

        retval = IERC20(token).transferFrom(owner(), address(this), spent_on_fees);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "../interfaces/ITransferVerifier.sol";
import "../interfaces/ITreeVerifier.sol";
import "../interfaces/IBatchDepositVerifier.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IOperatorManager.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/ITokenSeller.sol";
import "../interfaces/IZkBobDirectDepositQueue.sol";
import "../interfaces/IZkBobPool.sol";
import "../interfaces/IBobVault.sol";
import "./utils/Parameters.sol";
import "./utils/ZkBobAccounting.sol";
import "../utils/Ownable.sol";
import "../proxy/EIP1967Admin.sol";

/**
 * @title ZkBobPool
 * Shielded transactions pool
 */
abstract contract ZkBobPool is IZkBobPool, EIP1967Admin, Ownable, Parameters, ZkBobAccounting {
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_POOL_ID = 0xffffff;
    bytes4 internal constant MESSAGE_PREFIX_COMMON_V1 = 0x00000000;

    uint256 internal immutable TOKEN_DENOMINATOR;
    uint256 internal constant TOKEN_NUMERATOR = 1;

    uint256 public immutable pool_id;
    ITransferVerifier public immutable transfer_verifier;
    ITreeVerifier public immutable tree_verifier;
    IBatchDepositVerifier public immutable batch_deposit_verifier;
    address public immutable token;
    IZkBobDirectDepositQueue public immutable direct_deposit_queue;

    IOperatorManager public operatorManager;

    mapping(uint256 => uint256) public nullifiers;
    mapping(uint256 => uint256) public roots;
    bytes32 public all_messages_hash;

    mapping(address => uint256) public accumulatedFee;

    event UpdateOperatorManager(address manager);
    event WithdrawFee(address indexed operator, uint256 fee);

    event Message(uint256 indexed index, bytes32 indexed hash, bytes message);

    constructor(
        uint256 __pool_id,
        address _token,
        ITransferVerifier _transfer_verifier,
        ITreeVerifier _tree_verifier,
        IBatchDepositVerifier _batch_deposit_verifier,
        address _direct_deposit_queue,
        uint256 _denominator,
        uint256 _precision
    )
        ZkBobAccounting(_precision)
    {
        require(__pool_id <= MAX_POOL_ID, "ZkBobPool: exceeds max pool id");
        require(Address.isContract(_token), "ZkBobPool: not a contract");
        require(Address.isContract(address(_transfer_verifier)), "ZkBobPool: not a contract");
        require(Address.isContract(address(_tree_verifier)), "ZkBobPool: not a contract");
        require(Address.isContract(address(_batch_deposit_verifier)), "ZkBobPool: not a contract");
        require(Address.isContract(_direct_deposit_queue), "ZkBobPool: not a contract");
        require(TOKEN_NUMERATOR == 1 || _denominator == 1, "ZkBobPool: incorrect denominator");
        pool_id = __pool_id;
        token = _token;
        transfer_verifier = _transfer_verifier;
        tree_verifier = _tree_verifier;
        batch_deposit_verifier = _batch_deposit_verifier;
        direct_deposit_queue = IZkBobDirectDepositQueue(_direct_deposit_queue);

        TOKEN_DENOMINATOR = _denominator;
    }

    /**
     * @dev Throws if called by any account other than the current relayer operator.
     */
    modifier onlyOperator() {
        require(operatorManager.isOperator(_msgSender()), "ZkBobPool: not an operator");
        _;
    }

    /**
     * @dev Initializes pool proxy storage.
     * Callable only once and only through EIP1967Proxy constructor / upgradeToAndCall.
     * @param _root initial empty merkle tree root.
     * @param _tvlCap initial upper cap on the entire pool tvl, 18 decimals.
     * @param _dailyDepositCap initial daily limit on the sum of all deposits, 18 decimals.
     * @param _dailyWithdrawalCap initial daily limit on the sum of all withdrawals, 18 decimals.
     * @param _dailyUserDepositCap initial daily limit on the sum of all per-address deposits, 18 decimals.
     * @param _depositCap initial limit on the amount of a single deposit, 18 decimals.
     * @param _dailyUserDirectDepositCap initial daily limit on the sum of all per-address direct deposits, 18 decimals.
     * @param _directDepositCap initial limit on the amount of a single direct deposit, 18 decimals.
     */
    function initialize(
        uint256 _root,
        uint256 _tvlCap,
        uint256 _dailyDepositCap,
        uint256 _dailyWithdrawalCap,
        uint256 _dailyUserDepositCap,
        uint256 _depositCap,
        uint256 _dailyUserDirectDepositCap,
        uint256 _directDepositCap
    )
        external
    {
        require(msg.sender == address(this), "ZkBobPool: not initializer");
        require(roots[0] == 0, "ZkBobPool: already initialized");
        require(_root != 0, "ZkBobPool: zero root");
        roots[0] = _root;
        _setLimits(
            0,
            _tvlCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyWithdrawalCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyUserDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _depositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyUserDirectDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _directDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR
        );
    }

    /**
     * @dev Updates used operator manager contract.
     * Callable only by the contract owner / proxy admin.
     * @param _operatorManager new operator manager implementation.
     */
    function setOperatorManager(IOperatorManager _operatorManager) external onlyOwner {
        require(address(_operatorManager) != address(0), "ZkBobPool: manager is zero address");
        operatorManager = _operatorManager;
        emit UpdateOperatorManager(address(_operatorManager));
    }

    /**
     * @dev Tells the denominator for converting pool token into zkBOB units.
     */
    function denominator() external view returns (uint256) {
        return TOKEN_NUMERATOR == 1 ? TOKEN_DENOMINATOR : (1 << 255) | TOKEN_NUMERATOR;
    }

    /**
     * @dev Tells the current merkle tree index, which will be used for the next operation.
     * Each operation increases merkle tree size by 128, so index is equal to the total number of seen operations, multiplied by 128.
     * @return next operator merkle index.
     */
    function pool_index() external view returns (uint256) {
        return _txCount() << 7;
    }

    function _root() internal view override returns (uint256) {
        return roots[_transfer_index()];
    }

    function _pool_id() internal view override returns (uint256) {
        return pool_id;
    }

    /**
     * @dev Converts given amount of tokens into native coins sent to the provided address.
     * @param _user native coins receiver address.
     * @param _tokenAmount amount to tokens to convert.
     * @return actual converted amount, might be less than requested amount.
     */
    function _withdrawNative(address _user, uint256 _tokenAmount) internal virtual returns (uint256);

    /**
     * @dev Performs token transfer using a signed permit signature.
     * @param _user token depositor address, should correspond to the signature author.
     * @param _nullifier nullifier and permit signature salt to avoid transaction data manipulation.
     * @param _tokenAmount amount to tokens to deposit.
     */
    function _transferFromByPermit(address _user, uint256 _nullifier, int256 _tokenAmount) internal virtual;

    /**
     * @dev Perform a zkBob pool transaction.
     * Callable only by the current operator.
     * Method uses a custom ABI encoding scheme described in CustomABIDecoder.
     * Single transact() call performs either deposit, withdrawal or shielded transfer operation.
     */
    function transact() external onlyOperator {
        address user = msg.sender;
        uint256 txType = _tx_type();
        if (txType == 0) {
            user = _deposit_spender();
        } else if (txType == 2) {
            user = _memo_receiver();
        } else if (txType == 3) {
            user = _memo_permit_holder();
        }
        int256 transfer_token_delta = _transfer_token_amount();
        // For private transfers, operator can receive any fee amount. As receiving a fee is basically a withdrawal,
        // we should consider operator's tier withdrawal limits respectfully.
        // For deposits, fee transfers can be left unbounded, since they are paid from the deposits themselves,
        // not from the pool funds.
        // For withdrawals, withdrawal amount that is checked against limits for specific user is already inclusive
        // of operator's fee, thus there is no need to consider it separately.
        (,, uint256 txCount) = _recordOperation(user, transfer_token_delta);

        uint256 nullifier = _transfer_nullifier();
        {
            uint256 _pool_index = txCount << 7;

            require(nullifiers[nullifier] == 0, "ZkBobPool: doublespend detected");
            require(_transfer_index() <= _pool_index, "ZkBobPool: transfer index out of bounds");
            require(transfer_verifier.verifyProof(_transfer_pub(), _transfer_proof()), "ZkBobPool: bad transfer proof");
            require(
                tree_verifier.verifyProof(_tree_pub(roots[_pool_index]), _tree_proof()), "ZkBobPool: bad tree proof"
            );

            nullifiers[nullifier] = uint256(keccak256(abi.encodePacked(_transfer_out_commit(), _transfer_delta())));
            _pool_index += 128;
            roots[_pool_index] = _tree_root_after();
            bytes memory message = _memo_message();
            // restrict memo message prefix (items count in little endian) to be < 2**16
            require(bytes4(message) & 0x0000ffff == MESSAGE_PREFIX_COMMON_V1, "ZkBobPool: bad message prefix");
            bytes32 message_hash = keccak256(message);
            bytes32 _all_messages_hash = keccak256(abi.encodePacked(all_messages_hash, message_hash));
            all_messages_hash = _all_messages_hash;
            emit Message(_pool_index, _all_messages_hash, message);
        }

        uint256 fee = _memo_fee();
        int256 token_amount = transfer_token_delta + int256(fee);
        int256 energy_amount = _transfer_energy_amount();

        require(token_amount % int256(TOKEN_NUMERATOR) == 0, "ZkBobPool: incorrect token amount");

        if (txType == 0) {
            // Deposit
            require(transfer_token_delta > 0 && energy_amount == 0, "ZkBobPool: incorrect deposit amounts");
            IERC20(token).safeTransferFrom(
                user, address(this), uint256(token_amount) * TOKEN_DENOMINATOR / TOKEN_NUMERATOR
            );
        } else if (txType == 1) {
            // Transfer
            require(token_amount == 0 && energy_amount == 0, "ZkBobPool: incorrect transfer amounts");
        } else if (txType == 2) {
            // Withdraw
            require(token_amount <= 0 && energy_amount <= 0, "ZkBobPool: incorrect withdraw amounts");

            uint256 native_amount = _memo_native_amount() * TOKEN_DENOMINATOR / TOKEN_NUMERATOR;
            uint256 withdraw_amount = uint256(-token_amount) * TOKEN_DENOMINATOR / TOKEN_NUMERATOR;

            if (native_amount > 0) {
                withdraw_amount -= _withdrawNative(user, native_amount);
            }

            if (withdraw_amount > 0) {
                IERC20(token).safeTransfer(user, withdraw_amount);
            }

            // energy withdrawals are not yet implemented, any transaction with non-zero energy_amount will revert
            // future version of the protocol will support energy withdrawals through negative energy_amount
            if (energy_amount < 0) {
                revert("ZkBobPool: XP claiming is not yet enabled");
            }
        } else if (txType == 3) {
            // Permittable token deposit
            require(transfer_token_delta > 0 && energy_amount == 0, "ZkBobPool: incorrect deposit amounts");
            _transferFromByPermit(user, nullifier, token_amount);
        } else {
            revert("ZkBobPool: Incorrect transaction type");
        }

        if (fee > 0) {
            accumulatedFee[msg.sender] += fee;
        }
    }

    /**
     * @dev Appends a batch of direct deposits into a zkBob merkle tree.
     * Callable only by the current operator.
     * @param _root_after new merkle tree root after append.
     * @param _indices list of indices for queued pending deposits.
     * @param _out_commit out commitment for output notes serialized from direct deposits.
     * @param _batch_deposit_proof snark proof for batch deposit verifier.
     * @param _tree_proof snark proof for tree update verifier.
     */
    function appendDirectDeposits(
        uint256 _root_after,
        uint256[] calldata _indices,
        uint256 _out_commit,
        uint256[8] memory _batch_deposit_proof,
        uint256[8] memory _tree_proof
    )
        external
        onlyOperator
    {
        (uint256 total, uint256 totalFee, uint256 hashsum, bytes memory message) =
            direct_deposit_queue.collect(_indices, _out_commit);

        (,, uint256 txCount) = _recordOperation(address(0), int256(total));
        uint256 _pool_index = txCount << 7;

        // verify that _out_commit corresponds to zero output account + 16 chosen notes + 111 empty notes
        require(
            batch_deposit_verifier.verifyProof([hashsum], _batch_deposit_proof), "ZkBobPool: bad batch deposit proof"
        );

        uint256[3] memory tree_pub = [roots[_pool_index], _root_after, _out_commit];
        require(tree_verifier.verifyProof(tree_pub, _tree_proof), "ZkBobPool: bad tree proof");

        _pool_index += 128;
        roots[_pool_index] = _root_after;
        bytes32 message_hash = keccak256(message);
        bytes32 _all_messages_hash = keccak256(abi.encodePacked(all_messages_hash, message_hash));
        all_messages_hash = _all_messages_hash;

        if (totalFee > 0) {
            accumulatedFee[msg.sender] += totalFee;
        }

        emit Message(_pool_index, _all_messages_hash, message);
    }

    /**
     * @dev Records submitted direct deposit into the users limits.
     * Callable only by the direct deposit queue.
     * @param _sender direct deposit sender.
     * @param _amount direct deposit amount in zkBOB units.
     */
    function recordDirectDeposit(address _sender, uint256 _amount) external {
        require(msg.sender == address(direct_deposit_queue), "ZkBobPool: not authorized");
        _checkDirectDepositLimits(_sender, _amount);
    }

    /**
     * @dev Withdraws accumulated fee on behalf of an operator.
     * Callable only by the operator itself, or by a pre-configured operator fee receiver address.
     * @param _operator address of an operator account to withdraw fee from.
     * @param _to address of the accumulated fee tokens receiver.
     */
    function withdrawFee(address _operator, address _to) external {
        require(
            _operator == msg.sender || operatorManager.isOperatorFeeReceiver(_operator, msg.sender),
            "ZkBobPool: not authorized"
        );
        uint256 fee = accumulatedFee[_operator] * TOKEN_DENOMINATOR / TOKEN_NUMERATOR;
        require(fee > 0, "ZkBobPool: no fee to withdraw");
        IERC20(token).safeTransfer(_to, fee);
        accumulatedFee[_operator] = 0;
        emit WithdrawFee(_operator, fee);
    }

    /**
     * @dev Updates pool usage limits.
     * Callable only by the contract owner / proxy admin.
     * @param _tier pool limits tier (0-254).
     * @param _tvlCap new upper cap on the entire pool tvl, 18 decimals.
     * @param _dailyDepositCap new daily limit on the sum of all deposits, 18 decimals.
     * @param _dailyWithdrawalCap new daily limit on the sum of all withdrawals, 18 decimals.
     * @param _dailyUserDepositCap new daily limit on the sum of all per-address deposits, 18 decimals.
     * @param _depositCap new limit on the amount of a single deposit, 18 decimals.
     * @param _dailyUserDirectDepositCap new daily limit on the sum of all per-address direct deposits, 18 decimals.
     * @param _directDepositCap new limit on the amount of a single direct deposit, 18 decimals.
     */
    function setLimits(
        uint8 _tier,
        uint256 _tvlCap,
        uint256 _dailyDepositCap,
        uint256 _dailyWithdrawalCap,
        uint256 _dailyUserDepositCap,
        uint256 _depositCap,
        uint256 _dailyUserDirectDepositCap,
        uint256 _directDepositCap
    )
        external
        onlyOwner
    {
        _setLimits(
            _tier,
            _tvlCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyWithdrawalCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyUserDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _depositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _dailyUserDirectDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR,
            _directDepositCap / TOKEN_DENOMINATOR * TOKEN_NUMERATOR
        );
    }

    /**
     * @dev Resets daily limit usage for the current day.
     * Callable only by the contract owner / proxy admin.
     * @param _tier tier id to reset daily limits for.
     */
    function resetDailyLimits(uint8 _tier) external onlyOwner {
        _resetDailyLimits(_tier);
    }

    /**
     * @dev Updates users limit tiers.
     * Callable only by the contract owner / proxy admin.
     * @param _tier pool limits tier (0-255).
     * 0 is the default tier.
     * 1-254 are custom pool limit tiers, configured at runtime.
     * 255 is the special tier with zero limits, used to effectively prevent some address from accessing the pool.
     * @param _users list of user account addresses to assign a tier for.
     */
    function setUsersTier(uint8 _tier, address[] memory _users) external onlyOwner {
        _setUsersTier(_tier, _users);
    }

    /**
     * @dev Tells if caller is the contract owner.
     * Gives ownership rights to the proxy admin as well.
     * @return true, if caller is the contract owner or proxy admin.
     */
    function _isOwner() internal view override returns (bool) {
        return super._isOwner() || _admin() == _msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ZkBobPool.sol";

/**
 * @title ZkBobTokenSellerMixin
 */
abstract contract ZkBobTokenSellerMixin is ZkBobPool {
    using SafeERC20 for IERC20;

    ITokenSeller public tokenSeller;

    event UpdateTokenSeller(address seller);

    /**
     * @dev Updates token seller contract used for native coin withdrawals.
     * Callable only by the contract owner / proxy admin.
     * @param _seller new token seller contract implementation. address(0) will deactivate native withdrawals.
     */
    function setTokenSeller(address _seller) external onlyOwner {
        tokenSeller = ITokenSeller(_seller);
        emit UpdateTokenSeller(_seller);
    }

    // @inheritdoc ZkBobPool
    function _withdrawNative(address _user, uint256 _tokenAmount) internal override returns (uint256) {
        ITokenSeller seller = tokenSeller;
        if (address(seller) != address(0)) {
            IERC20(token).safeTransfer(address(seller), _tokenAmount);
            (, uint256 refunded) = seller.sellForETH(_user, _tokenAmount);
            return _tokenAmount - refunded;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../interfaces/IUSDCPermit.sol";
import "./ZkBobPool.sol";

/**
 * @title ZkBobUSDCPermitMixin
 */
abstract contract ZkBobUSDCPermitMixin is ZkBobPool {
    // @inheritdoc ZkBobPool
    function _transferFromByPermit(address _user, uint256 _nullifier, int256 _tokenAmount) internal override {
        (uint8 v, bytes32 r, bytes32 s) = _permittable_deposit_signature();
        IUSDCPermit(token).transferWithAuthorization(
            _user,
            address(this),
            uint256(_tokenAmount) * TOKEN_DENOMINATOR / TOKEN_NUMERATOR,
            0,
            _memo_permit_deadline(),
            bytes32(_nullifier),
            v,
            r,
            s
        );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITransferVerifier {
    function verifyProof(uint256[5] memory input, uint256[8] memory p) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITreeVerifier {
    function verifyProof(uint256[3] memory input, uint256[8] memory p) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IBatchDepositVerifier {
    function verifyProof(uint256[1] memory input, uint256[8] memory p) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IOperatorManager {
    function isOperator(address _addr) external view returns (bool);

    function isOperatorFeeReceiver(address _operator, address _addr) external view returns (bool);

    function operatorURI() external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function SALTED_PERMIT_TYPEHASH() external view returns (bytes32);

    function receiveWithPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;

    function receiveWithSaltedPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface ITokenSeller {
    /**
     * @dev Sells tokens for ETH.
     * Prior to calling this function, contract balance of token0 should be greater than or equal to the sold amount.
     * @param _receiver native ETH receiver.
     * @param _amount amount of tokens to sell.
     * @return (received eth amount, refunded token amount).
     */
    function sellForETH(address _receiver, uint256 _amount) external returns (uint256, uint256);

    /**
     * @dev Estimates amount of received ETH, when selling given amount of tokens via sellForETH function.
     * @param _amount amount of tokens to sell.
     * @return received eth amount.
     */
    function quoteSellForETH(uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IZkBobDirectDepositQueue {
    /**
     * @dev Collects aggregated info about submitted direct deposits and marks them as completed.
     * Callable only by the zkBOB pool contract.
     * @param _indices list of direct deposit indices to process, max of 16 indices are allowed.
     * @param _out_commit pre-calculated out commitment associated with the given deposits.
     * @return total sum of deposit amounts, not counting fees.
     * @return totalFee sum of deposit fees.
     * @return hashsum hashsum over all retrieved direct deposits.
     * @return message memo message to record into the tree.
     */
    function collect(
        uint256[] calldata _indices,
        uint256 _out_commit
    )
        external
        returns (uint256 total, uint256 totalFee, uint256 hashsum, bytes memory message);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IZkBobPool {
    function pool_id() external view returns (uint256);

    function recordDirectDeposit(address _sender, uint256 _amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IBobVault {
    function buy(address _token, uint256 _amount) external returns (uint256);
    function sell(address _token, uint256 _amount) external returns (uint256);
    function swap(address _inToken, address _outToken, uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./CustomABIDecoder.sol";

abstract contract Parameters is CustomABIDecoder {
    uint256 constant R = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    bytes32 constant S_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function _root() internal view virtual returns (uint256);
    function _pool_id() internal view virtual returns (uint256);

    function _transfer_pub() internal view returns (uint256[5] memory r) {
        r[0] = _root();
        r[1] = _transfer_nullifier();
        r[2] = _transfer_out_commit();
        r[3] = _transfer_delta() + (_pool_id() << (transfer_delta_size * 8));
        r[4] = uint256(keccak256(_memo_data())) % R;
    }

    function _tree_pub(uint256 _root_before) internal view returns (uint256[3] memory r) {
        r[0] = _root_before;
        r[1] = _tree_root_after();
        r[2] = _transfer_out_commit();
    }

    // NOTE only valid in the context of normal deposit (tx_type=0)
    function _deposit_spender() internal pure returns (address) {
        (bytes32 r, bytes32 vs) = _sign_r_vs();
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes32(_transfer_nullifier())), r, vs);
    }

    // NOTE only valid in the context of permittable token deposit (tx_type=3)
    function _permittable_deposit_signature() internal pure returns (uint8, bytes32, bytes32) {
        (bytes32 r, bytes32 vs) = _sign_r_vs();
        return (uint8((uint256(vs) >> 255) + 27), r, vs & S_MASK);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../../interfaces/IKycProvidersManager.sol";
import "./KycProvidersManagerStorage.sol";

/**
 * @title ZkBobAccounting
 * @dev On chain accounting for zkBob operations, limits and stats.
 * Units: 1 BOB = 1e18 wei = 1e9 zkBOB units
 * Limitations: Contract will only work correctly as long as pool tvl does not exceed 4.7e12 BOB (4.7 trillion)
 * and overall transaction count does not exceed 4.3e9 (4.3 billion). Pool usage limits cannot exceed 4.3e9 BOB (4.3 billion) per day.
 */
contract ZkBobAccounting is KycProvidersManagerStorage {
    uint256 internal constant SLOT_DURATION = 1 hours;
    uint256 internal constant DAY_SLOTS = 1 days / SLOT_DURATION;
    uint256 internal constant WEEK_SLOTS = 1 weeks / SLOT_DURATION;

    uint256 internal immutable PRECISION;

    struct Slot0 {
        // max seen average tvl over period of at least 1 week (granularity of 1e9), might not be precise
        // max possible tvl - type(uint56).max * 1e9 zkBOB units ~= 7.2e16 BOB
        uint56 maxWeeklyAvgTvl;
        // max number of pool interactions over 1 week, might not be precise
        // max possible tx count - type(uint32).max ~= 4.3e9 transactions
        uint32 maxWeeklyTxCount;
        // 1 week behind snapshot time slot (granularity of 1 hour)
        // max possible timestamp - Dec 08 3883
        uint24 tailSlot;
        // active snapshot time slot (granularity of 1 hour)
        // max possible timestamp - Dec 08 3883
        uint24 headSlot;
        // cumulative sum of tvl over txCount interactions (granularity of 1e9)
        // max possible cumulative tvl ~= type(uint32).max * type(uint56).max = 4.3e9 transactions * 7.2e16 BOB
        uint88 cumTvl;
        // number of successful pool interactions since launch
        // max possible tx count - type(uint32).max ~= 4.3e9 transactions
        uint32 txCount;
    }

    struct Slot1 {
        // current pool tvl (granularity of 1)
        // max possible tvl - type(uint72).max * 1 zkBOB units ~= 4.7e21 zkBOB units ~= 4.7e12 BOB
        uint72 tvl;
    }

    struct Tier {
        TierLimits limits;
        TierStats stats;
    }

    struct TierLimits {
        // max cap on the entire pool tvl (granularity of 1e9)
        // max possible cap - type(uint56).max * 1e9 zkBOB units ~= 7.2e16 BOB
        uint56 tvlCap;
        // max cap on the daily deposits sum (granularity of 1e9)
        // max possible cap - type(uint32).max * 1e9 zkBOB units ~= 4.3e9 BOB
        uint32 dailyDepositCap;
        // max cap on the daily withdrawal sum (granularity of 1e9)
        // max possible cap - type(uint32).max * 1e9 zkBOB units ~= 4.3e9 BOB
        uint32 dailyWithdrawalCap;
        // max cap on the daily deposits sum for single user (granularity of 1e9)
        // max possible cap - type(uint32).max * 1e9 zkBOB units ~= 4.3e9 BOB
        uint32 dailyUserDepositCap;
        // max cap on a single deposit (granularity of 1e9)
        // max possible cap - type(uint32).max * 1e9 zkBOB units ~= 4.3e9 BOB
        uint32 depositCap;
        // max cap on a single direct deposit (granularity of 1e9)
        // max possible cap - type(uint32).max * 1e9 zkBOB units ~= 4.3e9 BOB
        uint32 directDepositCap;
        // max cap on the daily direct deposits sum for single user (granularity of 1e9)
        // max possible cap - type(uint32).max * 1e9 zkBOB units ~= 4.3e9 BOB
        uint32 dailyUserDirectDepositCap;
    }

    struct TierStats {
        uint16 day; // last update day number
        uint72 dailyDeposit; // sum of all deposits during given day
        uint72 dailyWithdrawal; // sum of all withdrawals during given day
    }

    struct Snapshot {
        uint24 nextSlot; // next slot to from the queue
        uint32 txCount; // number of successful pool interactions since launch at the time of the snapshot
        uint88 cumTvl; // cumulative sum of tvl over txCount interactions (granularity of 1e9)
    }

    struct UserStats {
        uint16 day; // last update day number
        uint72 dailyDeposit; // sum of user deposits during given day
        uint8 tier; // user limits tier, 0 being the default tier
        uint72 dailyDirectDeposit; // sum of user direct deposits during given day
    }

    struct Limits {
        uint256 tvlCap;
        uint256 tvl;
        uint256 dailyDepositCap;
        uint256 dailyDepositCapUsage;
        uint256 dailyWithdrawalCap;
        uint256 dailyWithdrawalCapUsage;
        uint256 dailyUserDepositCap;
        uint256 dailyUserDepositCapUsage;
        uint256 depositCap;
        uint8 tier;
        uint256 dailyUserDirectDepositCap;
        uint256 dailyUserDirectDepositCapUsage;
        uint256 directDepositCap;
    }

    Slot0 private slot0;
    Slot1 private slot1;
    mapping(uint256 => Tier) private tiers; // pool limits and usage per tier
    mapping(uint256 => Snapshot) private snapshots; // single linked list of hourly snapshots
    mapping(address => UserStats) private userStats;

    event UpdateLimits(uint8 indexed tier, TierLimits limits);
    event UpdateTier(address user, uint8 tier);

    constructor(uint256 _precision) {
        PRECISION = _precision;
    }

    /**
     * @dev Returns currently configured limits and remaining quotas for the given user as of the current block.
     * @param _user user for which to retrieve limits.
     * @return limits (denominated in zkBOB units = 1e-9 BOB)
     */
    function getLimitsFor(address _user) external view returns (Limits memory) {
        Slot1 memory s1 = slot1;
        UserStats memory us = userStats[_user];
        uint8 tier = _adjustConfiguredTierForUser(_user, us.tier);
        Tier storage t = tiers[tier];
        TierLimits memory tl = t.limits;
        TierStats memory ts = t.stats;
        uint24 curSlot = uint24(block.timestamp / SLOT_DURATION);
        uint24 today = curSlot / uint24(DAY_SLOTS);
        return Limits({
            tvlCap: tl.tvlCap * PRECISION,
            tvl: s1.tvl,
            dailyDepositCap: tl.dailyDepositCap * PRECISION,
            dailyDepositCapUsage: (ts.day == today) ? ts.dailyDeposit : 0,
            dailyWithdrawalCap: tl.dailyWithdrawalCap * PRECISION,
            dailyWithdrawalCapUsage: (ts.day == today) ? ts.dailyWithdrawal : 0,
            dailyUserDepositCap: tl.dailyUserDepositCap * PRECISION,
            dailyUserDepositCapUsage: (us.day == today) ? us.dailyDeposit : 0,
            depositCap: tl.depositCap * PRECISION,
            tier: tier,
            dailyUserDirectDepositCap: tl.dailyUserDirectDepositCap * PRECISION,
            dailyUserDirectDepositCapUsage: (us.day == today) ? us.dailyDirectDeposit : 0,
            directDepositCap: tl.directDepositCap * PRECISION
        });
    }

    function _recordOperation(
        address _user,
        int256 _txAmount
    )
        internal
        returns (uint56 maxWeeklyAvgTvl, uint32 maxWeeklyTxCount, uint256 txCount)
    {
        Slot0 memory s0 = slot0;
        Slot1 memory s1 = slot1;
        uint24 curSlot = uint24(block.timestamp / SLOT_DURATION);
        txCount = uint256(s0.txCount);

        // for full correctness, next line should use "while" instead of "if"
        // however, in order to keep constant gas usage, "if" is being used
        // this can lead to a longer sliding window (> 1 week) in some cases,
        // but eventually it will converge back to the 1 week target
        if (s0.txCount > 0 && curSlot - s0.tailSlot > WEEK_SLOTS) {
            // if tail is more than 1 week behind, we move tail pointer to the next snapshot
            Snapshot memory sn = snapshots[s0.tailSlot];
            delete snapshots[s0.tailSlot];
            s0.tailSlot = sn.nextSlot;
            uint32 weeklyTxCount = s0.txCount - sn.txCount;
            if (weeklyTxCount > s0.maxWeeklyTxCount) {
                s0.maxWeeklyTxCount = weeklyTxCount;
            }
            uint56 avgTvl = uint56((s0.cumTvl - sn.cumTvl) / weeklyTxCount);
            if (avgTvl > s0.maxWeeklyAvgTvl) {
                s0.maxWeeklyAvgTvl = avgTvl;
            }
        }

        if (s0.headSlot < curSlot) {
            snapshots[s0.headSlot] = Snapshot(curSlot, s0.txCount, s0.cumTvl);
            s0.headSlot = curSlot;
        }

        // update head stats
        s0.cumTvl += s1.tvl / uint72(PRECISION);
        s0.txCount++;

        if (_txAmount != 0) {
            _processTVLChange(s1, _user, _txAmount);
        }

        slot0 = s0;
        return (s0.maxWeeklyAvgTvl, s0.maxWeeklyTxCount, txCount);
    }

    function _processTVLChange(Slot1 memory s1, address _user, int256 _txAmount) internal {
        // short path for direct deposits batch processing
        if (_user == address(0) && _txAmount > 0) {
            slot1.tvl += uint72(uint256(_txAmount));

            return;
        }

        uint16 curDay = uint16(block.timestamp / SLOT_DURATION / DAY_SLOTS);

        UserStats memory us = userStats[_user];
        Tier storage t = tiers[_adjustConfiguredTierForUser(_user, us.tier)];
        TierLimits memory tl = t.limits;
        TierStats memory ts = t.stats;

        if (_txAmount > 0) {
            uint256 depositAmount = uint256(_txAmount);
            s1.tvl += uint72(depositAmount);

            // check all sorts of limits when processing a deposit
            require(depositAmount <= uint256(tl.depositCap) * PRECISION, "ZkBobAccounting: single deposit cap exceeded");
            require(uint256(s1.tvl) <= uint256(tl.tvlCap) * PRECISION, "ZkBobAccounting: tvl cap exceeded");

            if (curDay > us.day) {
                // user snapshot is outdated, day number and daily sum could be reset
                // original user's tier (0) is preserved
                userStats[_user] =
                    UserStats({day: curDay, dailyDeposit: uint72(depositAmount), tier: us.tier, dailyDirectDeposit: 0});
            } else {
                us.dailyDeposit += uint72(depositAmount);
                require(
                    uint256(us.dailyDeposit) <= uint256(tl.dailyUserDepositCap) * PRECISION,
                    "ZkBobAccounting: daily user deposit cap exceeded"
                );
                userStats[_user] = us;
            }

            if (curDay > ts.day) {
                // latest deposit was on an earlier day, reset daily withdrawal sum
                ts = TierStats({day: curDay, dailyDeposit: uint72(depositAmount), dailyWithdrawal: 0});
            } else {
                ts.dailyDeposit += uint72(depositAmount);
                require(
                    uint256(ts.dailyDeposit) <= uint256(tl.dailyDepositCap) * PRECISION,
                    "ZkBobAccounting: daily deposit cap exceeded"
                );
            }
        } else {
            uint256 withdrawAmount = uint256(-_txAmount);
            require(withdrawAmount <= type(uint32).max * PRECISION, "ZkBobAccounting: withdrawal amount too large");
            s1.tvl -= uint72(withdrawAmount);

            if (curDay > ts.day) {
                // latest withdrawal was on an earlier day, reset daily deposit sum
                ts = TierStats({day: curDay, dailyDeposit: 0, dailyWithdrawal: uint72(withdrawAmount)});
            } else {
                ts.dailyWithdrawal += uint72(withdrawAmount);
                require(
                    uint256(ts.dailyWithdrawal) <= uint256(tl.dailyWithdrawalCap) * PRECISION,
                    "ZkBobAccounting: daily withdrawal cap exceeded"
                );
            }
        }

        slot1 = s1;
        t.stats = ts;
    }

    function _checkDirectDepositLimits(address _user, uint256 _amount) internal {
        uint16 curDay = uint16(block.timestamp / SLOT_DURATION / DAY_SLOTS);

        UserStats memory us = userStats[_user];
        TierLimits memory tl = tiers[_adjustConfiguredTierForUser(_user, us.tier)].limits;

        // check all sorts of limits when processing a deposit
        require(
            _amount <= uint256(tl.directDepositCap) * PRECISION, "ZkBobAccounting: single direct deposit cap exceeded"
        );

        if (curDay > us.day) {
            // user snapshot is outdated, day number and daily sum could be reset
            // original user's tier (0) is preserved
            us = UserStats({day: curDay, dailyDeposit: 0, tier: us.tier, dailyDirectDeposit: uint72(_amount)});
        } else {
            us.dailyDirectDeposit += uint72(_amount);
            require(
                uint256(us.dailyDirectDeposit) <= uint256(tl.dailyUserDirectDepositCap) * PRECISION,
                "ZkBobAccounting: daily user direct deposit cap exceeded"
            );
        }
        userStats[_user] = us;
    }

    function _resetDailyLimits(uint8 _tier) internal {
        delete tiers[_tier].stats;
    }

    function _setLimits(
        uint8 _tier,
        uint256 _tvlCap,
        uint256 _dailyDepositCap,
        uint256 _dailyWithdrawalCap,
        uint256 _dailyUserDepositCap,
        uint256 _depositCap,
        uint256 _dailyUserDirectDepositCap,
        uint256 _directDepositCap
    )
        internal
    {
        require(_tier < 255, "ZkBobAccounting: invalid limit tier");
        require(_depositCap > 0, "ZkBobAccounting: zero deposit cap");
        require(_tvlCap <= type(uint56).max * PRECISION, "ZkBobAccounting: tvl cap too large");
        require(_dailyDepositCap <= type(uint32).max * PRECISION, "ZkBobAccounting: daily deposit cap too large");
        require(_dailyWithdrawalCap <= type(uint32).max * PRECISION, "ZkBobAccounting: daily withdrawal cap too large");
        require(_dailyUserDepositCap >= _depositCap, "ZkBobAccounting: daily user deposit cap too low");
        require(_dailyDepositCap >= _dailyUserDepositCap, "ZkBobAccounting: daily deposit cap too low");
        require(_tvlCap >= _dailyDepositCap, "ZkBobAccounting: tvl cap too low");
        require(_dailyWithdrawalCap > 0, "ZkBobAccounting: zero daily withdrawal cap");
        require(
            _dailyUserDirectDepositCap >= _directDepositCap, "ZkBobAccounting: daily user direct deposit cap too low"
        );
        TierLimits memory tl = TierLimits({
            tvlCap: uint56(_tvlCap / PRECISION),
            dailyDepositCap: uint32(_dailyDepositCap / PRECISION),
            dailyWithdrawalCap: uint32(_dailyWithdrawalCap / PRECISION),
            dailyUserDepositCap: uint32(_dailyUserDepositCap / PRECISION),
            depositCap: uint32(_depositCap / PRECISION),
            dailyUserDirectDepositCap: uint32(_dailyUserDirectDepositCap / PRECISION),
            directDepositCap: uint32(_directDepositCap / PRECISION)
        });
        tiers[_tier].limits = tl;
        emit UpdateLimits(_tier, tl);
    }

    // Tier is set as per the KYC Providers Manager recommendation only in the case if no
    // specific tier assigned to the user
    function _adjustConfiguredTierForUser(address _user, uint8 _configuredTier) internal view returns (uint8) {
        IKycProvidersManager kycProvidersMgr = kycProvidersManager();
        if (_configuredTier == 0 && address(kycProvidersMgr) != address(0)) {
            (bool kycPassed, uint8 tier) = kycProvidersMgr.getIfKYCpassedAndTier(_user);
            if (kycPassed && tiers[tier].limits.tvlCap > 0) {
                return tier;
            }
        }
        return _configuredTier;
    }

    function _setUsersTier(uint8 _tier, address[] memory _users) internal {
        require(
            _tier == 255 || tiers[uint256(_tier)].limits.tvlCap > 0, "ZkBobAccounting: non-existing pool limits tier"
        );
        for (uint256 i = 0; i < _users.length; ++i) {
            address user = _users[i];
            userStats[user].tier = _tier;
            emit UpdateTier(user, _tier);
        }
    }

    function _txCount() internal view returns (uint256) {
        return slot0.txCount;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol" as OZOwnable;

/**
 * @title Ownable
 */
contract Ownable is OZOwnable.Ownable {
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view override {
        require(_isOwner(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Tells if caller is the contract owner.
     * @return true, if caller is the contract owner.
     */
    function _isOwner() internal view virtual returns (bool) {
        return owner() == _msgSender();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

/**
 * @title EIP1967Admin
 * @dev Upgradeable proxy pattern implementation according to minimalistic EIP1967.
 */
contract EIP1967Admin {
    // EIP 1967
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    uint256 internal constant EIP1967_ADMIN_STORAGE = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    modifier onlyAdmin() {
        require(msg.sender == _admin(), "EIP1967Admin: not an admin");
        _;
    }

    function _admin() internal view returns (address res) {
        assembly {
            res := sload(EIP1967_ADMIN_STORAGE)
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IUSDCPermit {
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
}

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract CustomABIDecoder {
    uint256 constant transfer_nullifier_pos = 4;
    uint256 constant transfer_nullifier_size = 32;
    uint256 constant uint256_size = 32;

    function _loaduint256(uint256 pos) internal pure returns (uint256 r) {
        assembly {
            r := calldataload(pos)
        }
    }

    function _transfer_nullifier() internal pure returns (uint256 r) {
        r = _loaduint256(transfer_nullifier_pos);
    }

    uint256 constant transfer_out_commit_pos = transfer_nullifier_pos + transfer_nullifier_size;
    uint256 constant transfer_out_commit_size = 32;

    function _transfer_out_commit() internal pure returns (uint256 r) {
        r = _loaduint256(transfer_out_commit_pos);
    }

    uint256 constant transfer_index_pos = transfer_out_commit_pos + transfer_out_commit_size;
    uint256 constant transfer_index_size = 6;

    function _transfer_index() internal pure returns (uint48 r) {
        r = uint48(_loaduint256(transfer_index_pos + transfer_index_size - uint256_size));
    }

    uint256 constant transfer_energy_amount_pos = transfer_index_pos + transfer_index_size;
    uint256 constant transfer_energy_amount_size = 14;

    function _transfer_energy_amount() internal pure returns (int112 r) {
        r = int112(uint112(_loaduint256(transfer_energy_amount_pos + transfer_energy_amount_size - uint256_size)));
    }

    uint256 constant transfer_token_amount_pos = transfer_energy_amount_pos + transfer_energy_amount_size;
    uint256 constant transfer_token_amount_size = 8;

    function _transfer_token_amount() internal pure returns (int64 r) {
        r = int64(uint64(_loaduint256(transfer_token_amount_pos + transfer_token_amount_size - uint256_size)));
    }

    uint256 constant transfer_proof_pos = transfer_token_amount_pos + transfer_token_amount_size;
    uint256 constant transfer_proof_size = 256;

    function _transfer_proof() internal pure returns (uint256[8] calldata r) {
        uint256 pos = transfer_proof_pos;
        assembly {
            r := pos
        }
    }

    uint256 constant tree_root_after_pos = transfer_proof_pos + transfer_proof_size;
    uint256 constant tree_root_after_size = 32;

    function _tree_root_after() internal pure returns (uint256 r) {
        r = _loaduint256(tree_root_after_pos);
    }

    uint256 constant tree_proof_pos = tree_root_after_pos + tree_root_after_size;
    uint256 constant tree_proof_size = 256;

    function _tree_proof() internal pure returns (uint256[8] calldata r) {
        uint256 pos = tree_proof_pos;
        assembly {
            r := pos
        }
    }

    uint256 constant tx_type_pos = tree_proof_pos + tree_proof_size;
    uint256 constant tx_type_size = 2;
    uint256 constant tx_type_mask = (1 << (tx_type_size * 8)) - 1;

    function _tx_type() internal pure returns (uint256 r) {
        r = _loaduint256(tx_type_pos + tx_type_size - uint256_size) & tx_type_mask;
    }

    uint256 constant memo_data_size_pos = tx_type_pos + tx_type_size;
    uint256 constant memo_data_size_size = 2;
    uint256 constant memo_data_size_mask = (1 << (memo_data_size_size * 8)) - 1;

    uint256 constant memo_data_pos = memo_data_size_pos + memo_data_size_size;

    function _memo_data_size() internal pure returns (uint256 r) {
        r = _loaduint256(memo_data_size_pos + memo_data_size_size - uint256_size) & memo_data_size_mask;
    }

    function _memo_data() internal pure returns (bytes calldata r) {
        uint256 offset = memo_data_pos;
        uint256 length = _memo_data_size();
        assembly {
            r.offset := offset
            r.length := length
        }
    }

    function _sign_r_vs_pos() internal pure returns (uint256) {
        return memo_data_pos + _memo_data_size();
    }

    uint256 constant sign_r_vs_size = 64;

    function _sign_r_vs() internal pure returns (bytes32 r, bytes32 vs) {
        uint256 offset = _sign_r_vs_pos();
        assembly {
            r := calldataload(offset)
            vs := calldataload(add(offset, 32))
        }
    }

    uint256 constant transfer_delta_size =
        transfer_index_size + transfer_energy_amount_size + transfer_token_amount_size;
    uint256 constant transfer_delta_mask = (1 << (transfer_delta_size * 8)) - 1;

    function _transfer_delta() internal pure returns (uint256 r) {
        r = _loaduint256(transfer_index_pos + transfer_delta_size - uint256_size) & transfer_delta_mask;
    }

    function _memo_fixed_size() internal pure returns (uint256 r) {
        uint256 t = _tx_type();
        if (t == 0 || t == 1) {
            // fee
            // 8
            r = 8;
        } else if (t == 2) {
            // fee + native amount + recipient
            // 8 + 8 + 20
            r = 36;
        } else if (t == 3) {
            // fee + deadline + address
            // 8 + 8 + 20
            r = 36;
        } else {
            revert();
        }
    }

    function _memo_message() internal pure returns (bytes calldata r) {
        uint256 memo_fixed_size = _memo_fixed_size();
        uint256 offset = memo_data_pos + memo_fixed_size;
        uint256 length = _memo_data_size() - memo_fixed_size;
        assembly {
            r.offset := offset
            r.length := length
        }
    }

    uint256 constant memo_fee_pos = memo_data_pos;
    uint256 constant memo_fee_size = 8;
    uint256 constant memo_fee_mask = (1 << (memo_fee_size * 8)) - 1;

    function _memo_fee() internal pure returns (uint256 r) {
        r = _loaduint256(memo_fee_pos + memo_fee_size - uint256_size) & memo_fee_mask;
    }

    // Withdraw specific data

    uint256 constant memo_native_amount_pos = memo_fee_pos + memo_fee_size;
    uint256 constant memo_native_amount_size = 8;
    uint256 constant memo_native_amount_mask = (1 << (memo_native_amount_size * 8)) - 1;

    function _memo_native_amount() internal pure returns (uint256 r) {
        r = _loaduint256(memo_native_amount_pos + memo_native_amount_size - uint256_size) & memo_native_amount_mask;
    }

    uint256 constant memo_receiver_pos = memo_native_amount_pos + memo_native_amount_size;
    uint256 constant memo_receiver_size = 20;

    function _memo_receiver() internal pure returns (address r) {
        r = address(uint160(_loaduint256(memo_receiver_pos + memo_receiver_size - uint256_size)));
    }

    // Permittable token deposit specific data

    uint256 constant memo_permit_deadline_pos = memo_fee_pos + memo_fee_size;
    uint256 constant memo_permit_deadline_size = 8;

    function _memo_permit_deadline() internal pure returns (uint64 r) {
        r = uint64(_loaduint256(memo_permit_deadline_pos + memo_permit_deadline_size - uint256_size));
    }

    uint256 constant memo_permit_holder_pos = memo_permit_deadline_pos + memo_permit_deadline_size;
    uint256 constant memo_permit_holder_size = 20;

    function _memo_permit_holder() internal pure returns (address r) {
        r = address(uint160(_loaduint256(memo_permit_holder_pos + memo_permit_holder_size - uint256_size)));
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IKycProvidersManager {
    function getIfKYCpassedAndTier(address _user) external view returns (bool, uint8);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/IKycProvidersManager.sol";
import "../../utils/Ownable.sol";

contract KycProvidersManagerStorage is Ownable {
    // In order to avoid shifting storage slots by defining a new variable in
    // the contract, KYC Providers Manager will be accessed through specifying
    // a free slot explicitly. Similar approach is used in EIP1967.
    //
    // bytes32(uint256(keccak256('zkBob.ZkBobAccounting.kycProvidersManager')) - 1)
    uint256 internal constant KYC_PROVIDER_MANAGER_STORAGE =
        0x06c991646992b7f0f3fd0c832eac3f519e26682bcb82fbbcfd1ff8013d876f64;

    event UpdateKYCProvidersManager(address manager);

    /**
     * @dev Tells the KYC Providers Manager contract address.
     * @return res the manager address.
     */
    function kycProvidersManager() public view returns (IKycProvidersManager res) {
        assembly {
            res := sload(KYC_PROVIDER_MANAGER_STORAGE)
        }
    }

    /**
     * @dev Updates kyc providers manager contract.
     * Callable only by the contract owner / proxy admin.
     * @param _kycProvidersManager new operator manager implementation.
     */
    function setKycProvidersManager(IKycProvidersManager _kycProvidersManager) external onlyOwner {
        require(Address.isContract(address(_kycProvidersManager)), "KycProvidersManagerStorage: not a contract");
        assembly {
            sstore(KYC_PROVIDER_MANAGER_STORAGE, _kycProvidersManager)
        }
        emit UpdateKYCProvidersManager(address(_kycProvidersManager));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}