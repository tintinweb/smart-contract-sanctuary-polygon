pragma solidity 0.8.17;

import "./interfaces/ISeaport.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";




// offerer:
// 0xE29CeC4BbC1ee29f66B2e68140a94463a6Ca5a2d
// offer:
// 0:
// itemType:
// 2
// token:
// 0x1feD5296d7284CC438dCdf606dEFf38887CF94C1
// identifierOrCriteria:
// 4
// startAmount:
// 1
// endAmount:
// 1
// consideration:
// 0:
// itemType:
// 0
// token:
// 0x0000000000000000000000000000000000000000
// identifierOrCriteria:
// 0
// startAmount:
// 975000000000000000
// endAmount:
// 975000000000000000
// recipient:
// 0xE29CeC4BbC1ee29f66B2e68140a94463a6Ca5a2d
// 1:
// itemType:
// 0
// token:
// 0x0000000000000000000000000000000000000000
// identifierOrCriteria:
// 0
// startAmount:
// 25000000000000000
// endAmount:
// 25000000000000000
// recipient:
// 0x0000a26b00c1F0DF003000390027140000fAa719
// startTime:
// 1664200171
// endTime:
// 1666792171
// orderType:
// 0
// zone:
////////////// 0x0000000000000000000000000000000000000000
/////////////// zoneHash:
/////////// 0x0000000000000000000000000000000000000000000000000000000000000000
// salt:
// 24446860302761739304752683030156737591518664810215442929810319719917889779760
// conduitKey:
// 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000
// counter:
// 0


contract FungibleFuture {
    
    ISeaport public seaport;
    IERC721 public nft;
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    uint256 public deployCheck = 1;
    
    constructor(address _seaport, address _nft) public {
        seaport = ISeaport(_seaport);
        nft = IERC721(_nft);
    }

    function listFuture(uint256 _tokenId) external {
        nft.setApprovalForAll(address(seaport), true);
        //IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;
        //IAsset[] memory tokens = new IAsset[](2);
        ISeaport.OrderType ordertype1 = ISeaport.OrderType.FULL_OPEN;
    
        ISeaport.ItemType offeritemtype = ISeaport.ItemType.ERC721;
        ISeaport.OfferItem[] memory offeritems = new ISeaport.OfferItem[](1);
        offeritems[0] = ISeaport.OfferItem({
                itemType: offeritemtype, //done
                token: address(nft), //done
                identifierOrCriteria: _tokenId, //done
                startAmount: 1, //done
                endAmount: 1 //done

        });

        ISeaport.ItemType considerationitemtype = ISeaport.ItemType.NATIVE; //done
        ISeaport.ConsiderationItem[] memory considerationitems = new ISeaport.ConsiderationItem[](1);
        considerationitems[0] = ISeaport.ConsiderationItem({
            itemType: considerationitemtype, //done
            token:  ZERO_ADDRESS, //done
            identifierOrCriteria:0, //done
            startAmount: 1000000000000000000, //done
            endAmount: 1000000000000000000 , //done
            recipient: payable(0x0000a26b00c1F0DF003000390027140000fAa719) //????????????? polygon fee collector?????
        });

    ISeaport.OrderParameters memory orderparams = ISeaport.OrderParameters ({
    offerer: address(this), // done
    zone: 0x0000000000000000000000000000000000000000, //done
    offer: offeritems,
    consideration: considerationitems, 
    orderType: ordertype1,
    startTime: block.timestamp,
    endTime: block.timestamp + 1 weeks, 
    zoneHash: 0x0000000000000000000000000000000000000000000000000000000000000000, //done
    salt: 5, //done ????????????????????? not sure if there should be a huge number
    conduitKey: 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000, //// ????
    totalOriginalConsiderationItems: 0 //// ??              
});

    ISeaport.Order[] memory realorder = new ISeaport.Order[](1);
    realorder[0] = ISeaport.Order({
        parameters: orderparams,
        signature: "0x"
    });
    seaport.validate(realorder);


    }



}

//     function validate(Order[] calldata orders)
//         external
//         returns (bool validated);


//     struct Order {
//     OrderParameters parameters;
//     bytes signature;
// }


// struct OrderParameters {
//     address offerer; // 0x00
//     address zone; // 0x20
//     OfferItem[] offer; // 0x40
//     ConsiderationItem[] consideration; // 0x60
//     OrderType orderType; // 0x80
//     uint256 startTime; // 0xa0
//     uint256 endTime; // 0xc0
//     bytes32 zoneHash; // 0xe0
//     uint256 salt; // 0x100
//     bytes32 conduitKey; // 0x120
//     uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
// }

// struct ConsiderationItem {
    //ItemType itemType;
    // address token;
    // uint256 identifierOrCriteria;
    // uint256 startAmount;
    // uint256 endAmount;
    // address payable recipient;
// }

// struct OfferItem {
    // ItemType itemType;
    // address token;
    // uint256 identifierOrCriteria;
    // uint256 startAmount;
    // uint256 endAmount;
// }


// enum OrderType {
//     // 0: no partial fills, anyone can execute
//     FULL_OPEN,

//     // 1: partial fills supported, anyone can execute
//     PARTIAL_OPEN,

//     // 2: no partial fills, only offerer or zone can execute
//     FULL_RESTRICTED,

//     // 3: partial fills supported, only offerer or zone can execute
//     PARTIAL_RESTRICTED
// }

// enum ItemType {
//     // 0: ETH on mainnet, MATIC on polygon, etc.
//     NATIVE,

//     // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
//     ERC20,

//     // 2: ERC721 items
//     ERC721,

//     // 3: ERC1155 items
//     ERC1155,

//     // 4: ERC721 items where a number of tokenIds are supported
//     ERC721_WITH_CRITERIA,

//     // 5: ERC1155 items where a number of ids are supported
//     ERC1155_WITH_CRITERIA
// }

pragma solidity 0.8.17;

interface ISeaport {

    function validate(Order[] calldata orders)
        external
        returns (bool validated);


    struct Order {
    OrderParameters parameters;
    bytes signature;
}


struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}


enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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