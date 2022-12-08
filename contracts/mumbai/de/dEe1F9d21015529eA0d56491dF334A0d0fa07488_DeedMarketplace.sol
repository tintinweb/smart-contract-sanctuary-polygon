/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;



// File: @openzeppelin/contracts/token/ERC20/IERC20.sol




library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}






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

abstract contract ERC165 is IERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(type(IERC165).interfaceId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
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

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IDeed is IERC721 {

    function getPropertyInfo(uint256 tokenId) external view returns (
        address,
        string memory,
        string memory,
        string memory,
        string memory
    );

    function getBedsBathsUnits(uint256 tokenId) external view returns (uint8, uint8, uint8);

    function getPropertyAddress(uint256 tokenId) external view returns (
        string memory,
        string memory,
        string memory,
        string memory
    );


}



contract DeedMarketplace  {
    using SafeMath for uint256;

   
   IDeed public deed;
    

    uint256 public count = 0;
    //Keeps track of the number of items sold on the marketplace
    uint256 public itemsSold = 0;
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 listingFee = 0.01 ether;
    
    

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 listId;
        uint256 tokenId;
        address seller;
        uint256 minimumPriceIncrement;
        uint256 currentPrice;
        uint256 endTime;
        address currentWinner;
        bool auction;
        bool currentlyListed;
    }

    event BulkListing(uint256);
    event TimeReset(uint256, uint256);

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed listId,
        address seller,
        uint256 minimumPriceIncrement,
        uint256 initialPrice,
        uint256 endTime,
        bool auction,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;
    mapping(uint256 => ListedToken) public listIds;
    uint256[] public activeList;
    
    constructor(address _deed) {
        owner = payable(msg.sender);
        deed = IDeed(_deed);
        
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getTotalListed() public view returns (uint256) {
        return count - itemsSold;
    }

    
    
    function createListedToken(uint256 tokenId, uint256 _initialPrice, uint256 _increment, uint256 _endTime) external payable {
        require(deed.ownerOf(tokenId) == msg.sender, "Not the token owner or invalid tokenId");
        require(_initialPrice >= 0, "Make sure the price isn't negative");
        require(msg.value >= listingFee, "Insufficient amount sent for listing fee");
        

        uint256 listId = count + 1;
        uint256 endTime;
        bool auction = false;

        if(_endTime > 0) {
            
            endTime = block.timestamp + _endTime;
            auction = true;
        }

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        listIds[listId] = ListedToken(
            listId,
            tokenId,
            msg.sender,
            _increment,
            _initialPrice,
            endTime,
            msg.sender,
            auction,
            true
        );

        deed.transferFrom(msg.sender, address(this), tokenId);
        count++;
        activeList.push(listId);
        payable(owner).transfer(listingFee);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            listId,
            msg.sender,
            _increment,
            _initialPrice,
            endTime,
            auction,
            true
        );
    }

    function bulkListingCreate(uint16[] calldata _tokenIds, uint256[] calldata _initialPrices, uint256[] calldata _increments, uint256[] calldata _endTimes) external payable {
        require(msg.value >= listingFee * _tokenIds.length, "Not authorized to list");
        uint256 endTime;
        uint256 listId;
        bool auction;
        uint16 tokenId;
        
        

        for(uint8 i; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            require(deed.ownerOf(tokenId) == msg.sender, "Not the token owner or invalid tokenId");
            

            listId = count + 1;

            auction = false;
            

        if(_endTimes[i] > 0) {
            
            endTime = block.timestamp + _endTimes[i];
            auction = true;
        }

        listIds[listId] = ListedToken(
            listId,
            _tokenIds[i],
            msg.sender,
            _increments[i],
            _initialPrices[i],
            endTime,
            msg.sender,
            auction,
            true
        );

        deed.transferFrom(msg.sender, address(this), tokenId);
        count++;
        activeList.push(listId);
        

        }
        payable(owner).transfer(listingFee * _tokenIds.length);

        emit BulkListing(_tokenIds.length);

          
    }

    function getActiveListIds() public view returns (uint256[] memory) {
        uint256 nftCount = getTotalListed();
        uint256[] memory tokens = new uint256[](nftCount);
        uint256 currentIndex = 0;

        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] != 0){
                tokens[currentIndex] = activeList[i];
                currentIndex++;
            }
        }
        return tokens;
    }
    
    

    function getEndTime(uint256 listId) public view returns (uint256) {
        return listIds[listId].endTime;
    }

    function getCurrentWinner(uint256 listId) public view returns (address) {
        return listIds[listId].currentWinner;
    }

    function isAuction(uint256 listId) public view returns (bool) {
        return listIds[listId].auction;
    }

    function getMinIncrement(uint256 listId) public view returns (uint256) {
        return listIds[listId].minimumPriceIncrement;
    }
 

    function getTrueTokenID(uint256 listId) public view returns (uint256){
        return listIds[listId].tokenId;
    }

    

   function getPriceOfItem(uint256 listId) public view returns (uint){
        uint256 price = listIds[listId].currentPrice;

        return price;

   }

   function propertyInfo(uint256 listId) public view returns (
       address,
         string memory,
        string memory,
        string memory,
        string memory
   ) {
       return deed.getPropertyInfo(getTrueTokenID(listId));

   }

   function fullPropertyAddress(uint256 listId) public view returns (
       string memory,
       string memory,
       string memory,
       string memory
   ) {
       return deed.getPropertyAddress(getTrueTokenID(listId));
   }

   function unitInfo(uint256 listId) public view returns (uint8, uint8, uint8) {
       return deed.getBedsBathsUnits(getTrueTokenID(listId));
   }

   

   function getMinimumBid(uint256 listId) public view returns (uint) {
       uint256 price = getPriceOfItem(listId);
       uint256 minIncrement = listIds[listId].minimumPriceIncrement;

        return price + minIncrement;
   }





    function bid(uint256 listId, uint256 value) external {
        //Get current price of ETH in USD and the token Price in ETH
        uint256 price = getMinimumBid(listId);
        
        if(listIds[listId].auction) {
            
            //Minimum accepted bid is the current price + minimum increment in Ammo
            uint256 minimumAcceptedBid = price;
            require(value >= minimumAcceptedBid && block.timestamp < listIds[listId].endTime, "Insufficient bid amount or expired auction");

            
            listIds[listId].currentPrice = value;  
            listIds[listId].currentWinner = msg.sender;
        }
        else {
            require(value >= price, "Please submit the asking price in order to complete the purchase");
        

        //update the details of the token
        listIds[listId].currentlyListed = false;
        address seller = listIds[listId].seller;
        itemsSold++;
        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] == listId) {
                delete activeList[i];
            }
        }
        


        //Actually transfer the token to the new owner
        deed.transferFrom(address(this), msg.sender, getTrueTokenID(listId));
        //approve the marketplace to sell NFTs on your behalf
        //nft.approve(address(this), tokenId);

        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(value);
    }


    }

    function finalize(uint256 listId) external payable {
        uint256 price = getPriceOfItem(listId);
        address winner = listIds[listId].currentWinner;
        
        require(block.timestamp > listIds[listId].endTime, "Auction has not ended");
        require(msg.sender == listIds[listId].currentWinner);
        require(msg.value >= price, "Insufficient balance");
        listIds[listId].currentlyListed = false;

        address seller = listIds[listId].seller;
        itemsSold++;

        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] == listId) {
                delete activeList[i];
            }
        }

    
        //Actually transfer the token to the new owner
        deed.transferFrom(address(this), winner, getTrueTokenID(listId));
        //approve the marketplace to sell NFTs on your behalf
        //approve(address(this), tokenId);

        payable(seller).transfer(price);


    }

    function resetTime(uint256 listId, uint256 _newEndTime) external {
        require(msg.sender == owner, "Not authorized to reset auction time");
        uint256 newEndTime = block.timestamp + _newEndTime;
        listIds[listId].endTime = newEndTime;

        emit TimeReset(listId, newEndTime);

    }

    function setListingFee(uint256 _fee) external {
        require(msg.sender == owner, "Not authorized");
        listingFee = _fee;
    }

    

    function emergencyNFTWithdraw(uint256[] calldata _listIds) external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        
        for(uint8 i = 0; i < _listIds.length; i++) {
            deed.transferFrom(address(this), msg.sender, getTrueTokenID(_listIds[i]));
            listIds[_listIds[i]].currentlyListed = false;
            itemsSold++;
            for(uint8 j = 0; j < activeList.length; j++) {
            if(activeList[j] == _listIds[i]) {
                delete activeList[j];
            }
        }
            


        }
    }

    //This is to remove the native currency of the network (e.g. ETH, BNB, MATIC, etc.)
    function emergencyWithdraw() public {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

     receive() external payable {}
    




    
            


    

    
}