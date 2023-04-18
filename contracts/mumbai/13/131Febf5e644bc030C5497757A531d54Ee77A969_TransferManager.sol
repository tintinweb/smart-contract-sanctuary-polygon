// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the call recipient is not a contract.
 */
error NotAContract();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the ETH transfer fails.
 */
error ETHTransferFail();

/**
 * @notice It is emitted if the ERC20 approval fails.
 */
error ERC20ApprovalFail();

/**
 * @notice It is emitted if the ERC20 transfer fails.
 */
error ERC20TransferFail();

/**
 * @notice It is emitted if the ERC20 transferFrom fails.
 */
error ERC20TransferFromFail();

/**
 * @notice It is emitted if the ERC721 transferFrom fails.
 */
error ERC721TransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeTransferFrom fails.
 */
error ERC1155SafeTransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeBatchTransferFrom fails.
 */
error ERC1155SafeBatchTransferFromFail();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IOwnableTwoSteps
 * @author LooksRare protocol team (👀,💎)
 */
interface IOwnableTwoSteps {
    /**
     * @notice This enum keeps track of the ownership status.
     * @param NoOngoingTransfer The default status when the owner is set
     * @param TransferInProgress The status when a transfer to a new owner is initialized
     * @param RenouncementInProgress The status when a transfer to address(0) is initialized
     */
    enum Status {
        NoOngoingTransfer,
        TransferInProgress,
        RenouncementInProgress
    }

    /**
     * @notice This is returned when there is no transfer of ownership in progress.
     */
    error NoOngoingTransferInProgress();

    /**
     * @notice This is returned when the caller is not the owner.
     */
    error NotOwner();

    /**
     * @notice This is returned when there is no renouncement in progress but
     *         the owner tries to validate the ownership renouncement.
     */
    error RenouncementNotInProgress();

    /**
     * @notice This is returned when the transfer is already in progress but the owner tries
     *         initiate a new ownership transfer.
     */
    error TransferAlreadyInProgress();

    /**
     * @notice This is returned when there is no ownership transfer in progress but the
     *         ownership change tries to be approved.
     */
    error TransferNotInProgress();

    /**
     * @notice This is returned when the ownership transfer is attempted to be validated by the
     *         a caller that is not the potential owner.
     */
    error WrongPotentialOwner();

    /**
     * @notice This is emitted if the ownership transfer is cancelled.
     */
    event CancelOwnershipTransfer();

    /**
     * @notice This is emitted if the ownership renouncement is initiated.
     */
    event InitiateOwnershipRenouncement();

    /**
     * @notice This is emitted if the ownership transfer is initiated.
     * @param previousOwner Previous/current owner
     * @param potentialOwner Potential/future owner
     */
    event InitiateOwnershipTransfer(address previousOwner, address potentialOwner);

    /**
     * @notice This is emitted when there is a new owner.
     */
    event NewOwner(address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC1155} from "../interfaces/generic/IERC1155.sol";

// Errors
import {ERC1155SafeTransferFromFail, ERC1155SafeBatchTransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC1155Transfer
 * @notice This contract contains low-level calls to transfer ERC1155 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC1155Transfer {
    /**
     * @notice Execute ERC1155 safeTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     * @param amount Amount to transfer
     */
    function _executeERC1155SafeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ERC1155SafeTransferFromFail();
        }
    }

