// SPDX-License-Identifier: UNLICEN

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * Design a contract 

 * Create a function

 * Specify Auction Time & minimum Bid Amount & item Description

 * After each auction the highest should be shown

 * When the Auction ends the winner should get his item and the money to seller

 * If the auction ends without any bids, the seller should be able to retrieve the item.
 */

/**
   *function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

  */ 

contract Auction  {
    struct Details {
        address owner;
        uint duration;
        uint amount;
        string description;
        uint tokenId;
        address tokenAddress;
        address previousBidder;
        uint previousAmount;
    }

    // auction ID => item details
    mapping(uint => Details) itemDetails; 
    uint auctionId = 1 ;

    event PutToAuction(
        address _user,
        address _tokenAddress,
        uint _tokenId,
        uint _duration,
        uint _amount,
        string _description,
        uint _auctionID
    );

    event BidAdd(
        address _bidder,
        uint _amount ,
        uint _tokenId
    );

    event BidClaim(
        address _bidder,
        address owner,
        address _tokenAddress,
        uint _tokenId,
        uint _bidAmount,
        uint _auctionId
    );

    event AuctionRevoked(
        address owner,
        address _tokenAddress,
        uint _tokenId,
        uint _auctionId
    );

    function putOnAuction(
        address _tokenAddress,
        uint _tokenId,
        uint _duration,
        uint _amount,
        string calldata _description
    ) external {
        address user = msg.sender;
        address owner = IERC721(_tokenAddress).ownerOf(_tokenId);
        //check owner
        require(user == owner, "NOT OWNER");

        // check approved
        address operator = IERC721(_tokenAddress).getApproved(_tokenId);
        require(address(this) == operator, "NOT APPROVED");

        // moving NFT from user to this contract
        //external call
        IERC721(_tokenAddress).safeTransferFrom(user, address(this), _tokenId);

        require(_duration > 0 && _amount > 0, "CANNOT BE ZERO");

        itemDetails[auctionId] = Details(
            user,
            block.timestamp + _duration,
            _amount,
            _description,
            _tokenId,
            _tokenAddress,
            address(0),
            0); 

        emit PutToAuction(
            user,
            _tokenAddress,
            _tokenId,
            _duration,
            _amount,
            _description,
            auctionId
        );
        auctionId ++;
    }

    function placeBid(uint _auctionId) external payable{
        /**
        Auction Exists
        valid Amount
        Amount greater than previous
        Owner can't bid
         */
        Details storage auction = itemDetails[_auctionId];

        require(block.timestamp < auction.duration, "NOT EXISTS");

        require(msg.value > auction.amount, "AMOUNT ERROR") ;

        require(msg.value > auction.previousAmount, "VALUE ERROR") ;

        require(auction.owner != msg.sender, " CANT'T BID ");

        (bool sent, ) = payable(auction.previousBidder).call{value: auction.previousAmount}("");
        require(sent, "Failed to send Ether");

            
            auction.previousAmount = msg.value;

            auction.previousBidder = msg.sender;       

            emit BidAdd(
                msg.sender,
                msg.value,
                _auctionId
            );

    }

    function claimBid(uint _auctionId) external {
        /**
        auction exists
        auction ended
        msg.sender == lastBidder || owner
        owner != address(0)
        transfer money to owner
        transfer item to lastBidder
         */
        
        Details storage auction = itemDetails[_auctionId];
        require(auction.duration != 0 && block.timestamp > auction.duration, "NOT EXISTS");
        
        require(msg.sender == auction.previousBidder || msg.sender == auction.owner, "INVALID CALL");

        require(auction.owner != address(0), "ZERO ADDRESS");

        (bool sent, ) = payable(auction.owner).call{value : auction.previousAmount}("");
        require(sent,"TRANSFER FAILED");

        IERC721(auction.tokenAddress).transferFrom(address(this), auction.previousBidder, auction.tokenId);


        emit BidClaim(auction.previousBidder, auction.owner, auction.tokenAddress, auction.tokenId, auction.previousAmount, _auctionId);
        delete itemDetails[_auctionId];
    }

    function revokeAuction(uint _auctionId) external {
        /**
        auction ended
        auction Exists
        no bid placed
        only owner call
        transfer back item
         */
        Details storage auction = itemDetails[_auctionId];
        
        //exists and not ended check
        require(auction.duration != 0 && block.timestamp > auction.duration, "NOT EXISTS");

        //no bid placed
        require(auction.previousAmount == 0, "ALREADY BIDDED");

        require(msg.sender == auction.owner, "NOT OWNER");

        IERC721(auction.tokenAddress).transferFrom(address(this), auction.owner, auction.tokenId);

        emit AuctionRevoked(auction.owner, auction.tokenAddress, auction.tokenId, _auctionId);

        
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        // Add your implementation here
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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