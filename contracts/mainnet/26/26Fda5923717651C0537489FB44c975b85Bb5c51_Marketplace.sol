pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/SafeERC20.sol";
import "./interfaces/IUA.sol";
import "./interfaces/IERC721Receiver.sol";

contract Marketplace is IERC721Receiver, ReentrancyGuard {
    using Counters for Counters.Counter;
    //using SafeERC20 for IERC20;
    constructor()
    {
        _deployer = msg.sender;
    }

        // Address of the NFT minter
    address _rootContract;
    // Custodial wallet
    address _treasury;
    address _deployer;

    // Mapping from token ID to students
    mapping(uint256 => uint256) _students;

    // Mapping students to token count
    mapping(uint256 => uint256) _balancesOf;

    function _ownByStudent(uint256 tokenId) internal view virtual returns (uint256) {
        return _students[tokenId];
    }

    function ownerByID(uint256 tokenId) public view virtual returns (uint256) {
        uint256 userId = _ownByStudent(tokenId);
        require(userId != 0, "Invalid token ID");
        return userId;
    }

    mapping(IERC20 => bool) allowedTokens;

    modifier onlyNFTOwner(IERC721 nftContract, uint256 tokenId) {
        require(
            msg.sender == nftContract.ownerOf(tokenId),
            "Not the owner"
        );
        _;
    }

    modifier onlyTokenOwner(IERC721 nftContract, uint256 tokenId) {
        require(
            msg.sender == nftContract.ownerOf(tokenId),
            "You are not the owner"
        );
        _;
    }

    modifier onlyStudent(uint256 userId, uint256 tokenId) {
        require(
            userId == ownerByID(tokenId),
            "This student not the owner"
        );
        _;
    }

    modifier onlyRoot(address root) {
        require(
            _rootContract == root,
            "Not the NFT minter"
        );
        _;
    }

    modifier onlyDeployer() {
        require(
            _deployer == msg.sender,
            "Rejected, wrong address"
        );
        _;
    }

    modifier onlyAllowedToken(IERC20 sellingToken) {
        require(allowedTokens[sellingToken], "Token is not allowed");
        _;
    }

    enum ItemState {
      Sold,
      Locked,
      OnSale,
      Withdrawn
    }
    
    struct MarketItem {
      uint256 listingId;
      uint256 tokenId;
      IERC721 nftContract;
      uint256 seller;
      uint256 price;
      IERC20 sellingToken;
      ItemState listingState;
    }

    Counters.Counter nextListingId;

    mapping(uint256 => MarketItem) listingIdToItem;

    mapping(uint256 => uint256) private _creators;

    mapping(uint256 => uint256) private _creatingCount;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from student to operator approvals
    mapping(uint256 => mapping(address => bool)) private _operatorApprovals;

    uint256 marketplaceFeePercentage;

    event itemMinted(
        uint256 indexed listingId,
        IERC721 nftContract,
        uint256 indexed tokenId,
        uint256 indexed creator,
        uint256 price,
        IERC20 sellingToken
    );

    event itemListed(
        uint256 indexed listingId,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        uint256 seller,
        uint256 creator,
        uint256 price,
        IERC20 sellingToken
    );

    event itemSold(
        uint256 indexed listingId,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        uint256 seller,
        uint256 creator,
        uint256 price,
        IERC20 sellingToken
    );

    event itemSoldInternal(
        uint256 indexed listingId,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        uint256 buyer,
        uint256 seller,
        uint256 creator,
        uint256 price,
        IERC20 sellingToken
    );

    event itemDelisted(
        uint256 indexed listingId,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        uint256 seller
    );

    event itemPriceUpdated(
        uint256 indexed itemId,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        uint256 seller,
        uint256 oldPrice,
        uint256 newPrice
    );

    function setMarketplaceFee(uint256 marketplaceFeePercent)
        external
        onlyDeployer
    {
        marketplaceFeePercentage = marketplaceFeePercent;
    }

    function changeWhitelist(
        address erc20,
        bool status
    ) external onlyDeployer {
        allowedTokens[IERC20(erc20)] = status;
    }

    function initVariables(address custodial, address NFTcontract) external onlyDeployer nonReentrant {
        _treasury = custodial;
        _rootContract = NFTcontract;
    }

    function balanceCount(uint256 userId) public view virtual returns (uint256) {
        require(userId != 0, "ZERO not a valid userId");
        return _balancesOf[userId];
    }
    function count(uint256 userId) public view virtual returns (uint256) {
        require(userId != 0, "ZERO not a valid userId");
        return _creatingCount[userId];
    }

    // Mapping from token ID to creators

    function _created(uint256 tokenId) internal view virtual returns (uint256) {
        return _creators[tokenId];
    }

    function creatorByID(uint256 tokenId) public view virtual returns (uint256) {
        uint256 userId = _created(tokenId);
        require(userId != 0, "Invalid token ID");
        return userId;
    }


    /// @param tokenId - id of listed nft
    /// @param sellingToken - token that is used in listing f.e. wmatic,usdc ...
    /// @param price - item price in wei
    function listItem(
        address nftContract,
        uint256 userId,
        uint256 tokenId,
        address sellingToken,
        uint256 price
    )
        external
        onlyRoot(msg.sender)
        onlyAllowedToken(IERC20(sellingToken))
        nonReentrant
    {
        require(price > 0, "Price must be not zero");
        //IERC721 workingNft = IERC721(nftContract);
        uint256 listingId = nextListingId.current();
        //workingNft.safeTransferFrom(msg.sender, address(this), tokenId);
        _creators[tokenId] = userId;
        _creatingCount[userId] += 1;
        _students[tokenId] = userId;
        _balancesOf[userId] += 1;
        listingIdToItem[listingId] = MarketItem(
            listingId,
            tokenId,
            IERC721(nftContract),
            userId,
            price,
            IERC20(sellingToken),
            ItemState.OnSale
        );
        nextListingId.increment();

        emit itemMinted(
            listingId,
            IERC721(nftContract),
            tokenId,
            userId,
            price,
            IERC20(sellingToken)
        );
    }

    function listNFT(
        address nftContract,
        uint256 userId,
        uint256 tokenId,
        address sellingToken,
        uint256 price
        )
        external
        onlyDeployer
    { 
        require(price > 0, "Price must be not zero");
        IERC721 workingNft = IERC721(nftContract);
        uint256 creator = creatorByID(tokenId);
        uint256 listingId = nextListingId.current();
        _students[tokenId] = userId;
        _balancesOf[userId] += 1;
        listingIdToItem[listingId] = MarketItem(
            listingId,
            tokenId,
            workingNft,
            userId,
            price,
            IERC20(sellingToken),
            ItemState.OnSale
        );
        nextListingId.increment();

        emit itemListed(
            listingId,
            workingNft,
            tokenId,
            userId,
            creator,
            price,
            IERC20(sellingToken)
        );
    }

    /// @dev listingId is being pulled from subgraph
    function buyItem(uint256 listingId, bool isWETH) external nonReentrant {
        require(
            listingIdToItem[listingId].seller != 0,
            "Listing does not exist"
        );
        MarketItem memory currentListing = listingIdToItem[
            listingId
        ];
        (uint256 transferAmount, uint256 feeAmount) = calculateFee(
            currentListing.price
        );
        IERC20 workingToken = currentListing.sellingToken;
        IUA custodial = IUA(_treasury);
        IERC721 workingNft = currentListing.nftContract;
        uint256 creator = _students[currentListing.tokenId];
        if (isWETH){
            workingToken.transferFrom(msg.sender, address(_treasury), currentListing.price);
            custodial.splitRoyalty(currentListing.seller, creator, transferAmount, feeAmount, isWETH);
        } else {
            workingToken.feeLessTransfer(msg.sender, address(_treasury), currentListing.price);
            custodial.splitRoyalty(currentListing.seller, creator, transferAmount, feeAmount, isWETH);
        }

        workingNft.safeTransferFrom(
            address(this),
            msg.sender,
            currentListing.tokenId,
            "0x00"
        );

        delete listingIdToItem[listingId];
        _students[currentListing.tokenId] = 0;
        _balancesOf[currentListing.seller] -= 1;

        emit itemSold(
            listingId,
            workingNft,
            currentListing.tokenId,
            msg.sender,
            currentListing.seller,
            creator,
            currentListing.price,
            workingToken
        );
    }

    /// @dev listingId is being pulled from subgraph
    function buyItemInternal(uint256 listingId, uint256 buyer, bool isWETH) external onlyDeployer nonReentrant {
        require(
            listingIdToItem[listingId].seller != 0,
            "Listing does not exist"
        );
        MarketItem memory currentListing = listingIdToItem[
            listingId
        ];
        (uint256 transferAmount, uint256 feeAmount) = calculateFee(
            currentListing.price
        );
        IERC20 workingToken = currentListing.sellingToken;
        IUA custodial = IUA(_treasury);
        IERC721 workingNft = currentListing.nftContract;
        uint256 creator = _students[currentListing.tokenId];
        custodial.transferSale(buyer, currentListing.seller, creator, transferAmount, feeAmount, isWETH);

        delete listingIdToItem[listingId];
        _students[currentListing.tokenId] = buyer;
        _balancesOf[currentListing.seller] -= 1;
        _balancesOf[buyer] += 1;

        emit itemSoldInternal(
            listingId,
            workingNft,
            currentListing.tokenId,
            buyer,
            currentListing.seller,
            creator,
            currentListing.price,
            workingToken
        );
    }

    /// @param listingId - id of listing from subgraph
    /// _price - new price of selected item
    function changeItemPrice(uint256 listingId, uint256 _price)
        external
        onlyDeployer
    {
        require(_price > 0, "Price must be not zero");
        require(
            listingIdToItem[listingId].seller != 0,
            "Listing does not exist"
        );
        MarketItem memory currentListing = listingIdToItem[
            listingId
        ];
        listingIdToItem[listingId].price = _price;

        emit itemPriceUpdated(
            currentListing.listingId,
            currentListing.nftContract,
            currentListing.tokenId,
            currentListing.seller,
            currentListing.price,
            _price
        );
    }

    function delistItem(uint256 listingId)
        external
        onlyDeployer
    {
        require(
            listingIdToItem[listingId].seller != 0,
            "Listing does not exist"
        );
        MarketItem memory currentListing = listingIdToItem[
            listingId
        ];

        delete listingIdToItem[listingId];
        emit itemDelisted(
            currentListing.listingId,
            currentListing.nftContract,
            currentListing.tokenId,
            currentListing.seller
        );
    }

    /// @dev function to calculate fees
    function calculateFee(uint256 value)
        internal
        view
        returns (uint256 transferAmount, uint256 feeAmount)
    {
        require(marketplaceFeePercentage > 0, "Marketplace fee is not set");
        feeAmount = (value * marketplaceFeePercentage) / 100;
        transferAmount = value - feeAmount;
    }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    )
        public pure
        returns(bytes4)
    {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.11;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function feeLessTransfer(
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.11;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    // Custom starts here

    function mintLand(
        address to,
        uint256 tokenId,
        uint256 planetId,
        string memory customTokenUri
    ) external;

    function mint(address to) external returns (uint256);

    function burn(uint256 tokenId) external;

    function changeConsumer(address _consumer, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IUA {
    event RoyaltySplitted(uint256 indexed userId, uint256 indexed creator, uint256 amount, uint256 fee, bool isWETH);
    
    event TransferSale(uint256 indexed buyer, uint256 indexed seller, uint256 amount, uint256 fee, bool isWETH);

    function transferSale(uint256 from, uint256 to, uint256 creator, uint256 amount, uint256 fee, bool isWETH) external;

    function splitRoyalty(uint256 userId, uint256 creator, uint256 amount, uint256 fee, bool isWETH) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  )
    external
    returns(bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}