    /**
     * @notice Execute ERC1155 safeBatchTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenIds Array of tokenIds to transfer
     * @param amounts Array of amounts to transfer
     */
    function _executeERC1155SafeBatchTransferFrom(
        address collection,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(
            abi.encodeCall(IERC1155.safeBatchTransferFrom, (from, to, tokenIds, amounts, ""))
        );

        if (!status) {
            revert ERC1155SafeBatchTransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC721} from "../interfaces/generic/IERC721.sol";

// Errors
import {ERC721TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC721Transfer {
    /**
     * @notice Execute ERC721 transferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     */
    function _executeERC721TransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ERC721TransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IOwnableTwoSteps} from "./interfaces/IOwnableTwoSteps.sol";

/**
 * @title OwnableTwoSteps
 * @notice This contract offers transfer of ownership in two steps with potential owner
 *         having to confirm the transaction to become the owner.
 *         Renouncement of the ownership is also a two-step process since the next potential owner is the address(0).
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract OwnableTwoSteps is IOwnableTwoSteps {
    /**
     * @notice Address of the current owner.
     */
    address public owner;

    /**
     * @notice Address of the potential owner.
     */
    address public potentialOwner;

    /**
     * @notice Ownership status.
     */
    Status public ownershipStatus;

    /**
     * @notice Modifier to wrap functions for contracts that inherit this contract.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _owner The contract's owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit NewOwner(_owner);
    }

    /**
     * @notice This function is used to cancel the ownership transfer.
     * @dev This function can be used for both cancelling a transfer to a new owner and
     *      cancelling the renouncement of the ownership.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        Status _ownershipStatus = ownershipStatus;
        if (_ownershipStatus == Status.NoOngoingTransfer) {
            revert NoOngoingTransferInProgress();
        }

        if (_ownershipStatus == Status.TransferInProgress) {
            delete potentialOwner;
        }

        delete ownershipStatus;

        emit CancelOwnershipTransfer();
    }

    /**
     * @notice This function is used to confirm the ownership renouncement.
     */
    function confirmOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.RenouncementInProgress) {
            revert RenouncementNotInProgress();
        }

        delete owner;
        delete ownershipStatus;

        emit NewOwner(address(0));
    }

    /**
     * @notice This function is used to confirm the ownership transfer.
     * @dev This function can only be called by the current potential owner.
     */
    function confirmOwnershipTransfer() external {
        if (ownershipStatus != Status.TransferInProgress) {
            revert TransferNotInProgress();
        }

        if (msg.sender != potentialOwner) {
            revert WrongPotentialOwner();
        }

        owner = msg.sender;
        delete ownershipStatus;
        delete potentialOwner;

        emit NewOwner(msg.sender);
    }

    /**
     * @notice This function is used to initiate the transfer of ownership to a new owner.
     * @param newPotentialOwner New potential owner address
     */
    function initiateOwnershipTransfer(address newPotentialOwner) external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.TransferInProgress;
        potentialOwner = newPotentialOwner;

        /**
         * @dev This function can only be called by the owner, so msg.sender is the owner.
         *      We don't have to SLOAD the owner again.
         */
        emit InitiateOwnershipTransfer(msg.sender, newPotentialOwner);
    }

    /**
     * @notice This function is used to initiate the ownership renouncement.
     */
    function initiateOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.RenouncementInProgress;

        emit InitiateOwnershipRenouncement();
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}

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

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

// Enums
import {CollectionType} from "../enums/CollectionType.sol";

/**
 * @title ITransferManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ITransferManager {
    /**
     * @notice This struct is only used for transferBatchItemsAcrossCollections.
     * @param collection Collection address
     * @param collectionType 0 for ERC721, 1 for ERC1155
     * @param itemIds Array of item ids to transfer
     * @param amounts Array of amounts to transfer
     */
    struct BatchTransferItem {
        address collection;
        CollectionType collectionType;
        uint256[] itemIds;
        uint256[] amounts;
    }

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are granted by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsGranted(address user, address[] operators);

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are revoked by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsRemoved(address user, address[] operators);

    /**
     * @notice It is emitted if a new operator is added to the global allowlist.
     * @param operator Operator address
     */
    event OperatorAllowed(address operator);

    /**
     * @notice It is emitted if an operator is removed from the global allowlist.
     * @param operator Operator address
     */
    event OperatorRemoved(address operator);

    /**
     * @notice It is returned if the operator to approve has already been approved by the user.
     */
    error OperatorAlreadyApprovedByUser();

    /**
     * @notice It is returned if the operator to revoke has not been previously approved by the user.
     */
    error OperatorNotApprovedByUser();

    /**
     * @notice It is returned if the transfer caller is already allowed by the owner.
     * @dev This error can only be returned for owner operations.
     */
    error OperatorAlreadyAllowed();

    /**
     * @notice It is returned if the operator to approve is not in the global allowlist defined by the owner.
     * @dev This error can be returned if the user tries to grant approval to an operator address not in the
     *      allowlist or if the owner tries to remove the operator from the global allowlist.
     */
    error OperatorNotAllowed();

    /**
     * @notice It is returned if the transfer caller is invalid.
     *         For a transfer called to be valid, the operator must be in the global allowlist and
     *         approved by the 'from' user.
     */
    error TransferCallerInvalid();
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// LooksRare unopinionated libraries
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";

