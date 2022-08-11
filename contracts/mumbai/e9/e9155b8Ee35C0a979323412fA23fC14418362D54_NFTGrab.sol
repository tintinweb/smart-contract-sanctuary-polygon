// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTGrab is IERC721Receiver {
  
    // Contract events
    event AuctionCreated(uint256 indexed auctionId);
    event AuctionCompleted(uint256 indexed auctionId);
    event AuctionCanceled(uint256 indexed auctionId);
    event AuctionBid(uint256 indexed auctionId);

    /** 
    * @dev Auction Statuses  
    *
    * (0) Listed - Created but no bids placed. Can be canceled.
    * (1) Active - Auction has started with at least one bid being placed.
    * (2) Complete - Auction has ended and winnner has widthdraw the token.
    * (3) Canceled - Canceled and token returned to seller. 
    */ 
    enum Status {
        Listed,
        Active,
        Complete,
        Canceled
    }

    /**
    * @dev Structure defining the properties of each auction
    *
    * status - Auction status
    * nftContract - ERC721 Interface for NFT contract address
    * seller - Address of token seller
    * bidder - Address of latest bidder
    * tokenId - NFT identifier for token
    * auctionId - Identifier for auction details
    * startBlock - Block number when auction began
    * endBlock - Block number when auciton will end
    * blockIncrease - Number of blocks added with each bid
    * bidPrice - Value required to place a bid
    * bidTotal - Value of all bids placed
    */ 
    struct Auction {
        Status status;
        IERC721 nftContract;
        address seller;
        address bidder;
        uint256 tokenId;
        uint256 auctionId;
        uint256 startBlock;
        uint256 endBlock;
        uint256 blockIncrease; 
        uint256 bidPrice;
        uint256 bidTotal;
    }

    // Array of auction IDs
    uint256[] private auctionIds;

    // Mapping of auction ID to Auction details
    mapping (uint256 => Auction) private auctions;

    /**
    * @dev Implementation of the required {onERC721Received} function for contracts 
    * intended as recipients of ERC721 token transfers using {safeTransferFrom}. 
    *
    * Creates auction for the received token and returns required ERC721TokenReciever value. 
    *
    * TODO: Allow custom auction details to be passed through the calldata
    *
    * @param _from Address that previously owned the token
    * @param _tokenId NFT identifier of token being transfered
    * @return Expected magic value defined by ERC721TokenReciever spec
    */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) 
        external 
        returns (bytes4) 
    {
        _createAuction(msg.sender, _from, _tokenId);
        return this.onERC721Received.selector;
    }

    /**
    * @dev Accepts a new bid for an auction
    *
    * A successfull bid will add the caller as auction bidder and 
    * increase the auction's `endBlock` deadline. Auctions with no previous 
    * bidders will have `startBlock` and `status` values updated as well. 
    *
    * Emits an {AuctionBid} event
    *
    * Requirements
    * - `_auctionId` must correspond to valid auction
    * - Auction `seller` cannot place a bid
    * - Payment must meet minimum bid price
    * - Auction status must be Listed or Active
    * - Bid must be placed before auction's `endBlock` deadline
    *
    * @param _auctionId Identifier for auction listing
    */
    function bid(
        uint _auctionId
    )
        external
        auctionExists(_auctionId)    
        payable
    {
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "Auction seller cannot place bid.");
        require(msg.value >= auction.bidPrice, "Auction bid price not met.");
        require(
            auction.status == Status.Listed || auction.status == Status.Active, 
            "Auction status does not allow for bidding."
        );

        if (auction.status == Status.Active) {
            require(block.number <= auction.endBlock, "Auction bidding has ended.");
        } else {
            auction.status = Status.Active;
            auction.startBlock = block.number;
        }

        auction.bidder = msg.sender;
        auction.endBlock = block.number + auction.blockIncrease;
        auction.bidTotal += msg.value; 

        emit AuctionBid(_auctionId);
    }

    /**
    * @dev Cancel an auction and return the token to the seller.
    *
    * Emits an {AuctionCancelled} event
    *
    * Requirements
    * - `_auctionId` must correspond to valid auction
    * - Only `seller` can cancel the auction
    * - Only `status: Listed` auctions can be canceled
    *
    * @param _auctionId Identifier for auction listing
    */
    function cancelAuction(
        uint _auctionId
    ) 
        external 
        auctionExists(_auctionId) 
    {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller == msg.sender, "Auction can only be canceled by the seller.");
        require(auction.status == Status.Listed, "Auction status does not allow for canceling.");

        auction.nftContract.safeTransferFrom(
            address(this), 
            auction.seller, 
            auction.tokenId
        );

        auction.status = Status.Canceled;

        emit AuctionCanceled(_auctionId);
    }

    /**
    * @dev Transfer the auction token to the winning bidder
    *
    * Emits an {AuctionCompleted} event
    *
    * Requirements
    * - `_auctionId` must correspond to valid auction
    * - Only `status: Active` auctions be widthdrawn from
    * - Can only be widthdrawn after auction's `endBlock` deadline
    * - Only `bidder` can widthdraw the token
    * 
    * @param _auctionId Identifier for auction listing
    */
    function widthdrawToken(
        uint _auctionId
    ) 
        external 
        auctionExists(_auctionId) 
    {
        Auction storage auction = auctions[_auctionId];
        require(auction.status == Status.Active, "Auction status does not allow for token widthdrawal.");
        require(block.number > auction.endBlock, "Auction bidding has not ended.");
        require(msg.sender == auction.bidder, "Token can only be widthdrawn by the winning bidder.");

        auction.nftContract.safeTransferFrom(
            address(this), 
            auction.bidder, 
            auction.tokenId
        );

        auction.status = Status.Complete;

        emit AuctionCompleted(_auctionId);
    }

    /**
    * @dev Transfer the auction bids to the seller
    *
    * Requirements
    * - `_auctionId` must correspond to valid auction
    * - Auction `status` must be Active or Complete
    * - Can only be widthdrawn after auction's `endBlock` deadline
    * - Only `seller` can widthdraw bids
    * 
    * @param _auctionId Identifier for auction listing
    */
    function widthdrawBids(
        uint _auctionId
    ) 
        external 
        auctionExists(_auctionId) 
    {
        Auction storage auction = auctions[_auctionId];
        require(
            auction.status == Status.Active || auction.status == Status.Complete, 
            "Auction status does not allow for bid widthdrawal."
        );
        require(block.number > auction.endBlock, "Auction bidding has not ended.");
        require(msg.sender == auction.seller, "Bids can only be widthdrawn by the seller.");

        payable(auction.seller).transfer(auction.bidTotal);
        auction.bidTotal = 0;
    }

    /**
    * @dev Return auction details for input auction ID.
    *
    * Requirements
    * - `_auctionId` must correspond to valid auction
    *
    * @param _auctionId Identifier for auction listing
    * @return Auction structure containing the auction's details
    */
    function getAuction(
        uint _auctionId
    ) 
        external 
        view 
        auctionExists(_auctionId) 
        returns (Auction memory) 
    {
        return auctions[_auctionId];
    }

    /**
    * @dev Return details for all auctions
    *
    * @return Array of Auction structures containing each auction's details
    */
    function getAuctions() 
        external
        view 
        returns (Auction[] memory) 
    {
        return _getAuctions(auctionIds);
    }

    /**
    * @dev Return details for all auctions from specific seller
    *
    * @return Array of Auction structures containing each auction's details
    */
    function getAuctionsBySeller(
        address _seller
    ) 
        external 
        view 
        returns (Auction[] memory) 
    {
        uint256[] memory sellerAuctionIds;
        uint count = 0;
        for (uint i = 0; i < auctionIds.length; i++) {
            if (auctions[auctionIds[i]].seller == _seller) {
                sellerAuctionIds[count] = auctionIds[i];
                count++;
            }     
        }
        return _getAuctions(sellerAuctionIds);
    }

    /**
    * @dev Return array of auction IDs
    *
    * @return Array of auction IDs
    */
    function getAuctionIds() external view returns (uint256[] memory) {
        return auctionIds;
    }

    /**
    * @dev Modifier to check if '_auctionID' references a created auction
    */
    modifier auctionExists(uint256 _auctionId) {
        require(auctions[_auctionId].seller != address(0), "Auction ID does not reference valid auction");
        _;
    }

    /**
    * @dev Return auction data for array of IDs
    *
    *
    * @param _auctionIds Array of uint256 IDs
     */
     function _getAuctions(
        uint256[] memory _auctionIds
     )
        internal
        view
        returns (Auction[] memory)
    {
        Auction[] memory _auctions = new Auction[](_auctionIds.length);
        for (uint i = 0; i < _auctionIds.length; i++) {
            _auctions[i] = auctions[_auctionIds[i]];
        }
        return _auctions;
    }
    

    /**
    * @dev Create a new auction for a token
    *
    * Emits an {AuctionCreated} event
    *
    * @param _nftAddress Address of the NFT contract defining the token
    * @param _seller Address of seller of the token
    * @param _tokenId NFT identifier of the token
    */
    function _createAuction(
        address _nftAddress, 
        address _seller, 
        uint _tokenId
    ) 
        internal
    {
        uint auctionId = auctionIds.length;

        Auction memory newAuction = Auction({
            status: Status.Listed,
            nftContract: IERC721(_nftAddress),
            seller: _seller,
            bidder: address(0),
            tokenId: _tokenId,
            auctionId: auctionId,
            bidPrice: 5 ether,
            startBlock: 0,
            endBlock: 0,
            blockIncrease: 100,
            bidTotal: 0
        });

        auctionIds.push(auctionId);
        auctions[auctionId] = newAuction;

        emit AuctionCreated(auctionId);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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