// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./FxBaseChildTunnel.sol";
import "../Config/IAddressManager.sol";

/// @dev This contract lives on the L2 and receives messages from the L1 to register and unregister
/// NFTs on the L1 chain.
/// This is not an upgradeable contract and should not be used with a proxy.
contract ChildRegistrar is FxBaseChildTunnel {
    bytes32 public constant REGISTER = keccak256("REGISTER");
    bytes32 public constant DE_REGISTER = keccak256("DE_REGISTER");

    /// @dev local reference to the address manager contract
    IAddressManager public addressManager;

    /// @dev the address that deployed this contract is the only one that can update the fxRootTunnel
    address public deployer;

    /// @param _fxChild - This is the contract deployed on the L2 that will be sending messages here.
    /// This is a well known deployed contract that Matic has set up.
    /// @param _addressManager - This is the address manager on the protocol
    /// @dev After deployment you must call setFxRootTunnel() with the RootRegistrar Address on the L1.
    constructor(address _fxChild, IAddressManager _addressManager)
        FxBaseChildTunnel(_fxChild)
    {
        addressManager = _addressManager;
        deployer = msg.sender;
    }

    /// @dev Set fxRootTunnel if not set already
    /// Only the deploying account can update this
    /// Overrides the function in the base contract
    function setFxRootTunnel(address _fxRootTunnel) external override {
        require(deployer == msg.sender, "Only deployer");
        require(fxRootTunnel == address(0x0), "Already set");
        fxRootTunnel = _fxRootTunnel;
    }

    /// @dev The base contract ensures that the incoming message is from the contract _fxChild passed in the constructor.
    /// The validateSender() makes sure that the contract on the root chain is the one relaying the message.
    /// The root contract should have been set via setFxRootTunnel() after deployment
    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (syncType == REGISTER) {
            _registerNft(syncData);
        } else if (syncType == DE_REGISTER) {
            _deRegisterNft(syncData);
        } else {
            revert("ERR MSG");
        }
    }

    /// @dev Handler for messages coming from the L1 when an owner wants to register
    function _registerNft(bytes memory syncData) internal {
        // Decode the params from the data
        (
            address owner,
            uint256 chainId,
            address nftContractAddress,
            uint256 nftId,
            address[] memory creatorAddresses,
            uint256[] memory creatorSaleBasisPoints,
            uint256 optionBits,
            string memory ipfsMetadataHash
        ) = abi.decode(
                syncData,
                (
                    address,
                    uint256,
                    address,
                    uint256,
                    address[],
                    uint256[],
                    uint256,
                    string
                )
            );

        // Call the registrar and register the NFT
        addressManager.makerRegistrar().registerNftFromBridge(
            owner,
            chainId,
            nftContractAddress,
            nftId,
            creatorAddresses,
            creatorSaleBasisPoints,
            optionBits,
            ipfsMetadataHash
        );
    }

    /// @dev Handler for messages coming from the L1 when an owner wants to de-register
    function _deRegisterNft(bytes memory syncData) internal {
        // Decode the params from the data
        (
            address owner,
            uint256 chainId,
            address nftContractAddress,
            uint256 nftId
        ) = abi.decode(syncData, (address, uint256, address, uint256));

        addressManager.makerRegistrar().deRegisterNftFromBridge(
            owner,
            chainId,
            nftContractAddress,
            nftId
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FxBaseChildTunnel
/// @author @maticnetwork
/// @notice This contract is copied from @maticnetwork/fx-portal
/// @dev The only change was to make setFxRootTunnel() virtual

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
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(
            fxRootTunnel == address(0x0),
            "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
        );
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Permissions/IRoleManager.sol";
import "../Parameters/IParameterManager.sol";
import "../Maker/IMakerRegistrar.sol";
import "../Token/IStandard1155.sol";
import "../Reactions/IReactionVault.sol";
import "../CuratorVault/ICuratorVault.sol";

interface IAddressManager {
    /// @dev Getter for the role manager address
    function roleManager() external returns (IRoleManager);

    /// @dev Setter for the role manager address
    function setRoleManager(IRoleManager _roleManager) external;

    /// @dev Getter for the role manager address
    function parameterManager() external returns (IParameterManager);

    /// @dev Setter for the role manager address
    function setParameterManager(IParameterManager _parameterManager) external;

    /// @dev Getter for the maker registrar address
    function makerRegistrar() external returns (IMakerRegistrar);

    /// @dev Setter for the maker registrar address
    function setMakerRegistrar(IMakerRegistrar _makerRegistrar) external;

    /// @dev Getter for the reaction NFT contract address
    function reactionNftContract() external returns (IStandard1155);

    /// @dev Setter for the reaction NFT contract address
    function setReactionNftContract(IStandard1155 _reactionNftContract)
        external;

    /// @dev Getter for the default Curator Vault contract address
    function defaultCuratorVault() external returns (ICuratorVault);

    /// @dev Setter for the default Curator Vault contract address
    function setDefaultCuratorVault(ICuratorVault _defaultCuratorVault)
        external;

    /// @dev Getter for the L2 bridge registrar
    function childRegistrar() external returns (address);

    /// @dev Setter for the L2 bridge registrar
    function setChildRegistrar(address _childRegistrar) external;

    /// @dev Getter for the address of the royalty registry
    function royaltyRegistry() external returns (address);

    /// @dev Setter for the address of the royalty registry
    function setRoyaltyRegistry(address _royaltyRegistry) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Token/IStandard1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @dev Interface for the curator vault
interface ICuratorVault {
    function getTokenId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken
    ) external returns (uint256);

    function buyCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken,
        uint256 paymentAmount,
        address mintToAddress,
        bool isTakerPosition
    ) external returns (uint256);

    function sellCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken,
        uint256 tokensToBurn,
        address refundToAddress
    ) external returns (uint256);

    function curatorTokens() external returns (IStandard1155);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev Interface for the maker registrar that supports registering and de-registering NFTs
interface IMakerRegistrar {
    /// @dev struct for storing details about a registered NFT
    struct NftDetails {
        bool registered;
        address owner;
        address[] creators;
        uint256[] creatorSaleBasisPoints;
    }

    function transformToSourceLookup(uint256 metaId) external returns (uint256);

    function deriveSourceId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId
    ) external returns (uint256);

    /// @dev lookup for NftDetails from source ID
    function sourceToDetailsLookup(uint256)
        external
        returns (NftDetails memory);

    function verifyOwnership(
        address nftContractAddress,
        uint256 nftId,
        address potentialOwner
    ) external returns (bool);

    function registerNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId,
        address[] memory nftCreatorAddresses,
        uint256[] memory creatorSaleBasisPoints,
        uint256 optionBits,
        string memory ipfsMetadataHash
    ) external;

    function deRegisterNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Permissions/IRoleManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IParameterManager {
    /// @dev Getter for the payment token
    function paymentToken() external returns (IERC20Upgradeable);

    /// @dev Setter for the payment token
    function setPaymentToken(IERC20Upgradeable _paymentToken) external;

    /// @dev Getter for the reaction price
    function reactionPrice() external returns (uint256);

    /// @dev Setter for the reaction price
    function setReactionPrice(uint256 _reactionPrice) external;

    /// @dev Getter for the cut of purchase price going to the curator liability
    function saleCuratorLiabilityBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of purchase price going to the curator liability
    function setSaleCuratorLiabilityBasisPoints(
        uint256 _saleCuratorLiabilityBasisPoints
    ) external;

    /// @dev Getter for the cut of purchase price going to the referrer
    function saleReferrerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of purchase price going to the referrer
    function setSaleReferrerBasisPoints(uint256 _saleReferrerBasisPoints)
        external;

    /// @dev Getter for the cut of spend curator liability going to the taker
    function spendTakerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of spend curator liability going to the taker
    function setSpendTakerBasisPoints(uint256 _spendTakerBasisPoints) external;

    /// @dev Getter for the cut of spend curator liability going to the taker
    function spendReferrerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of spend curator liability going to the referrer
    function setSpendReferrerBasisPoints(uint256 _spendReferrerBasisPoints)
        external;

    /// @dev Getter for the check to see if a curator vault is allowed to be used
    function approvedCuratorVaults(address potentialVault)
        external
        returns (bool);

    /// @dev Setter for the list of curator vaults allowed to be used
    function setApprovedCuratorVaults(address vault, bool approved) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IRoleManager {
    /// @dev Determines if the specified address has capability to mint and burn reaction NFTs
    /// @param potentialAddress Address to check
    function isAdmin(address potentialAddress) external view returns (bool);

    /// @dev Determines if the specified address has permission to udpate addresses in the protocol
    /// @param potentialAddress Address to check
    function isAddressManagerAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to update parameters in the protocol
    /// @param potentialAddress Address to check
    function isParameterManagerAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to to mint and burn reaction NFTs
    /// @param potentialAddress Address to check
    function isReactionNftAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to purchase curator vault tokens
    /// @param potentialAddress Address to check
    function isCuratorVaultPurchaser(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to mint and burn curator tokens
    /// @param potentialAddress Address to check
    function isCuratorTokenAdmin(address potentialAddress)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @dev Interface for the ReactionVault that supports buying and spending reactions
interface IReactionVault {
    struct ReactionPriceDetails {
        IERC20Upgradeable paymentToken;
        uint256 reactionPrice;
        uint256 saleCuratorLiabilityBasisPoints;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev Interface for the Standard1155 toke contract.
interface IStandard1155 {
    /// @dev Allows a priviledged account to mint tokens to the specified address
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}