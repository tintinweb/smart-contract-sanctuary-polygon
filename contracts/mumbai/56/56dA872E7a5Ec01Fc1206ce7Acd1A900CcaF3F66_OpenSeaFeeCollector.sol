// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_COLLECTOR_NAME_HASH } from "../registry/constants.sol";

// libs
import "../royalties/RoyaltySharesLib.sol";

// interfaces
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "../registry/IContractRegistry.sol";
import "../royalties/IFeeCollector.sol";
import "../royalties/IFeeCollectorRevenueShareCallback.sol";
import "../royalties/IRoyaltyShares.sol";

// modules
import "../card/CardMarket.sol";

contract OpenSeaFeeCollector is IFeeCollectorRevenueShareCallback {

  //
  // --- Storage
  //

  address public contractRegistry;
  
  //
  // --- Initialize
  //

  function initialize(address _contractRegistry) public {
    contractRegistry = _contractRegistry;
  }
 
  //
  // --- OpenSea support for FeeCollector logic
  //

  function shareRevenueToFeeCollector(address[] calldata feeTokenList) public {
    for (uint256 i = 0; i < feeTokenList.length; i++) {
        address token = feeTokenList[i];
        _shareRevenue(token);   
    }
  }

  function _shareRevenue(address feeToken) public {
    RoyaltySharesLib.RoyaltyShare[] memory creatorRoyalties = 
      IRoyaltyShares(address(this)).royaltyShares();

    uint256 balanceOf = ILSP7CompatibilityForERC20(feeToken).balanceOf(address(this));
    IFeeCollector feeCollector = IFeeCollector(
                IContractRegistry(contractRegistry).getRegisteredContract(
                    FEE_COLLECTOR_NAME_HASH
                )
            );

    // the entire balance for this contract, is all the fees that have been received from OpenSea,
    // and the entire balance should be considered as fees.. therefore we do the math...
    uint256 totalRevenueShareFee = feeCollector.totalRevenueShareFee();
    uint256 amount = balanceOf * totalRevenueShareFee;

    uint256 totalFee = feeCollector.shareRevenue(
                feeToken,
                amount,
                address(0),
                creatorRoyalties,
                abi.encode(feeToken)
            );
  }

  function revenueShareCallback(
        uint256 totalFee,
        bytes calldata dataForCallback
    ) external override(IFeeCollectorRevenueShareCallback) {
        address feeCollector = IContractRegistry(contractRegistry)
            .getRegisteredContract(FEE_COLLECTOR_NAME_HASH);

        if (msg.sender != feeCollector) {
            revert RevenueShareCallbackInvalidSender();
        }

        (address feeToken) = abi.decode(
            dataForCallback,
            (address)
        );

        ILSP7CompatibilityForERC20(feeToken).transfer(
            feeCollector,
            totalFee
        );
  }

}

// keccak256("FeeCollector")
bytes32 constant FEE_COLLECTOR_NAME_HASH = 0xd59ed7e0cf777b70bff43b36b5e7942a53db5cdc1ed3eac0584ffe6898bb47cd;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

