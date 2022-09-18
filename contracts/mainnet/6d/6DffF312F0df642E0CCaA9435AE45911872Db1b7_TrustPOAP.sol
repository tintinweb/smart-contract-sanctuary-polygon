pragma solidity ^0.8.13;

import "./IPoap.sol";
import "./IGetterLogic.sol";

contract TrustPOAP {
    address humanboundToken;
    address poap;

    mapping(uint256 => string) reviewURIbyReviewId;
    mapping(uint256 => uint256[]) reviewersByEventId;

    constructor(address _humanboundToken, address _poap) {
        humanboundToken = _humanboundToken;
        poap = _poap;
    }

    modifier onlyUniqueHuman(uint256 hbtId) {
        require(IGetterLogic(humanboundToken).balanceOf(msg.sender) > 0, "caller is not human");
        require(IGetterLogic(humanboundToken).ownerOf(hbtId) == msg.sender, "caller is not holder of this hbt");
        _;
    }

    modifier onlyUnwrittenReview(uint256 eventId, uint256 hbtId, uint256 tokenId) {
        // uint256 eventId = IPoap(poap).tokenEvent(tokenId);
        uint256 reviewId = calculateReviewId(hbtId, eventId);

        require(bytes(reviewURIbyReviewId[reviewId]).length > 0);
        _;
    }

    modifier onlyAttendee(uint256 tokenId) {
        require(IGetterLogic(poap).ownerOf(tokenId) == msg.sender);
        _;
    }

    function submitReview(uint256 eventId, uint256 hbtId, uint256 poapTokenId, string calldata uri) public 
        onlyUniqueHuman(hbtId)
        // onlyAttendee(poapTokenId) 
        onlyUnwrittenReview(eventId, hbtId, poapTokenId)
    {
        // uint256 eventId = IPoap(poap).tokenEvent(poapTokenId);
        uint256 reviewId = calculateReviewId(hbtId, eventId);

        reviewURIbyReviewId[reviewId] = uri;
    }

    function getEventReviewURIs(uint256 eventId) public view returns(string[] memory reviews) {
        uint256[] memory reviewers = reviewersByEventId[eventId];

        reviews = new string[](reviewers.length);
        for (uint256 i = 0; i < reviewers.length; i++) {
            uint256 reviewer = reviewers[i];
            uint256 reviewId = calculateReviewId(reviewer, eventId);
            reviews[i] = reviewURIbyReviewId[reviewId];
        }
    }

    function calculateReviewId(uint256 hbt, uint256 eventId) internal pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(hbt, eventId)));
    }
}

pragma solidity ^0.8.13;

interface IPoap {
    event EventToken(uint256 eventId, uint256 tokenId);

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory);

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Gets the event id for a token
     * @return string representing the token symbol
     */
    function tokenEvent(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return tokenId token ID at the given index of the tokens list owned by the requested address
     * @return eventId event ID for the token at the given index of the tokens owned by the address
     */
    function tokenDetailsOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId, uint256 eventId);

    /**
     * @dev Gets the token uri
     * @return string representing the token uri
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(uint256 eventId, address[] memory to)
    external returns (bool);

    /**
     * @dev Function to mint tokens
     * @param eventIds EventIds to assing to user
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(uint256[] memory eventIds, address to)
    external returns (bool);

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGetterLogic {
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external returns (bool);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * Requirements:
     *
     * - Must be modified with `public _internal`.
     */
    function _exists(uint256 tokenId) external returns (bool);

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - Must be modified with `public _internal`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) external returns (bool);
}