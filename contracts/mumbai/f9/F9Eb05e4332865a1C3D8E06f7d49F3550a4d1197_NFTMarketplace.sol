// SPDX-License-Identifier: MTI
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    uint256  marketitemscount;
    address payable  withdrawfeesaccount; //owner to withdraw fees
    uint256  marketfeespercentage;


    struct nftmarketitem{
        uint256 itemid;
        address nftcontractaddress;
        uint256 tokenid;
        address payable seller;
        uint256 price;
        bool issold;
        bool islisted;
    }
    mapping (uint256 => nftmarketitem) nftmarketitems;

    
    event sellnft(
        uint256 itemid,
        address indexed nftcontractaddress,
        uint256 tokenid,
        address indexed seller,
        uint256 price
    );
    event buyingnft(
        uint256 itemid,
        address indexed nftcontractaddress,
        uint256 tokenid,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );


    //Stake state variables 
    IERC20  rewardsToken; // Reward token (Reward)
    uint256 allowdeposit_time_endat;
    uint256 allowdeposit_duration = 1 minutes; 

    mapping (address => bool) isdeposited ;  
    mapping (address => bool) iscanceledstaking;  
    mapping (address => mapping (address => uint256)) stakednftstokens; // user address >  nftcontractaddress > tokenid


    uint256 takeprofit_time;
    uint256 takeprofit_duration = 1 minutes;  
    address [] stakers;


    modifier OnlyDeployer {
        require (withdrawfeesaccount == msg.sender , "Only contract deployer can call this function");
        _;
    }

    constructor (uint256 _feespercentage , address rewardtokenaddress) {
        marketfeespercentage = _feespercentage;
        withdrawfeesaccount = payable(msg.sender);
        //staking
        rewardsToken = IERC20 (rewardtokenaddress);
        allowdeposit_time_endat = block.timestamp + allowdeposit_duration;
    }

    // list function (sell nft) 
    function listnft (address nftcontractaddress, uint256 tokenid, uint256 price) external nonReentrant {
        require(price > 0 , "price should greater than 0");
        marketitemscount ++;
        require (nftmarketitems[marketitemscount].islisted == false , " item is already listed");
        nftmarketitems[marketitemscount] = nftmarketitem (
            marketitemscount,
            nftcontractaddress,
            tokenid,
            payable(msg.sender),
            price,
            false,
            true
        );
        IERC721(nftcontractaddress).transferFrom(msg.sender, address(this), tokenid);
        
        emit sellnft(
            marketitemscount,
            nftcontractaddress,
            tokenid,
            msg.sender,
            price
        );
    } 
    // Buy NFT function

    function buynft (uint256 marketitemid) external payable nonReentrant {
        require (marketitemid >0 && marketitemid<= marketitemscount , "invalid market item id");
        require (msg.sender != nftmarketitems[marketitemid].seller , "buyer can not be seller");
        uint256 nfttotalprice = totalpricewith_marketfees(marketitemid);
        nftmarketitem storage nftitem = nftmarketitems[marketitemid];
        require (msg.value == nfttotalprice , "Pay what seller requires");
        require (nftitem.issold == false, "this nft is already sold");
        nftitem.seller.transfer(nftitem.price);
        withdrawfeesaccount.transfer(nfttotalprice - nftitem.price);
        IERC721(nftitem.nftcontractaddress).transferFrom( address(this) ,msg.sender, nftitem.tokenid);

        nftitem.issold = true;
        nftitem.seller = payable(msg.sender);
        nftitem.islisted = false;

        emit buyingnft(
            marketitemid,
            nftitem.nftcontractaddress,
            nftitem.tokenid,
            nftitem.seller,
            msg.sender,
            nftitem.price
        );
    }

    //Function to apply market fees (1%)
    function totalpricewith_marketfees (uint256 marketitemid) public view returns (uint256) {
        uint256 totalprice= nftmarketitems[marketitemid].price ;
        uint256 totalpricewithfees = totalprice* (100+marketfeespercentage);
        return totalpricewithfees/100;
    }

    function getmarketdata ( uint256 marketitemid) public view returns (nftmarketitem memory){
        return nftmarketitems[marketitemid];
    }

    function gettotalcountitems () public view returns (uint256) {
        return marketitemscount;
    }


    // Staking Functions

    function startstaking () public OnlyDeployer {
        allowdeposit_time_endat = block.timestamp + allowdeposit_duration;
    }


    function stakeNFT (address nftcontractaddress, uint256 tokenid) public {
        require (block.timestamp <= allowdeposit_time_endat , "duration to deposit has been passed");
        IERC721(nftcontractaddress).transferFrom(msg.sender, address(this), tokenid);
        isdeposited[msg.sender] = true;
        takeprofit_time = allowdeposit_time_endat + takeprofit_duration;
        stakednftstokens[msg.sender][nftcontractaddress]=tokenid;
        stakers.push(msg.sender); 
    }

    function cancelstaking () public {
        require(isdeposited[msg.sender] == true , "You did not deposit NFTs");
        require(block.timestamp < takeprofit_time , "You could not not cancel locking, withdraw your nft with profits");
        iscanceledstaking[msg.sender] = true;
    }


    function claimrewards (address nftcontractaddress) public {
        require(isdeposited[msg.sender] == true , "You did not stake NFTs");
        require(iscanceledstaking[msg.sender] == false , "You have canceled the staking, you are able to withdraw without reward tokens");
        require(block.timestamp >= takeprofit_time , "wait until the time of taking profit comes");
        uint256 tokenid = stakednftstokens[msg.sender][nftcontractaddress]; 
        IERC721(nftcontractaddress).transferFrom(address(this), msg.sender, tokenid);
        rewardsToken.transfer(msg.sender, 100000000000000000000); // 1000 tokens reward 
        isdeposited[msg.sender] = false; 
    }

    function claimnftonly_withoutrewards (address nftcontractaddress) public{
        require(isdeposited[msg.sender] == true , "You did not deposit locked token");
        require(iscanceledstaking[msg.sender] == true , "To withdraw without reward, you have to cancel locking first");
        uint256 tokenid = stakednftstokens[msg.sender][nftcontractaddress]; 
        IERC721(nftcontractaddress).transferFrom(address(this), msg.sender, tokenid);
        isdeposited[msg.sender] = false;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (security/ReentrancyGuard.sol)

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