library RoyaltySharesLib {
    struct RoyaltyShare {
        address receiver;
        // using basis points to describe shares
        uint96 share;
    }
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

interface IContractRegistry {
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

    //
    // --- Whitelist Token Logic
    //

    function setWhitelistedToken(address token) external;

    function removeWhitelistedToken(address token) external;
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

    function totalRevenueShareFee() external view returns (uint256);

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_COLLECTOR_NAME_HASH } from "../registry/constants.sol";

// interfaces
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "./ICardMarket.sol";
import "../registry/IContractRegistry.sol";
import "../royalties/IFeeCollector.sol";
import "../royalties/IFeeCollectorRevenueShareCallback.sol";
import "../royalties/IRoyaltyShares.sol";

// modules
import "@openzeppelin/contracts/utils/Context.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

abstract contract CardMarket is
    Context,
    LSP8IdentifiableDigitalAssetCore,
    IFeeCollectorRevenueShareCallback,
    IRoyaltyShares,
    ICardMarket
{
    //
    // --- Errors
    //

    error CardMarketContractRegistryRequired();
    error CardMarketCreatorRoyaltiesRequired();
    error CardMarketCreatorRoyaltiesSum();

    error CardMarketNotTokenOwner(
        address owner,
        address operator,
        bytes32 tokenId
    );
    error CardMarketNoMarket(bytes32 tokenId);
    error CardMarketMinimumAmountRequired();
    error CardMarketBuyAmountTooSmall(uint256 minimumAmount, uint256 amount);

    //
    // --- Storage
    //

    address private _contractRegistry;

    RoyaltySharesLib.RoyaltyShare[] private _creatorRoyalties;

    mapping(bytes32 => CardMarketState) private marketStateForTokenId;

    //
    // --- Initialize
    //

    constructor(
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares
    ) {
        if (contractRegistry == address(0)) {
            revert CardMarketContractRegistryRequired();
        }
        _contractRegistry = contractRegistry;

        _validateAndStoreCreatorRoyalties(creators, creatorRoyaltyShares);
    }

    // TODO: this could be part of a RoyaltyShares contract / lib
    function _validateAndStoreCreatorRoyalties(
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares
    ) internal {
        if (
            creators.length == 0 ||
            creators.length != creatorRoyaltyShares.length
        ) {
            revert CardMarketCreatorRoyaltiesRequired();
        }

        uint256 revenueShareSum;
        for (uint256 i = 0; i < creatorRoyaltyShares.length; i++) {
            revenueShareSum += creatorRoyaltyShares[i];
            _creatorRoyalties.push(
                RoyaltySharesLib.RoyaltyShare({
                    receiver: creators[i],
                    share: creatorRoyaltyShares[i]
                })
            );
        }

        if (revenueShareSum != 100_00) {
            revert CardMarketCreatorRoyaltiesSum();
        }
    }

    //
    // --- Royalty Queries
    //

    // TODO: this could be part of RoyaltyShares contract
    function royaltyShares()
        public
        view
        override
        returns (RoyaltySharesLib.RoyaltyShare[] memory)
    {
        return _creatorRoyalties;
    }

    //
    // --- FeeCollector Extension Logic
    //

    // function pushFees(address token) public onlyOwner {
    // TODO: if we use the CardMarket address for external markets like OpenSea, could receive
    // tokens from their revenue share processes here, then push into FeeCollector.revenueShare
    // like `buyFromMarket` flow does..
    // }

    //
    // --- Market queries
    //

    function marketFor(bytes32 tokenId)
        public
        view
        override
        returns (CardMarketState memory)
    {
        CardMarketState storage market = marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }

        return market;
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

        marketStateForTokenId[tokenId] = CardMarketState({
            minimumAmount: minimumAmount,
            acceptedToken: acceptedToken
        });

        emit MarketSet(tokenId, acceptedToken, minimumAmount);
    }

    function removeMarketFor(bytes32 tokenId) public override {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();
        if (tokenOwner != operator) {
            revert CardMarketNotTokenOwner(tokenOwner, operator, tokenId);
        }

        CardMarketState storage market = marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }

        delete marketStateForTokenId[tokenId];

        emit MarketRemove(tokenId);
    }

    function buyFromMarket(
        bytes32 tokenId,
        uint256 amount,
        address referrer
    ) public override {
        CardMarketState memory market = marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }
        if (amount < market.minimumAmount) {
            revert CardMarketBuyAmountTooSmall(market.minimumAmount, amount);
        }

        address buyer = _msgSender();
        address tokenOwner = tokenOwnerOf(tokenId);

        uint256 totalFee = IFeeCollector(
            IContractRegistry(_contractRegistry).getRegisteredContract(
                FEE_COLLECTOR_NAME_HASH
            )
        ).shareRevenue(
                market.acceptedToken,
                amount,
                referrer,
                IRoyaltyShares(address(this)).royaltyShares(),
                abi.encode(buyer, tokenId)
            );
        uint256 tokenOwnerAmount = amount - totalFee;

        // clear market state after shareRevenue, we need market state in revenueShareCallback
        delete marketStateForTokenId[tokenId];

        ILSP7CompatibilityForERC20(market.acceptedToken).transferFrom(
            buyer,
            tokenOwner,
            tokenOwnerAmount
        );

        _transfer(tokenOwner, buyer, tokenId, true, "");

        emit MarketBuy(tokenId, buyer, amount);
    }

    //
    // --- FeeCollectorCallback logic
    //

    function revenueShareCallback(
        uint256 totalFee,
        bytes calldata dataForCallback
    ) external override {
        address feeCollector = IContractRegistry(_contractRegistry)
            .getRegisteredContract(FEE_COLLECTOR_NAME_HASH);

        if (msg.sender != feeCollector) {
            revert RevenueShareCallbackInvalidSender();
        }

        (address feePayer, bytes32 tokenId) = abi.decode(
            dataForCallback,
            (address, bytes32)
        );
        CardMarketState memory market = marketStateForTokenId[tokenId];

        ILSP7CompatibilityForERC20(market.acceptedToken).transferFrom(
            feePayer,
            feeCollector,
            totalFee
        );
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
        delete marketStateForTokenId[tokenId];

        super._transfer(from, to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override
    {
        delete marketStateForTokenId[tokenId];

        super._burn(tokenId, data);
    }
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardMarket {
    //
    // --- Structs
    //

    struct CardMarketState {
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

// modules
import "./LSP8IdentifiableDigitalAssetCore.sol";
import "../LSP4DigitalAssetMetadata/LSP4DigitalAssetMetadata.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// constants
import "./LSP8Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Implementation of a LSP8 compliant contract.
 */
contract LSP8IdentifiableDigitalAsset is
    LSP8IdentifiableDigitalAssetCore,
    LSP4DigitalAssetMetadata
{
    /**
     * @notice Sets the token-Metadata and register LSP8InterfaceId
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the the token-Metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) LSP4DigitalAssetMetadata(name_, symbol_, newOwner_) {
        _registerInterface(_INTERFACEID_LSP8);
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
    error LSP8NotTokenOwner(address tokenOwner, bytes32 tokenId, address caller);
    error LSP8NotTokenOperator(bytes32 tokenId, address caller);
    error LSP8CannotUseAddressZeroAsOperator();
    error LSP8CannotSendToAddressZero();
    error LSP8TokenIdAlreadyMinted(bytes32 tokenId);
    error LSP8InvalidTransferBatch();
    error LSP8NotifyTokenReceiverContractMissingLSP1Interface(address tokenReceiver);
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

        if(!_isOperatorOrOwner(operator, tokenId)) {
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
        if (from.length != to.length ||
                from.length != tokenId.length ||
                from.length != data.length) {
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

        _notifyTokenSender(tokenOwner, address(0), tokenId, data);

        _beforeTokenTransfer(tokenOwner, address(0), tokenId);

        _clearOperators(tokenOwner, tokenId);

        _ownedTokens[tokenOwner].remove(tokenId);
        delete _tokenOwners[tokenId];

        emit Transfer(operator, tokenOwner, address(0), tokenId, false, data);
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

        _notifyTokenSender(from, to, tokenId, data);

        _beforeTokenTransfer(from, to, tokenId);

        _clearOperators(from, tokenId);

        _ownedTokens[from].remove(tokenId);
        _ownedTokens[to].add(tokenId);
        _tokenOwners[tokenId] = to;

        emit Transfer(operator, from, to, tokenId, force, data);

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
            if (to.isContract()) {
                revert LSP8NotifyTokenReceiverContractMissingLSP1Interface(to);
            } else {
                revert LSP8NotifyTokenReceiverIsEOA(to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// constants
import "./LSP4Constants.sol";

/**
 * @title LSP4DigitalAssetMetadata
 * @author Matthew Stevens
 * @dev Implementation of a LSP8 compliant contract.
 */
abstract contract LSP4DigitalAssetMetadata is ERC725Y {
    /**
     * @notice Sets the name, symbol of the token and the owner, and sets the SupportedStandards:LSP4DigitalAsset key
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the token contract
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) ERC725Y(newOwner_) {
        // SupportedStandards:LSP4DigitalAsset
        _setData(
            _LSP4_SUPPORTED_STANDARDS_KEY,
            _LSP4_SUPPORTED_STANDARDS_VALUE
        );

        _setData(_LSP4_METADATA_TOKEN_NAME_KEY, bytes(name_));
        _setData(_LSP4_METADATA_TOKEN_SYMBOL_KEY, bytes(symbol_));
    }
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

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP8 = 0x49399145;

// --- ERC725Y entries

// bytes8('LSP8MetadataAddress') + bytes4(0)
bytes12 constant _LSP8_METADATA_ADDRESS_KEY_PREFIX = 0x73dcc7c3c4096cdc00000000;

// bytes8('LSP8MetadataJSON') + bytes4(0)
bytes12 constant _LSP8_METADATA_JSON_KEY_PREFIX = 0x9a26b4060ae7f7d500000000;

// --- Token Hooks
bytes32 constant _TYPEID_LSP8_TOKENSSENDER = 0x3724c94f0815e936299cca424da4140752198e0beb7931a6e0925d11bc97544c; // keccak256("LSP8TokensSender")

bytes32 constant _TYPEID_LSP8_TOKENSRECIPIENT = 0xc7a120a42b6057a0cbed111fbbfbd52fcd96748c04394f77fc2c3adbe0391e01; // keccak256("LSP8TokensRecipient")

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC725Y entries

// bytes16(keccak256('SupportedStandard')) + bytes12(0) + bytes4(keccak256('LSP4DigitalAsset'))
bytes32 constant _LSP4_SUPPORTED_STANDARDS_KEY = 0xeafec4d89fa9619884b6b89135626455000000000000000000000000a4d96624;

// bytes4(keccak256('LSP4DigitalAsset'))
bytes constant _LSP4_SUPPORTED_STANDARDS_VALUE = hex"a4d96624";

// keccak256('LSP4TokenName')
bytes32 constant _LSP4_METADATA_TOKEN_NAME_KEY = 0xdeba1e292f8ba88238e10ab3c7f88bd4be4fac56cad5194b6ecceaf653468af1;

// keccak256('LSP4TokenSymbol')
bytes32 constant _LSP4_METADATA_TOKEN_SYMBOL_KEY = 0x2f0a68ab07768e01943a599e73362a0e17a63a72e94dd2e384d2c1d4db932756;

// keccak256('LSP4Metadata')
bytes32 constant _LSP4_METADATA_KEY = 0x9afb95cacc9f95858ec44aa8c3b685511002e30ae54415823f406128b85b238e;

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

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

library ERC725Utils {
    // internal functions

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

    /**
     * @dev Initiates Map and ArrayKey and sets the length of the Array to `1` if it's not set before,
     * If it's already set, it decodes the arrayLength, increment it and adds Map and ArrayKey
     */
    function addMapAndArrayKey(
        IERC725Y _account,
        bytes32 _arrayKey,
        bytes32 _mapKey,
        address _sender,
        bytes4 _appendix
    ) internal view returns (bytes32[] memory keys, bytes[] memory values) {
        keys = new bytes32[](3);
        values = new bytes[](3);

        bytes memory rawArrayLength = getDataSingle(_account, _arrayKey);

        keys[0] = _arrayKey;
        keys[2] = _mapKey;

        values[1] = abi.encodePacked(_sender);

        if (rawArrayLength.length != 32) {
            keys[1] = _generateArrayKeyAtIndex(_arrayKey, 0);

            values[0] = abi.encodePacked(uint256(1));
            values[2] = abi.encodePacked(bytes8(0), _appendix);
        } else if (rawArrayLength.length == 32) {
            uint256 arrayLength = abi.decode(rawArrayLength, (uint256));
            uint256 newArrayLength = arrayLength + 1;

            keys[1] = _generateArrayKeyAtIndex(_arrayKey, newArrayLength - 1);

            values[0] = abi.encodePacked(newArrayLength);
            values[2] = abi.encodePacked(
                bytes8(uint64(arrayLength)),
                _appendix
            );
        }
    }

    /**
     * @dev Decrements the arrayLength, removes the Map, swaps the arrayKey that need to be removed with
     * the last `arrayKey` in the array and removes the last arrayKey with updating all modified entries
     */
    function removeMapAndArrayKey(
        IERC725Y _account,
        bytes32 _arrayKey,
        bytes32 mapHash,
        bytes32 _mapKeyToRemove
    ) internal view returns (bytes32[] memory keys, bytes[] memory values) {
        keys = new bytes32[](5);
        values = new bytes[](5);

        uint64 index = _extractIndexFromMap(_account, _mapKeyToRemove);
        bytes32 arrayKeyToRemove = _generateArrayKeyAtIndex(_arrayKey, index);

        bytes memory rawArrayLength = getDataSingle(_account, _arrayKey);
        uint256 arrayLength = abi.decode(rawArrayLength, (uint256));
        uint256 newLength = arrayLength - 1;

        keys[0] = _arrayKey;
        values[0] = abi.encodePacked(newLength);

        keys[1] = _mapKeyToRemove;
        values[1] = "";

        if (index == (arrayLength - 1)) {
            keys[2] = arrayKeyToRemove;
            values[2] = "";
        } else {
            bytes32 lastKey = _generateArrayKeyAtIndex(_arrayKey, newLength);
            bytes memory lastKeyValue = getDataSingle(_account, lastKey);

            bytes32 mapOfLastkey = generateMapKey(mapHash, lastKeyValue);
            bytes memory mapValueOfLastkey = getDataSingle(
                _account,
                mapOfLastkey
            );

            bytes memory appendix = BytesLib.slice(mapValueOfLastkey, 8, 4);

            keys[2] = arrayKeyToRemove;
            values[2] = lastKeyValue;

            keys[3] = lastKey;
            values[3] = "";

            keys[4] = mapOfLastkey;
            values[4] = abi.encodePacked(bytes8(index), appendix);
        }
    }

    function generateMapKey(bytes32 _mapHash, bytes memory _sender)
        internal
        pure
        returns (bytes32)
    {
        bytes memory mapKey = abi.encodePacked(
            bytes8(_mapHash),
            bytes4(0),
            _sender
        );
        return _generateBytes32Key(mapKey);
    }

    // private functions

    function _generateBytes32Key(bytes memory _rawKey)
        private
        pure
        returns (bytes32 key)
    {
        /* solhint-disable */
        assembly {
            key := mload(add(_rawKey, 32))
        }
        /* solhint-enable */
    }

    function _generateArrayKeyAtIndex(bytes32 _arrayKey, uint256 _index)
        private
        pure
        returns (bytes32)
    {
        bytes memory elementInArray = abi.encodePacked(
            bytes16(_arrayKey),
            bytes16(uint128(_index))
        );
        return _generateBytes32Key(elementInArray);
    }

    function _extractIndexFromMap(IERC725Y _account, bytes32 _mapKey)
        private
        view
        returns (uint64)
    {
        bytes memory indexInBytes = getDataSingle(_account, _mapKey);
        bytes8 indexKey;
        /* solhint-disable */
        assembly {
            indexKey := mload(add(indexInBytes, 32))
        }
        /* solhint-enable */
        return uint64(indexKey);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP1 = 0x6bb56a14;
bytes4 constant _INTERFACEID_LSP1_DELEGATE = 0xc2d7bcc1;

// --- ERC725Y Keys
bytes32 constant _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY = 0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47; // keccak256("LSP1UniversalReceiverDelegate")

bytes32 constant _ARRAYKEY_LSP5 = 0x6460ee3c0aac563ccbf76d6e1d07bada78e3a9514e6382b736ed3f478ab7b90b; // keccak256("LSP5ReceivedAssets[]")

bytes32 constant _MAPHASH_LSP5 = 0x812c4334633eb816c80deebfa5fb7d2509eb438ca1b6418106442cb5ccc62f6c; // keccak256("LSP5ReceivedAssetsMap")

bytes32 constant _ARRAYKEY_LSP10 = 0x55482936e01da86729a45d2b87a6b1d3bc582bea0ec00e38bdb340e3af6f9f06; // keccak256("LSP10Vaults[]")

bytes32 constant _MAPHASH_LSP10 = 0x192448c3c0f88c7f238c7f70449c270032f9752568e88cc8936ce3a2cb18e3ec; // keccak256("LSP10VaultsMap")

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725Y.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

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

        for (uint256 i = 0; i < keys.length; i++) {
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
        for (uint256 i = 0; i < _keys.length; i++) {
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

// SPDX-License-Identifier: MIT

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