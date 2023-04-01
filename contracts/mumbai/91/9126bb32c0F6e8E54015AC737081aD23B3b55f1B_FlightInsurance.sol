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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IFlightStatusOracle.sol";
import "./interfaces/IProduct.sol";
import "./PredictionMarket.sol";

contract FlightDelayMarket is PredictionMarket {
    event FlightCompleted(
        bytes8 indexed flightName,
        uint64 indexed departureDate,
        bytes1 status,
        uint64 delay
    );

    struct FlightInfo {
        bytes8 flightName;
        uint64 departureDate;

        uint32 delayMinutes;
    }

    FlightInfo private _flightInfo;

    constructor(
        FlightInfo memory flightInfo_,
        Config memory config_,
        uint256 uniqueId_,
        bytes32 marketId_,
        ITokensRepository tokensRepo_,
        address payable feeCollector_,
        IProduct product_
    )
        PredictionMarket(config_, uniqueId_, marketId_, tokensRepo_, feeCollector_, product_)
    {
        _flightInfo = flightInfo_;
    }

    function flightInfo() external view returns (FlightInfo memory) {
        return _flightInfo;
    }

    function _trySettle() internal override {
        IFlightStatusOracle(_config.oracle)
            .requestFlightStatus(
                string(abi.encodePacked(_flightInfo.flightName)),
                _flightInfo.departureDate,
                this.recordDecision.selector
            );
    }

    function _renderDecision(
        bytes calldata payload
    ) internal override returns (DecisionState state, Result result) {
        (bytes1 status, uint64 delay) = abi.decode(payload, (bytes1, uint64));

        // TODO: carefully check other statuses
        if (status != "L") {
            // not arrived yet
            // will have to reschedule the check
            state = DecisionState.DECISION_NEEDED;
            // TODO: also add a cooldown mechanism
        } else if (status == "C" || delay >= _flightInfo.delayMinutes * 60) {
            // YES wins
            state = DecisionState.DECISION_RENDERED;
            result = Result.YES;
        } else {
            // NO wins
            state = DecisionState.DECISION_RENDERED;
            result = Result.NO;
        }

        if (state == DecisionState.DECISION_RENDERED) {
            emit FlightCompleted(
                _flightInfo.flightName,
                _flightInfo.departureDate,
                status,
                delay
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/ITokensRepository.sol";
import "./interfaces/IProduct.sol";
import "./interfaces/IRegistry.sol";
import "./utils/RegistryMixin.sol";
import "./FlightDelayMarket.sol";

contract FlightDelayMarketFactory is RegistryMixin {
    constructor(IRegistry registry_)
        RegistryMixin(registry_)
    { }

    function createMarket(
        uint256 uniqueId,
        bytes32 marketId,
        PredictionMarket.Config calldata config,
        FlightDelayMarket.FlightInfo calldata flightInfo,
        ITokensRepository tokensRepo,
        address payable feeCollector,
        IProduct product
    )
        external
        onlyProduct
        returns (FlightDelayMarket)
    {
        FlightDelayMarket market = new FlightDelayMarket(
            flightInfo,
            config,
            uniqueId,
            marketId,
            tokensRepo,
            feeCollector,
            product
        );
        return market;
    }

    function getMarketId(bytes8 flightName, uint64 departureDate, uint32 delayMinutes)
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(flightName, departureDate, delayMinutes)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Trustus.sol";
import "./LPWallet.sol";

import "./interfaces/IFlightStatusOracle.sol";
import "./interfaces/ITokensRepository.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IProduct.sol";
import "./interfaces/IRegistry.sol";
import "./utils/RegistryMixin.sol";
import "./FlightDelayMarketFactory.sol";
import "./FlightDelayMarket.sol";

contract FlightInsurance is IProduct, Ownable, ReentrancyGuard, Trustus, RegistryMixin {
    event FlightDelayMarketCreated(
        bytes32 indexed marketId,
        uint256 indexed uniqueId,
        address indexed creator,
        FlightDelayMarket.FlightInfo flightInfo,
        IMarket.Config config
    );

    event FlightDelayMarketLiquidityProvided(
        bytes32 indexed marketId,
        address indexed provider,
        uint256 value
    );

    event FlightDelayMarketParticipated(
        bytes32 indexed marketId,
        address indexed participant,
        uint256 value,
        bool betYes,
        uint256 amount
    );

    event FlightDelayMarketWithdrawn(
        bytes32 indexed marketId,
        address indexed participant,
        uint256 amount,
        bool betYes,
        uint256 value
    );

    event FlightDelayMarketSettled(
        bytes32 indexed marketId,
        bool yesWin
    );

    event FlightDelayMarketClaimed(
        bytes32 indexed marketId,
        address indexed participant,
        uint256 value
    );

    error ZeroAddress();

    bytes32 private constant TRUSTUS_REQUEST_MARKET = 0x416d5838653a925e2c4ccf0b43e376ad31434b2095ec358fe6b0519c1e2f2bbe;

    /// @dev Stores the next value to use
    uint256 private _marketUniqueIdCounter;

    /// @notice Markets storage
    mapping (bytes32 => FlightDelayMarket) private _markets;

    /// @notice Holds LP funds
    LPWallet private _lpWallet;

    constructor(IRegistry registry_)
        RegistryMixin(registry_)
    {
        // first 10 are reserved for something special
        _marketUniqueIdCounter = 10;
    }

    function getMarket(bytes32 marketId) external view override returns (address) {
        return address(_markets[marketId]);
    }

    function findMarket(bytes8 flightName, uint64 departureDate, uint32 delayMinutes)
        external
        view
        returns (bytes32, FlightDelayMarket)
    {
        FlightDelayMarketFactory factory = FlightDelayMarketFactory(_registry.getAddress(1));
        bytes32 marketId = factory.getMarketId(flightName, departureDate, delayMinutes);
        return (marketId, _markets[marketId]);
    }

    function createMarket(
        bool betYes,
        TrustusPacket calldata packet
    )
        external
        payable
        nonReentrant
        verifyPacket(TRUSTUS_REQUEST_MARKET, packet)
    {
        // TODO: extract config
        (IMarket.Config memory config, FlightDelayMarket.FlightInfo memory flightInfo) =
            abi.decode(packet.payload, (IMarket.Config, FlightDelayMarket.FlightInfo));

        // TODO: add "private market"
        require(config.cutoffTime > block.timestamp, "Cannot create closed market");

        FlightDelayMarketFactory factory = FlightDelayMarketFactory(_registry.getAddress(1));
        ITokensRepository tokensRepo = ITokensRepository(_registry.getAddress(2));
        address payable feeCollector = payable(_registry.getAddress(100));

        bytes32 marketId = factory.getMarketId(flightInfo.flightName, flightInfo.departureDate, flightInfo.delayMinutes);
        require(address(_markets[marketId]) == address(0), "Market already exists");

        uint256 uniqueId = _marketUniqueIdCounter;
        FlightDelayMarket market = factory.createMarket(
            uniqueId,
            marketId,
            config,
            flightInfo,
            tokensRepo,
            feeCollector,
            this
        );
        _markets[marketId] = market;
        _lpWallet.provideLiquidity(market, config.lpBid);

        market.registerParticipant{value: msg.value}(_msgSender(), betYes);

        _marketUniqueIdCounter += market.tokenSlots();

        emit FlightDelayMarketCreated(marketId, uniqueId, _msgSender(), flightInfo, config);
    }

    /// @notice Sets the trusted signer of Trustus package
    function setIsTrusted(address account_, bool trusted_)
        external
        onlyOwner
    {
        if (account_ == address(0)) {
            revert ZeroAddress();
        }

        _setIsTrusted(account_, trusted_);
    }

    function setWallet(LPWallet lpWallet_)
        external
        onlyOwner
    {
        _lpWallet = lpWallet_;
    }

    function wallet()
        external
        view
        returns (address)
    {
        return address(_lpWallet);
    }

    // hooks
    function onMarketLiquidity(bytes32 marketId, address provider, uint256 value) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketLiquidityProvided(marketId, provider, value);
    }

    function onMarketParticipate(bytes32 marketId, address account, uint256 value, bool betYes, uint256 amount) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketParticipated(marketId, account, value, betYes, amount);
    }

    function onMarketWithdraw(bytes32 marketId, address account, uint256 amount, bool betYes, uint256 value) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketWithdrawn(marketId, account, amount, betYes, value);
    }

    function onMarketSettle(bytes32 marketId, bool yesWin) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketSettled(marketId, yesWin);
    }

    function onMarketClaim(bytes32 marketId, address account, uint256 value) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketClaimed(marketId, account, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IFlightStatusOracle {
    function requestFlightStatus(
        string calldata flightName,
        uint64 departureDate,
        bytes4 callback
    ) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMarket.sol";

interface ILPWallet {
    function provideLiquidity(IMarket market, uint256 amount) external;
    function withdraw(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMarket {
    enum DecisionState {
        NO_DECISION,
        DECISION_NEEDED,
        DECISION_LOADING,
        DECISION_RENDERED
    }

    enum Result {
        UNDEFINED,
        YES,
        NO
    }

    enum Mode {
        BURN,
        BUYER
    }

    struct FinalBalance {
        uint256 bank;
        uint256 yes;
        uint256 no;
    }

    struct Config {
        uint64 cutoffTime;
        uint64 closingTime;

        uint256 lpBid;
        uint256 minBid;
        uint256 maxBid;
        uint16 initP;
        uint16 fee;

        Mode mode;

        address oracle;
    }

    function provideLiquidity() external payable returns (bool success);
    function product() external view returns (address);
    function marketId() external view returns (bytes32);
    function tokenIds() external view returns (uint256 tokenIdYes, uint256 tokenIdNo);
    function finalBalance() external view returns (FinalBalance memory);
    function decisionState() external view returns (DecisionState);
    function config() external view returns (Config memory);
    function tvl() external view returns (uint256);
    function result() external view returns (Result);
    function currentDistribution() external view returns (uint256);
    function canBeSettled() external view returns (bool);
    function trySettle() external;
    function priceETHToYesNo(uint256 amountIn) external view returns (uint256, uint256);
    function priceETHForYesNo(uint256 amountOut) external view returns (uint256, uint256);
    function participate(bool betYes) external payable;
    function withdrawBet(uint256 amount, bool betYes) external;
    function claim() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IProduct {
    function getMarket(bytes32 marketId) external view returns (address);

    // hooks
    function onMarketLiquidity(bytes32 marketId, address provider, uint256 value) external;
    function onMarketParticipate(bytes32 marketId, address account, uint256 value, bool betYes, uint256 amount) external;
    function onMarketWithdraw(bytes32 marketId, address account, uint256 amount, bool betYes, uint256 value) external;
    function onMarketSettle(bytes32 marketId, bool yesWin) external;
    function onMarketClaim(bytes32 marketId, address account, uint256 value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRegistry {
    function getAddress(uint64 id) external view returns (address);
    function getId(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITokensRepository {
    function totalSupply(uint256 tokenId) external view returns (uint256);
    function mint(address to, uint256 tokenId, uint256 amount) external;
    function burn(address holder, uint256 tokenId, uint256 amount) external;
    function balanceOf(address holder, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "./interfaces/ILPWallet.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IRegistry.sol";
import "./utils/RegistryMixin.sol";

contract LPWallet is ILPWallet, ERC1155Receiver, Ownable, RegistryMixin {

    constructor(IRegistry registry_)
        RegistryMixin(registry_)
    { }

    function provideLiquidity(IMarket market, uint256 amount)
        external
        override
        onlyProduct
    {
        bool success = market.provideLiquidity{value: amount}();
        require(success, "Can't provide liquidity");
    }

    function withdraw(address to, uint256 amount)
        external
        onlyOwner
    {
        (bool sent,) = payable(to).call{value: amount}("");
        require(sent, "Can't withdraw");
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 tokenId,
        uint256,
        bytes calldata
    )
        external
        view
        onlyMarketTokens(operator, tokenId)
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata tokenIds,
        uint256[] calldata,
        bytes calldata
    )
        external
        view
        onlyMarketTokensMultiple(operator, tokenIds)
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./interfaces/ITokensRepository.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IProduct.sol";

abstract contract PredictionMarket is IMarket, IERC165, ReentrancyGuard {
    event DecisionRendered(Result result);
    event DecisionPostponed();
    event LiquidityProvided(address provider, uint256 amount);
    event ParticipatedInMarket(address indexed participant, uint256 amount, bool betYes);
    event BetWithdrawn(address indexed participant, uint256 amount, bool betYes);
    event RewardWithdrawn(address indexed participant, uint256 amount);

    bytes32 _marketId;
    uint256 _uniqueId;
    DecisionState _decisionState;
    Result _result;
    uint256 _ammConst;

    ITokensRepository _tokensRepo;
    FinalBalance _finalBalance;
    address payable _liquidityProvider;
    address payable _feeCollector;
    address private _createdBy;
    IProduct _product;

    Config _config;

    mapping (address => uint256) _bets;
    uint256 _tvl;

    uint256 private immutable _tokensBase = 10000;

    constructor(
        Config memory config_,
        uint256 uniqueId_,
        bytes32 marketId_,
        ITokensRepository tokensRepo_,
        address payable feeCollector_,
        IProduct product_
    ) {
        _config = config_;
        _uniqueId = uniqueId_;
        _marketId = marketId_;
        _tokensRepo = tokensRepo_;
        _feeCollector = feeCollector_;
        _product = product_;

        _createdBy = msg.sender;
    }

    function product() external view returns (address) {
        return address(_product);
    }

    function marketId() external view returns (bytes32) {
        return _marketId;
    }

    function createdBy() external view returns (address) {
        return _createdBy;
    }

    function tokenSlots() external pure returns (uint8) {
        return 2;
    }

    function finalBalance() external view returns (FinalBalance memory) {
        return _finalBalance;
    }

    function decisionState() external view returns (DecisionState) {
        return _decisionState;
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function tvl() external view returns (uint256) {
        return _tvl;
    }

    function result() external view returns (Result) {
        return _result;
    }

    function tokenIds() external view returns (uint256 tokenIdYes, uint256 tokenIdNo) {
        tokenIdYes = _tokenIdYes();
        tokenIdNo = _tokenIdNo();
    }

    /// @dev Returns the current distribution of tokens in the market. 2439 = 2.439%
    function currentDistribution() external view returns (uint256) {
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes()); // 250
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo()); // 10240

        uint256 grandTotal = totalYes + totalNo; // 10290
        return totalYes * _tokensBase / grandTotal; // 250 * 10000 / 10290 = 2439
    }

    function canBeSettled()
        external
        view
        returns (bool)
    {
        bool stateCheck = _decisionState == DecisionState.NO_DECISION || _decisionState == DecisionState.DECISION_NEEDED;
        bool timeCheck = _config.closingTime < block.timestamp;
        return stateCheck && timeCheck;
    }

    function trySettle() external {
        require(block.timestamp > _config.cutoffTime, "Market is not closed yet");
        require(_decisionState == DecisionState.NO_DECISION || _decisionState == DecisionState.DECISION_NEEDED, "Wrong market state");

        _trySettle();

        _decisionState = DecisionState.DECISION_LOADING;

        _finalBalance = FinalBalance(
            _tvl,
            _tokensRepo.totalSupply(_tokenIdYes()),
            _tokensRepo.totalSupply(_tokenIdNo())
        );
    }

    function recordDecision(bytes calldata payload) external {
        require(msg.sender == address(_config.oracle), "Unauthorized sender");
        require(_decisionState == DecisionState.DECISION_LOADING, "Wrong state");

        (_decisionState, _result) = _renderDecision(payload);

        if (_decisionState == DecisionState.DECISION_RENDERED) {
            _claim(_liquidityProvider, true);
            emit DecisionRendered(_result);
            _product.onMarketSettle(_marketId, _result == Result.YES);
        } else if (_decisionState == DecisionState.DECISION_NEEDED) {
            emit DecisionPostponed();
        }
    }

    function priceETHToYesNo(
        uint256 amountIn
    )
        external
        view
        returns (uint256, uint256)
    {
        // adjusts the fee
        amountIn -= amountIn * _config.fee / 10000;

        return _priceETHToYesNo(amountIn);
    }

    function priceETHForYesNo(
        uint256 amountOut
    )
        external
        view
        returns (uint256, uint256)
    {
        return _priceETHForYesNo(amountOut);
    }

    function provideLiquidity()
        external
        override
        payable
        returns (bool)
    {
        require(_liquidityProvider == address(0), "Already provided");
        require(msg.value == _config.lpBid, "Not enough to init");

        uint256 amountLPYes = _tokensBase * (10**18) * uint256(_config.initP) / 10000;
        uint256 amountLPNo = _tokensBase * (10**18) * (10000 - uint256(_config.initP)) / 10000;

        _ammConst = amountLPYes * amountLPNo;
        _liquidityProvider = payable(msg.sender);
        _tvl += msg.value;

        _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), amountLPYes);
        _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), amountLPNo);

        emit LiquidityProvided(_liquidityProvider, msg.value);

        _product.onMarketLiquidity(_marketId, msg.sender, msg.value);

        return true;
    }

    function participate(
        bool betYes
    )
        external
        payable
        nonReentrant
    {
        // TODO: add slippage guard
        _beforeAddBet(msg.sender, msg.value);
        _addBet(msg.sender, betYes, msg.value);
    }

    function registerParticipant(
        address account,
        bool betYes
    )
        external
        payable
        nonReentrant
    {
        require(msg.sender == address(_product), "Unknown caller");

        _beforeAddBet(account, msg.value);
        _addBet(account, betYes, msg.value);
    }

    function withdrawBet(
        uint256 amount,
        bool betYes
    )
        external
        nonReentrant
    {
        require(_decisionState == DecisionState.NO_DECISION, "Wrong state");
        require(_config.cutoffTime > block.timestamp, "Market is closed");

        _withdrawBet(betYes, amount);
    }

    function claim()
        external
        nonReentrant
    {
        require(_decisionState == DecisionState.DECISION_RENDERED);
        require(_result != Result.UNDEFINED);

        _claim(msg.sender, false);
    }

    function _priceETHToYesNo(
        uint256 amountIn
    )
        internal
        view
        returns (uint256 amountOutYes, uint256 amountOutNo)
    {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        amountOutYes = amountIn * totalYes / amountBank;
        amountOutNo = amountIn * totalNo / amountBank;
    }

    function _priceETHForYesNo(
        uint256 amountOut
    )
        internal
        view
        returns (uint256 amountInYes, uint256 amountInNo)
    {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        amountInYes = amountOut * amountBank / totalYes;
        amountInNo = amountOut * amountBank / totalNo;
    }

    function _addBet(
        address account,
        bool betYes,
        uint256 value
    ) internal {
        uint256 fee = value * uint256(_config.fee) / 10000;
        value -= fee;

        uint256 userPurchaseYes;
        uint256 userPurchaseNo;
        (userPurchaseYes, userPurchaseNo) = _priceETHToYesNo(value);

        // 4. Mint for user and for DFI
        // 5. Also balance out DFI
        uint256 userPurchase;
        if (betYes) {
            userPurchase = userPurchaseYes;
            _tokensRepo.mint(account, _tokenIdYes(), userPurchaseYes);
            _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), userPurchaseNo);
        } else {
            userPurchase = userPurchaseNo;
            _tokensRepo.mint(account, _tokenIdNo(), userPurchaseNo);
            _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), userPurchaseYes);
        }

        _balanceLPTokens(account, betYes, false);

        _bets[account] += value;
        _tvl += value;

        (bool sent,) = _feeCollector.call{value: fee}("");
        require(sent, "Cannot distribute the fee");

        // Check in AMM product is the same
        // FIXME: will never be the same because of rounding
        // amountLPYes = balanceOf(address(_lpWallet), tokenIdYes);
        // amountLPNo = balanceOf(address(_lpWallet), tokenIdNo);
        // require(ammConst == amountDfiYes * amountDfiNo, "AMM const is wrong");

        emit ParticipatedInMarket(account, value, betYes);
        _product.onMarketParticipate(_marketId, account, value, betYes, userPurchase);
    }

    function _withdrawBet(
        bool betYes,
        uint256 amount
    ) internal {
        uint256 userRefundYes;
        uint256 userRefundNo;
        (userRefundYes, userRefundNo) = _priceETHForYesNo(amount);

        uint256 userRefund;
        if (betYes) {
            userRefund = userRefundYes;

            _tokensRepo.burn(msg.sender, _tokenIdYes(), amount);
            _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), amount);
        } else {
            userRefund = userRefundNo;

            _tokensRepo.burn(msg.sender, _tokenIdNo(), amount);
            _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), amount);
        }

        _balanceLPTokens(msg.sender, !betYes, true);

        // 6. Check in AMM product is the same
        // FIXME: will never be the same because of rounding
        // amountLpYes = balanceOf(address(_lpWallet), tokenIdYes);
        // amountLpNo = balanceOf(address(_lpWallet), tokenIdNo);
        // require(ammConst == amountLpYes * amountLpNo, "AMM const is wrong");

        if (userRefund > _bets[msg.sender]) {
            _bets[msg.sender] = 0;
        } else {
            _bets[msg.sender] -= userRefund;
        }
        _tvl -= userRefund;

        // TODO: add a fee or something
        (bool sent,) = payable(msg.sender).call{value: userRefund}("");
        require(sent, "Cannot withdraw");

        emit BetWithdrawn(msg.sender, userRefund, betYes);
        _product.onMarketWithdraw(_marketId, msg.sender, amount, betYes, userRefund);
    }

    function _balanceLPTokens(address account, bool fixYes, bool isWithdraw) internal {
        uint256 tokenIdYes = _tokenIdYes();
        uint256 tokenIdNo = _tokenIdNo();

        uint256 amountLPYes = _tokensRepo.balanceOf(_liquidityProvider, tokenIdYes);
        uint256 amountLPNo = _tokensRepo.balanceOf(_liquidityProvider, tokenIdNo);

        if (fixYes) {
            uint256 newAmountYes = _ammConst / amountLPNo;
            if (amountLPYes > newAmountYes) {
                uint256 toBurn = amountLPYes - newAmountYes;
                if (_config.mode == Mode.BUYER && !isWithdraw) {
                    _tokensRepo.burn(_liquidityProvider, tokenIdYes, toBurn);
                    _tokensRepo.mint(account, tokenIdYes, toBurn);
                } else {
                    _tokensRepo.burn(_liquidityProvider, tokenIdYes, toBurn);
                }
            } else {
                uint256 toMint = newAmountYes - amountLPYes;
                _tokensRepo.mint(_liquidityProvider, tokenIdYes, toMint);
            }
        } else {
            uint256 newAmountNo = _ammConst / amountLPYes;
            if (amountLPNo > newAmountNo) {
                uint256 toBurn = amountLPNo - newAmountNo;
                if (_config.mode == Mode.BUYER && !isWithdraw) {
                    _tokensRepo.burn(_liquidityProvider, tokenIdNo, toBurn);
                    _tokensRepo.mint(account, tokenIdNo, toBurn);
                } else {
                    _tokensRepo.burn(_liquidityProvider, tokenIdNo, toBurn);
                }
            } else {
                uint256 toMint = newAmountNo - amountLPNo;
                _tokensRepo.mint(_liquidityProvider, tokenIdNo, toMint);
            }
        }
    }

    function _claim(address account, bool silent)
        internal
    {
        bool yesWins = _result == Result.YES;

        uint256 reward;
        // TODO: if Yes wins and you had NoTokens - it will never be burned
        if (yesWins) {
            uint256 balance = _tokensRepo.balanceOf(account, _tokenIdYes());
            if (!silent) {
                require(balance > 0, "Nothing to withdraw");
            }

            reward = balance * _finalBalance.bank / _finalBalance.yes;

            _tokensRepo.burn(account, _tokenIdYes(), balance);
        } else {
            uint256 balance = _tokensRepo.balanceOf(account, _tokenIdNo());
            if (!silent) {
                require(balance > 0, "Nothing to withdraw");
            }

            reward = balance * _finalBalance.bank / _finalBalance.no;

            _tokensRepo.burn(account, _tokenIdNo(), balance);
        }

        if (reward > 0) {
            (bool sent,) = payable(account).call{value: reward}("");
            require(sent, "Cannot withdraw");

            emit RewardWithdrawn(account, reward);
            _product.onMarketClaim(_marketId, account, reward);
        }
    }

    function _tokenIdYes() internal view returns (uint256) {
        return _uniqueId;
    }

    function _tokenIdNo() internal view returns (uint256) {
        return _uniqueId + 1;
    }

    function _beforeAddBet(address account, uint256 amount) internal virtual view {
        require(_config.cutoffTime > block.timestamp, "Market is closed");
        require(_decisionState == DecisionState.NO_DECISION, "Wrong state");
        require(amount >= _config.minBid, "Value included is less than min-bid");

        uint256 balance = _bets[account];
        require(balance + amount <= _config.maxBid, "Exceeded max bid");
    }

    function _trySettle() internal virtual;
    function _renderDecision(bytes calldata) internal virtual returns (DecisionState, Result);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IMarket).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

