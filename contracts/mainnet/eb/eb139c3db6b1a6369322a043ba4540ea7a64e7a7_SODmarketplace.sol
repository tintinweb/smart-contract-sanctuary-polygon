/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: contracts/Marketplace/Marketplace.sol

pragma solidity ^0.8.7;



//This is a Suns Of DeFi project for buying and selling SOD products and SOD partner Projects exclusively
contract SODmarketplace {

address sodMarket;
address owner;

    constructor(){
        sodMarket = payable(address(this));
        owner = msg.sender;
        
    }

     struct AuctionItem {
            uint256 id;
            address tokenAddress;
            uint256 tokenId;
            address payable seller;
            uint256 askingPrice;
            uint256 units;
            bool isSold;
            uint256 tokenType;
        }

    AuctionItem[] public itemsForSale;

       
    mapping(address => mapping(uint256 => bool))activeItems;
    mapping(address => bool)SODProject;

    event multiItemAdded(uint256 id, uint256 tokenId, address tokenAddress,address seller, uint amount ,uint256 askingPrice, uint256 date);
    event multiItemSold(uint256 id,address seller, address buyer, uint256 amount, uint256 askingPrice, uint256 date);
    event multiItemRemoved(uint256 id, address seller, uint256 amount, uint256 askingPrice, uint256 date);
    event singleItemAdded(uint256 id, uint256 tokenId, address tokenAddress,address seller, uint amount ,uint256 askingPrice, uint256 date);
    event singleItemSold(uint256 id,address seller, address buyer, uint256 amount, uint256 askingPrice, uint256 date);
    event singleItemRemoved(uint256 id, address seller, uint256 amount, uint256 askingPrice, uint256 date);

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId)
            {
                IERC1155 tokenContract = IERC1155(tokenAddress);
                require(tokenContract.balanceOf(msg.sender, tokenId) > 0, "You dont own the specific NFT(s)"); //check if caller is owner of this token
                _;
            } 
    modifier onlyOwner
    {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }                     
    modifier HasTransferApproval(address tokenAddress)
            {
                IERC1155 tokenContract = IERC1155(tokenAddress);
                require(tokenContract.isApprovedForAll(msg.sender, address(this)) == true, "You need to grant Market approval first"); //check if callers given contract approvals
                _;
            }
       
    modifier ItemExist(uint256 id)
            {
                require(id < itemsForSale.length && itemsForSale[id].id == id,"could not find id");
                _;
            }
       
    modifier IsForSale(uint256 id)
            {
                require(itemsForSale[id].isSold == false,"id already sold");
                _;
            }
    modifier isSODProject(address contractAddress)
    {
        require(SODProject[contractAddress] == true, "Only Suns Of DeFi projects can be placed on SOD Market");
        _;
    } 
    modifier onlyNFTowner(address nftContract, uint256 tokenId)
            {
                IERC721 nftContract = IERC721(nftContract);
                require(nftContract.ownerOf(tokenId) == msg.sender,  "You dont own this NFT");
                _;
            } 
    modifier canTransferNFT(address nftContract, uint256 tokenId)
            {
                IERC721 nftContract = IERC721(nftContract);
                require(nftContract.getApproved(tokenId) == address(this), "You need to grant Market approval first"); 
                _;
            }        

    //ERC1155
    function add1155ToMarket(uint256 tokenId, address tokenAddress, uint256 units, uint256 askingPrice) OnlyItemOwner(tokenAddress,tokenId) HasTransferApproval(tokenAddress) isSODProject(tokenAddress) external returns(uint256){
            require(activeItems[tokenAddress][tokenId] == false,"Item up for sale already");
            uint256 newItemId = itemsForSale.length;
           
            itemsForSale.push(AuctionItem(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice, units, false, 1155));
           
            activeItems[tokenAddress][tokenId] = true; //items now up for sale
                      
            assert(itemsForSale[newItemId].id == newItemId);
            emit multiItemAdded(newItemId, tokenId, tokenAddress, msg.sender, units ,askingPrice, block.timestamp);
           
            return newItemId;
           
        }
    //ERC721
    function add721toMarket(uint256 tokenId, address tokenAddress, uint256 askingPrice) onlyNFTowner(tokenAddress, tokenId) canTransferNFT(tokenAddress, tokenId) isSODProject(tokenAddress) external returns(uint256){
          require(activeItems[tokenAddress][tokenId] == false,"Item up for sale already");
          uint256 newItemId = itemsForSale.length; 

          itemsForSale.push(AuctionItem(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice, 1, false, 721));
           
          activeItems[tokenAddress][tokenId] = true; //items now up for sale
                      
          assert(itemsForSale[newItemId].id == newItemId);
          emit singleItemAdded(newItemId, tokenId, tokenAddress, msg.sender, 1 ,askingPrice, block.timestamp);
           
          return newItemId;
    }     
    //ERC1155
    function buyERC1155Item(uint256 id) payable external ItemExist(id) IsForSale(id) {
            require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent");
            require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead!");
           
            itemsForSale[id].isSold = true; //items been marked as sold
            activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; //
           
            IERC1155(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, itemsForSale[id].units, '');
            
            uint256 marketfee = msg.value * 2 / 100; 
           

            sodMarket.call{value: marketfee};

            itemsForSale[id].seller.transfer(msg.value - marketfee); //send funds to seller
           
            emit multiItemSold(id, itemsForSale[id].seller, msg.sender, itemsForSale[id].units ,itemsForSale[id].askingPrice, block.timestamp);
           
        }
     function buyERC721Item(uint256 id) payable external ItemExist(id) IsForSale(id) {
            require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent");
            require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead!");
           
            itemsForSale[id].isSold = true; //items been marked as sold
            activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; //
        
            IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, '');

            uint256 marketfee = msg.value * 2 / 100; 
            sodMarket.call{value: marketfee};

            itemsForSale[id].seller.transfer(msg.value - marketfee); //send funds to seller
           
            emit singleItemSold(id, itemsForSale[id].seller, msg.sender, 1, itemsForSale[id].askingPrice, block.timestamp);
           
        }       


    function removeItem(uint256 id) public ItemExist(id) IsForSale(id) returns(bool success){
             require(msg.sender == itemsForSale[id].seller);
           
            if(itemsForSale[id].tokenType == 721){
                 activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
                  delete itemsForSale[id];
             
              emit singleItemRemoved(id, msg.sender, itemsForSale[id].units , itemsForSale[id].askingPrice, block.timestamp);
            }else if(itemsForSale[id].tokenType == 1155){
                 activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
             delete itemsForSale[id];
             
             emit multiItemRemoved(id, msg.sender, itemsForSale[id].units , itemsForSale[id].askingPrice, block.timestamp);
            }
            
           
             return success;
        } 

 function withdraw() public payable onlyOwner {
    // This will pay partner 50% of every withdraw.
    // =============================================================================
    (bool hs, ) = payable(0x625Cd0169A8B36E138D84a00BCa1d9d1c8b45f51).call{value: address(this).balance * 50 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 50% of the contract balance.
    // =============================================================================
    (bool os, ) = payable(owner).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }           

  function addProject(address sodContract, bool _status) public onlyOwner returns(bool){
      SODProject[sodContract] = _status;
      return  _status;
  }

  function marketBalance() onlyOwner public view returns(uint256 balance){
      return address(this).balance;
  }

  function approvedProjects(address sodContract) public view returns(bool){
      return SODProject[sodContract];
  }

}