// Interfaces and errors
import {ITransferManager} from "./interfaces/ITransferManager.sol";
import {AmountInvalid, LengthsInvalid} from "./errors/SharedErrors.sol";

// Libraries
import {OrderStructs} from "./libraries/OrderStructs.sol";

// Enums
import {CollectionType} from "./enums/CollectionType.sol";

/**
 * @title TransferManager
 * @notice This contract provides the transfer functions for ERC721/ERC1155 for contracts that require them.
 *         Collection type "0" refers to ERC721 transfer functions.
 *         Collection type "1" refers to ERC1155 transfer functions.
 * @dev "Safe" transfer functions for ERC721 are not implemented since they come with added gas costs
 *       to verify if the recipient is a contract as it requires verifying the receiver interface is valid.
 * @author LooksRare protocol team (👀,💎)
 */
contract TransferManager is ITransferManager, LowLevelERC721Transfer, LowLevelERC1155Transfer, OwnableTwoSteps {
    /**
     * @notice This returns whether the user has approved the operator address.
     * The first address is the user and the second address is the operator (e.g. LooksRareProtocol).
     */
    mapping(address => mapping(address => bool)) public hasUserApprovedOperator;

    /**
     * @notice This returns whether the operator address is allowed by this contract's owner.
     */
    mapping(address => bool) public isOperatorAllowed;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @notice This function transfers items for a single ERC721 collection.
     * @param collection Collection address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     */
    function transferItemsERC721(
        address collection,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external {
        uint256 length = itemIds.length;
        if (length == 0) {
            revert LengthsInvalid();
        }

        _isOperatorValidForTransfer(from, msg.sender);

        for (uint256 i; i < length; ) {
            if (amounts[i] != 1) {
                revert AmountInvalid();
            }
            _executeERC721TransferFrom(collection, from, to, itemIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function transfers items for a single ERC1155 collection.
     * @param collection Collection address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     * @dev It does not allow batch transferring if from = msg.sender since native function should be used.
     */
    function transferItemsERC1155(
        address collection,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external {
        uint256 length = itemIds.length;

        if (length == 0 || amounts.length != length) {
            revert LengthsInvalid();
        }

        _isOperatorValidForTransfer(from, msg.sender);

        if (length == 1) {
            if (amounts[0] == 0) {
                revert AmountInvalid();
            }
            _executeERC1155SafeTransferFrom(collection, from, to, itemIds[0], amounts[0]);
        } else {
            for (uint256 i; i < length; ) {
                if (amounts[i] == 0) {
                    revert AmountInvalid();
                }

                unchecked {
                    ++i;
                }
            }
            _executeERC1155SafeBatchTransferFrom(collection, from, to, itemIds, amounts);
        }
    }

    /**
     * @notice This function transfers items across an array of collections that can be both ERC721 and ERC1155.
     * @param items Array of BatchTransferItem
     * @param from Sender address
     * @param to Recipient address
     */
    function transferBatchItemsAcrossCollections(
        BatchTransferItem[] calldata items,
        address from,
        address to
    ) external {
        uint256 itemsLength = items.length;

        if (itemsLength == 0) {
            revert LengthsInvalid();
        }

        if (from != msg.sender) {
            _isOperatorValidForTransfer(from, msg.sender);
        }

        for (uint256 i; i < itemsLength; ) {
            uint256[] calldata itemIds = items[i].itemIds;
            uint256 itemIdsLengthForSingleCollection = itemIds.length;
            uint256[] calldata amounts = items[i].amounts;

            if (itemIdsLengthForSingleCollection == 0 || amounts.length != itemIdsLengthForSingleCollection) {
                revert LengthsInvalid();
            }

            CollectionType collectionType = items[i].collectionType;
            if (collectionType == CollectionType.ERC721) {
                for (uint256 j; j < itemIdsLengthForSingleCollection; ) {
                    if (amounts[j] != 1) {
                        revert AmountInvalid();
                    }
                    _executeERC721TransferFrom(items[i].collection, from, to, itemIds[j]);
                    unchecked {
                        ++j;
                    }
                }
            } else if (collectionType == CollectionType.ERC1155) {
                for (uint256 j; j < itemIdsLengthForSingleCollection; ) {
                    if (amounts[j] == 0) {
                        revert AmountInvalid();
                    }

                    unchecked {
                        ++j;
                    }
                }
                _executeERC1155SafeBatchTransferFrom(items[i].collection, from, to, itemIds, amounts);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function allows a user to grant approvals for an array of operators.
     *         Users cannot grant approvals if the operator is not allowed by this contract's owner.
     * @param operators Array of operator addresses
     * @dev Each operator address must be globally allowed to be approved.
     */
    function grantApprovals(address[] calldata operators) external {
        uint256 length = operators.length;

        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            address operator = operators[i];

            if (!isOperatorAllowed[operator]) {
                revert OperatorNotAllowed();
            }

            if (hasUserApprovedOperator[msg.sender][operator]) {
                revert OperatorAlreadyApprovedByUser();
            }

            hasUserApprovedOperator[msg.sender][operator] = true;

            unchecked {
                ++i;
            }
        }

        emit ApprovalsGranted(msg.sender, operators);
    }

    /**
     * @notice This function allows a user to revoke existing approvals for an array of operators.
     * @param operators Array of operator addresses
     * @dev Each operator address must be approved at the user level to be revoked.
     */
    function revokeApprovals(address[] calldata operators) external {
        uint256 length = operators.length;
        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            address operator = operators[i];

            if (!hasUserApprovedOperator[msg.sender][operator]) {
                revert OperatorNotApprovedByUser();
            }

            delete hasUserApprovedOperator[msg.sender][operator];
            unchecked {
                ++i;
            }
        }

        emit ApprovalsRemoved(msg.sender, operators);
    }

    /**
     * @notice This function allows an operator to be added for the shared transfer system.
     *         Once the operator is allowed, users can grant NFT approvals to this operator.
     * @param operator Operator address to allow
     * @dev Only callable by owner.
     */
    function allowOperator(address operator) external onlyOwner {
        if (isOperatorAllowed[operator]) {
            revert OperatorAlreadyAllowed();
        }

        isOperatorAllowed[operator] = true;

        emit OperatorAllowed(operator);
    }

    /**
     * @notice This function allows the user to remove an operator for the shared transfer system.
     * @param operator Operator address to remove
     * @dev Only callable by owner.
     */
    function removeOperator(address operator) external onlyOwner {
        if (!isOperatorAllowed[operator]) {
            revert OperatorNotAllowed();
        }

        delete isOperatorAllowed[operator];

        emit OperatorRemoved(operator);
    }

    /**
     * @notice This function is internal and verifies whether the transfer
     *         (by an operator on behalf of a user) is valid. If not, it reverts.
     * @param user User address
     * @param operator Operator address
     */
    function _isOperatorValidForTransfer(address user, address operator) private view {
        if (isOperatorAllowed[operator] && hasUserApprovedOperator[user][operator]) {
            return;
        }

        revert TransferCallerInvalid();
    }
}