/// @title Trustus
/// @author zefram.eth
/// @notice Trust-minimized method for accessing offchain data onchain
abstract contract Trustus {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param v Part of the ECDSA signature
    /// @param r Part of the ECDSA signature
    /// @param s Part of the ECDSA signature
    /// @param request Identifier for verifying the packet is what is desired
    /// , rather than a packet for some other function/contract
    /// @param deadline The Unix timestamp (in seconds) after which the packet
    /// should be rejected by the contract
    /// @param payload The payload of the packet
    struct TrustusPacket {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 request;
        uint256 deadline;
        bytes payload;
    }

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Trustus__InvalidPacket();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The chain ID used by EIP-712
    uint256 internal immutable INITIAL_CHAIN_ID;

    /// @notice The domain separator used by EIP-712
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Records whether an address is trusted as a packet provider
    /// @dev provider => value
    mapping(address => bool) internal isTrusted;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Verifies whether a packet is valid and returns the result.
    /// Will revert if the packet is invalid.
    /// @dev The deadline, request, and signature are verified.
    /// @param request The identifier for the requested payload
    /// @param packet The packet provided by the offchain data provider
    modifier verifyPacket(bytes32 request, TrustusPacket calldata packet) {
        if (!_verifyPacket(request, packet)) revert Trustus__InvalidPacket();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// Packet verification
    /// -----------------------------------------------------------------------

    /// @notice Verifies whether a packet is valid and returns the result.
    /// @dev The deadline, request, and signature are verified.
    /// @param request The identifier for the requested payload
    /// @param packet The packet provided by the offchain data provider
    /// @return success True if the packet is valid, false otherwise
    function _verifyPacket(bytes32 request, TrustusPacket calldata packet)
    internal
    virtual
    returns (bool success)
    {
        // verify deadline
        if (block.timestamp > packet.deadline) return false;

        // verify request
        if (request != packet.request) return false;

        // verify signature
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "VerifyPacket(bytes32 request,uint256 deadline,bytes payload)"
                            ),
                            packet.request,
                            packet.deadline,
                            keccak256(packet.payload)
                        )
                    )
                )
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return (recoveredAddress != address(0)) && isTrusted[recoveredAddress];
    }

    /// @notice Sets the trusted status of an offchain data provider.
    /// @param signer The data provider's ECDSA public key as an Ethereum address
    /// @param isTrusted_ The desired trusted status to set
    function _setIsTrusted(address signer, bool isTrusted_) internal virtual {
        isTrusted[signer] = isTrusted_;
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 compliance
    /// -----------------------------------------------------------------------

    /// @notice The domain separator used by EIP-712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
        block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : _computeDomainSeparator();
    }

    /// @notice Computes the domain separator used by EIP-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Trustus"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IProduct.sol";
