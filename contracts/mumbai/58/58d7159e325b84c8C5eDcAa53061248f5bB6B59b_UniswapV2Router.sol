/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// File: contracts/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
// File: contracts/interfaces/IERC20PermitLegacy.sol

pragma solidity ^0.8.0;

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.8.0;

interface IUniswapV2Pair {

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    )
        external;
        
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// File: contracts/interfaces/IRouter.sol

pragma solidity ^0.8.0;

interface IRouter {

    /**
    * @dev Certain routers/exchanges needs to be initialized.
    * This method will be called from Augustus
    */
    function initialize(bytes calldata data) external;

    /**
    * @dev Returns unique identifier for the router
    */
    function getKey() external pure returns(bytes32);

    event Swapped(
        bytes16 uuid,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event Bought(
        bytes16 uuid,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount
    );

    event FeeTaken(
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare
    );

    event SwappedV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event BoughtV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event Swapped2(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event Bought2(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount
    );
}
// File: contracts/interfaces/ITokenTransferProxy.sol

pragma solidity ^0.8.0;

interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;
}
// File: contracts/AugustusStorage.sol

pragma solidity ^0.8.0;


contract AugustusStorage {

    struct FeeStructure {
        uint256 partnerShare;
        bool noPositiveSlippage;
        bool positiveSlippageToUser;
        uint16 feePercent;
        string partnerId;
        bytes data;
    }

    ITokenTransferProxy internal tokenTransferProxy;
    address payable internal feeWallet;
    
    mapping(address => FeeStructure) internal registeredPartners;

    mapping (bytes4 => address) internal selectorVsRouter;
    mapping (bytes32 => bool) internal adapterInitialized;
    mapping (bytes32 => bytes) internal adapterVsData;

    mapping (bytes32 => bytes) internal routerData;
    mapping (bytes32 => bool) internal routerInitialized;


    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
}
// File: contracts/DeBridgeContracts/Flags.sol


pragma solidity ^0.8.0;

library Flags {

    /* ========== FLAGS ========== */

    /// @dev Flag to unwrap ETH
    uint256 public constant UNWRAP_ETH = 0;
    /// @dev Flag to revert if external call fails
    uint256 public constant REVERT_IF_EXTERNAL_FAIL = 1;
    /// @dev Flag to call proxy with a sender contract
    uint256 public constant PROXY_WITH_SENDER = 2;
    /// @dev Data is hash in DeBridgeGate send method
    uint256 public constant SEND_HASHED_DATA = 3;
    /// @dev First 24 bytes from data is gas limit for external call
    uint256 public constant SEND_EXTERNAL_CALL_GAS_LIMIT = 4;
    /// @dev Support multi send for externall call
    uint256 public constant MULTI_SEND = 5;

    /// @dev Get flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to check
    function getFlag(
        uint256 _packedFlags,
        uint256 _flag
    ) internal pure returns (bool) {
        uint256 flag = (_packedFlags >> _flag) & uint256(1);
        return flag == 1;
    }

    /// @dev Set flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to set
    /// @param _value Is set or not set
     function setFlag(
         uint256 _packedFlags,
         uint256 _flag,
         bool _value
     ) internal pure returns (uint256) {
         if (_value)
             return _packedFlags | uint256(1) << _flag;
         else
             return _packedFlags & ~(uint256(1) << _flag);
     }
}

// File: contracts/DeBridgeContracts/IDeBridgeGate.sol

/**
It's a fork of IDeBridgeGate.sol with callProxy getter added
Changing original interface will change the bytecode which is not handled well by our deploy process
Until a better solution is found this file will be used
*/

pragma solidity ^0.8.0;

interface IDeBridgeGate {
    /* ========== STRUCTS ========== */

    struct TokenInfo {
        uint256 nativeChainId;
        bytes nativeAddress;
    }

    struct DebridgeInfo {
        uint256 chainId; // native chain id
        uint256 maxAmount; // maximum amount to transfer
        uint256 balance; // total locked assets
        uint256 lockedInStrategies; // total locked assets in strategy (AAVE, Compound, etc)
        address tokenAddress; // asset address on the current chain
        uint16 minReservesBps; // minimal hot reserves in basis points (1/10000)
        bool exist;
    }

