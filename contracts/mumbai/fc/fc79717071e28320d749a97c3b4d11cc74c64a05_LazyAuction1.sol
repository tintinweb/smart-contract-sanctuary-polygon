/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// File: utils/IAccountsEvidence.sol


pragma solidity >=0.7.0 <0.9.0;

interface IAccountsEvidence {
    function get(address fAddress) external view returns(address);

}
// File: utils/LazySellingContractBaseCfg.sol


pragma solidity >=0.7.0 <0.9.0;

library LazySellingContractBaseCfg {
    
    // address for receive a fee
    address payable public constant feeReceiverAddress = payable(0xD0d896F4E701054D3F5ed64a5FF470D227eE5D16); // U3
    

    // fee from auction per thousand
    uint public constant fee = 30; // = 3%

}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: utils/LazySellingContractBase.sol


pragma solidity >=0.7.0 <0.9.0;






abstract contract LazySellingContractBase is Ownable, ERC1155Holder {

    //event HighestBidIncreased(address indexed _finacialAddress, address indexed _tokenAddress, uint _totalAmount, uint _bid);
    event Bid(uint _timeStampUtc, address indexed _finacialAddress, address indexed _tokenAddress, uint _totalAmount, uint _bid);

    event IsAuctionTokenOwner(address indexed _contractAddress, uint _tokenId);
 
    event WithdrawalBid(address indexed _receiverAddress, uint _amount);
    event WithdrawalFee(address indexed _receiverAddress, uint _fee);
    event WithdrawalRevenue(address indexed _receiverAddress, uint _revenue);
    event TokenTransfer(address indexed _contractAddress, uint _tokenId, address indexed _ownerAddress, string msg);

    event AuctionEnded(address indexed win_finacialAddressner, address indexed _tokenAddress, uint amount);
    event AuctionCanceled();

    address payable public immutable feeReceiverAddress; // address for receive a fee
    uint public immutable fee; // per thousand

    uint public immutable auctionStartTime; // start auction in seconds
    uint public immutable auctionEndTime; // end auction in seconds

    // info about token
    address public immutable lnftAddress; // address of ERC1155
    uint public immutable tokenId; // token id in ERC1155
    address public immutable tokenOwnerAddress; // token owner
    IERC1155 internal immutable lnft; // instance of ERC1155

    address public immutable aeAddress; // address of contract for evidence
    IAccountsEvidence public immutable ae; // instance of IAccountsEvidence

    address payable public immutable revenueAddress; // address for receive the MATIC from auction



    uint public highestOffer; // current MATIC

    // address of buyer
    address public highestOfferFinancialAddress; // finance address of offer
    address public highestOfferTokenAddress; //token address of offer
    
    bool public isAuctionTokenOwner; //check the auction is owner of token in ERC1155

    bool public isAuctionClosed;
    bool public isCanceled;

    mapping(address => uint) public pendingReturns; // accounts and amounts(bids) to return 
    uint public feeAmount;
    uint public revenueAmount;

    constructor(
        uint _auctionStartTime, //seconds
        uint _auctionEndTime, //seconds
        address _lnftAddress,
        address _aeAddress,
        uint256 _tokenId,
        uint _amount,
        address payable _revenueAddress
    )  {
        feeReceiverAddress = LazySellingContractBaseCfg.feeReceiverAddress;
        fee = LazySellingContractBaseCfg.fee;

        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;
        lnftAddress = _lnftAddress;
        aeAddress = _aeAddress;
        tokenId = _tokenId;
        tokenOwnerAddress = msg.sender;
        highestOffer = _amount;
        revenueAddress = _revenueAddress;

        //----------------------------
        isAuctionTokenOwner = false;
        lnft = IERC1155(_lnftAddress);
        ae = IAccountsEvidence(_aeAddress);
    }

/*require pokud je FALSE tak konec*/
//https://medium.com/blockchannel/the-use-of-revert-assert-and-require-in-solidity-and-the-new-revert-opcode-in-the-evm-1a3a7990e06e

    function cancel() public 
        onlyOwner 
        noCanceled 
    {
        require(
            highestOfferFinancialAddress == address(0),
            "It is not possible to cancel it. Auction has a offer."
        );

        isCanceled = true;

        emit AuctionCanceled();
    }
    
    function bid(address _offerTokenAddress) public payable virtual;

    function end() public 
        noAuctionClosed 
        noCanceled
    {
        require(
            auctionEndTime < block.timestamp, 
            "Auction not yet ended."
        );

        isAuctionClosed = true;

        emit AuctionEnded(highestOfferFinancialAddress, highestOfferTokenAddress, highestOffer);

    }

    function tokenTransfer() public virtual     
    {
        require(isCanceled || isAuctionClosed, "It is no possible to transfer token. Auction is not canceled or closed.");

        if(highestOfferFinancialAddress == address(0)) {
            _tokenTransferBackToOwner();
        }
        else {
            _tokenTransferToWinner();
        }
    }

    //https://solidity-by-example.org/sending-ether/
    function withdrawalBid() public virtual {
        uint refund  = pendingReturns[msg.sender];
        if (refund  > 0) {
            pendingReturns[msg.sender] = 0;
            (bool sent, ) = payable(msg.sender).call{value: refund }("");
            if (!sent) {
                pendingReturns[msg.sender] = refund ;
                require(false, "Transfer refund failed");
            }
            emit WithdrawalBid(msg.sender, refund);
        }
    }
    function withdrawalFee() public virtual 
        auctionClosed
    {
        (bool sent, ) = feeReceiverAddress.call{value: feeAmount}("");
        require(sent, "Transfer fee failed");
        emit WithdrawalFee(feeReceiverAddress, feeAmount);
        feeAmount = 0;
    }
    function withdrawalRevenue() public virtual 
        auctionClosed
    {
        (bool sent, ) = revenueAddress.call{value: revenueAmount}("");
        require(sent, "Transfer revenue failed");
        emit WithdrawalRevenue(revenueAddress, revenueAmount);
        revenueAmount = 0;
    }

    //--------------------
    //---------------------------------
    function _tokenTransferBackToOwner() internal {
        isAuctionTokenOwner = lnft.balanceOf(address(this), tokenId) == 1;
        if(isAuctionTokenOwner) {
            lnft.safeTransferFrom(address(this), tokenOwnerAddress, tokenId, 1, "Token was returned");
            emit TokenTransfer(lnftAddress, tokenId, tokenOwnerAddress, "Token was returned");
        }        
    } 

    function _tokenTransferToWinner() internal {
        //***** pokud bude highestBidderTokenAddress null ne 0 tak prevest na highestBidderFinancialAddress???????
        lnft.safeTransferFrom(address(this), highestOfferTokenAddress, tokenId, 1, "Token was sold");
        emit TokenTransfer(lnftAddress, tokenId, highestOfferTokenAddress, "Token was sold");        
    }

    function _bid(address payable _financialAddress, address _tokenAddress, uint _offer, uint _nbid) internal {    

        highestOfferFinancialAddress = _financialAddress;
        highestOfferTokenAddress = _tokenAddress;
        highestOffer = _offer;

        feeAmount = (highestOffer / 1000) * fee;
        revenueAmount = highestOffer - feeAmount;

        emit Bid(block.timestamp, _financialAddress, _tokenAddress, _offer, _nbid); 
    }

    function _isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    //--------------------------------------------

    modifier noOwner {
        require(msg.sender != owner(),
            "Ownable: caller is the owner");
        _;
    }

    modifier auctionClosed {
        require(
            isAuctionClosed == true,
            "Auction is closed."
        );
        _;
    }
    modifier noAuctionClosed {
        require(
            isAuctionClosed == false,
            "Auction is not closed."
        );
        _;
    }

    modifier canceled {
        require(
            isCanceled == true,
            "Auction is not canceled."
        );
        _;
    }
    modifier noCanceled {
        require(
            isCanceled == false,
            "Auction is canceled."
        );
        _;
    }

    modifier onlyInAuctionTime {
        require(
            auctionStartTime <= block.timestamp && block.timestamp <= auctionEndTime,
            "Auction is not active."
        );
        _;
    }

    modifier auctionTokenOwner{
        if(!isAuctionTokenOwner){
            isAuctionTokenOwner = lnft.balanceOf(address(this), tokenId) == 1;
            emit IsAuctionTokenOwner(lnftAddress, tokenId);
        }
        require(
            isAuctionTokenOwner == true,
            "Auction is not owner of token."
        );
        _;
    }

    modifier checkAccounts(address _tokenAddress) {
        address tAddress = ae.get(msg.sender);        
        require(
            tAddress == _tokenAddress,
            "This selling contract is used only for accounts from platform. Please register on https://lazynft.com"
        );
        _;
    }

}
// File: LazyAuction1.sol


