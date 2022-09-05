/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

//Neolithic DeFi Instruments Developed by The Suns Of DeFi [TruTrade] 2022

//SOD: IBN5X | Pro. Kalito

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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


pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.7;

contract truTradeNFT {

    address public owner;
    address public TruTrader;
    uint256 public tradingFee;
    uint256 public cancelFee;
    uint256 public tradeId;
    bool public PAUSED;

    modifier truHolder(address _giveAddress){
        IERC721 giveAddress = IERC721(_giveAddress);
        require(giveAddress.balanceOf(msg.sender) > 0, "You dont own this NFT");
        _;
    }

    modifier tru1155Holder(address _giveAddress, uint256 _tokenId, uint256 _amount){
        IERC1155 giveAddress = IERC1155(_giveAddress);
        require(giveAddress.balanceOf(msg.sender, _tokenId) >= _amount, "You dont own the amount of NFTs");
        _;
    }
    modifier canTransferNFT(address nftContract, uint256 tokenId)
        {
                IERC721 nftContract = IERC721(nftContract);
                require(nftContract.getApproved(tokenId) == address(this), "You need  TruTrade permission first"); 
                _;
        }  

    modifier canTransfer1155(address _giveAddress){
        IERC1155 multiContract = IERC1155(_giveAddress);
        
        require(multiContract.isApprovedForAll(msg.sender, address(this)), "You must approve contract first!");
        _;
    }    

    modifier onlyOwner{
        require(msg.sender == owner, "Only Owner can use function");
        _;
    } 

    modifier trustworthy{
        require(dontTrust[msg.sender] != true, "You have destroyed your rep and can not use protocol");
        _;
    }

    constructor(){

        owner = msg.sender;
        TruTrader = payable(address(this));
        tradeId = 1;
        tradingFee = 0.004 ether;
        cancelFee = 0.004 ether;
        PAUSED = false;

    }

    mapping(uint256 => bool) public tradeInit;
    mapping(uint256 => bool) public doneDeal;
    mapping(uint256 => bool) public dealsOff;

    mapping(address => uint256) trustScore;
    mapping(address => bool) dontTrust;
    
    mapping(address => bool) public waved;
    mapping(address => bool) public approvedERC20;
    mapping(address => uint256) public tokenPrice;

    struct singleTrade{
        uint256 tradeId;
        address trader;
        address giveNFT;
        uint256 giveId;
        address wantNFT;
        uint256 wantID;
        uint256 endTime;
    }

    struct multiTrade{
        uint256 tradeId;
        address trader;
        address giveNFT;
        uint256 giveId;
        uint256 giveAmount;
        address wantNFT;
        uint256 wantID;
        uint256 wantAmount;
        uint256 endTime;
      
    }

    event tradeStarted (uint256 tradeId, address trader, address NFT, uint256 tokenId, uint256 amount, address wantNFT, uint256 wantTokenId, uint256 wantAmount, string tokenType, uint256 tradeTime);
    event tradeCompleted (uint256 tradeId, address trader, address NFT, uint256 tokenId, uint256 amount, address otherparty, address wantNFT, uint256 wantTokenId, uint256 wantAmount, string tokenType, uint256 tradeTime);
    event tradeCanceled(uint256 tradeId, address trader, address NFT, uint256 tokenId, uint256 amount, address wantNFT, uint256 wantTokenId, uint256 wantAmount, string tokenType, uint256 cancelTime);
    event tradeWithdrawn(uint256 tradeId, address trader, address NFT, uint256 tokenId, uint256 amount, address wantNFT, uint256 wantTokenId, uint256 wantAmount, string tokenType, uint256 cancelTime);



    singleTrade [] public SingleTrader;
    multiTrade [] public MultiTrade;

     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external  pure returns (bytes4)
    {
 
       return this.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external  pure returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external  pure returns (bytes4)
    {
        return this.onERC721Received.selector;
    }


    //Trade for ERC721
    function init721Trade(address _giveNFT, uint256 _giveId, address _wantNFT, uint256 _wantID, uint256 _endtime) public payable trustworthy truHolder(_giveNFT)  canTransferNFT(_giveNFT, _giveId) returns(bool){
            require(PAUSED != true , "New Trades have been paused");
            require(tradeInit[tradeId] != true, "This trade has already been setup");
            
            if(waved[_giveNFT] != true){
                if(tradingFee >= 0){
                    require(msg.value >= tradingFee, "Not enough funds to cover fee!");
                }
            }
            
            tradeInit[tradeId] = true;

            IERC721(_giveNFT).safeTransferFrom(msg.sender, address(this), _giveId);

            uint256 timer = block.timestamp + _endtime;

            SingleTrader.push(singleTrade(tradeId,msg.sender, _giveNFT, _giveId,  _wantNFT, _wantID, timer));
            
            doneDeal[tradeId] = false;

            emit tradeStarted (tradeId, msg.sender, _giveNFT, _giveId, 1, _wantNFT, _wantID, 1, "ERC721", timer);

            tradeId++;

            return true;

    }

    function init721TradeERC20(address _giveNFT, uint256 _giveId, address _wantNFT, uint256 _wantID, uint256 _endtime, address tokenAddress) public payable trustworthy truHolder(_giveNFT)  canTransferNFT(_giveNFT, _giveId) returns(bool){
            require(PAUSED != true , "New Trades have been paused");
            require(tradeInit[tradeId] != true, "This trade has already been setup");
            
            if(waved[_giveNFT] != true){

              _ERC20Fee(tokenAddress);

            }
            
            tradeInit[tradeId] = true;

            IERC721(_giveNFT).safeTransferFrom(msg.sender, address(this), _giveId);

            uint256 timer = block.timestamp + _endtime;

            SingleTrader.push(singleTrade(tradeId, msg.sender, _giveNFT, _giveId,  _wantNFT, _wantID, timer));
            
            doneDeal[tradeId] = false;

            _documentTrade(_giveNFT, _giveId, _wantNFT, _wantID, timer);
           
            return true;

    }
    function makeTrade721(uint256 _tradeId, address _wantNFT, uint256 _wantID ) public truHolder(_wantNFT) returns(bool){
            require(PAUSED != true , "paused");
            require(tradeInit[tradeId] != false, "initialized");

            singleTrade storage trade =  SingleTrader[_tradeId - 1];

            require(trade.wantNFT == _wantNFT && trade.wantID == _wantID, "invalid");
           

            if(block.timestamp >= trade.endTime){
                require(dealsOff[_tradeId] != true, "canceled");
            }

            doneDeal[trade.tradeId] = true;
            
            trustScore[msg.sender]+= 1;
            trustScore[trade.trader]+= 1;

            IERC721(_wantNFT).safeTransferFrom(msg.sender, trade.trader, _wantID); //send NFT to trade
            IERC721(trade.giveNFT).safeTransferFrom(address(this), msg.sender, trade.giveId); //retrieve NFT from contract

            emit tradeCompleted (_tradeId, trade.trader, trade.giveNFT, trade.giveId, 1 , msg.sender, trade.wantNFT, trade.wantID, 1, "ERC721", block.timestamp);
    
            return true;
    }

    function cancelTrade721(uint256 _tradeId) public payable returns(bool){
        require(doneDeal[_tradeId] != true, "completed");
        require(msg.value >= cancelFee, "pay fee");
        
        singleTrade storage trade =  SingleTrader[_tradeId - 1];

        require(msg.sender == trade.trader, "Only creator");
        require(block.timestamp < trade.endTime, "Timer ended, Use withdrawTrade");

        dealsOff[_tradeId] = true;

        IERC721 secondParty = IERC721(trade.wantNFT);
        address otherParty = secondParty.ownerOf(trade.wantID);

        uint256 fee = msg.value;
        uint256 split = fee * 50 /100;

        payable(TruTrader).transfer(split);
        payable(otherParty).transfer(split);

        uint256 prevScore = trustScore[msg.sender];

        if(prevScore <= 0){
            trustScore[msg.sender] = 0;
            dontTrust[msg.sender] = true;
        }else{
            trustScore[msg.sender]-= 1;
        }

        IERC721(trade.giveNFT).safeTransferFrom(address(this), trade.trader, trade.giveId);

        emit tradeCanceled(_tradeId, msg.sender, trade.giveNFT, trade.giveId, 1, trade.wantNFT, trade.wantID, 1, "ERC721", block.timestamp);

        return true;
    }
    
    function withdrawTrade721(uint256 _tradeId) public returns(bool){
        require(doneDeal[_tradeId] != true, "completed");
        
        singleTrade storage trade =  SingleTrader[_tradeId - 1];

        require(msg.sender == trade.trader, "Only creator");
        require(block.timestamp >= trade.endTime, "Time ended, use cancelTrade");

        dealsOff[_tradeId] = true;

        IERC721(trade.giveNFT).safeTransferFrom(address(this), trade.trader, trade.giveId);

        emit tradeWithdrawn(_tradeId, msg.sender, trade.giveNFT, trade.giveId, 1, trade.wantNFT, trade.wantID, 1, "ERC721", block.timestamp);


        return true;

    }


    //Trade for ERC1155
    function initTrade1155(address _giveNFT, uint256 _giveId, uint256 _giveAmount, address _wantNFT, uint256 _wantID, uint256 _wantAmount, uint256 _endTime ) public payable trustworthy tru1155Holder(_giveNFT, _giveId, _giveAmount) canTransfer1155(_giveNFT) returns(bool){
            require(PAUSED != true , "paused");
            require(tradeInit[tradeId] != true, "initialized");

            _feeChecker(_giveNFT);

            tradeInit[tradeId] = true;

            _get1155(_giveNFT, _giveId, _giveAmount);

            _multi(_giveNFT, _giveId, _giveAmount, _wantNFT, _wantID, _wantAmount, _endTime);

            return true;

    }

    function initTrade1155ERC20(address _giveNFT, uint256 _giveId, uint256 _giveAmount, address _wantNFT, uint256 _wantID, uint256 _wantAmount, uint256 _endTime, address tokenAddress ) public payable trustworthy tru1155Holder(_giveNFT, _giveId, _giveAmount) canTransfer1155(_giveNFT) returns(bool){
            require(PAUSED != true , "paused");
            require(tradeInit[tradeId] != true, "initialized");

            _ERC20FeeCheck(_giveNFT, tokenAddress);

            tradeInit[tradeId] = true;

            _get1155(_giveNFT, _giveId, _giveAmount);

            _multi(_giveNFT, _giveId, _giveAmount, _wantNFT, _wantID, _wantAmount, _endTime);

            return true;

    }

    function makeTrade1155(uint256 _tradeId, address _wantNFT, uint256 _wantID, uint256 _wantAmount) public tru1155Holder(_wantNFT, _wantID, _wantAmount) returns(bool) {
            require(PAUSED != true , "paused");
            require(tradeInit[tradeId] != false, "not initialized");

            multiTrade storage trade =  MultiTrade[_tradeId - 1];

            require(trade.wantNFT == _wantNFT, "invalid contract");
            require(trade.wantID == _wantID, "invalid ID");

            if(block.timestamp >= trade.endTime){
                require(dealsOff[_tradeId] != true, "canceled deal");
            }

            doneDeal[trade.tradeId] = true;
            trustScore[msg.sender]+= 1;
            trustScore[trade.trader]+= 1;

            IERC1155(_wantNFT).safeTransferFrom(msg.sender, trade.trader, _wantID, _wantAmount, ''); //send to
            IERC1155(trade.giveNFT).safeTransferFrom(address(this), msg.sender, trade.giveId, trade.giveAmount, ''); //send from

            emit tradeCompleted (_tradeId, trade.trader, trade.giveNFT, trade.giveId, trade.giveAmount , msg.sender, trade.wantNFT, trade.wantID, trade.wantAmount, "ERC1155", block.timestamp);
    

            return true;
    }

    function cancelTrade1155(uint256 _tradeId) public payable returns(bool){
        require(doneDeal[_tradeId] != true, "deal completed");
        require(msg.value >= cancelFee, "pay fee");

        multiTrade storage trade =  MultiTrade[_tradeId - 1];

        require(msg.sender == trade.trader, "Only creator");
        require(block.timestamp < trade.endTime, "Time has ended, use withdrawTrade function");

        dealsOff[_tradeId] = true;

        uint256 prevScore = trustScore[msg.sender];

        if(prevScore <= 0){
            trustScore[msg.sender] = 0;
            dontTrust[msg.sender] = true;
        }

        IERC1155(trade.giveNFT).safeTransferFrom(address(this), trade.trader, trade.giveId, trade.giveAmount, '');

        emit tradeCanceled(_tradeId, msg.sender, trade.giveNFT, trade.giveId, trade.giveAmount, trade.wantNFT, trade.wantID, trade.wantAmount, "ERC1155", block.timestamp);

        return true;

    }

    function withdrawTrade1155(uint256 _tradeId) public returns(bool){
        require(doneDeal[_tradeId] != true, "This deal has been completed");
        
        multiTrade storage trade =  MultiTrade[_tradeId - 1];

        require(msg.sender == trade.trader, "creator only");
        require(block.timestamp >= trade.endTime, "Time ended, use withdrawTrade");

        dealsOff[_tradeId] = true;

        IERC1155(trade.giveNFT).safeTransferFrom(address(this), trade.trader, trade.giveId, trade.giveAmount, '');

        emit tradeWithdrawn(_tradeId, msg.sender, trade.giveNFT, trade.giveId, trade.giveAmount, trade.wantNFT, trade.wantID, trade.wantAmount, "ERC1155", block.timestamp);
        
        return true;

    }
 
    //Utils and views
    function Approve721(address _contract, uint256 _tokenId) public  returns(bool){

        IERC721(_contract).approve(address(this), _tokenId);

        return true;

    }
    function Approve1155(address _contract, bool _status) public returns(bool) {

        IERC1155(_contract).setApprovalForAll(address(this), _status);

        return true;
    }

    function getTradeDetails721(uint256 _tradeId) public view returns(singleTrade memory){
        return SingleTrader[_tradeId - 1];
    }
    function getTradeDetails1155(uint256 _tradeId) public view returns(multiTrade memory){
        return MultiTrade[_tradeId - 1];
    }

    function erc20Balance(address _contract) public view returns(uint256){
        IERC20 erc20 = IERC20(_contract);

        uint256 _amount = erc20.balanceOf(address(this));

        return _amount;
    }


    //Privates
    function _feeChecker(address _giveNFT) private {
      
        if(waved[_giveNFT] != true){
                if(tradingFee >= 0){
                    require(msg.value >= tradingFee, "Not enough funds to cover fee!");
                }
            }

    }
    function _ERC20FeeCheck(address _giveNFT, address tokenAddress) private {
         
         if(waved[_giveNFT] != true){

              _ERC20Fee(tokenAddress);

            }

    }
    function _ERC20Fee(address _tokenAddress) private {
       require(approvedERC20[_tokenAddress] != false,"Token not approved for use");

       IERC20 GreenToken = IERC20(_tokenAddress);

       uint256 erc20Fee = tokenPrice[_tokenAddress];

       require(GreenToken.balanceOf(msg.sender) >= erc20Fee, "Your balance of this ERC20 is not enough");

       GreenToken.transfer(address(this), erc20Fee * (10**18));

    }
    function _documentTrade(address _giveNFT, uint256 _giveId, address _wantNFT, uint256 _wantID, uint256 _endtime) private {

        emit tradeStarted (tradeId, msg.sender, _giveNFT, _giveId, 1, _wantNFT, _wantID, 1, "ERC721", _endtime);

        tradeId++;

    }
    function _multi(address _giveNFT, uint256 _giveId, uint256 _giveAmount, address _wantNFT, uint256 _wantID, uint256 _wantAmount, uint256 _endTime ) private {

            MultiTrade.push(multiTrade(tradeId, msg.sender,_giveNFT, _giveId, _giveAmount, _wantNFT, _wantID, _wantAmount, _endTime));
            
            emit tradeStarted (tradeId, msg.sender, _giveNFT, _giveId, _giveAmount, _wantNFT, _wantID, _wantAmount, "ERC1155", _endTime);

            tradeId++;

            

    }
    function _get1155(address _giveNFT, uint256 _giveId, uint256 _giveAmount) private {
            
            IERC1155(_giveNFT).safeTransferFrom(msg.sender, address(this), _giveId, _giveAmount, '' );


    }

    //Owner Functions
    function approveERC20(address _tokenAddress, bool _status) public onlyOwner returns (bool){
        
        approvedERC20[_tokenAddress] = _status;

        return approvedERC20[_tokenAddress];

    }
    function setFee(uint256 _fee) public onlyOwner returns(uint256) {
        tradingFee = _fee;

        return tradingFee;
    }
    function setCancelFee(uint256 _fee) public onlyOwner returns(uint256) {
        cancelFee = _fee;

        return cancelFee;
    }
    function setERC20Fee(address _tokenAddress, uint256 _price) public onlyOwner returns(uint256){
        tokenPrice[_tokenAddress] = _price;

        return tokenPrice[_tokenAddress];
    }
    function waveContract(address _contract, bool _status) public onlyOwner returns(bool){
        waved[_contract] = _status;

        return waved[_contract];
    }

    function withdrawERC20(address _contract) public onlyOwner returns(bool, uint256){
        require(approvedERC20[_contract] != false, "Do you trust this token? DYOR");

        IERC20 erc20 = IERC20(_contract);

        uint256 _amount = erc20.balanceOf(address(this));

        erc20.transfer(owner, _amount * (10**18));

        return (true, _amount);

    }
    
    function withdraw() public payable onlyOwner {

    (bool hs, ) = payable(0x625Cd0169A8B36E138D84a00BCa1d9d1c8b45f51).call{value: address(this).balance * 45 / 100}("");
    require(hs);

    (bool sb, ) = payable(0xca22CBe44Ad307c1f2F5498f71dDE4fA25251136).call{value: address(this).balance * 45 / 100}("");
    require(sb);
    
    // expenses payout.
    // =============================================================================
    (bool os, ) = payable(owner).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

}