    struct DebridgeFeeInfo {
        uint256 collectedFees; // total collected fees
        uint256 withdrawnFees; // fees that already withdrawn
        mapping(uint256 => uint256) getChainFee; // whether the chain for the asset is supported
    }

    struct ChainSupportInfo {
        uint256 fixedNativeFee; // transfer fixed fee
        bool isSupported; // whether the chain for the asset is supported
        uint16 transferFeeBps; // transfer fee rate nominated in basis points (1/10000) of transferred amount
    }

    struct DiscountInfo {
        uint16 discountFixBps; // fix discount in BPS
        uint16 discountTransferBps; // transfer % discount in BPS
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsTo {
        uint256 executionFee;
        uint256 flags;
        bytes fallbackAddress;
        bytes data;
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsFrom {
        uint256 executionFee;
        uint256 flags;
        address fallbackAddress;
        bytes data;
        bytes nativeSender;
    }

    struct FeeParams {
        uint256 receivedAmount;
        uint256 fixFee;
        uint256 transferFee;
        bool useAssetFee;
        bool isNativeToken;
    }

    /* ========== PUBLIC VARS GETTERS ========== */
    /// @dev Returns whether the transfer with the submissionId was claimed.
    /// submissionId is generated in getSubmissionIdFrom
    function isSubmissionUsed(bytes32 submissionId) external returns (bool);

    /* ========== FUNCTIONS ========== */

    /// @dev This method is used for the transfer of assets [from the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-native-chain).
    /// It locks an asset in the smart contract in the native chain and enables minting of deAsset on the secondary chain.
    /// @param _tokenAddress Asset identifier.
    /// @param _amount Amount to be transferred (note: the fee can be applied).
    /// @param _chainIdTo Chain id of the target chain.
    /// @param _receiver Receiver address.
    /// @param _permit deadline + signature for approving the spender by signature.
    /// @param _useAssetFee use assets fee for pay protocol fix (work only for specials token)
    /// @param _referralCode Referral code
    /// @param _autoParams Auto params for external call in target network
    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external payable;

    /// @dev Is used for transfers [into the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-secondary-chain-to-native-chain)
    /// to unlock the designated amount of asset from collateral and transfer it to the receiver.
    /// @param _debridgeId Asset identifier.
    /// @param _amount Amount of the transferred asset (note: the fee can be applied).
    /// @param _chainIdFrom Chain where submission was sent
    /// @param _receiver Receiver address.
    /// @param _nonce Submission id.
    /// @param _signatures Validators signatures to confirm
    /// @param _autoParams Auto params for external call
    function claim(
        bytes32 _debridgeId,
        uint256 _amount,
        uint256 _chainIdFrom,
        address _receiver,
        uint256 _nonce,
        bytes calldata _signatures,
        bytes calldata _autoParams
    ) external;

    /// @dev Get a flash loan, msg.sender must implement IFlashCallback
    /// @param _tokenAddress An asset to loan
    /// @param _receiver Where funds should be sent
    /// @param _amount Amount to loan
    /// @param _data Data to pass to sender's flashCallback function
    function flash(
        address _tokenAddress,
        address _receiver,
        uint256 _amount,
        bytes memory _data
    ) external;

    /// @dev Get reserves of a token available to use in defi
    /// @param _tokenAddress Token address
    function getDefiAvaliableReserves(address _tokenAddress) external view returns (uint256);

    /// @dev Request the assets to be used in DeFi protocol.
    /// @param _tokenAddress Asset address.
    /// @param _amount Amount of tokens to request.
    function requestReserves(address _tokenAddress, uint256 _amount) external;

    /// @dev Return the assets that were used in DeFi  protocol.
    /// @param _tokenAddress Asset address.
    /// @param _amount Amount of tokens to claim.
    function returnReserves(address _tokenAddress, uint256 _amount) external;

    /// @dev Withdraw collected fees to feeProxy
    /// @param _debridgeId Asset identifier.
    function withdrawFee(bytes32 _debridgeId) external;


    /// @dev Returns address of the proxy to execute user's calls.
    function callProxy() external view returns (address);

    /// @dev Returns asset fixed fee value for specified debridge and chainId.
    /// @param _debridgeId Asset identifier.
    /// @param _chainId Chain id.
    function getDebridgeChainAssetFixedFee(
        bytes32 _debridgeId,
        uint256 _chainId
    ) external view returns (uint256);

    /* ========== EVENTS ========== */

    /// @dev Emitted once the tokens are sent from the original(native) chain to the other chain; the transfer tokens
    /// are expected to be claimed by the users.
    event Sent(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        bytes receiver,
        uint256 nonce,
        uint256 indexed chainIdTo,
        uint32 referralCode,
        FeeParams feeParams,
        bytes autoParams,
        address nativeSender
    // bool isNativeToken //added to feeParams
    );

    /// @dev Emitted once the tokens are transferred and withdrawn on a target chain
    event Claimed(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        address indexed receiver,
        uint256 nonce,
        uint256 indexed chainIdFrom,
        bytes autoParams,
        bool isNativeToken
    );

    /// @dev Emitted when new asset support is added.
    event PairAdded(
        bytes32 debridgeId,
        address tokenAddress,
        bytes nativeAddress,
        uint256 indexed nativeChainId,
        uint256 maxAmount,
        uint16 minReservesBps
    );

    /// @dev Emitted when the asset is allowed/disallowed to be transferred to the chain.
    event ChainSupportUpdated(uint256 chainId, bool isSupported, bool isChainFrom);
    /// @dev Emitted when the supported chains are updated.
    event ChainsSupportUpdated(
        uint256 chainIds,
        ChainSupportInfo chainSupportInfo,
        bool isChainFrom);

    /// @dev Emitted when the new call proxy is set.
    event CallProxyUpdated(address callProxy);
    /// @dev Emitted when the transfer request is executed.
    event AutoRequestExecuted(
        bytes32 submissionId,
        bool indexed success,
        address callProxy
    );

    /// @dev Emitted when a submission is blocked.
    event Blocked(bytes32 submissionId);
    /// @dev Emitted when a submission is unblocked.
    event Unblocked(bytes32 submissionId);

    /// @dev Emitted when a flash loan is successfully returned.
    event Flash(
        address sender,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 amount,
        uint256 paid
    );

    /// @dev Emitted when fee is withdrawn.
    event WithdrawnFee(bytes32 debridgeId, uint256 fee);

    /// @dev Emitted when globalFixedNativeFee and globalTransferFeeBps are updated.
    event FixedNativeFeeUpdated(
        uint256 globalFixedNativeFee,
        uint256 globalTransferFeeBps);

    /// @dev Emitted when globalFixedNativeFee is updated by feeContractUpdater
    event FixedNativeFeeAutoUpdated(uint256 globalFixedNativeFee);
}

// File: contracts/DeBridgeContracts/BridgeAppBase.sol


pragma solidity ^0.8.0;



contract BridgeAppBase {

    /* ========== STATE VARIABLES ========== */

    IDeBridgeGate public deBridgeGate;

    // chainId => (address => isControlling)
    /// @dev Maps chainId and address on that chain to bool that defines if the address is controlling
    /// Controlling address is the one that is allowed to call the contract
    /// By default it should be this contract address on sending chain and may be another depending
    /// on the contract logic
    mapping(uint256 => mapping(bytes => bool)) public isAddressFromChainIdControlling;
    /// @dev Maps chainId to address of this contract on that chain
    mapping(uint256 => address) public chainIdToContractAddress;


    /* ========== ERRORS ========== */

    // error CallProxyBadRole();
    // error NativeSenderBadRole(bytes nativeSender, uint256 chainIdFrom);

    // error AddressAlreadyAdded();
    // error RemovingMissingAddress();
    // error AdminBadRole();

    // error ChainToIsNotSupported();

    /* ========== EVENTS ========== */

    // emitted when controlling address is updated
    event ControllingAddressUpdated(
        bytes nativeSender,
        uint256 chainIdFrom,
        bool enabled
    );

    // emitted when chainIdToContractAddress address is updated
    event ContractAddressOnChainIdUpdated(
        address newAddress,
        uint256 chainIdTo
    );

    /* ========== MODIFIERS ========== */

    // modifier onlyAdmin() {
    //     if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
    //     _;
    // }

    // modifier onlyControllingAddress() {
    //     ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());
    //     if (address(callProxy) != msg.sender) revert CallProxyBadRole();

    //     bytes memory nativeSender = callProxy.submissionNativeSender();
    //     uint256 chainIdFrom = callProxy.submissionChainIdFrom();
    //     if(!isAddressFromChainIdControlling[chainIdFrom][nativeSender]) {
    //         revert NativeSenderBadRole(nativeSender, chainIdFrom);
    //     }
    //     _;
    // }

    /* ========== CONSTRUCTOR  ========== */

    function __BridgeAppBase_init(IDeBridgeGate _deBridgeGate) internal {
        __BridgeAppBase_init_unchained(_deBridgeGate);
    }

    function __BridgeAppBase_init_unchained(IDeBridgeGate _deBridgeGate) internal {
        deBridgeGate = _deBridgeGate;
    }

    function addControllingAddress(
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external {
        // if(isAddressFromChainIdControlling[_chainIdFrom][_nativeSender]) {
        //     revert AddressAlreadyAdded();
        // }

        isAddressFromChainIdControlling[_chainIdFrom][_nativeSender] = true;

        emit ControllingAddressUpdated(_nativeSender, _chainIdFrom, true);
    }

    function removeControllingAddress(
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external {
        // if(!isAddressFromChainIdControlling[_chainIdFrom][_nativeSender]) {
        //     revert RemovingMissingAddress();
        // }

        isAddressFromChainIdControlling[_chainIdFrom][_nativeSender] = false;

        emit ControllingAddressUpdated(_nativeSender, _chainIdFrom, false);
    }

    function setContractAddressOnChainId(
        address _address,
        uint256 _chainIdTo
    ) external {
        chainIdToContractAddress[_chainIdTo] = _address;
        emit ContractAddressOnChainIdUpdated(_address, _chainIdTo);
    }


    /// @dev Stop all transfers.
    // function pause() external {
    //     _pause();
    // }

    /// @dev Allow transfers.
    // function unpause() external {
    //     _unpause();
    // }

    // ============ VIEWS ============

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getDebridgeId(uint256 _chainId, address _tokenAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }

    function isControllingAddress(
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external view returns (bool) {
        return isAddressFromChainIdControlling[_chainIdFrom][_nativeSender];
    }

    /// @dev Get current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }
    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: contracts/libraries/UniswapV2Lib.sol

pragma solidity ^0.8.0;



library UniswapV2Lib {
    using SafeMath for uint256;

    function checkAndConvertETHToWETH(address token, address weth) internal pure returns(address) {

        if(token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            return weth;
        }
        return token;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {

        return(tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCode
    )
        internal
        pure
        returns (address)
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return(address(uint160(uint256(keccak256(abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initCode // init code hash
        ))))));
    }

    function getReservesByPair(
        address pair,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee,
        uint256 feeFactor
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV3Library: INSUFFICIENT_INPUT_AMOUNT");
        uint256 amountInWithFee = amountIn.mul(fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(feeFactor).add(amountInWithFee);
        amountOut = uint256(numerator / denominator);
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInAndPair(
        address factory,
        uint amountOut,
        address tokenA,
        address tokenB,
        bytes32 initCode,
        uint256 fee,
        uint256 feeFactor,
        address weth
    )
        internal
        view
        returns (uint256 amountIn, address pair)
    {
        tokenA = checkAndConvertETHToWETH(tokenA, weth);
        tokenB = checkAndConvertETHToWETH(tokenB, weth);

        pair = pairFor(factory, tokenA, tokenB, initCode);
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, tokenA, tokenB);
        require(amountOut > 0, "UniswapV3Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveOut > amountOut, "UniswapV3Library: reserveOut should be greater than amountOut");
        uint numerator = reserveIn.mul(amountOut).mul(feeFactor);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountOutByPair(
        uint256 amountIn,
        address pair,
        address tokenA,
        address tokenB,
        uint256 fee,
        uint256 feeFactor
    )
        internal
        view
        returns(uint256 amountOut)
    {
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, tokenA, tokenB);
        return (getAmountOut(amountIn, reserveIn, reserveOut, fee, feeFactor));
    }
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

// File: contracts/interfaces/IWETH.sol

pragma solidity ^0.8.0;


abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: contracts/libraries/Utils.sol

/*solhint-disable avoid-low-level-calls */


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;







library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    // Data required for cross chain swap in UniswapV2Router
    struct UniswapV2RouterData{
        // Amount that user give to swap 
        uint256 amountIn;
        // Minimal amount that user receive after swap.  
        uint256 amountOutMin;
        // Path of the tokens addresses to swap before DeBridge
        address[] pathBeforeSend;
        // Path of the tokens addresses to swap after DeBridge
        address[] pathAfterSend;
        // Wallet that receive tokens after swap
        address beneficiary;
        // Fee paid to keepers to execute swap in second chain
        uint256 executionFee;
        // Chain id to which tokens are sent
        uint256 chainId;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    // Data required for cross chain swap in SimpleSwap
    struct SimpleDataDeBridge {
        // Path of the tokens addresses to swap before DeBridge
        address[] pathBeforeSend;
        // Path of the tokens addresses to swap after DeBridge
        address[] pathAfterSend;
        // Amount that user give to swap
        uint256 fromAmount;
        // Minimal amount that user will reicive after swap
        uint256 toAmount;
        // Expected amount that user will receive after swap
        uint256 expectedAmount;
        // Addresses of exchanges that will perform swap
        address[] callees;
        // Encoded data to call exchanges
        bytes exchangeData;
        // Start and end indexes of the exchangeData 
        uint256[] startIndexes;
        // Amount of the ether that user send
        uint256[] values;
        // The number of callees used for swap before DeBridge
        uint256 calleesBeforeSend;
        // Address of the wallet that receive tokens
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
        // Fee paid to keepers to execute swap in second chain
        uint256 executionFee;
        // Chain id to which tokens are sent
        uint256 chainId;
    }

    struct ZeroxV4DataDeBridge {
        IERC20[] pathBeforeSend;
        IERC20[] pathAfterSend;
        uint256 fromAmount;
        uint256 amountOutMin;
        address exchangeBeforeSend;
        address exchangeAfterSend;
        bytes payloadBeforeSend;
        bytes payloadAfterSend;
        address payable beneficiary;
        uint256 executionFee;
        uint256 chainIdTo;
    }

    // Data required for cross chain swap in MultiPath
    struct SellDataDeBridge {
        // Addresses of two tokens from which swap will begin if different chains
        address[] fromToken;
        // Amount that user give to swap
        uint256 fromAmount;
        // Minimal amount that user will reicive after swap
        uint256 toAmount;
        // Expected amount that user will receive after swap
        uint256 expectedAmount;
        // Address of the wallet that receive tokens
        address payable beneficiary;
        // Array of Paths that  perform swap before DeBridge
        Utils.Path[] pathBeforeSend;
        // Array of Paths that perform swap after DeBridge
        Utils.Path[] pathAfterSend;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
        // Fee paid to keepers to execute swap in second chain
        uint256 executionFee;
        // Chain id to which tokens are sent
        uint256 chainId;
    }

    struct MegaSwapSellDataDeBridge {
        address[] fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] pathBeforeSend;
        Utils.MegaSwapPath[] pathAfterSend;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
        uint256 executionFee;
        uint256 chainId;
    }

    struct Adapter {
        // Address of the adapter that perform swap
        address payable adapter;
        // Percent of tokens to be swapped
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        // Index of the router in the adapter
        uint256 index; //Adapter at which index needs to be used
        // Address of the exhcnage that will execute swap
        address targetExchange;
        // Percent of tokens to be swapped
        uint256 percent;
        // Data for the exchange
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        // Address of the token that user will receive after swap
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    // Data required for cross chain swap in MultiPath
    struct UniswapV2ForkDeBridge{
        // Address of the token that user will swap
        address[] tokenIn;

        uint256 amountIn;
        // Minimal amount of tokens that user will receive
        uint256 amountOutMin;
        // Address of wrapped native token, if user swap native token
        address weth;
        // Number that contains address of the pair, direction and exchange fee
        uint256[] poolsBeforeSend;

        uint256[] poolsAfterSend;
        // Fee paid to keepers to execute swap in second chain
        uint256 executionFee;
        // Chain id to which tokens are sent
        uint256 chainIdTo;
        // Address of the wallet that receive tokens
        address beneficiary;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(
                address(this),
                addressToApprove
            );

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{value: amount, gas: 10000}(
                    ""
                );
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account)
        internal
        view
        returns (uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(
                abi.encodePacked(IERC20Permit.permit.selector, permit)
            );
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(
                abi.encodePacked(IERC20PermitLegacy.permit.selector, permit)
            );
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{value: amount, gas: 10000}("");
            require(result, "Transfer ETH failed");
        }
    }
}

// File: contracts/interfaces/IUniswapV2Router.sol

pragma solidity ^0.8.0;


interface IUniswapV2Router{

    function swapOnUniswapDeBridge(
        Utils.UniswapV2RouterData[] memory _data
    ) 
        external
        payable;
}
// File: contracts/routers/UniswapV2Router.sol/UniswapV2Router.sol

pragma solidity ^0.8.0;
















contract UniswapV2Router is AugustusStorage, IRouter, BridgeAppBase, Ownable {
    using SafeMath for uint256;
    using Flags for uint256;

    address public immutable UNISWAP_FACTORY;
    address public immutable WETH;
    address public immutable ETH_IDENTIFIER;
    bytes32 public immutable UNISWAP_INIT_CODE;
    uint256 public immutable FEE;
    uint256 public immutable FEE_FACTOR;
    uint256 public CURRENT_CHAINID;

    // 0x68D936Cb4723BdD38C488FD50514803f96789d2D адрес deBridgeGate в BSC и KOVAN
    // 0xEF3B092e84a2Dbdbaf507DeCF388f7f02eb43669 адрес прокси deBridge в KOVAN
    // 0xEF3B092e84a2Dbdbaf507DeCF388f7f02eb43669 адрес прокси deBridge в POLYGON

    mapping(address => bool) admins;

    constructor(
        address _factory,
        address _weth,
        address _eth,
        bytes32 _initCode,
        uint256 _fee,
        uint256 _feeFactor
    ) public {
        UNISWAP_FACTORY = _factory;
        WETH = _weth;
        ETH_IDENTIFIER = _eth;
        UNISWAP_INIT_CODE = _initCode;
        FEE = _fee;
        FEE_FACTOR = _feeFactor;
        CURRENT_CHAINID = getChainId();
    }

    function initialize(bytes calldata data) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("UNISWAP_DIRECT_ROUTER", "1.0.0"));
    }

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) public payable {
        (uint256 tokensBought, ) = _swap(
            UNISWAP_FACTORY,
            UNISWAP_INIT_CODE,
            amountIn,
            path,
            ((0 << 161) + uint256(uint160(msg.sender)))
        );

        require(
            tokensBought >= amountOutMin,
            "Uniswap: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable {
        (uint256 tokensBought, ) = _swap(
            factory,
            initCode,
            amountIn,
            path,
            ((0 << 161) + uint256(uint160(msg.sender)))
        );

        require(
            tokensBought >= amountOutMin,
            "Uniswap: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    /// @notice The function using to swap tokens between chains
    /** @dev variable crossChain using to understand which swap being performed. 
        Index 0 - usual swap in the same chain
        Index 1 - swap before DeBridge
        Index 2 - swap after Debrodge*/
    /// @param _data All data needed to cross chain swap. See ../../libraries/utils.sol
    function swapOnUniswapDeBridge(Utils.UniswapV2RouterData memory _data)
        external
        payable
    {
        bool currentChainId = _data.chainId == CURRENT_CHAINID;
        uint256 tokensBought;
        address tokenBought;
        bool instaTransfer = false;
        address[] memory path = currentChainId ? _data.pathAfterSend : _data.pathBeforeSend;
        uint256 crossChain = (currentChainId ? (2 << 161) : (1 << 161)) + uint256(uint160(_data.beneficiary));
        uint256 amountIn = _data.amountIn;

        if (currentChainId) {
            amountIn = IERC20(path[0]).balanceOf(msg.sender);
            IERC20(path[0]).approve(address(getTokenTransferProxy()), amountIn);
            IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
            if (path.length == 1) {
                transferTokens(path[0], address(this), _data.beneficiary, amountIn);
                instaTransfer = true;
            }
        }
        if (!instaTransfer) {
                 
            (tokensBought, tokenBought) = _swap(
                UNISWAP_FACTORY,
                UNISWAP_INIT_CODE,
                amountIn,
                path,
                crossChain
            );

            if (!currentChainId) {
                send(_data, tokensBought, tokenBought);
            }
            require(
                tokensBought >= _data.amountOutMin,
                "Uniswap: INSUFFICIENT_OUTPUT_AMOUNT"
            );
        }
    }

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    ) external payable {
        uint256 tokensSold = _buy(
            UNISWAP_FACTORY,
            UNISWAP_INIT_CODE,
            amountOut,
            path
        );

        require(
            tokensSold <= amountInMax,
            "Uniswap: INSUFFICIENT_INPUT_AMOUNT"
        );
    }

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    ) external payable {
        uint256 tokensSold = _buy(factory, initCode, amountOut, path);

        require(
            tokensSold <= amountInMax,
            "Uniswap: INSUFFICIENT_INPUT_AMOUNT"
        );
    }

    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        ITokenTransferProxy(tokenTransferProxy).transferFrom(token, from, to, amount);
        // IERC20(token).transferFrom(from, to,amount);
    }

    function _swap(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        address[] memory path,
        uint256 crossChainData
    ) private returns (uint256 tokensBought, address tokenBought) {
        require(path.length > 1, "More than 1 token required");
        uint256 pairs = uint256(path.length - 1);
        bool tokensBoughtEth;
        tokensBought = amountIn;
        address receiver;
        tokenBought;

        for (uint256 i = 0; i < pairs; i++) {
            address tokenSold = path[i];
            tokenBought = path[i + 1];

            address currentPair = receiver;

            if (i == pairs - 1) {
                if (tokenBought == ETH_IDENTIFIER) {
                    tokenBought = WETH;
                    tokensBoughtEth = true;
                }
            }
            if (i == 0) {
                if (tokenSold == ETH_IDENTIFIER) {
                    tokenSold = WETH;
                    currentPair = UniswapV2Lib.pairFor(
                        factory,
                        tokenSold,
                        tokenBought,
                        initCode
                    );
                    uint256 amount = (crossChainData >> 161) == 1
                        ? msg.value -
                            (CURRENT_CHAINID == 80001 ? 0.1 ether : 0.01 ether)
                        : 0;
                    require(amountIn == amount, "Incorrect amount of ETH sent");
                    IWETH(WETH).deposit{value: amount}();
                    assert(IWETH(WETH).transfer(currentPair, amount));
                } else {
                    currentPair = UniswapV2Lib.pairFor(
                        factory,
                        tokenSold,
                        tokenBought,
                        initCode
                    );
                    if ((crossChainData >> 161) == 2) {
                        IERC20(tokenSold).approve(
                            address(getTokenTransferProxy()),
                            amountIn
                        );
                        transferTokens(
                            tokenSold,
                            address(this),
                            currentPair,
                            amountIn
                        );
                    } else {
                        transferTokens(
                            tokenSold,
                            msg.sender,
                            currentPair,
                            amountIn
                        );
                    }
                }
            }
            //AmountIn for this hop is amountOut of previous hop
            tokensBought = UniswapV2Lib.getAmountOutByPair(
                tokensBought,
                currentPair,
                tokenSold,
                tokenBought,
                FEE,
                FEE_FACTOR
            );

            if ((i + 1) == pairs) {
                receiver = ((crossChainData >> 161) == 1) || tokensBoughtEth
                    ? address(this)
                    : address(uint160(crossChainData));
            } else {
                receiver = UniswapV2Lib.pairFor(
                    factory,
                    tokenBought,
                    path[i + 2] == ETH_IDENTIFIER ? WETH : path[i + 2],
                    initCode
                );
            }

            (address token0, ) = UniswapV2Lib.sortTokens(
                tokenSold,
                tokenBought
            );
            (uint256 amount0Out, uint256 amount1Out) = tokenSold == token0
                ? (uint256(0), tokensBought)
                : (tokensBought, uint256(0));
            IUniswapV2Pair(currentPair).swap(
                amount0Out,
                amount1Out,
                receiver,
                new bytes(0)
            );
        }
        if (tokensBoughtEth) {
            IWETH(WETH).withdraw(tokensBought);
            TransferHelper.safeTransferETH(receiver, tokensBought);
        }
    }

    function _buy(
        address factory,
        bytes32 initCode,
        uint256 amountOut,
        address[] calldata path
    ) private returns (uint256 tokensSold) {
        require(path.length > 1, "More than 1 token required");
        bool tokensBoughtEth;
        uint256 length = uint256(path.length);

        uint256[] memory amounts = new uint256[](length);
        address[] memory pairs = new address[](length - 1);

        amounts[length - 1] = amountOut;

        for (uint256 i = length - 1; i > 0; i--) {
            (amounts[i - 1], pairs[i - 1]) = UniswapV2Lib.getAmountInAndPair(
                factory,
                amounts[i],
                path[i - 1],
                path[i],
                initCode,
                FEE,
                FEE_FACTOR,
                WETH
            );
        }

        tokensSold = amounts[0];

        for (uint256 i = 0; i < length - 1; i++) {
            address tokenSold = path[i];
            address tokenBought = path[i + 1];

            if (i == length - 2) {
                if (tokenBought == ETH_IDENTIFIER) {
                    tokenBought = WETH;
                    tokensBoughtEth = true;
                }
            }
            if (i == 0) {
                if (tokenSold == ETH_IDENTIFIER) {
                    tokenSold = WETH;
                    TransferHelper.safeTransferETH(
                        msg.sender,
                        msg.value.sub(tokensSold)
                    );
                    IWETH(WETH).deposit{value: tokensSold}();
                    assert(IWETH(WETH).transfer(pairs[i], tokensSold));
                } else {
                    transferTokens(tokenSold, msg.sender, pairs[i], tokensSold);
                }
            }

            address receiver;

            if (i == length - 2) {
                if (tokensBoughtEth) {
                    receiver = address(this);
                } else {
                    receiver = msg.sender;
                }
            } else {
                receiver = pairs[i + 1];
            }

            (address token0, ) = UniswapV2Lib.sortTokens(
                tokenSold,
                tokenBought
            );
            (uint256 amount0Out, uint256 amount1Out) = tokenSold == token0
                ? (uint256(0), amounts[i + 1])
                : (amounts[i + 1], uint256(0));
            IUniswapV2Pair(pairs[i]).swap(
                amount0Out,
                amount1Out,
                receiver,
                new bytes(0)
            );
        }
        if (tokensBoughtEth) {
            IWETH(WETH).withdraw(amountOut);
            TransferHelper.safeTransferETH(msg.sender, amountOut);
        }
    }

    /// @dev Function using for send tokens and data through DeBridge
    /// @param data Data to execute swap in second chain
    /// @param tokensBought Amount of tokens that contract receive after swap
    /// @param tokenBought Address of token that was last in the path
    function send(
        Utils.UniswapV2RouterData memory data,
        uint256 tokensBought,
        address tokenBought
    ) public payable {
        address _bridgeAddress = 0x68D936Cb4723BdD38C488FD50514803f96789d2D;

        address contractAddressTo = chainIdToContractAddress[data.chainId];
        require(contractAddressTo != address(0), "Incremetor: ChainId is not supported");
        require(tokensBought.div(2) >= data.executionFee, "UNISWAPV2ROuter: #1");

        IERC20(tokenBought).approve(_bridgeAddress, tokensBought);
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        autoParams.flags = autoParams.flags.setFlag(Flags.REVERT_IF_EXTERNAL_FAIL, true);
        autoParams.flags = autoParams.flags.setFlag(Flags.PROXY_WITH_SENDER, true);
        autoParams.executionFee = data.executionFee;
        autoParams.fallbackAddress = abi.encodePacked(data.beneficiary);
        autoParams.data = abi.encodeWithSelector(
            this.swapOnUniswapDeBridge.selector,
            data
        );

        uint256 deBridgeFee = CURRENT_CHAINID == 80001
            ? 0.1 ether
            : 0.01 ether;

        if (tokenBought == WETH) {
            deBridgeGate.send{value: tokensBought}(
                address(0),
                tokensBought,
                data.chainId,
                abi.encodePacked(contractAddressTo),
                "",
                false,
                0,
                abi.encode(autoParams)
            );
        } else {
            deBridgeGate.send{value: deBridgeFee}(
                tokenBought,
                tokensBought,
                data.chainId,
                abi.encodePacked(contractAddressTo),
                "",
                false,
                0,
                abi.encode(autoParams)
            );
        }
    }

    function initialize(address _bridgeAddr) public {
        __BridgeAppBase_init(IDeBridgeGate(_bridgeAddr));
    }

    function getTokenTransferProxy() public view returns (address) {
        return address(tokenTransferProxy);
    }
}