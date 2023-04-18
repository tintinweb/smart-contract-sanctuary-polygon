// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
 * @dev error OrderInvalid()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OrderInvalid_error_selector = 0x2e0c0f71;
uint256 constant OrderInvalid_error_length = 0x04;

/*
 *  @dev error CurrencyInvalid()
 *       Memory layout:
 *         - 0x00: Left-padded selector (data begins at 0x1c)
 *       Revert buffer is memory[0x1c:0x20]
 */
uint256 constant CurrencyInvalid_error_selector = 0x4f795487;
uint256 constant CurrencyInvalid_error_length = 0x04;

/*
 * @dev error OutsideOfTimeRange()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OutsideOfTimeRange_error_selector = 0x7476320f;
uint256 constant OutsideOfTimeRange_error_length = 0x04;

/*
 * @dev error NoSelectorForStrategy()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant NoSelectorForStrategy_error_selector = 0xab984846;
uint256 constant NoSelectorForStrategy_error_length = 0x04;

uint256 constant Error_selector_offset = 0x1c;

uint256 constant OneWord = 0x20;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice CollectionType is used in OrderStructs.Maker's collectionType to determine the collection type being traded.
 */
enum CollectionType {
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice QuoteType is used in OrderStructs.Maker's quoteType to determine whether the maker order is a bid or an ask.
 */
enum QuoteType {
    Bid,
    Ask
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice It is returned if the amount is invalid.
 *         For ERC721, any number that is not 1. For ERC1155, if amount is 0.
 */
error AmountInvalid();

/**
 * @notice It is returned if the ask price is too high for the bid user.
 */
error AskTooHigh();

/**
 * @notice It is returned if the bid price is too low for the ask user.
 */
error BidTooLow();

/**
 * @notice It is returned if the function cannot be called by the sender.
 */
error CallerInvalid();

/**
 * @notice It is returned if the currency is invalid.
 */
error CurrencyInvalid();

/**
 * @notice The function selector is invalid for this strategy implementation.
 */
error FunctionSelectorInvalid();

/**
 * @notice It is returned if there is either a mismatch or an error in the length of the array(s).
 */
error LengthsInvalid();

/**
 * @notice It is returned if the merkle proof provided is invalid.
 */
error MerkleProofInvalid();

/**
 * @notice It is returned if the length of the merkle proof provided is greater than tolerated.
 * @param length Proof length
 */
error MerkleProofTooLarge(uint256 length);

/**
 * @notice It is returned if the order is permanently invalid.
 *         There may be an issue with the order formatting.
 */
error OrderInvalid();

/**
 * @notice It is returned if the maker quote type is invalid.
 */
error QuoteTypeInvalid();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces
import {IStrategy} from "../interfaces/IStrategy.sol";

// Assembly constants
import {OrderInvalid_error_selector} from "../constants/AssemblyConstants.sol";

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

// Enums
import {CollectionType} from "../enums/CollectionType.sol";

/**
 * @title BaseStrategy
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract BaseStrategy is IStrategy {
    /**
     * @inheritdoc IStrategy
     */
    function isLooksRareV2Strategy() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev This is equivalent to
     *      if (amount == 0 || (amount != 1 && collectionType == 0)) {
     *          return (0, OrderInvalid.selector);
     *      }
     * @dev OrderInvalid_error_selector is a left-padded 4 bytes. If the error selector is returned
     *      instead of reverting, the error selector needs to be right-padded by
     *      28 bytes. Therefore it needs to be left shifted by 28 x 8 = 224 bits.
     */
    function _validateAmountNoRevert(uint256 amount, CollectionType collectionType) internal pure {
        assembly {
            if or(iszero(amount), and(xor(amount, 1), iszero(collectionType))) {
                mstore(0x00, 0x00)
                mstore(0x20, shl(224, OrderInvalid_error_selector))
                return(0, 0x40)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

// OpenZeppelin's library for verifying Merkle proofs
import {MerkleProofMemory} from "../libraries/OpenZeppelin/MerkleProofMemory.sol";

// Enums
import {QuoteType} from "../enums/QuoteType.sol";

// Shared errors
import {OrderInvalid, FunctionSelectorInvalid, MerkleProofInvalid, QuoteTypeInvalid} from "../errors/SharedErrors.sol";

// Base strategy contracts
import {BaseStrategy, IStrategy} from "./BaseStrategy.sol";

/**
 * @title StrategyCollectionOffer
 * @notice This contract offers execution strategies for users to create maker bid offers for items in a collection.
 *         There are two available functions:
 *         1. executeCollectionStrategyWithTakerAsk --> it applies to all itemIds in a collection
 *         2. executeCollectionStrategyWithTakerAskWithProof --> it allows adding merkle proof criteria.
 * @notice The bidder can only bid on 1 item id at a time.
 *         1. If ERC721, the amount must be 1.
 *         2. If ERC1155, the amount can be greater than 1.
 * @dev Use cases can include trait-based offers or rarity score offers.
 * @author LooksRare protocol team (👀,💎)
 */
contract StrategyCollectionOffer is BaseStrategy {
    /**
     * @notice This function validates the order under the context of the chosen strategy and
     *         returns the fulfillable items/amounts/price/nonce invalidation status.
     *         This strategy executes a collection offer against a taker ask order without the need of merkle proofs.
     * @param takerAsk Taker ask struct (taker ask-specific parameters for the execution)
     * @param makerBid Maker bid struct (maker bid-specific parameters for the execution)
     */
    function executeCollectionStrategyWithTakerAsk(
        OrderStructs.Taker calldata takerAsk,
        OrderStructs.Maker calldata makerBid
    )
        external
        pure
        returns (uint256 price, uint256[] memory itemIds, uint256[] calldata amounts, bool isNonceInvalidated)
    {
        price = makerBid.price;
        amounts = makerBid.amounts;

        // A collection order can only be executable for 1 itemId but quantity to fill can vary
        if (amounts.length != 1) {
            revert OrderInvalid();
        }

        uint256 offeredItemId = abi.decode(takerAsk.additionalParameters, (uint256));
        itemIds = new uint256[](1);
        itemIds[0] = offeredItemId;
        isNonceInvalidated = true;
    }

    /**
     * @notice This function validates the order under the context of the chosen strategy
     *         and returns the fulfillable items/amounts/price/nonce invalidation status.
     *         This strategy executes a collection offer against a taker ask order with the need of a merkle proof.
     * @param takerAsk Taker ask struct (taker ask-specific parameters for the execution)
     * @param makerBid Maker bid struct (maker bid-specific parameters for the execution)
     * @dev The transaction reverts if the maker does not include a merkle root in the additionalParameters.
     */
    function executeCollectionStrategyWithTakerAskWithProof(
        OrderStructs.Taker calldata takerAsk,
        OrderStructs.Maker calldata makerBid
    )
        external
        pure
        returns (uint256 price, uint256[] memory itemIds, uint256[] calldata amounts, bool isNonceInvalidated)
    {
        price = makerBid.price;
        amounts = makerBid.amounts;

        // A collection order can only be executable for 1 itemId but the actual quantity to fill can vary
        if (amounts.length != 1) {
            revert OrderInvalid();
        }

        (uint256 offeredItemId, bytes32[] memory proof) = abi.decode(
            takerAsk.additionalParameters,
            (uint256, bytes32[])
        );
        itemIds = new uint256[](1);
        itemIds[0] = offeredItemId;
        isNonceInvalidated = true;

        bytes32 root = abi.decode(makerBid.additionalParameters, (bytes32));
        bytes32 node = keccak256(abi.encodePacked(offeredItemId));

        // Verify the merkle root for the given merkle proof
        if (!MerkleProofMemory.verify(proof, root, node)) {
            revert MerkleProofInvalid();
        }
    }

    /**
     * @inheritdoc IStrategy
     */
    function isMakerOrderValid(
        OrderStructs.Maker calldata makerBid,
        bytes4 functionSelector
    ) external pure override returns (bool isValid, bytes4 errorSelector) {
        if (
            functionSelector != StrategyCollectionOffer.executeCollectionStrategyWithTakerAskWithProof.selector &&
            functionSelector != StrategyCollectionOffer.executeCollectionStrategyWithTakerAsk.selector
        ) {
            return (isValid, FunctionSelectorInvalid.selector);
        }

        if (makerBid.quoteType != QuoteType.Bid) {
            return (isValid, QuoteTypeInvalid.selector);
        }

        if (makerBid.amounts.length != 1) {
            return (isValid, OrderInvalid.selector);
        }

        _validateAmountNoRevert(makerBid.amounts[0], makerBid.collectionType);

        // If no root is provided or invalid length, it should be invalid.
        // @dev It does not mean the merkle root is valid against a specific itemId that exists in the collection.
        if (
            functionSelector == StrategyCollectionOffer.executeCollectionStrategyWithTakerAskWithProof.selector &&
            makerBid.additionalParameters.length != 32
        ) {
            return (isValid, OrderInvalid.selector);
        }

        isValid = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

/**
 * @title IStrategy
 * @author LooksRare protocol team (👀,💎)
 */
interface IStrategy {
    /**
     * @notice Validate *only the maker* order under the context of the chosen strategy. It does not revert if
     *         the maker order is invalid. Instead it returns false and the error's 4 bytes selector.
     * @param makerOrder Maker struct (maker specific parameters for the execution)
     * @param functionSelector Function selector for the strategy
     * @return isValid Whether the maker struct is valid
     * @return errorSelector If isValid is false, it returns the error's 4 bytes selector
     */
    function isMakerOrderValid(
        OrderStructs.Maker calldata makerOrder,
        bytes4 functionSelector
    ) external view returns (bool isValid, bytes4 errorSelector);

    /**
     * @notice This function acts as a safety check for the protocol's owner when adding new execution strategies.
     * @return isStrategy Whether it is a LooksRare V2 protocol strategy
     */
    function isLooksRareV2Strategy() external pure returns (bool isStrategy);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title MerkleProofMemory
 * @notice This library is adjusted from the work of OpenZeppelin.
 *         It is based on the 4.7.0 (utils/cryptography/MerkleProof.sol).
 * @author OpenZeppelin (adjusted by LooksRare)
 */
library MerkleProofMemory {
    /**
     * @notice This returns true if a `leaf` can be proved to be a part of a Merkle tree defined by `root`.
     *         For this, a `proof` must be provided, containing sibling hashes on the branch from the leaf to the
     *         root of the tree. Each pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @notice This returns the rebuilt hash obtained by traversing a Merkle tree up from `leaf` using `proof`.
     *         A `proof` is valid if and only if the rebuilt hash matches the root of the tree.
     *         When processing the proof, the pairs of leafs & pre-images are assumed to be sorted.
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        uint256 length = proof.length;

        for (uint256 i = 0; i < length; ) {
            computedHash = _hashPair(computedHash, proof[i]);
            unchecked {
                ++i;
            }
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Enums
import {CollectionType} from "../enums/CollectionType.sol";
import {QuoteType} from "../enums/QuoteType.sol";

/**
 * @title OrderStructs
 * @notice This library contains all order struct types for the LooksRare protocol (v2).
 * @author LooksRare protocol team (👀,💎)
 */
library OrderStructs {
    /**
     * 1. Maker struct
     */

    /**
     * @notice Maker is the struct for a maker order.
     * @param quoteType Quote type (i.e. 0 = BID, 1 = ASK)
     * @param globalNonce Global user order nonce for maker orders
     * @param subsetNonce Subset nonce (shared across bid/ask maker orders)
     * @param orderNonce Order nonce (it can be shared across bid/ask maker orders)
     * @param strategyId Strategy id
     * @param collectionType Collection type (i.e. 0 = ERC721, 1 = ERC1155)
     * @param collection Collection address
     * @param currency Currency address (@dev address(0) = ETH)
     * @param signer Signer address
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @param price Minimum price for maker ask, maximum price for maker bid
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     * @param additionalParameters Extra data specific for the order
     */
    struct Maker {
        QuoteType quoteType;
        uint256 globalNonce;
        uint256 subsetNonce;
        uint256 orderNonce;
        uint256 strategyId;
        CollectionType collectionType;
        address collection;
        address currency;
        address signer;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256[] itemIds;
        uint256[] amounts;
        bytes additionalParameters;
    }

    /**
     * 2. Taker struct
     */

    /**
     * @notice Taker is the struct for a taker ask/bid order. It contains the parameters required for a direct purchase.
     * @dev Taker struct is matched against MakerAsk/MakerBid structs at the protocol level.
     * @param recipient Recipient address (to receive NFTs or non-fungible tokens)
     * @param additionalParameters Extra data specific for the order
     */
    struct Taker {
        address recipient;
        bytes additionalParameters;
    }

    /**
     * 3. Merkle tree struct
     */

    enum MerkleTreeNodePosition { Left, Right }

    /**
     * @notice MerkleTreeNode is a MerkleTree's node.
     * @param value It can be an order hash or a proof
     * @param position The node's position in its branch.
     *                 It can be left or right or none
     *                 (before the tree is sorted).
     */
    struct MerkleTreeNode {
        bytes32 value;
        MerkleTreeNodePosition position;
    }

    /**
     * @notice MerkleTree is the struct for a merkle tree of order hashes.
     * @dev A Merkle tree can be computed with order hashes.
     *      It can contain order hashes from both maker bid and maker ask structs.
     * @param root Merkle root
     * @param proof Array containing the merkle proof
     */
    struct MerkleTree {
        bytes32 root;
        MerkleTreeNode[] proof;
    }

    /**
     * 4. Constants
     */

    /**
     * @notice This is the type hash constant used to compute the maker order hash.
     */
    bytes32 internal constant _MAKER_TYPEHASH =
        keccak256(
            "Maker("
                "uint8 quoteType,"
                "uint256 globalNonce,"
                "uint256 subsetNonce,"
                "uint256 orderNonce,"
                "uint256 strategyId,"
                "uint8 collectionType,"
                "address collection,"
                "address currency,"
                "address signer,"
                "uint256 startTime,"
                "uint256 endTime,"
                "uint256 price,"
                "uint256[] itemIds,"
                "uint256[] amounts,"
                "bytes additionalParameters"
            ")"
        );

    /**
     * 5. Hash functions
     */

    /**
     * @notice This function is used to compute the order hash for a maker struct.
     * @param maker Maker order struct
     * @return makerHash Hash of the maker struct
     */
    function hash(Maker memory maker) internal pure returns (bytes32) {
        // Encoding is done into two parts to avoid stack too deep issues
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _MAKER_TYPEHASH,
                        maker.quoteType,
                        maker.globalNonce,
                        maker.subsetNonce,
                        maker.orderNonce,
                        maker.strategyId,
                        maker.collectionType,
                        maker.collection,
                        maker.currency
                    ),
                    abi.encode(
                        maker.signer,
                        maker.startTime,
                        maker.endTime,
                        maker.price,
                        keccak256(abi.encodePacked(maker.itemIds)),
                        keccak256(abi.encodePacked(maker.amounts)),
                        keccak256(maker.additionalParameters)
                    )
                )
            );
    }
}