/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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



//This is a Suns Of DeFi: Wallet Monsters LaunchPad

contract WalletMonstersLaunchPad {

address LaunchPad; //Launchpad address
address owner; //Owner Address
address burn; //Tossed Keys Burner Address
address sodGuard; //Address Guard
address public WMTP; //WMTP contract
address public LaunchPadTokens; //LPTs contract
address public Wallebytes; // $WALY contract
string public name;
string public symbol;

uint256 public walyCost; //LP WALY buy cost



    constructor(){
        LaunchPad = payable(address(this));
        owner = msg.sender;

        name = "Wallet Monsters Launchpad";
        symbol = "WMLP";

        burn = 0x0C2dCb65b5EB0dEe082b1B7a6F458E7cB210e321; //No Keys, tossed them - burn address - Hard coded
        sodGuard = 0xfcbD40e2FDA1b292D5a15f9a2c85E94b393a5023; //Rewards holder set 
    }

     struct AuctionItem {
            uint256 id;
            address tokenAddress;
            uint256 tokenId;
            address payable seller;
            uint256 askingPrice;
            uint256 units;
            bool isSold;
            bool useLPT; //price in native token or LPTs
            uint256 tokenType; //721 or 1155
        }

    AuctionItem[] public itemsForSale;

       
    mapping(address => mapping(uint256 => bool))activeItems; //Items on Launchpad
    mapping(address => bool)LaunchPadItem; //Approve contracts that can add items to LP
    mapping(address => bool) public tokenApproved; //approved LPT
    mapping(address => uint256) public LPlevel;

    event multiItemAdded(uint256 id, uint256 tokenId, address tokenAddress,address seller, uint amount ,uint256 askingPrice, uint256 date);
    event multiItemSold(uint256 id,  uint256 tokenId, address tokenAddress, address buyer, uint256 amount, uint256 askingPrice, uint256 date, bool LPTBuy);
    event multiItemRemoved(uint256 id,  uint256 tokenId, address tokenAddress, uint256 amount, uint256 askingPrice, uint256 date);
    event singleItemAdded(uint256 id, uint256 tokenId, address tokenAddress,address seller, uint256 askingPrice, uint256 date);
    event singleItemSold(uint256 id,  uint256 tokenId, address tokenAddress, address buyer, uint256 askingPrice, uint256 date, bool LPTBuy);
    event singleItemRemoved(uint256 id, uint256 tokenId, address tokenAddress, uint256 askingPrice, uint256 date);
    event LaunchPadTokenReward(address LPToken, uint256 amount, address sender, address recipient, uint256 date);
    event walySold(address buyer, uint256 quantity, uint256 cost, uint256 date);
    
    //Ensures Launch Pad exclusive to WMTP holders
    modifier onlyWMTPholder()
            {
                IERC721 WMTPcontract = IERC721(WMTP);
                require(WMTPcontract.balanceOf(msg.sender) > 0,  "Only WMTP holders can purchase from Launch Pad");
                _;
            } 
    //Only ERC1155 owner check
    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId)
            {
                IERC1155 tokenContract = IERC1155(tokenAddress);
                require(tokenContract.balanceOf(msg.sender, tokenId) > 0, "You dont own the specific NFT(s)"); //check if caller is owner of this token
                _;
            } 
    //1155 approval check        
    modifier HasTransferApproval(address tokenAddress)
            {
                IERC1155 tokenContract = IERC1155(tokenAddress);
                require(tokenContract.isApprovedForAll(msg.sender, address(this)) == true, "You need to grant LaunchPad approval first"); //check if callers given contract approvals
                _;
            }
    //Only 721 Owner check        
    modifier onlyNFTowner(address nftContract, uint256 tokenId)
            {
                IERC721 nftContract = IERC721(nftContract);
                require(nftContract.ownerOf(tokenId) == msg.sender,  "You dont own this NFT");
                _;
            }            
    //721 token approval check        
    modifier canTransferNFT(address nftContract, uint256 tokenId)
            {
                IERC721 nftContract = IERC721(nftContract);
                require(nftContract.getApproved(tokenId) == address(this), "You need to grant Market approval first"); 
                _;
            }         

    modifier onlyOwner
    {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }         
    //check that offer is listed on LaunchPad
    modifier ItemExist(uint256 id)
            {
                require(id < itemsForSale.length && itemsForSale[id].id == id,"could not find id on LaunchPad");
                _;
            }
   //check offer has not be purchased    
    modifier IsForSale(uint256 id)
            {
                require(itemsForSale[id].isSold == false,"id already sold");
                _;
            }
    //check offer being made has been approved
    modifier isLaunchPadItem(address contractAddress)
    {
        require(LaunchPadItem[contractAddress] == true, "Only WMON contracts can be added");
        _;
    } 
 
    //LaunchPad offer listings functionality //
    
    //ERC1155 offers    
    function add1155ToLaunchPad(uint256 tokenId, address tokenAddress, uint256 units, uint256 askingPrice, bool useLTP) OnlyItemOwner(tokenAddress,tokenId) HasTransferApproval(tokenAddress) isLaunchPadItem(tokenAddress) onlyOwner external returns(uint256){
                        
            uint256 newItemId = itemsForSale.length;
           
            itemsForSale.push(AuctionItem(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice, units, false, useLTP, 1155));
           
            activeItems[tokenAddress][tokenId] = true; //items now up for sale
                      
            assert(itemsForSale[newItemId].id == newItemId);
            
            emit multiItemAdded(newItemId, tokenId, tokenAddress, msg.sender, units ,askingPrice, block.timestamp);

            return newItemId;      
     }

    //ERC721 offers
    function add721toLaunchPad(uint256 tokenId, address tokenAddress, uint256 askingPrice, bool useLPT) onlyNFTowner(tokenAddress, tokenId) canTransferNFT(tokenAddress, tokenId) isLaunchPadItem(tokenAddress) onlyOwner external returns(uint256){
          require(activeItems[tokenAddress][tokenId] == false,"Item up for sale already");
          
          uint256 newItemId = itemsForSale.length; 

          itemsForSale.push(AuctionItem(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice, 1, false, useLPT, 721));
           
          activeItems[tokenAddress][tokenId] = true; 
                      
          assert(itemsForSale[newItemId].id == newItemId);

          emit singleItemAdded(newItemId, tokenId, tokenAddress, msg.sender, askingPrice, block.timestamp);

          return newItemId;
    }     



    //WMTP Holders functions/Interactions//
    
    //Buy ERC1155 offers
    function buyERC1155Offer(uint256 id) payable external ItemExist(id) IsForSale(id) onlyWMTPholder() {
            //if offer is being listed in LPTs...
            if(itemsForSale[id].useLPT == true){
        
                require(tokenApproved[LaunchPadTokens] == true,"LaunchPad Token has not been approved");
                require(IERC20(LaunchPadTokens).balanceOf(msg.sender) >= itemsForSale[id].askingPrice, "Not enough LaunchPad Tokens");
                require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead!");

                itemsForSale[id].isSold = true;
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; 

                IERC20(LaunchPadTokens).transferFrom(msg.sender, burn, itemsForSale[id].askingPrice *(10**18)); //Forever locks LPT 

                IERC1155(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, itemsForSale[id].units, ''); //Transfer offerings to buyer

                emit multiItemSold(id, itemsForSale[id].tokenId, itemsForSale[id].tokenAddress, msg.sender, itemsForSale[id].units ,itemsForSale[id].askingPrice, block.timestamp, true);

            }else if(itemsForSale[id].useLPT == false){
                //if offer is being listed in Native Token...
                require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent");
                require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead!");
            
                itemsForSale[id].isSold = true;
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
          
                itemsForSale[id].seller.transfer(msg.value);

                LPlevel[msg.sender]+=1; //increase LPlevel for user
                
                //WMTP holders earn LaunchPad Tokens for each purchase from LaunchPad, LPTs can be used to purchase items
                

                uint256 guardBal = IERC20(LaunchPadTokens).balanceOf(sodGuard); //Get balance of remaining LPTs
               
                IERC721 trainerPass = IERC721(WMTP);
                uint256 wmtpBonus = trainerPass.balanceOf(msg.sender);

                uint256 LPTbonus = wmtpBonus * 100; //LPT rewards amount

                //if sodGuard can cover rewards, pay out if not continue.
                if(guardBal >= LPTbonus){
                    //reward rates
                    IERC20(LaunchPadTokens).transferFrom(sodGuard, msg.sender, LPTbonus *(10**18)); //transfer  LaunchPad Rewards
   
                    emit LaunchPadTokenReward(LaunchPadTokens, LPTbonus, sodGuard, msg.sender, block.timestamp);
                    
                }

                //Finally transfer LaunchPad offers
                IERC1155(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, itemsForSale[id].units, '');

                emit multiItemSold(id, itemsForSale[id].tokenId, itemsForSale[id].tokenAddress, msg.sender, itemsForSale[id].units ,itemsForSale[id].askingPrice, block.timestamp, false);
            } 
        }

   
    //Buy ERC721 offers
    function buyERC721Offer(uint256 id) payable external ItemExist(id) IsForSale(id) onlyWMTPholder()  {
            //if offer is being listed in LPTs...
            if(itemsForSale[id].useLPT == true){

                require(tokenApproved[LaunchPadTokens] == true,"LaunchPad Token has not been approved");
                require(IERC20(LaunchPadTokens).balanceOf(msg.sender) >= itemsForSale[id].askingPrice, "Not enough LaunchPad Tokens");
                require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead!");

                itemsForSale[id].isSold = true; 
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;

                IERC20(LaunchPadTokens).transferFrom(msg.sender, burn, itemsForSale[id].askingPrice *(10**18)); //for ever lock up

                IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, '');

                emit singleItemSold(id,itemsForSale[id].tokenId, itemsForSale[id].tokenAddress, msg.sender, itemsForSale[id].askingPrice, block.timestamp, true);

            }else if(itemsForSale[id].useLPT == false){
                //if offer is being listed in Native token...
                require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent");
                require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead!");

                itemsForSale[id].isSold = true; 
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; 

                LPlevel[msg.sender]+=1; //increase LPlevel for user

                itemsForSale[id].seller.transfer(msg.value);

                //WMTP holders earn LaunchPad Tokens for each purchase from LaunchPad, LPTs can be used to purchase items

                uint256 guardBal = IERC20(LaunchPadTokens).balanceOf(sodGuard); //Get balance of remaining LPTs
               
                IERC721 trainerPass = IERC721(WMTP);
                uint256 wmtpBonus = trainerPass.balanceOf(msg.sender);

                uint256 LPTbonus = wmtpBonus * 100; //LPT rewards amount

                 if(guardBal >= LPTbonus){
                        
                        IERC20(LaunchPadTokens).transferFrom(sodGuard, msg.sender, LPTbonus *(10**18)); //reward LPT
    
                        emit LaunchPadTokenReward(LaunchPadTokens, LPTbonus, sodGuard, msg.sender, block.timestamp);
                    }
                
                //finally transfer item
                IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, '');

                emit singleItemSold(id,itemsForSale[id].tokenId, itemsForSale[id].tokenAddress, msg.sender, itemsForSale[id].askingPrice, block.timestamp, false);

            }
            
        }       
    //Buy Discounted $WALY
    function discountedWALY() public payable onlyWMTPholder() {

        require(tokenApproved[Wallebytes] == true, "$WALY contract has not been approved");
        require(IERC20(Wallebytes).balanceOf(sodGuard) >= 100000, "Discounted $WALY reserves depleted");
        require(msg.value >= walyCost, "Not enough funds for tx");
        
        payable(sodGuard).transfer(msg.value);

        LPlevel[msg.sender]+=1; //increase LPlevel for user

        IERC20(Wallebytes).transferFrom(sodGuard, msg.sender, 100000 *(10**18));

        emit walySold(msg.sender, 100000, walyCost, block.timestamp);
    }

    //Remove Offer from LaunchPad
    function removeOffer(uint256 id) public ItemExist(id) IsForSale(id) onlyOwner returns(bool success){
             require(msg.sender == itemsForSale[id].seller);
           
            //if ERC721...
            if(itemsForSale[id].tokenType == 721){
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
                delete itemsForSale[id];
             
             //!
              emit singleItemRemoved(id, itemsForSale[id].tokenId, itemsForSale[id].tokenAddress, itemsForSale[id].askingPrice, block.timestamp);

            }else if(itemsForSale[id].tokenType == 1155){
                //if ERC1155...
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
                delete itemsForSale[id];
             
             emit multiItemRemoved(id, itemsForSale[id].tokenId, itemsForSale[id].tokenAddress, itemsForSale[id].units , itemsForSale[id].askingPrice, block.timestamp);

            }
            
            return success;
        } 

    
    //Owner Utility functions

   

        //Sets //

  //Wallet Monsters Trainer Pass
  function setWMTPcontract(address _WMTP) public onlyOwner returns(address){
            WMTP = _WMTP;

            return WMTP;
  }
  //LaunchPad Tokens
  function setLPTcontract(address _LPT) public onlyOwner returns(address){
            LaunchPadTokens = _LPT;

            return LaunchPadTokens;
  }
    //WalleBytes
  function setWALYcontract(address _WALY) public onlyOwner returns(address){
                Wallebytes = _WALY;

                return Wallebytes;
    }  
    //set discounted Price
    function setWALYprice(uint256 _cost) public onlyOwner returns(uint256){
            walyCost = _cost;

        return walyCost;
    } 

        //Set Approvals//

  //Interoperable contracts from Wallet Monster Metaverse      
  function addProject(address Contract, bool _status) public onlyOwner returns(bool){
      LaunchPadItem[Contract] = _status;
      
      return  _status;
  }

  //$WALY Tokens
  function approveWALY(bool _status) public onlyOwner returns(bool){
            tokenApproved[Wallebytes] = _status;            

            return  tokenApproved[Wallebytes];
  } 

  //LaunchPad Tokens 
  function approveLPT(bool _status) public onlyOwner returns(bool){
            tokenApproved[LaunchPadTokens] = _status;

            return tokenApproved[LaunchPadTokens];
  }

  //check approvals

  //check if Launchpad items contract has been approved  
  function approvedProjects(address sodContract) public view returns(bool){
      return LaunchPadItem[sodContract];
  }
    //check if tokens been approved
   function approvedTokens(address _Contract) public view returns(bool){
      return tokenApproved[_Contract];
  }



  //Happenstance withdrawl is needed, (donations etc no tokens are transferred or held within contract

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

  //LP Level
  function launchpadLevel(address _trainer) public view returns(uint256){
      return LPlevel[_trainer];
  }

  //items listed on launchPad
  function LaunchPadListingCount() public view returns(uint256){
      return itemsForSale.length;
  }

  //LaunchPad Balances  
function launchPadBalance() onlyOwner public view returns(uint256 balance){
      return address(this).balance;
  }   


//Suns Of DeFi ~ IBN5X ~ Prof. Kalito ~ Suns Of DeFi
}