import "../interfaces/IRegistry.sol";

abstract contract RegistryMixin {
    IRegistry _registry;

    constructor(IRegistry registry_) {
        _registry = registry_;
    }

    function isValidMarket(address operator) internal view returns (bool) {
        // check if it's even a market
        bool isMarket = IERC165(operator).supportsInterface(type(IMarket).interfaceId);
        require(isMarket);

        // get the product market claims it belongs to
        IMarket market = IMarket(operator);
        address productAddr = market.product();
        // check if the product is registered
        require(_registry.getId(productAddr) != 0, "Unknown product");

        // check that product has the market with the same address
        IProduct product = IProduct(productAddr);
        require(product.getMarket(market.marketId()) == operator, "Unknown market");

        return true;
    }

    modifier onlyMarket(address operator) {
        require(isValidMarket(operator));
        _;
    }

    modifier onlyMarketTokens(address operator, uint256 tokenId) {
        require(isValidMarket(operator));

        IMarket market = IMarket(operator);

        // check that market is modifying the tokens it controls
        (uint256 tokenIdYes, uint256 tokenIdNo) = market.tokenIds();
        require(tokenId == tokenIdYes || tokenId == tokenIdNo, "Wrong tokens");

        _;
    }

    modifier onlyMarketTokensMultiple(address operator, uint256[] calldata tokenIds) {
        require(isValidMarket(operator));

        IMarket market = IMarket(operator);

        // check that market is modifying the tokens it controls
        (uint256 tokenIdYes, uint256 tokenIdNo) = market.tokenIds();
        for (uint32 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] == tokenIdYes || tokenIds[i] == tokenIdNo, "Wrong tokens");
        }

        _;
    }

    modifier onlyProduct() {
        require(_registry.getId(msg.sender) != 0, "Unknown product");
        _;
    }
}