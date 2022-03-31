// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./ICardTokenProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CardTokenProxy.sol";

contract CardTokenProxyFactory is Ownable {
    //
    // --- Errors
    //

    error CardTokenProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new CardTokenProxy());

        if (implementation == address(0)) {
            revert CardTokenProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(
        bytes32 salt,
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares,
        uint256 tokenSupplyCap,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId
    ) public onlyOwner returns (address) {
        address clone = Clones.cloneDeterministic(implementation, salt);
        ICardTokenProxy(clone).initialize(
            msg.sender,
            name,
            symbol,
            contractRegistry,
            creators,
            creatorRoyaltyShares,
            tokenSupplyCap,
            scoreMin,
            scoreMax,
            scoreScale,
            scoreMaxTokenId
        );

        return clone;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardTokenProxy {
    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares,
        uint256 tokenSupplyCap,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// constants
import { CARD_TOKEN_SCORING_NAME_HASH } from "../registry/constants.sol";

// libs
import "../royalties/RoyaltySharesLib.sol";

// interfaces
import "../registry/IContractRegistry.sol";
import "./ICardTokenScoring.sol";
import "./ICardToken.sol";
import "./ICardTokenProxy.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CappedSupplyInitAbstract.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CompatibilityForERC721InitAbstract.sol";
import "../lsp/LSP8Metadata.sol";
import "../lsp/OpenSeaCompatForLSP8.sol";
import "../registry/UsesContractRegistryProxy.sol";
import "../royalties/RoyaltySharesProxy.sol";
import "./CardMarket.sol";
// TODO: remove me one day soon
import "../lsp/TemporaryLSP4Compatability.sol";

contract CardTokenProxy is
    ICardToken,
    ICardTokenProxy,
    Initializable,
    Pausable,
    LSP8CompatibilityForERC721InitAbstract,
    LSP8CappedSupplyInitAbstract,
    LSP8Metadata,
    RoyaltySharesProxy,
    UsesContractRegistryProxy,
    TemporaryLSP4Compatability,
    CardMarket,
    OpenSeaCompatForLSP8
{
    //
    // --- Storage
    //

    // TODO: could pack score values together to save some gas on initialize
    uint256 private _scoreMin;
    uint256 private _scoreMax;
    uint256 private _scoreScale;
    uint256 private _scoreMaxTokenId;

    //
    // --- Errors
    //

    error CardTokenScoreRange();
    error CardTokenScoreScaleZero();
    error CardTokenScoreMaxTokenIdZero();
    error CardTokenScoreMaxTokenIdLargerThanSupplyCap();
    error CardTokenInvalidTokenId(bytes32 tokenId);

    //
    // --- Modifiers
    //

    modifier onlyValidTokenId(bytes32 tokenId) {
        _onlyValidTokenId(tokenId);

        _;
    }

    function _onlyValidTokenId(bytes32 tokenId) internal view {
        uint256 tokenIdAsNumber = uint256(tokenId);

        if (tokenIdAsNumber == 0 || tokenIdAsNumber > tokenSupplyCap()) {
            revert CardTokenInvalidTokenId(tokenId);
        }
    }

    //
    // --- Initialize
    //

    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares,
        uint256 tokenSupplyCap,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId
    ) public override initializer {
        LSP8CompatibilityForERC721InitAbstract._initialize(name, symbol, owner);
        LSP8CappedSupplyInitAbstract._initialize(tokenSupplyCap);
        _initializeUsesContractRegistry(contractRegistry);
        _initializeRoyaltyShares(creators, creatorRoyaltyShares);

        if (scoreMin > scoreMax) {
            revert CardTokenScoreRange();
        }
        _scoreMin = scoreMin;
        _scoreMax = scoreMax;

        if (scoreScale == 0) {
            revert CardTokenScoreScaleZero();
        }
        _scoreScale = scoreScale;

        if (scoreMaxTokenId == 0) {
            revert CardTokenScoreMaxTokenIdZero();
        }
        if (scoreMaxTokenId > tokenSupplyCap) {
            revert CardTokenScoreMaxTokenIdLargerThanSupplyCap();
        }
        _scoreMaxTokenId = scoreMaxTokenId;
    }

    //
    // --- Token queries
    //

    /**
     * @dev Returns the number of tokens available to be minted.
     */
    function mintableSupply() public view override returns (uint256) {
        return tokenSupplyCap() - totalSupply();
    }

    //
    // --- TokenId queries
    //

    /**
     * @dev Returns the score for a given `tokenId`.
     */
    function calculateScore(bytes32 tokenId)
        public
        view
        override
        onlyValidTokenId(tokenId)
        returns (string memory)
    {
        uint256 tokenIdAsNumber = uint256(tokenId);

        return
            ICardTokenScoring(_getCardTokenScoringAddress()).calculateScore(
                tokenSupplyCap(),
                _scoreMin,
                _scoreMax,
                _scoreScale,
                _scoreMaxTokenId,
                tokenIdAsNumber
            );
    }

    //
    // --- Unpacking logic
    //

    /**
     * @dev Mints a `tokenId` to `to`.
     *
     * Returns the `mintableSupply` for the caller to know when it is no longer available for unpack
     * requests.
     *
     * Requirements:
     *
     * - `mintableSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function unpackCard(address to, bytes32 tokenId)
        public
        override
        onlyOwner
        onlyValidTokenId(tokenId)
        returns (uint256)
    {
        // TODO(future version): eventually this function should be called from a CardManager contract for better
        // control of unpacking on-chain and visibility when creating new cards; instead of onlyOwner
        // modifier we might want a different access control pattern

        // using force=true to allow minting a token to an EOA or contract that isnt an UniversalProfile
        _mint(to, tokenId, true, "");

        // inform the caller about mintable supply
        return mintableSupply();
    }

    //
    // --- Pause logic
    //

    function pause() public onlyOwner {
        _pause();
    }

    //
    // --- Metadata logic
    //

    /*
     * @dev Creates a metadata contract (ERC725Y) for `tokenId`.
     *
     * Returns the created contract address.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function createMetadataFor(bytes32 tokenId)
        public
        override
        onlyOwner
        onlyValidTokenId(tokenId)
        whenNotPaused
        returns (address)
    {
        _existsOrError(tokenId);

        // TODO(future version): eventually this function could be called from a CardManager contract for better
        // control over all deployed CardTokens; instead of onlyOwner modifier we might want a
        // different access control pattern

        return _createMetadataFor(tokenId);
    }

    //
    // --- Contract Registry queries
    //

    function _getCardTokenScoringAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .getRegisteredContract(CARD_TOKEN_SCORING_NAME_HASH);
    }

    //
    // --- Public override
    //

    // TODO: we shouldnt need to do this.. instead each initialize function should have unique name
    // so we dont have function selector collision (ie. __LSP8IdentifiableDigitalAsset_initialize)
    function _initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetInitAbstract,
            LSP8CompatibilityForERC721InitAbstract
        )
    {
        super.initialize(name_, symbol_, newOwner_);
    }

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            ILSP8IdentifiableDigitalAsset,
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract
        )
    {
        super.authorizeOperator(operator, tokenId);
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=true so that any address may receive the tokenId.
     * Change added to support transfer on third-party platforms (ex: OpenSea)
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), true, "");
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=true so that any address may receive the tokenId.
     * Change added to support transfer on third-party platforms (ex: OpenSea)
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), true, data);
    }

    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override(LSP8CompatibilityForERC721Core, OpenSeaCompatForLSP8)
        returns (bool)
    {
        return super.isApprovedForAll(tokenOwner, operator);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(LSP8CompatibilityForERC721Core, OpenSeaCompatForLSP8)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    //
    // --- Internal override
    //

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract,
            CardMarket,
            TemporaryLSP4Compatability
        )
        whenNotPaused
    {
        super._transfer(from, to, tokenId, force, data);
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract,
            LSP8CappedSupplyInitAbstract,
            TemporaryLSP4Compatability
        )
        whenNotPaused
    {
        super._mint(to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract,
            CardMarket
        )
        whenNotPaused
    {
        super._burn(tokenId, data);
    }

    function _isOperatorOrOwner(address caller, bytes32 tokenId)
        internal
        view
        virtual
        override(LSP8IdentifiableDigitalAssetCore, OpenSeaCompatForLSP8)
        returns (bool)
    {
        return super._isOperatorOrOwner(caller, tokenId);
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// keccak256("FeeCollector")
bytes32 constant FEE_COLLECTOR_NAME_HASH = 0xd59ed7e0cf777b70bff43b36b5e7942a53db5cdc1ed3eac0584ffe6898bb47cd;

// keccak256("CardTokenScoring")
bytes32 constant CARD_TOKEN_SCORING_NAME_HASH = 0xdffe073e73d032dfae2943de6514599be7d9b1cd7b5ff3c3cafaeafef9ce8120;

// keccak256("OpenSeaProxy")
bytes32 constant OPENSEA_PROXY_NAME_HASH = 0x0cef494da2369e60d9db5c21763fa9ba82fceb498a37b9aaa12fe66296738da9;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

library RoyaltySharesLib {
    struct RoyaltyShare {
        address receiver;
        // using basis points to describe shares
        uint96 share;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IContractRegistry {
    //
    // --- Events
    //

    event RegisteredContract(bytes32 nameHash, address target);
    event WhitelistedToken(address token, bool whitelisted);

    //
    // --- Registry Queries
    //

    function getRegisteredContract(bytes32 nameHash)
        external
        view
        returns (address);

    //
    // --- Registry Logic
    //

    function setRegisteredContract(bytes32 nameHash, address target) external;

    function removeRegisteredContract(bytes32 nameHash) external;

    //
    // --- Whitelist Token Queries
    //

    function isWhitelistedToken(address token) external view returns (bool);

    function allWhitelistedTokens() external view returns (address[] memory);

    //
    // --- Whitelist Token Logic
    //

    function setWhitelistedToken(address token) external;

    function removeWhitelistedToken(address token) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface ICardTokenScoring {
    function calculateScore(
        uint256 tokenSupply,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId,
        uint256 tokenId
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardToken {
    //
    // --- Token queries
    //

    /**
     * @dev Returns the number of tokens available to be minted.
     */
    function mintableSupply() external view returns (uint256);

    //
    // --- TokenId queries
    //

    /**
     * @dev Returns the score for a given `tokenId`.
     */
    function calculateScore(bytes32 tokenId) external returns (string memory);

    //
    // --- Unpacking logic
    //

    /**
     * @dev Mints a `tokenId` and transfers it to `to`.
     *
     * Returns the `mintableSupply` for the caller to know when it is no longer available for unpack
     * requests.
     *
     * Requirements:
     *
     * - `mintableSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function unpackCard(address to, bytes32 tokenId) external returns (uint256);

    //
    // --- Owner logic
    //

    /*
     * @dev Creates a metadata contract (ERC725Y) for `tokenId`.
     *
     * Returns the created contract address.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function createMetadataFor(bytes32 tokenId) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "./LSP8CappedSupplyCore.sol";
import "../LSP8IdentifiableDigitalAssetInit.sol";

/**
 * @dev LSP8 extension, adds token supply cap.
 */
abstract contract LSP8CappedSupplyInitAbstract is
    Initializable,
    LSP8CappedSupplyCore,
    LSP8IdentifiableDigitalAssetInit
{
    function _initialize(uint256 tokenSupplyCap_)
        internal
        virtual
        onlyInitializing
    {
        if (tokenSupplyCap_ == 0) {
            revert LSP8CappedSupplyRequired();
        }

        _tokenSupplyCap = tokenSupplyCap_;
    }

    // --- Overrides

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenSupplyCap() - totalSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(LSP8IdentifiableDigitalAssetCore, LSP8CappedSupplyCore)
    {
        super._mint(to, tokenId, force, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "./LSP8CompatibilityForERC721Core.sol";
import "../LSP8IdentifiableDigitalAssetInitAbstract.sol";

// constants
import "./LSP8CompatibilityConstants.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
contract LSP8CompatibilityForERC721InitAbstract is
    LSP8CompatibilityForERC721Core,
    LSP8IdentifiableDigitalAssetInitAbstract
{
    function _initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) internal virtual override onlyInitializing {
        LSP8IdentifiableDigitalAssetInitAbstract._initialize(
            name_,
            symbol_,
            newOwner_
        );
    }

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super.authorizeOperator(operator, tokenId);
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._transfer(from, to, tokenId, force, data);
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._mint(to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._burn(tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, LSP8IdentifiableDigitalAssetInitAbstract)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_ERC721 ||
            interfaceId == _INTERFACEID_ERC721METADATA ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libraries
import "@lukso/lsp-smart-contracts/contracts/Utils/ERC725Utils.sol";

// modules
import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetCore.sol";
import "@erc725/smart-contracts/contracts/ERC725YCore.sol";

// TODO: this should be in
// "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions"

abstract contract LSP8Metadata is
    LSP8IdentifiableDigitalAssetCore,
    ERC725YCore
{
    //
    // --- Metadata queries
    //

    event MetadataAddressCreated(
        bytes32 indexed tokenId,
        address metadataAddress
    );

    function metadataAddressOf(bytes32 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "LSP8Metadata: metadata query for nonexistent token"
        );

        bytes memory value = ERC725Utils.getDataSingle(
            this,
            _buildMetadataKey(tokenId, true)
        );

        if (value.length == 0) {
            return address(0);
        } else {
            return address(bytes20(value));
        }
    }

    function metadataJsonOf(bytes32 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "LSP8Metadata: metadata query for nonexistent token"
        );

        bytes memory value = ERC725Utils.getDataSingle(
            this,
            _buildMetadataKey(tokenId, false)
        );

        return abi.decode(value, (string));
    }

    function _buildMetadataKey(bytes32 tokenId, bool buildAddressKey)
        internal
        pure
        returns (bytes32)
    {
        return
            bytes32(
                abi.encodePacked(
                    buildAddressKey
                        ? _LSP8_METADATA_ADDRESS_KEY_PREFIX
                        : _LSP8_METADATA_JSON_KEY_PREFIX,
                    bytes20(keccak256(abi.encodePacked(tokenId)))
                )
            );
    }

    //
    // --- Metadata functionality
    //

    /**
     * @dev Create a ERC725Y contract to be used for metadata storage of `tokenId`.
     */
    function _createMetadataFor(bytes32 tokenId)
        internal
        virtual
        returns (address)
    {
        require(
            _exists(tokenId),
            "LSP8: metadata creation for nonexistent token"
        );

        bytes32 metadataKeyForTokenId = _buildMetadataKey(tokenId, true);

        bytes memory existingMetadataValue = _getData(metadataKeyForTokenId);
        if (existingMetadataValue.length > 0) {
            address existingMetadataAddress = address(
                bytes20(existingMetadataValue)
            );
            return existingMetadataAddress;
        }

        // TODO: can use a proxy pattern here / have a factory registed in ContractRegistry
        //
        // NOTE: the owner for the ERC725Y will be the current owner of the CardToken. If the owner
        // for CardToken ever changes, all metadata contracts could also have their owner changed..
        address metadataAddress = address(new ERC725Y(_msgSender()));
        _setData(metadataKeyForTokenId, abi.encodePacked(metadataAddress));

        emit MetadataAddressCreated(tokenId, metadataAddress);

        return metadataAddress;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { OPENSEA_PROXY_NAME_HASH } from "../registry/constants.sol";

// libs
import "@openzeppelin/contracts/utils/Strings.sol";

// interfaces
import "../registry/IContractRegistry.sol";

// modules
import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CompatibilityForERC721Core.sol";
import "../registry/UsesContractRegistryProxy.sol";

// NOTE: this contract allows OpenSea to be able to sell & auction tokens
//
// https://docs.opensea.io/docs/polygon-basic-integration
abstract contract OpenSeaCompatForLSP8 is
    LSP8CompatibilityForERC721Core,
    UsesContractRegistryProxy
{
    using ERC725Utils for IERC725Y;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // this is expected to return a string like `ipfs://ipfs-cid-for-a-directory/0.json`
        string memory uriString = super.tokenURI(tokenId);

        if (tokenId == 0) {
            // this is returning the `0.json` ipfs path
            return uriString;
        } else {
            // this is the offset to use, so we get the string `ipfs://ipfs-cid-for-a-directory/`
            uint256 ipfsDirectoryPrefixSize = 54;
            bytes memory ipfsURIForTokenId = new bytes(ipfsDirectoryPrefixSize);

            bytes memory strBytes = bytes(uriString);
            for (uint256 i = 0; i < ipfsDirectoryPrefixSize; i++) {
                ipfsURIForTokenId[i] = strBytes[i];
            }

            return
                string(
                    abi.encodePacked(
                        ipfsURIForTokenId,
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        }
    }

    function contractURI() public view returns (string memory) {
        return tokenURI(0);
    }

    // support for ERC721
    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == _getOpenSeaProxyAddress()) {
            return true;
        }

        return super.isApprovedForAll(tokenOwner, operator);
    }

    // support for LSP8
    function _isOperatorOrOwner(address caller, bytes32 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (caller == _getOpenSeaProxyAddress()) {
            return true;
        }

        return super._isOperatorOrOwner(caller, tokenId);
    }

    //
    // --- Contract Registry queries
    //

    function _getOpenSeaProxyAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .getRegisteredContract(OPENSEA_PROXY_NAME_HASH);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import "./IUsesContractRegistry.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract UsesContractRegistryProxy is
    IUsesContractRegistry,
    Initializable
{
    //
    // --- Errors
    //

    error ContractRegistryRequired();

    //
    // --- Storage
    //

    address private _contractRegistry;

    //
    // --- Initialize
    //

    function _initializeUsesContractRegistry(address contractRegistry_)
        internal
        onlyInitializing
    {
        if (contractRegistry_ == address(0)) {
            revert ContractRegistryRequired();
        }
        _contractRegistry = contractRegistry_;
    }

    //
    // --- Queries
    //

    function contractRegistry() public view override returns (address) {
        return _contractRegistry;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_SCALE } from "../royalties/constants.sol";

// libs
import "./RoyaltySharesLib.sol";

// interfaces
import "../royalties/IRoyaltyShares.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract RoyaltySharesProxy is IRoyaltyShares, Initializable {
    //
    // --- Errors
    //

    error RoyaltySharesRoyaltiesRequired();
    error RoyaltySharesRoyaltiesSum();

    //
    // --- Storage
    //

    RoyaltySharesLib.RoyaltyShare[] private _royalties;

    //
    // --- Initialize
    //

    function _initializeRoyaltyShares(
        address[] memory receivers,
        uint96[] memory receiverRoyaltyShares
    ) internal onlyInitializing {
        if (
            receivers.length == 0 ||
            receivers.length != receiverRoyaltyShares.length
        ) {
            revert RoyaltySharesRoyaltiesRequired();
        }

        uint256 revenueShareSum;
        for (uint256 i = 0; i < receiverRoyaltyShares.length; i++) {
            revenueShareSum += receiverRoyaltyShares[i];
            _royalties.push(
                RoyaltySharesLib.RoyaltyShare({
                    receiver: receivers[i],
                    share: receiverRoyaltyShares[i]
                })
            );
        }

        if (revenueShareSum != FEE_SCALE) {
            revert RoyaltySharesRoyaltiesSum();
        }
    }

    //
    // --- Royalty Queries
    //

    function royaltyShares()
        public
        view
        override
        returns (RoyaltySharesLib.RoyaltyShare[] memory)
    {
        return _royalties;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_COLLECTOR_NAME_HASH } from "../registry/constants.sol";

// interfaces
import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "../registry/IContractRegistry.sol";
import "../royalties/IFeeCollector.sol";
import "../royalties/IFeeCollectorRevenueShareCallback.sol";
import "./ICardMarket.sol";

// modules
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetCore.sol";
import "../registry/UsesContractRegistryProxy.sol";
import "../royalties/RoyaltySharesProxy.sol";

abstract contract CardMarket is
    ICardMarket,
    IFeeCollectorRevenueShareCallback,
    LSP8IdentifiableDigitalAssetCore,
    RoyaltySharesProxy,
    UsesContractRegistryProxy
{
    //
    // --- Errors
    //

    error CardMarketNotTokenOwner(
        address owner,
        address operator,
        bytes32 tokenId
    );
    error CardMarketNoMarket(bytes32 tokenId);
    error CardMarketMinimumAmountRequired();
    error CardMarketTokenNotWhitelisted(address token);
    error CardMarketBuyAmountTooSmall(uint256 minimumAmount, uint256 amount);

    //
    // --- Storage
    //

    mapping(bytes32 => CardMarketState) private _marketStateForTokenId;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _allMarkets;

    //
    // --- Market queries
    //

    function marketFor(bytes32 tokenId)
        public
        view
        override
        returns (CardMarketState memory)
    {
        CardMarketState storage market = _marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }

        return market;
    }

    function getAllMarkets()
        public
        view
        override
        returns (CardMarketState[] memory)
    {
        uint256 _allMarketsLength = _allMarkets.length();
        CardMarketState[] memory _allMarketsStates = new CardMarketState[](
            _allMarketsLength
        );

        for (uint256 index = 0; index < _allMarketsLength; index++) {
            bytes32 _tokenId = _allMarkets.at(index);

            _allMarketsStates[index] = marketFor(_tokenId);
        }
        return _allMarketsStates;
    }

    //
    // --- Market logic
    //

    function setMarketFor(
        bytes32 tokenId,
        address acceptedToken,
        uint256 minimumAmount
    ) public override {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();
        if (tokenOwner != operator) {
            revert CardMarketNotTokenOwner(tokenOwner, operator, tokenId);
        }

        if (minimumAmount == 0) {
            revert CardMarketMinimumAmountRequired();
        }

        if (
            !IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .isWhitelistedToken(acceptedToken)
        ) {
            revert CardMarketTokenNotWhitelisted(acceptedToken);
        }

        _marketStateForTokenId[tokenId] = CardMarketState({
            tokenId: tokenId,
            minimumAmount: minimumAmount,
            acceptedToken: acceptedToken
        });

        _allMarkets.add(tokenId);

        emit MarketSet(tokenId, acceptedToken, minimumAmount);
    }

    function removeMarketFor(bytes32 tokenId) public override {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();
        if (tokenOwner != operator) {
            revert CardMarketNotTokenOwner(tokenOwner, operator, tokenId);
        }

        CardMarketState storage market = _marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }

        _removeMarketFor(tokenId);

        emit MarketRemove(tokenId);
    }

    function buyFromMarket(
        bytes32 tokenId,
        uint256 amount,
        address referrer
    ) public override {
        CardMarketState memory market = _marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }
        if (amount < market.minimumAmount) {
            revert CardMarketBuyAmountTooSmall(market.minimumAmount, amount);
        }

        address buyer = _msgSender();
        address tokenOwner = tokenOwnerOf(tokenId);

        _removeMarketFor(tokenId);

        uint256 totalFee = IFeeCollector(_getFeeCollectorAddress())
            .shareRevenue(
                market.acceptedToken,
                amount,
                referrer,
                RoyaltySharesProxy.royaltyShares(),
                abi.encode(buyer, market.acceptedToken)
            );
        uint256 tokenOwnerAmount = amount - totalFee;

        ILSP7CompatibilityForERC20(market.acceptedToken).transferFrom(
            buyer,
            tokenOwner,
            tokenOwnerAmount
        );

        _transfer(tokenOwner, buyer, tokenId, true, "");

        emit MarketBuy(tokenId, buyer, amount);
    }

    function _removeMarketFor(bytes32 tokenId) internal {
        delete _marketStateForTokenId[tokenId];
        _allMarkets.remove(tokenId);
    }

    //
    // --- FeeCollectorCallback logic
    //

    function revenueShareCallback(
        uint256 totalFee,
        bytes calldata dataForCallback
    ) external override {
        address feeCollector = _getFeeCollectorAddress();

        if (msg.sender != feeCollector) {
            revert RevenueShareCallbackInvalidSender();
        }

        (address feePayer, address token) = abi.decode(
            dataForCallback,
            (address, address)
        );

        ILSP7CompatibilityForERC20(token).transferFrom(
            feePayer,
            feeCollector,
            totalFee
        );
    }

    //
    // --- Contract Registry queries
    //

    function _getFeeCollectorAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .getRegisteredContract(FEE_COLLECTOR_NAME_HASH);
    }

    //
    // --- Internal overrides
    //

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        _removeMarketFor(tokenId);

        super._transfer(from, to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override
    {
        _removeMarketFor(tokenId);

        super._burn(tokenId, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

//
// --- This file contains temporary code to support the change from old LSP4DigitalCertificate
//

import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetCore.sol";

// TODO: only here to satisfy current client expectation that token holders can be discovered
// directly from the contract (this is a leftover from LSP4DigitalCertificate)
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract TemporaryLSP4Compatability is
    LSP8IdentifiableDigitalAssetCore
{
    //
    // --- Storage
    //

    // TODO: only here to satisfy current client expectation that token holders can be discovered
    // directly from the contract (this is a leftover from LSP4DigitalCertificate)
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _tokenHolders;

    //
    // --- Queries
    //

    /**
     * @dev Returns a bytes32 array of all token holder addresses
     */
    function allTokenHolders() public view returns (bytes32[] memory) {
        // TODO: only here to satisfy current client expectation that token holders can be discovered
        // directly from the contract (this is a leftover from LSP4DigitalCertificate)
        return _tokenHolders._inner._values;
    }

    //
    // --- Overrides
    //

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._transfer(from, to, tokenId, force, data);

        // TODO: only here to satisfy current client expectation that token holders can be discovered
        // directly from the contract (this is a leftover from LSP4DigitalCertificate)
        _tokenHolders.add(to);
        if (balanceOf(from) == 0) {
            _tokenHolders.remove(from);
        }
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._mint(to, tokenId, force, data);

        // TODO: only here to satisfy current client expectation that token holders can be discovered
        // directly from the contract (this is a leftover from LSP4DigitalCertificate)
        _tokenHolders.add(to);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "../LSP8IdentifiableDigitalAssetCore.sol";

// interfaces
import "./ILSP8CappedSupply.sol";

/**
 * @dev LSP8 extension, adds token supply cap.
 */
abstract contract LSP8CappedSupplyCore is
    ILSP8CappedSupply,
    LSP8IdentifiableDigitalAssetCore
{
    // --- Errors

    error LSP8CappedSupplyRequired();
    error LSP8CappedSupplyCannotMintOverCap();

    // --- Storage

    uint256 internal _tokenSupplyCap;

    // --- Token queries

    /**
     * @inheritdoc ILSP8CappedSupply
     */
    function tokenSupplyCap() public view virtual override returns (uint256) {
        return _tokenSupplyCap;
    }

    // --- Transfer functionality

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenSupplyCap() - totalSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        if (totalSupply() + 1 > tokenSupplyCap()) {
            revert LSP8CappedSupplyCannotMintOverCap();
        }

        super._mint(to, tokenId, force, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP8IdentifiableDigitalAssetInitAbstract.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Proxy Implementation of a LSP8 compliant contract.
 */
contract LSP8IdentifiableDigitalAssetInit is
    LSP8IdentifiableDigitalAssetInitAbstract
{
    /**
     * @notice Sets the token-Metadata
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the the token-Metadata
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) public virtual initializer {
        LSP8IdentifiableDigitalAssetInitAbstract._initialize(
            name_,
            symbol_,
            newOwner_
        );
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// interfaces
import "../LSP1UniversalReceiver/ILSP1UniversalReceiver.sol";
import "./ILSP8IdentifiableDigitalAsset.sol";

// libraries
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Utils/ERC725Utils.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

// constants
import "./LSP8Constants.sol";
import "../LSP1UniversalReceiver/LSP1Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Core Implementation of a LSP8 compliant contract.
 */
abstract contract LSP8IdentifiableDigitalAssetCore is
    Context,
    ILSP8IdentifiableDigitalAsset
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Address for address;

    // --- Errors

    error LSP8NonExistentTokenId(bytes32 tokenId);
    error LSP8NotTokenOwner(
        address tokenOwner,
        bytes32 tokenId,
        address caller
    );
    error LSP8NotTokenOperator(bytes32 tokenId, address caller);
    error LSP8CannotUseAddressZeroAsOperator();
    error LSP8CannotSendToAddressZero();
    error LSP8TokenIdAlreadyMinted(bytes32 tokenId);
    error LSP8InvalidTransferBatch();
    error LSP8NotifyTokenReceiverContractMissingLSP1Interface(
        address tokenReceiver
    );
    error LSP8NotifyTokenReceiverIsEOA(address tokenReceiver);

    // --- Storage

    uint256 internal _existingTokens;

    // Mapping from `tokenId` to `tokenOwner`
    mapping(bytes32 => address) internal _tokenOwners;

    // Mapping `tokenOwner` to owned tokenIds
    mapping(address => EnumerableSet.Bytes32Set) internal _ownedTokens;

    // Mapping a `tokenId` to its authorized operator addresses.
    mapping(bytes32 => EnumerableSet.AddressSet) internal _operators;

    // --- Token queries

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function totalSupply() public view override returns (uint256) {
        return _existingTokens;
    }

    // --- Token owner queries

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return _ownedTokens[tokenOwner].length();
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function tokenOwnerOf(bytes32 tokenId)
        public
        view
        override
        returns (address)
    {
        address tokenOwner = _tokenOwners[tokenId];

        if (tokenOwner == address(0)) {
            revert LSP8NonExistentTokenId(tokenId);
        }

        return tokenOwner;
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function tokenIdsOf(address tokenOwner)
        public
        view
        override
        returns (bytes32[] memory)
    {
        return _ownedTokens[tokenOwner].values();
    }

    // --- Operator functionality

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override
    {
        address tokenOwner = tokenOwnerOf(tokenId);
        address caller = _msgSender();

        if (tokenOwner != caller) {
            revert LSP8NotTokenOwner(tokenOwner, tokenId, caller);
        }

        if (operator == address(0)) {
            revert LSP8CannotUseAddressZeroAsOperator();
        }

        // tokenOwner is always their own operator, no update required
        if (tokenOwner == operator) {
            return;
        }

        _operators[tokenId].add(operator);

        emit AuthorizedOperator(operator, tokenOwner, tokenId);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function revokeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override
    {
        address tokenOwner = tokenOwnerOf(tokenId);
        address caller = _msgSender();

        if (tokenOwner != caller) {
            revert LSP8NotTokenOwner(tokenOwner, tokenId, caller);
        }

        if (operator == address(0)) {
            revert LSP8CannotUseAddressZeroAsOperator();
        }

        // tokenOwner is always their own operator, no update required
        if (tokenOwner == operator) {
            return;
        }

        _revokeOperator(operator, tokenOwner, tokenId);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function isOperatorFor(address operator, bytes32 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        _existsOrError(tokenId);

        return _isOperatorOrOwner(operator, tokenId);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function getOperatorsOf(bytes32 tokenId)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        _existsOrError(tokenId);

        return _operators[tokenId].values();
    }

    function _isOperatorOrOwner(address caller, bytes32 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address tokenOwner = tokenOwnerOf(tokenId);

        return (caller == tokenOwner || _operators[tokenId].contains(caller));
    }

    // --- Transfer functionality

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) public virtual override {
        address operator = _msgSender();

        if (!_isOperatorOrOwner(operator, tokenId)) {
            revert LSP8NotTokenOperator(tokenId, operator);
        }

        _transfer(from, to, tokenId, force, data);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        bytes32[] memory tokenId,
        bool force,
        bytes[] memory data
    ) external virtual override {
        if (
            from.length != to.length ||
            from.length != tokenId.length ||
            from.length != data.length
        ) {
            revert LSP8InvalidTransferBatch();
        }

        for (uint256 i = 0; i < from.length; i++) {
            transfer(from[i], to[i], tokenId[i], force, data[i]);
        }
    }

    function _revokeOperator(
        address operator,
        address tokenOwner,
        bytes32 tokenId
    ) internal virtual {
        _operators[tokenId].remove(operator);
        emit RevokedOperator(operator, tokenOwner, tokenId);
    }

    function _clearOperators(address tokenOwner, bytes32 tokenId)
        internal
        virtual
    {
        // TODO: here is a good exmaple of why having multiple operators will be expensive.. we
        // need to clear them on token transfer
        //
        // NOTE: this may cause a tx to fail if there is too many operators to clear, in which case
        // the tokenOwner needs to call `revokeOperator` until there is less operators to clear and
        // the desired `transfer` or `burn` call can succeed.
        EnumerableSet.AddressSet storage operatorsForTokenId = _operators[
            tokenId
        ];

        uint256 operatorListLength = operatorsForTokenId.length();
        for (uint256 i = 0; i < operatorListLength; i++) {
            // we are emptying the list, always remove from index 0
            address operator = operatorsForTokenId.at(0);
            _revokeOperator(operator, tokenOwner, tokenId);
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`), and stop existing when they are burned
     * (`_burn`).
     */
    function _exists(bytes32 tokenId) internal view virtual returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    /**
     * @dev When `tokenId` does not exist then revert with an error.
     */
    function _existsOrError(bytes32 tokenId) internal view {
        if (!_exists(tokenId)) {
            revert LSP8NonExistentTokenId(tokenId);
        }
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert LSP8CannotSendToAddressZero();
        }

        if (_exists(tokenId)) {
            revert LSP8TokenIdAlreadyMinted(tokenId);
        }

        address operator = _msgSender();

        _beforeTokenTransfer(address(0), to, tokenId);

        _ownedTokens[to].add(tokenId);
        _tokenOwners[tokenId] = to;

        emit Transfer(operator, address(0), to, tokenId, force, data);

        _notifyTokenReceiver(address(0), to, tokenId, force, data);
    }

    /**
     * @dev Destroys `tokenId`, clearing authorized operators.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(bytes32 tokenId, bytes memory data) internal virtual {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();

        _beforeTokenTransfer(tokenOwner, address(0), tokenId);

        _clearOperators(tokenOwner, tokenId);

        _ownedTokens[tokenOwner].remove(tokenId);
        delete _tokenOwners[tokenId];

        emit Transfer(operator, tokenOwner, address(0), tokenId, false, data);

        _notifyTokenSender(tokenOwner, address(0), tokenId, data);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual {
        address tokenOwner = tokenOwnerOf(tokenId);
        if (tokenOwner != from) {
            revert LSP8NotTokenOwner(tokenOwner, tokenId, from);
        }

        if (to == address(0)) {
            revert LSP8CannotSendToAddressZero();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(from, to, tokenId);

        _clearOperators(from, tokenId);

        _ownedTokens[from].remove(tokenId);
        _ownedTokens[to].add(tokenId);
        _tokenOwners[tokenId] = to;

        emit Transfer(operator, from, to, tokenId, force, data);

        _notifyTokenSender(from, to, tokenId, data);
        _notifyTokenReceiver(from, to, tokenId, force, data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        bytes32 tokenId
    ) internal virtual {
        // silence compiler warning about unused variable
        tokenId;

        // token being minted
        if (from == address(0)) {
            _existingTokens += 1;
        }

        // token being burned
        if (to == address(0)) {
            _existingTokens -= 1;
        }
    }

    /**
     * @dev An attempt is made to notify the token sender about the `tokenId` changing owners using
     * LSP1 interface.
     */
    function _notifyTokenSender(
        address from,
        address to,
        bytes32 tokenId,
        bytes memory data
    ) internal virtual {
        if (
            ERC165Checker.supportsERC165(from) &&
            ERC165Checker.supportsInterface(from, _INTERFACEID_LSP1)
        ) {
            bytes memory packedData = abi.encodePacked(from, to, tokenId, data);
            ILSP1UniversalReceiver(from).universalReceiver(
                _TYPEID_LSP8_TOKENSSENDER,
                packedData
            );
        }
    }

    /**
     * @dev An attempt is made to notify the token receiver about the `tokenId` changing owners
     * using LSP1 interface. When force is FALSE the token receiver MUST support LSP1.
     *
     * The receiver may revert when the token being sent is not wanted.
     */
    function _notifyTokenReceiver(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual {
        if (
            ERC165Checker.supportsERC165(to) &&
            ERC165Checker.supportsInterface(to, _INTERFACEID_LSP1)
        ) {
            bytes memory packedData = abi.encodePacked(from, to, tokenId, data);
            ILSP1UniversalReceiver(to).universalReceiver(
                _TYPEID_LSP8_TOKENSRECIPIENT,
                packedData
            );
        } else if (!force) {
            if (to.code.length > 0) {
                revert LSP8NotifyTokenReceiverContractMissingLSP1Interface(to);
            } else {
                revert LSP8NotifyTokenReceiverIsEOA(to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP8IdentifiableDigitalAsset.sol";

/**
 * @dev LSP8 extension, adds token supply cap.
 */
interface ILSP8CappedSupply is ILSP8IdentifiableDigitalAsset {
    /**
     * @dev Returns the number of tokens that can be minted.
     * @return The token max supply
     */
    function tokenSupplyCap() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./ERC725YCore.sol";

/**
 * @title ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
contract ERC725Y is ERC725YCore {
    /**
     * @notice Sets the owner of the contract and register ERC725Y interfaceId
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }

        _registerInterface(_INTERFACEID_ERC725Y);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for LSP1UniversalReceiver
 * @dev LSP1UniversalReceiver allows to receive arbitrary messages and to be informed when assets are sent or received
 */
interface ILSP1UniversalReceiver {
    /**
     * @notice Emitted when the universalReceiver function is succesfully executed
     * @param from The address calling the universalReceiver function
     * @param typeId The hash of a specific standard or a hook
     * @param returnedValue The return value of universalReceiver function
     * @param receivedData The arbitrary data passed to universalReceiver function
     */
    event UniversalReceiver(
        address indexed from,
        bytes32 indexed typeId,
        bytes indexed returnedValue,
        bytes receivedData
    );

    /**
     * @param typeId The hash of a specific standard or a hook
     * @param data The arbitrary data received with the call
     * @dev Emits an event when it's succesfully executed
     *
     * Call the universalReceiverDelegate function in the UniversalReceiverDelegate (URD) contract, if the address of the URD
     * was set as a value for the `_UniversalReceiverKey` in the account key/value value store of the same contract implementing
     * the universalReceiver function and if the URD contract has the LSP1UniversalReceiverDelegate Interface Id registred using ERC165
     *
     * Emits a {UniversalReceiver} event
     */
    function universalReceiver(bytes32 typeId, bytes calldata data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev Required interface of a LSP8 compliant contract.
 */
interface ILSP8IdentifiableDigitalAsset is IERC165, IERC725Y {
    // --- Events

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param operator The address of operator sending tokens
     * @param from The address which tokens are sent
     * @param to The receiving address
     * @param tokenId The tokenId transferred
     * @param force When set to TRUE, `to` may be any address but
     * when set to FALSE `to` must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses
     */
    event Transfer(
        address operator,
        address indexed from,
        address indexed to,
        bytes32 indexed tokenId,
        bool force,
        bytes data
    );

    /**
     * @dev Emitted when `tokenOwner` enables `operator` for `tokenId`.
     * @param operator The address authorized as an operator
     * @param tokenOwner The token owner
     * @param tokenId The tokenId `operator` address has access to from `tokenOwner`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenOwner,
        bytes32 indexed tokenId
    );

    /**
     * @dev Emitted when `tokenOwner` disables `operator` for `tokenId`.
     * @param operator The address revoked from operating
     * @param tokenOwner The token owner
     * @param tokenId The tokenId `operator` is revoked from operating
     */
    event RevokedOperator(
        address indexed operator,
        address indexed tokenOwner,
        bytes32 indexed tokenId
    );

    // --- Token queries

    /**
     * @dev Returns the number of existing tokens.
     * @return The number of existing tokens
     */
    function totalSupply() external view returns (uint256);

    //
    // --- Token owner queries
    //

    /**
     * @dev Returns the number of tokens owned by `tokenOwner`.
     * @param tokenOwner The address to query
     * @return The number of tokens owned by this address
     */
    function balanceOf(address tokenOwner) external view returns (uint256);

    /**
     * @param tokenId The tokenId to query
     * @return The address owning the `tokenId`
     * @dev Returns the `tokenOwner` address of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenOwnerOf(bytes32 tokenId) external view returns (address);

    /**
     * @dev Returns the list of `tokenIds` for the `tokenOwner` address.
     * @param tokenOwner The address to query owned tokens
     * @return List of owned tokens by `tokenOwner` address
     */
    function tokenIdsOf(address tokenOwner)
        external
        view
        returns (bytes32[] memory);

    // --- Operator functionality

    /**
     * @param operator The address to authorize as an operator.
     * @param tokenId The tokenId operator has access to.
     * @dev Makes `operator` address an operator of `tokenId`.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     * - caller must be current `tokenOwner` of `tokenId`.
     * - `operator` cannot be the zero address.
     *
     * Emits an {AuthorizedOperator} event.
     */
    function authorizeOperator(address operator, bytes32 tokenId) external;

    /**
     * @param operator The address to revoke as an operator.
     * @param tokenId The tokenId `operator` is revoked from operating
     * @dev Removes `operator` address as an operator of `tokenId`.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     * - caller must be current `tokenOwner` of `tokenId`.
     * - `operator` cannot be the zero address.
     *
     * Emits a {RevokedOperator} event.
     */
    function revokeOperator(address operator, bytes32 tokenId) external;

    /**
     * @param operator The address to query
     * @param tokenId The tokenId to query
     * @return True if the owner of `tokenId` is `operator` address, false otherwise
     * @dev Returns whether `operator` address is an operator of `tokenId`.
     * Operators can send and burn tokens on behalf of their owners. The tokenOwner is their own
     * operator.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     */
    function isOperatorFor(address operator, bytes32 tokenId)
        external
        view
        returns (bool);

    /**
     * @param tokenId The tokenId to query
     * @return The list of operators for the `tokenId`
     * @dev Returns all `operator` addresses of `tokenId`.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     */
    function getOperatorsOf(bytes32 tokenId)
        external
        view
        returns (address[] memory);

    // --- Transfer functionality

    /**
     * @param from The sending address.
     * @param to The receiving address.
     * @param tokenId The tokenId to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be an operator of `tokenId`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) external;

    /**
     * @param from The list of sending addresses.
     * @param to The list of receiving addresses.
     * @param tokenId The list of tokenId to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers many tokens based on the list `from`, `to`, `tokenId`. If any transfer fails
     * the call will revert.
     *
     * Requirements:
     *
     * - `from`, `to`, `tokenId` lists are the same length.
     * - no values in `from` can be the zero address.
     * - no values in `to` can be the zero address.
     * - each `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be an operator of each `tokenId`.
     *
     * Emits {Transfer} events.
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        bytes32[] memory tokenId,
        bool force,
        bytes[] memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

library ERC725Utils {
    /**
     * @dev Gets one value from account storage
     */
    function getDataSingle(IERC725Y _account, bytes32 _key)
        internal
        view
        returns (bytes memory)
    {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = _key;
        bytes memory fetchResult = _account.getData(keys)[0];
        return fetchResult;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP8 = 0x49399145;

// --- ERC725Y Keys

// bytes8('LSP8MetadataAddress') + bytes4(0)
bytes12 constant _LSP8_METADATA_ADDRESS_KEY_PREFIX = 0x73dcc7c3c4096cdc00000000;

// bytes8('LSP8MetadataJSON') + bytes4(0)
bytes12 constant _LSP8_METADATA_JSON_KEY_PREFIX = 0x9a26b4060ae7f7d500000000;

// --- Token Hooks

// keccak256('LSP8TokensSender')
bytes32 constant _TYPEID_LSP8_TOKENSSENDER = 0x3724c94f0815e936299cca424da4140752198e0beb7931a6e0925d11bc97544c;

// keccak256('LSP8TokensRecipient')
bytes32 constant _TYPEID_LSP8_TOKENSRECIPIENT = 0xc7a120a42b6057a0cbed111fbbfbd52fcd96748c04394f77fc2c3adbe0391e01;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP1 = 0x6bb56a14;
bytes4 constant _INTERFACEID_LSP1_DELEGATE = 0xc2d7bcc1;

// --- ERC725Y Keys

// keccak256('LSP1UniversalReceiverDelegate')
bytes32 constant _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY = 0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC725Y entries

// bytes16(keccak256('SupportedStandard')) + bytes12(0) + bytes4(keccak256('LSP4DigitalAsset'))
bytes32 constant _LSP4_SUPPORTED_STANDARDS_KEY = 0xeafec4d89fa9619884b6b89135626455000000000000000000000000a4d96624;

// bytes4(keccak256('LSP4DigitalAsset'))
bytes constant _LSP4_SUPPORTED_STANDARDS_VALUE = hex"a4d96624";

// keccak256('LSP4TokenName')
bytes32 constant _LSP4_TOKEN_NAME_KEY = 0xdeba1e292f8ba88238e10ab3c7f88bd4be4fac56cad5194b6ecceaf653468af1;

// keccak256('LSP4TokenSymbol')
bytes32 constant _LSP4_TOKEN_SYMBOL_KEY = 0x2f0a68ab07768e01943a599e73362a0e17a63a72e94dd2e384d2c1d4db932756;

// keccak256('LSP4Creators[]')
bytes32 constant _LSP4_CREATORS_ARRAY_KEY = 0x114bd03b3a46d48759680d81ebb2b414fda7d030a7105a851867accf1c2352e7;

// bytes8(keccak256('LSP4CreatorsMap')) + bytes4(0)
bytes12 constant _LSP4_CREATORS_MAP_KEY_PREFIX = 0x6de85eaf5d982b4e00000000;

// keccak256('LSP4Metadata')
bytes32 constant _LSP4_METADATA_KEY = 0x9afb95cacc9f95858ec44aa8c3b685511002e30ae54415823f406128b85b238e;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725Y.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

// libraries
import "./utils/GasLib.sol";

/**
 * @title Core implementation of ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
abstract contract ERC725YCore is OwnableUnset, ERC165Storage, IERC725Y {
    /**
     * @dev Map the keys to their values
     */
    mapping(bytes32 => bytes) internal store;

    /* Public functions */

    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32[] memory keys)
        public
        view
        virtual
        override
        returns (bytes[] memory values)
    {
        values = new bytes[](keys.length);

        for (uint256 i = 0; i < keys.length; i = GasLib.unchecked_inc(i)) {
            values[i] = _getData(keys[i]);
        }

        return values;
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32[] memory _keys, bytes[] memory _values)
        public
        virtual
        override
        onlyOwner
    {
        require(_keys.length == _values.length, "Keys length not equal to values length");
        for (uint256 i = 0; i < _keys.length; i = GasLib.unchecked_inc(i)) {
            _setData(_keys[i], _values[i]);
        }
    }

    /* Internal functions */

    /**
     * @notice Gets singular data at a given `key`
     * @param key The key which value to retrieve
     * @return value The data stored at the key
     */
    function _getData(bytes32 key) internal view virtual returns (bytes memory value) {
        return store[key];
    }

    /**
     * @notice Sets singular data at a given `key`
     * @param key The key which value to retrieve
     * @param value The value to set
     */
    function _setData(bytes32 key, bytes memory value) internal virtual {
        store[key] = value;
        emit DataChanged(key, value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "./interfaces/IERC725X.sol";
import "./interfaces/IERC725Y.sol";

// >> INTERFACES

// ERC725 - Smart Contract based Account
bytes4 constant _INTERFACEID_ERC725X = 0x44c028fe;
bytes4 constant _INTERFACEID_ERC725Y = 0x5a988c0f;

// >> OPERATIONS
uint256 constant OPERATION_CALL = 0;
uint256 constant OPERATION_CREATE = 1;
uint256 constant OPERATION_CREATE2 = 2;
uint256 constant OPERATION_STATICCALL = 3;
uint256 constant OPERATION_DELEGATECALL = 4;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725Y General key/value store
 * @dev ERC725Y provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
interface IERC725Y {
    /**
     * @notice Emitted when data at a key is changed
     * @param key The key which value is set
     * @param value The value to set
     */
    event DataChanged(bytes32 indexed key, bytes value);

    /**
     * @notice Gets array of data at multiple given keys
     * @param keys The array of keys which values to retrieve
     * @return values The array of data stored at multiple keys
     */
    function getData(bytes32[] memory keys) external view returns (bytes[] memory values);

    /**
     * @param keys The array of keys which values to set
     * @param values The array of values to set
     * @dev Sets array of data at multiple given `key`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32[] memory keys, bytes[] memory values) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Modified version of ERC173 with no constructor, instead should call `initOwner` function
 * Contract module which provides a basic access control mechanism, where
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
abstract contract OwnableUnset is Context {
    address private _owner;

    bool private _initiatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @dev initiate the owner for the contract
     * It can be called once
     */
    function initOwner(address newOwner) internal {
        require(!_initiatedOwner, "Ownable: owner can only be initiated once");
        _initiatedOwner = true;
        _setOwner(newOwner);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev Library to add all efficient functions that could get repeated.
 */
library GasLib {
    /**
     * @dev Will return unchecked incremented uint256
     */
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725X General executor
 * @dev ERC725X provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall`, as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
interface IERC725X {
    /**
     * @notice Emitted when a contract is created
     * @param operation The operation used to create a contract
     * @param contractAddress The created contract address
     * @param value The value sent to the created contract address
     */
    event ContractCreated(
        uint256 indexed operation,
        address indexed contractAddress,
        uint256 indexed value
    );

    /**
     * @notice Emitted when a contract executed.
     * @param operation The operation used to execute a contract
     * @param to The address where the call is executed
     * @param value The value sent to the created contract address
     * @param data The data sent with the call
     */
    event Executed(
        uint256 indexed operation,
        address indexed to,
        uint256 indexed value,
        bytes data
    );

    /**
     * @param operationType The operation to execute: CALL = 0 CREATE = 1 CREATE2 = 2 STATICCALL = 3 DELEGATECALL = 4
     * @param to The smart contract or address to interact with, `to` will be unused if a contract is created (operation 1 and 2)
     * @param value The value to transfer
     * @param data The call data, or the contract data to deploy
     * @dev Executes any other smart contract.
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {Executed} event, when a call is executed under `operationType` 0, 3 and 4
     * Emits a {ContractCreated} event, when a contract is created under `operationType` 1 and 2
     */
    function execute(
        uint256 operationType,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP8IdentifiableDigitalAssetCore.sol";
import "../LSP4DigitalAssetMetadata/LSP4DigitalAssetMetadataInitAbstract.sol";

// constants
import "./LSP8Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Proxy Implementation of a LSP8 compliant contract.
 */
abstract contract LSP8IdentifiableDigitalAssetInitAbstract is
    LSP8IdentifiableDigitalAssetCore,
    Initializable,
    LSP4DigitalAssetMetadataInitAbstract
{
    function _initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) internal virtual override onlyInitializing {
        LSP4DigitalAssetMetadataInitAbstract._initialize(
            name_,
            symbol_,
            newOwner_
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165Storage)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_LSP8 ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725YInitAbstract.sol";

// constants
import "./LSP4Constants.sol";

/**
 * @title LSP4DigitalAssetMetadata
 * @author Matthew Stevens
 * @dev Inheritable Proxy Implementation of a LSP8 compliant contract.
 */
abstract contract LSP4DigitalAssetMetadataInitAbstract is
    Initializable,
    ERC725YInitAbstract
{
    function _initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) internal virtual onlyInitializing {
        ERC725YInitAbstract._initialize(newOwner_);

        // set SupportedStandards:LSP4DigitalAsset
        _setData(
            _LSP4_SUPPORTED_STANDARDS_KEY,
            _LSP4_SUPPORTED_STANDARDS_VALUE
        );

        _setData(_LSP4_TOKEN_NAME_KEY, bytes(name_));
        _setData(_LSP4_TOKEN_SYMBOL_KEY, bytes(symbol_));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./ERC725YCore.sol";

/**
 * @title Inheritable Proxy Implementation of ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
abstract contract ERC725YInitAbstract is ERC725YCore, Initializable {
    function _initialize(address _newOwner) internal virtual onlyInitializing {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }

        _registerInterface(_INTERFACEID_ERC725Y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../LSP8IdentifiableDigitalAssetCore.sol";
import "../../LSP4DigitalAssetMetadata/LSP4Compatibility.sol";

// libraries
import "solidity-bytes-utils/contracts/BytesLib.sol";

// interfaces
import "./ILSP8CompatibilityForERC721.sol";

// constants
import "./LSP8CompatibilityConstants.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
abstract contract LSP8CompatibilityForERC721Core is
    ILSP8CompatibilityForERC721,
    LSP8IdentifiableDigitalAssetCore,
    LSP4Compatibility
{
    using ERC725Utils for IERC725Y;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // silence compiler warning about unused variable
        tokenId;

        bytes memory data = _getData(_LSP4_METADATA_KEY);

        // offset = bytes4(hashSig) + bytes32(contentHash) -> 4 + 32 = 36
        uint256 offset = 36;

        bytes memory uriBytes = BytesLib.slice(
            data,
            offset,
            data.length - offset
        );
        return string(uriBytes);
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function ownerOf(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address)
    {
        return tokenOwnerOf(bytes32(tokenId));
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function approve(address operator, uint256 tokenId)
        external
        virtual
        override
    {
        authorizeOperator(operator, bytes32(tokenId));

        emit Approval(tokenOwnerOf(bytes32(tokenId)), operator, tokenId);
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function getApproved(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address)
    {
        bytes32 tokenIdAsBytes32 = bytes32(tokenId);
        _existsOrError(tokenIdAsBytes32);

        EnumerableSet.AddressSet storage operatorsForTokenId = _operators[
            tokenIdAsBytes32
        ];
        uint256 operatorListLength = operatorsForTokenId.length();

        if (operatorListLength == 0) {
            return address(0);
        } else {
            // Read the last added operator authorized to provide "best" compatibility.
            // In ERC721 there is one operator address at a time for a tokenId, so multiple calls to
            // `approve` would cause `getApproved` to return the last added operator. In this
            // compatibility version the same is true, when the authorized operators were not previously
            // authorized. If addresses are removed, then `getApproved` returned address can change due
            // to implementation of `EnumberableSet._remove`.
            return operatorsForTokenId.at(operatorListLength - 1);
        }
    }

    /*
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // silence compiler warning about unused variable
        tokenOwner;
        operator;

        return false;
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 transferFrom.
     * Using force=true so that EOA and any contract may receive the tokenId.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), true, "");
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=false so that no EOA and only contracts supporting LSP1 interface may receive the tokenId.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), false, "");
    }

    /*
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=false so that no EOA and only contracts supporting LSP1 interface may receive the tokenId.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), false, data);
    }

    // --- Overrides

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            ILSP8IdentifiableDigitalAsset,
            LSP8IdentifiableDigitalAssetCore
        )
    {
        super.authorizeOperator(operator, tokenId);

        emit Approval(
            tokenOwnerOf(tokenId),
            operator,
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._transfer(from, to, tokenId, force, data);

        emit Transfer(
            from,
            to,
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._mint(to, tokenId, force, data);

        emit Transfer(
            address(0),
            to,
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override
    {
        address tokenOwner = tokenOwnerOf(tokenId);

        super._burn(tokenId, data);

        emit Transfer(
            tokenOwner,
            address(0),
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_ERC721 = 0x80ac58cd;
bytes4 constant _INTERFACEID_ERC721METADATA = 0x5b5e139f;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725YCore.sol";

// interfaces
import "./ILSP4Compatibility.sol";

// libraries
import "../Utils/ERC725Utils.sol";

// constants
import "./LSP4Constants.sol";

/**
 * @title LSP4Compatibility
 * @author Matthew Stevens
 * @dev LSP4 extension, for compatibility with clients & tools that expect ERC20/721.
 */
abstract contract LSP4Compatibility is ILSP4Compatibility, ERC725YCore {
    // --- Token queries

    /**
     * @dev Returns the name of the token.
     * @return The name of the token
     */
    function name() public view virtual override returns (string memory) {
        bytes memory data = _getData(_LSP4_TOKEN_NAME_KEY);
        return string(data);
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     * @return The symbol of the token
     */
    function symbol() public view virtual override returns (string memory) {
        bytes memory data = _getData(_LSP4_TOKEN_SYMBOL_KEY);
        return string(data);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP8IdentifiableDigitalAsset.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
interface ILSP8CompatibilityForERC721 is ILSP8IdentifiableDigitalAsset {
    /**
     * @notice To provide compatibility with indexing ERC721 events.
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @notice To provide compatibility with indexing ERC721 events.
     * @dev Emitted when `owner` enables `approved` for `tokenId`.
     * @param owner The address of the owner of the `tokenId`
     * @param approved The address set as operator
     * @param tokenId The approved tokenId
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Compatible with ERC721 transferFrom.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Compatible with ERC721 transferFrom.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Compatible with ERC721 safeTransferFrom.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     * @param data The data to be sent with the transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    /**
     * @dev Compatible with ERC721 ownerOf.
     * @param tokenId The tokenId to query
     * @return The owner of the tokenId
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Compatible with ERC721 approve.
     * @param operator The address to approve for `amount`
     * @param tokenId The tokenId to approve
     */
    function approve(address operator, uint256 tokenId) external;

    /**
     * @dev Compatible with ERC721 getApproved.
     * @param tokenId The tokenId to query
     * @return The address of the operator for `tokenId`
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /*
     * @dev Compatible with ERC721 isApprovedForAll.
     * @param owner The tokenOwner address to query
     * @param operator The operator address to query
     * @return Returns if the `operator` is allowed to manage all of the assets of `owner`
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /*
     * @dev Compatible with ERC721Metadata tokenURI.
     * @param tokenId The tokenId to query
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) external returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev LSP4 extension, for compatibility with clients & tools that expect ERC20/721.
 */
interface ILSP4Compatibility is IERC725Y {
    /**
     * @dev Returns the name of the token.
     * @return The name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     * @return The symbol of the token
     */
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IUsesContractRegistry {
    function contractRegistry() external view returns (address);
}

// using basis points to describe fees
uint256 constant FEE_SCALE = 100_00;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "./RoyaltySharesLib.sol";

interface IRoyaltyShares {
    //
    // --- Royalty Queries
    //

    function royaltyShares()
        external
        view
        returns (RoyaltySharesLib.RoyaltyShare[] memory royaltiesForAsset);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP7DigitalAsset.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC20.
 */
interface ILSP7CompatibilityForERC20 is ILSP7DigitalAsset {
    /**
     * @notice To provide compatibility with indexing ERC20 events.
     * @dev Emitted when `amount` tokens is transferred from `from` to `to`.
     * @param from The sending address
     * @param to The receiving address
     * @param value The amount of tokens transfered.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice To provide compatibility with indexing ERC20 events.
     * @dev Emitted when `owner` enables `spender` for `value` tokens.
     * @param owner The account giving approval
     * @param spender The account receiving approval
     * @param value The amount of tokens `spender` has access to from `owner`
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*
     * @dev Compatible with ERC20 transfer
     * @param to The receiving address
     * @param amount The amount of tokens to transfer
     */
    function transfer(address to, uint256 amount) external;

    /*
     * @dev Compatible with ERC20 transferFrom
     * @param from The sending address
     * @param to The receiving address
     * @param amount The amount of tokens to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    /*
     * @dev Compatible with ERC20 approve
     * @param operator The address to approve for `amount`
     * @param amount The amount to approve
     */
    function approve(address operator, uint256 amount) external;

    /*
     * @dev Compatible with ERC20 allowance
     * @param tokenOwner The address of the token owner
     * @param operator The address approved by the `tokenOwner`
     * @return The amount `operator` is approved by `tokenOwner`
     */
    function allowance(address tokenOwner, address operator)
        external
        returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "./RoyaltySharesLib.sol";

interface IFeeCollector {
    //
    // --- Struct
    //

    // NOTE: packed into one storage slot
    struct RevenueShareFees {
        uint16 platform;
        uint16 creator;
        uint16 referral;
    }

    //
    // --- Fee queries
    //

    function feeBalance(address receiver, address token)
        external
        view
        returns (uint256);

    function revenueShareFees() external view returns (RevenueShareFees memory);

    function baseRevenueShareFee() external view returns (uint256);

    function platformFeeReceiver() external view returns (address);

    //
    // --- Fee logic
    //

    function shareRevenue(
        address token,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata creatorRoyalties,
        bytes calldata dataForCallback
    ) external returns (uint256);

    function withdrawTokens(address[] calldata tokenList) external;

    function withdrawTokensForMany(
        address[] calldata addressList,
        address[] calldata tokenList
    ) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IFeeCollectorRevenueShareCallback {
    error RevenueShareCallbackInvalidSender();

    // @notice Called to `msg.sender` after FeeCollector.revenueShare is called.
    // @param totalFee The amount expected to be transfered to the FeeCollector after the callback is complete
    // @param dataForCallback The data provided when calling FeeCollector.revenueShare to process the callback
    function revenueShareCallback(
        uint256 totalFee,
        bytes memory dataForCallback
    ) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardMarket {
    //
    // --- Structs
    //

    struct CardMarketState {
        bytes32 tokenId;
        uint256 minimumAmount;
        address acceptedToken;
    }

    //
    // --- Events
    //

    event MarketSet(
        bytes32 indexed tokenId,
        address indexed acceptedToken,
        uint256 amount
    );

    event MarketRemove(bytes32 indexed tokenId);

    event MarketBuy(
        bytes32 indexed tokenId,
        address indexed buyer,
        uint256 amount
    );

    //
    // --- Market queries
    //

    function marketFor(bytes32 tokenId)
        external
        returns (CardMarketState memory);

    function getAllMarkets() external returns (CardMarketState[] memory);

    //
    // --- Market logic
    //

    function setMarketFor(
        bytes32 tokenId,
        address acceptedToken,
        uint256 minimumAmount
    ) external;

    function removeMarketFor(bytes32 tokenId) external;

    function buyFromMarket(
        bytes32 tokenId,
        uint256 amount,
        address referrer
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev Required interface of a LSP8 compliant contract.
 */
interface ILSP7DigitalAsset is IERC165, IERC725Y {
    // --- Events

    /**
     * @dev Emitted when `amount` tokens is transferred from `from` to `to`.
     * @param operator The address of operator sending tokens
     * @param from The address which tokens are sent
     * @param to The receiving address
     * @param amount The amount of tokens transferred
     * @param force When set to TRUE, `to` may be any address but
     * when set to FALSE `to` must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses
     */
    event Transfer(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bool force,
        bytes data
    );

    /**
     * @dev Emitted when `tokenOwner` enables `operator` for `amount` tokens.
     * @param operator The address authorized as an operator
     * @param tokenOwner The token owner
     * @param amount The amount of tokens `operator` address has access to from `tokenOwner`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenOwner,
        uint256 indexed amount
    );

    /**
     * @dev Emitted when `tokenOwner` disables `operator` for `amount` tokens.
     * @param operator The address revoked from operating
     * @param tokenOwner The token owner
     */
    event RevokedOperator(address indexed operator, address indexed tokenOwner);

    // --- Token queries

    /**
     * @dev Returns the number of decimals used to get its user representation
     * If the contract represents a NFT then 0 SHOULD be used, otherwise 18 is the common value
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the number of existing tokens.
     * @return The number of existing tokens
     */
    function totalSupply() external view returns (uint256);

    // --- Token owner queries

    /**
     * @dev Returns the number of tokens owned by `tokenOwner`.
     * @param tokenOwner The address to query
     * @return The number of tokens owned by this address
     */
    function balanceOf(address tokenOwner) external view returns (uint256);

    // --- Operator functionality

    /**
     * @param operator The address to authorize as an operator.
     * @param amount The amount of tokens operator has access to.
     * @dev Sets `amount` as the amount of tokens `operator` address has access to from callers tokens.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     *
     * Emits an {AuthorizedOperator} event.
     */
    function authorizeOperator(address operator, uint256 amount) external;

    /**
     * @param operator The address to revoke as an operator.
     * @dev Removes `operator` address as an operator of callers tokens.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     *
     * Emits a {RevokedOperator} event.
     */
    function revokeOperator(address operator) external;

    /**
     * @param operator The address to query operator status for.
     * @param tokenOwner The token owner.
     * @return The amount of tokens `operator` address has access to from `tokenOwner`.
     * @dev Returns amount of tokens `operator` address has access to from `tokenOwner`.
     * Operators can send and burn tokens on behalf of their owners. The tokenOwner is their own
     * operator.
     */
    function isOperatorFor(address operator, address tokenOwner)
        external
        view
        returns (uint256);

    // --- Transfer functionality

    /**
     * @param from The sending address.
     * @param to The receiving address.
     * @param amount The amount of tokens to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers `amount` of tokens from `from` to `to`. The `force` parameter will be used
     * when notifying the token sender and receiver.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `amount` tokens must be owned by `from`.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) external;

    /**
     * @param from The list of sending addresses.
     * @param to The list of receiving addresses.
     * @param amount The amount of tokens to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers many tokens based on the list `from`, `to`, `amount`. If any transfer fails
     * the call will revert.
     *
     * Requirements:
     *
     * - `from`, `to`, `amount` lists are the same length.
     * - no values in `from` can be the zero address.
     * - no values in `to` can be the zero address.
     * - each `amount` tokens must be owned by `from`.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits {Transfer} events.
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        uint256[] memory amount,
        bool force,
        bytes[] memory data
    ) external;
}