pragma solidity >=0.7.0 <0.9.0;


contract LazyAuction1 is LazySellingContractBase {

    constructor(
        uint _auctionStartTime,
        uint _auctionEndTime,
        address _lnftAddress,
        address _aeAddress,
        uint _tokenId,
        uint _amount,
        address payable _revenueAddress
    ) 
        LazySellingContractBase(
            _auctionStartTime,
            _auctionEndTime,
            _lnftAddress,
            _aeAddress,
            _tokenId,
            _amount,
            _revenueAddress
        ) 
    {

    }

    function bid(address _offerTokenAddress) public payable override
        noOwner
        noAuctionClosed
        noCanceled
        onlyInAuctionTime
        auctionTokenOwner
        checkAccounts(_offerTokenAddress)
    {        
        require(
            _offerTokenAddress != address(0),
            "Address for token is empty."
        );

        require(
            _isContract(_offerTokenAddress) == false,
            "Address for token is contract."
        );


        uint offer = pendingReturns[msg.sender] + msg.value;
        require(
            offer > highestOffer,
            "There already is a higher offer."
        );

        if (highestOffer != 0){
            pendingReturns[highestOfferFinancialAddress] = highestOffer;
        }
        
        pendingReturns[msg.sender] = 0;

        _bid(payable(msg.sender), _offerTokenAddress, offer, msg.value);

    }

}