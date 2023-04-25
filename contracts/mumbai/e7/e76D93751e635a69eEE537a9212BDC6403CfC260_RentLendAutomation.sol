// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

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
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
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
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
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

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
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
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRentLendMarketplace {
    enum NFTStandard {
        E721,
        E1155
    }
    enum LendStatus {
        LISTED,
        DELISTED
    }
    enum RentStatus {
        RENTED,
        RETURNED
    }
    enum NFTType {
        SAME_CHAIN,
        CROSS_CHAIN
    }

    struct Lending {
        uint256 lendingId;
        NFTStandard nftStandard;
        address nftAddress;
        uint256 tokenId;
        address payable lenderAddress;
        uint256 tokenQuantity; //listed qty of NFT
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenQuantityAlreadyRented; //Already rented
        uint256[] renterKeyArray;
        LendStatus lendStatus;
        NFTType nftType;
        string chain;
    }

    struct Renting {
        uint256 rentingId;
        uint256 lendingId; //associated lending Id
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 startTimeStamp;
        uint256 rentedDuration;
        uint256 rentedPricePerDay;
        bool refundRequired;
        uint256 refundEndTimeStamp;
        RentStatus rentStatus;
    }

    // native
    error PriceNotMet(uint256 lendingId, uint256 price);
    error PriceMustBeAboveZero();
    error RentDurationNotAcceptable(uint256 maxRentDuration);
    error InvalidOrderIdInput(uint256 lendingId);
    error InvalidCaller(address expectedAddress, address callerAddress);
    error InvalidNFTStandard(address nftAddress);
    error InvalidInputs(
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    );

    // native
    event Lent(
        uint256 indexed lendingId,
        NFTStandard nftStandard,
        address nftAddress,
        uint256 tokenId,
        address indexed lenderAddress,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration,
        LendStatus lendStatus,
        NFTType indexed nftType
    );

    event LendingUpdated(
        uint256 indexed lendingId,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event Rented(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityRented,
        uint256 startTimeStamp,
        uint256 rentedDuration,
        RentStatus rentStatus
    );

    event Returned(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityReturned,
        RentStatus rentStatus
    );

    event DeListed(uint256 indexed lendingId, LendStatus lendStatus);

    function setAutomationAddress(address _automation) external;

    function setFeesForAdmin(uint256 _percentFees) external;

    function isERC721(address nftAddress) external view returns (bool output);

    function isERC1155(address nftAddress) external view returns (bool output);

    function withdrawFunds() external;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./RentLendMarketplace.sol";

contract RentLendAutomation is AutomationCompatibleInterface {
    RentLendMarketplace public rentLendMktAddress;
    address _owner;

    constructor(address payable _rentLendMktAddress) {
        _owner = msg.sender;
        rentLendMktAddress = RentLendMarketplace(_rentLendMktAddress);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (, uint256 _expired) = rentLendMktAddress.getExpiredRentings();

        (, uint256 _refunds) = rentLendMktAddress.getRefundRentings();

        upkeepNeeded = _expired > 0 || _refunds > 0;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        rentLendMktAddress.checkReturnRefundAutomation();
    }

    function setLyncRentLendMarketplace(address payable _newAddress) external {
        require(msg.sender == _owner, "Only owner can call tis function");
        rentLendMktAddress = RentLendMarketplace(_newAddress);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IRentLendMarketplace.sol";

contract RentLendMarketplace is ReentrancyGuard, IRentLendMarketplace {
    using ERC165Checker for address;

    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;

    address payable public adminAddress;
    uint256 public lendingCtr;
    uint256 public rentingCtr;

    uint256 public percentFeesAdmin = 4;
    uint256 public minRentDueSeconds = 86400;
    address public automationAddress;

    // keeps a check whether user has listed a particular NFT previously or not
    // NFT Address => Token Id => user address = bool
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public userListedNFTBeforeSameChain;

    uint256[] public activeLendingsKeys;
    mapping(uint256 => Lending) public lendings;

    uint256[] public activeRentingsKeys;
    mapping(uint256 => Renting) public rentings;

    modifier onlyAdmin() {
        if (msg.sender != adminAddress) {
            revert InvalidCaller(adminAddress, msg.sender);
        }
        _;
    }

    constructor() {
        lendingCtr = 0;
        rentingCtr = 0;
        adminAddress = payable(msg.sender);
    }

    function lend(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external {
        bool listed = userListedNFTBeforeSameChain[_nftAddress][_tokenId][
            msg.sender
        ];

        require(
            listed == false,
            "Token already listed, Kindly Modify the lending!"
        );

        if (_nftStandard == NFTStandard.E721) {
            if (!isERC721(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            require(
                _tokenQuantity == 1,
                "This NFT standard supports only 1 lending qty"
            );

            address ownerOf = IERC721(_nftAddress).ownerOf(_tokenId);
            require(ownerOf == msg.sender, "You do not own the NFT");
        } else if (_nftStandard == NFTStandard.E1155) {
            if (!isERC1155(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }

            uint256 ownerAmount = IERC1155(_nftAddress).balanceOf(
                msg.sender,
                _tokenId
            );
            require(
                ownerAmount >= _tokenQuantity,
                "Not enough tokens owned by Address or Tokens already lending"
            );
        }

        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (_maxRentDuration < minRentDueSeconds) {
            revert RentDurationNotAcceptable(_maxRentDuration);
        }
        _createNewOrder(
            _nftStandard,
            _nftAddress,
            _tokenId,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            NFTType.SAME_CHAIN,
            msg.sender
        );
        emit Lent(
            lendingCtr,
            _nftStandard,
            _nftAddress,
            _tokenId,
            msg.sender,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            LendStatus.LISTED,
            NFTType.SAME_CHAIN
        );
    }

    function _createNewOrder(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration,
        NFTType _nftType,
        address _lenderAddress
    ) internal {
        lendingCtr++;

        Lending memory lendingCache;
        lendingCache.lendingId = lendingCtr;
        lendingCache.nftStandard = _nftStandard;
        lendingCache.nftAddress = _nftAddress;
        lendingCache.tokenId = _tokenId;
        lendingCache.lenderAddress = payable(_lenderAddress);
        lendingCache.tokenQuantity = _tokenQuantity;
        lendingCache.pricePerDay = _price;
        lendingCache.maxRentDuration = _maxRentDuration;
        lendingCache.tokenQuantityAlreadyRented = 0;
        lendingCache.lendStatus = LendStatus.LISTED;
        lendingCache.nftType = _nftType;
        lendings[lendingCtr] = lendingCache;

        activeLendingsKeys.push(lendingCtr);
        userListedNFTBeforeSameChain[_nftAddress][_tokenId][
            _lenderAddress
        ] = true;
    }

    function modifyLending(
        uint256 _lendingId,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.lenderAddress != msg.sender) {
            revert InvalidCaller(lendingStorage.lenderAddress, msg.sender);
        }
        uint256 ownerHas = 1;
        if (lendingStorage.nftStandard == NFTStandard.E1155) {
            IERC1155 nft = IERC1155(lendingStorage.nftAddress);
            ownerHas = nft.balanceOf(msg.sender, lendingStorage.tokenId);
        }
        // require(
        //     lendingStorage.nftType == NFTType.SAME_CHAIN,
        //     "Not a same chain NFT!"
        // );
        require(
            lendingStorage.lendStatus == LendStatus.LISTED,
            "Item delisted!"
        );
        if (_tokenQtyToAdd > 0) {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than min rent duration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
                lendingStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than min rent duration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
            }
            require(
                ownerHas >=
                    lendingStorage.tokenQuantityAlreadyRented +
                        lendingStorage.tokenQuantity +
                        _tokenQtyToAdd,
                "Not Enough tokens owned by address"
            );
            lendingStorage.tokenQuantity += _tokenQtyToAdd;
        } else {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than min rent duration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
                lendingStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than min rent duration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                } else {
                    revert InvalidInputs(
                        _tokenQtyToAdd,
                        _newPrice,
                        _newMaxRentDuration
                    );
                }
            }
        }

        emit LendingUpdated(
            _lendingId,
            lendingStorage.tokenQuantity,
            lendingStorage.pricePerDay,
            lendingStorage.maxRentDuration
        );
    }

    function cancelLending(uint256 _lendingId) external {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.lenderAddress != msg.sender) {
            revert InvalidCaller(lendingStorage.lenderAddress, msg.sender);
        }

        require(
            lendingStorage.lendStatus == LendStatus.LISTED,
            "Item with lending Id is already delisted"
        );

        require(
            lendingStorage.tokenQuantityAlreadyRented == 0,
            "Some items are being rented! Cannot cancel now"
        );

        lendingStorage.tokenQuantity = 0;

        lendingStorage.lendStatus = LendStatus.DELISTED;
        _removeEntryFromArray(activeLendingsKeys, _lendingId);

        userListedNFTBeforeSameChain[lendingStorage.nftAddress][
            lendingStorage.tokenId
        ][msg.sender] = false;

        emit DeListed(_lendingId, lendingStorage.lendStatus);
    }

    function rent(
        uint256 _lendingId,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];

        require(
            msg.sender != lendingStorage.lenderAddress,
            "Owned NFTs cannot be rented"
        );

        require(
            lendingStorage.lendStatus != LendStatus.DELISTED,
            "This order is delisted"
        );
        require(
            lendingStorage.tokenQuantity >= _tokenQuantity,
            "Not Enough token available to rent"
        );

        if (_duration > lendingStorage.maxRentDuration) {
            revert RentDurationNotAcceptable(_duration);
        }
        uint256 cost = calculateCost(
            lendingStorage.pricePerDay,
            _duration,
            _tokenQuantity
        );
        if (msg.value != cost) {
            revert PriceNotMet(_lendingId, cost);
        }

        _updateRenting(lendingStorage, _tokenQuantity, _duration);

        // _splitFunds(msg.value, lendingStorage.lenderAddress);

        emit Rented(
            rentingCtr,
            _lendingId,
            msg.sender,
            _tokenQuantity,
            block.timestamp,
            _duration,
            RentStatus.RENTED
        );
    }

    function calculateCost(
        uint256 _pricePerDay,
        uint256 _duration,
        uint256 qty
    ) public pure returns (uint256 cost) {
        cost = ((_pricePerDay * _duration * qty) / 86400);
    }

    //Supporting the rentItem function
    function _updateRenting(
        Lending storage lendingStorage,
        uint256 _tokenQuantity,
        uint256 _duration
    ) internal {
        rentingCtr++;
        lendingStorage.tokenQuantity =
            lendingStorage.tokenQuantity -
            _tokenQuantity;

        lendingStorage.tokenQuantityAlreadyRented =
            lendingStorage.tokenQuantityAlreadyRented +
            _tokenQuantity;

        Renting memory rentingCache;
        rentingCache.rentingId = rentingCtr;
        rentingCache.lendingId = lendingStorage.lendingId;
        rentingCache.rentStatus = RentStatus.RENTED;

        rentingCache.renterAddress = msg.sender;
        rentingCache.rentedDuration = _duration;
        rentingCache.tokenQuantityRented += _tokenQuantity;
        rentingCache.startTimeStamp = block.timestamp;
        rentingCache.rentedPricePerDay = lendingStorage.pricePerDay;
        rentingCache.refundRequired = false;
        rentingCache.refundEndTimeStamp = 0;

        rentings[rentingCtr] = rentingCache;

        lendingStorage.renterKeyArray.push(rentingCtr);
        activeRentingsKeys.push(rentingCtr);
    }

    function returnRented(uint256 _rentingID, uint256 _tokenQuantity) external {
        if (_rentingID > rentingCtr) {
            revert InvalidOrderIdInput(_rentingID);
        }
        Renting storage rentingStorage = rentings[_rentingID];
        uint256 _lendingId = rentingStorage.lendingId;
        Lending storage lendingStorage = lendings[_lendingId];
        require(
            rentingStorage.renterAddress == msg.sender,
            "Unverified caller, only renter can return the NFT"
        );

        require(
            rentingStorage.tokenQuantityRented >= _tokenQuantity,
            "Not enough tokens rented"
        );

        lendingStorage.tokenQuantity =
            lendingStorage.tokenQuantity +
            _tokenQuantity;

        lendingStorage.tokenQuantityAlreadyRented =
            lendingStorage.tokenQuantityAlreadyRented -
            _tokenQuantity;

        rentingStorage.tokenQuantityRented =
            rentingStorage.tokenQuantityRented -
            _tokenQuantity;

        if (rentingStorage.tokenQuantityRented == 0) {
            rentingStorage.rentStatus = RentStatus.RETURNED;
            _removeEntryFromArray(lendingStorage.renterKeyArray, _rentingID);
            _removeEntryFromArray(activeRentingsKeys, _rentingID);
        }

        // Funds settlement
        if (rentingStorage.refundRequired == false) {
            // calculate the amount to be paid to the lender
            uint256 _lenderPayout = calculateCost(
                rentingStorage.rentedPricePerDay,
                rentingStorage.rentedDuration,
                _tokenQuantity
            );

            _splitFunds(_lenderPayout, lendingStorage.lenderAddress);
        } else {
            // actual cost if the lender owned the item(s) for whole rent duration
            uint256 costTotalDuration = calculateCost(
                rentingStorage.rentedPricePerDay,
                rentingStorage.rentedDuration,
                _tokenQuantity
            );

            // calculate the amount to be paid to the lender for how much time the item was owned by lender
            uint256 actualLenderPayout = calculateCost(
                rentingStorage.rentedPricePerDay,
                rentingStorage.refundEndTimeStamp -
                    rentingStorage.startTimeStamp,
                _tokenQuantity
            );

            _splitFunds(actualLenderPayout, lendingStorage.lenderAddress);

            // refund remaining amount to renter
            uint256 _refundAmount = costTotalDuration - actualLenderPayout;
            payable(rentingStorage.renterAddress).transfer(_refundAmount);
        }

        emit Returned(
            _rentingID,
            _lendingId,
            msg.sender,
            _tokenQuantity,
            rentingStorage.rentStatus
        );
    }

    function _removeEntryFromArray(
        uint256[] storage arrayStorage,
        uint256 _entry
    ) internal {
        // uint256 _index;
        for (uint256 i = 0; i < arrayStorage.length; i++) {
            if (arrayStorage[i] == _entry) {
                // _index = i;
                arrayStorage[i] = arrayStorage[arrayStorage.length - 1];
                arrayStorage.pop();
                break;
            }
        }
    }

    //@dev functions gives us the data for listing data for
    function getLendingData(
        uint256 _lendingId
    ) public view returns (Lending memory) {
        Lending memory listing = lendings[_lendingId];
        return listing;
    }

    uint256 public withdrawableAmount;

    //@dev Fucntion calculates admin fees to be deducted from total amount
    //and split the totalamout according to fees structure
    function _splitFunds(
        uint256 _totalAmount,
        address _lenderAddress
    ) internal {
        require(_totalAmount != 0, "_totalAmount must be greater than 0");
        uint256 amountToSeller = (_totalAmount * (100 - percentFeesAdmin)) /
            100;
        withdrawableAmount = _totalAmount - amountToSeller;

        payable(_lenderAddress).transfer(amountToSeller);
    }

    function setAdmin(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "Admin address can't be null!");
        adminAddress = payable(_newAddress);
    }

    function setFeesForAdmin(uint256 _percentFees) external onlyAdmin {
        require(_percentFees < 100, "Fees cannot exceed 100%");
        percentFeesAdmin = _percentFees;
    }

    function setMinRentDueSeconds(uint256 _minDuration) external onlyAdmin {
        minRentDueSeconds = _minDuration;
    }

    function isERC721(address nftAddress) public view returns (bool output) {
        output = nftAddress.supportsInterface(IID_IERC721);
    }

    function isERC1155(address nftAddress) public view returns (bool output) {
        output = nftAddress.supportsInterface(IID_IERC1155);
    }

    function withdrawFunds() external onlyAdmin {
        require(withdrawableAmount > 0, "No more funds to withdraw");
        withdrawableAmount = 0;
        payable(msg.sender).transfer(withdrawableAmount);
    }

    fallback() external payable {}

    receive() external payable {
        // React to receiving ether
    }

    // ------------------------------ Automation functions -------------------------------- //
    function setAutomationAddress(address _automation) external onlyAdmin {
        require(_automation != address(0), "Automation address can't be null!");
        automationAddress = _automation;
    }

    function checkReturnRefundAutomation() external {
        require(
            automationAddress != address(0),
            "No automation address set yet!"
        );
        require(
            msg.sender == automationAddress,
            "Only Authorized address can call this function!"
        );
        (uint256[] memory getExpired, uint256 toUpdate) = getExpiredRentings();
        if (toUpdate > 0) {
            _returnRentedUsingAutomation(getExpired, toUpdate);
        }
        (
            uint256[] memory getRefundRequireds,
            uint256 toRefund
        ) = getRefundRentings();
        if (toRefund > 0) {
            _markRefundsAndDelistUsingAutomation(getRefundRequireds, toRefund);
        }
    }

    function getExpiredRentings()
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arrLength = activeRentingsKeys.length;
        uint256[] memory tempArray = new uint256[](arrLength);
        uint256 j = 0;
        for (uint256 i = 0; i < activeRentingsKeys.length; i++) {
            uint256 _rentingId = activeRentingsKeys[i];
            if (
                block.timestamp >=
                rentings[_rentingId].startTimeStamp +
                    rentings[_rentingId].rentedDuration
            ) {
                tempArray[j] = _rentingId;
                j++;
            }
        }
        return (tempArray, j);
    }

    function _returnRentedUsingAutomation(
        uint256[] memory _rentingIDs,
        uint256 length
    ) internal {
        require(length != 0, "The renters Array is Empty");

        for (uint256 i = 0; i < length; i++) {
            uint256 _rentingId = _rentingIDs[i];
            Renting storage rentingStorage = rentings[_rentingId];

            Lending storage lendingStorage = lendings[rentingStorage.lendingId];

            lendingStorage.tokenQuantity += rentingStorage.tokenQuantityRented;
            lendingStorage.tokenQuantityAlreadyRented -= rentingStorage
                .tokenQuantityRented;

            rentingStorage.rentStatus = RentStatus.RETURNED;

            _removeEntryFromArray(lendingStorage.renterKeyArray, _rentingId);
            _removeEntryFromArray(activeRentingsKeys, _rentingId);

            // Funds settlement
            if (rentingStorage.refundRequired == false) {
                // calculate the amount to be paid to the lender
                uint256 _lenderPayout = calculateCost(
                    rentingStorage.rentedPricePerDay,
                    rentingStorage.rentedDuration,
                    rentingStorage.tokenQuantityRented
                );

                _splitFunds(_lenderPayout, lendingStorage.lenderAddress);
            } else {
                // actual cost if the lender owned the item for whole rent duration time
                uint256 costTotalDuration = calculateCost(
                    rentingStorage.rentedPricePerDay,
                    rentingStorage.rentedDuration,
                    rentingStorage.tokenQuantityRented
                );

                // calculate the amount to be paid to the lender for how much time the item was owned by lender
                uint256 actualLenderPayout = calculateCost(
                    rentingStorage.rentedPricePerDay,
                    rentingStorage.refundEndTimeStamp -
                        rentingStorage.startTimeStamp,
                    rentingStorage.tokenQuantityRented
                );

                _splitFunds(actualLenderPayout, lendingStorage.lenderAddress);

                // refund remaining amount to renter
                uint256 _refundAmount = costTotalDuration - actualLenderPayout;
                payable(rentingStorage.renterAddress).transfer(_refundAmount);
            }

            rentingStorage.tokenQuantityRented = 0;

            emit Returned(
                _rentingId,
                rentingStorage.lendingId,
                rentingStorage.renterAddress,
                rentingStorage.tokenQuantityRented,
                RentStatus.RETURNED
            );
        }
    }

    // address public automationAddressRefunds;

    // function setAutomationAddressRefunds(
    //     address _automation
    // ) external onlyAdmin {
    //     require(_automation != address(0), "Automation address can't be null!");
    //     automationAddressRefunds = _automation;
    // }

    // function checkAndMarkRefundAutomation() external {
    //     require(
    //         automationAddressRefunds != address(0),
    //         "No automation address set yet!"
    //     );
    //     require(
    //         msg.sender == automationAddressRefunds,
    //         "Only Authorized address can call this function!"
    //     );
    //     (
    //         uint256[] memory getRefundRequireds,
    //         uint256 toRefund
    //     ) = getRefundRentings();
    //     if (toRefund > 0) {
    //         _markRefundsAndDelistUsingAutomation(getRefundRequireds, toRefund);
    //     }
    // }

    function getRefundRentings()
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arrLength = activeRentingsKeys.length;
        uint256[] memory tempArray = new uint256[](arrLength);
        uint256 j = 0;
        for (uint256 i = 0; i < activeRentingsKeys.length; i++) {
            uint256 _rentingId = activeRentingsKeys[i];

            Renting memory rentingCache = rentings[_rentingId];
            if (rentingCache.refundRequired == false) {
                Lending memory lendingCache = lendings[rentingCache.lendingId];

                if (lendingCache.nftStandard == NFTStandard.E721) {
                    IERC721 nft721 = IERC721(lendingCache.nftAddress);
                    try nft721.ownerOf(lendingCache.tokenId) {
                        if (
                            nft721.ownerOf(lendingCache.tokenId) !=
                            lendingCache.lenderAddress
                        ) {
                            tempArray[j] = _rentingId;
                            j++;
                        }
                    } catch {
                        tempArray[j] = _rentingId;
                        j++;
                    }
                } else {
                    IERC1155 nft1155 = IERC1155(lendingCache.nftAddress);
                    if (
                        nft1155.balanceOf(
                            lendingCache.lenderAddress,
                            lendingCache.tokenId
                        ) < lendingCache.tokenQuantity
                    ) {
                        tempArray[j] = _rentingId;
                        j++;
                    }
                }
            }
        }
        return (tempArray, j);
    }

    function _markRefundsAndDelistUsingAutomation(
        uint256[] memory _rentingIDs,
        uint256 length
    ) internal {
        require(length != 0, "The renters Array is Empty");

        for (uint256 i = 0; i < length; i++) {
            uint256 _rentingId = _rentingIDs[i];
            Renting storage rentingStorage = rentings[_rentingId];
            rentingStorage.refundRequired = true;
            rentingStorage.refundEndTimeStamp = block.timestamp;
            Lending storage lendingStorage = lendings[rentingStorage.lendingId];

            lendingStorage.tokenQuantity = 0;

            lendingStorage.lendStatus = LendStatus.DELISTED;
            _removeEntryFromArray(activeLendingsKeys, rentingStorage.lendingId);

            userListedNFTBeforeSameChain[lendingStorage.nftAddress][
                lendingStorage.tokenId
            ][msg.sender] = false;

            emit DeListed(rentingStorage.lendingId, lendingStorage.lendStatus);
        }
    }
}