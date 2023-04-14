/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: contracts/NFTUtilities.sol


pragma solidity ^0.8.18;




contract NFTUtilities is ERC721Holder {
    IERC721 public nft;
    IERC20 public paymentToken;
    uint256 public utilityId;

    struct Utility {
        uint256 utilityId;
        uint256 tokenId;
        address collectionAddress;
        string utilityName;
        address[] holders;
        address collectionOwner;
        bool expirable;
        uint256 expiry;
        // uint256 expiriesIn;
    }
    //Utility detail for an wallet address
    struct userUtility {
        uint256 utilityId;
        address collectionAddress;
        uint256 tokenId;
        string utilityName;
        uint256 price;
        bool used;
        bool transferred;
        bool expirable;
        bool listed;
        // address user;
        address owner;
        uint256 expiry;
        // uint256 expiriesIn;
    }

    struct TokenDetail {
        uint256 utilityId;
        uint256 tokenId;
        address collectionAddress;
        // string utilityName;
        bool utilityclaimed;
        bool redeemedUtility;
        bool transferred;
        bool listed;
        bool expirable;
        uint256 expiry;
        address owner;
        address delegator;
    }

    // collectionaddr, token id , prv id-> tokenDetail
    mapping(address => mapping(uint256 => mapping(uint256 => TokenDetail)))
        public UtilityForToken;

    mapping(address => mapping(uint256 => Utility)) public utilitiesInfo; // collection address -> privilege Id-> Utility
    mapping(address => Utility[]) public UtilitiesForCollection; // collection address -> Utility[]
    // mapping(address => uint256[]) NoOfUtilitiesForCollection;

    mapping(address => userUtility[]) public UserUtilities; // user wallet address -> utilitiDetail[]
    // mapping(address => UtilityForToken) public utilityclaimed;

    //event UtilityCreated(address nftaddr, uint256 PrevId);
    event UtilityClaimed(
        uint256 PrevId,
        string name,
        address nftaddr,
        address buyer
    );
    event UtilityTransferred(
        address nftaddr,
        uint256 tokenId,
        uint256 PrevId,
        address receiver
    );
    event UtilityRedemmed(address nftaddr,
        uint256 tokenId,
        uint256 PrevId, 
        address user);

    event UtilityCreated(
        uint256 PrevId,
        string name,
        address nft,
        address owner
    );


    // Function to get the array associated with an address
    function getUtilitiesForCollection(address _collectionAddress)
        public
        view
        returns (Utility[] memory)
    {
        return UtilitiesForCollection[_collectionAddress];
    }

    //returns total number of utilities for an collection
    function getNoOfUtilitiesForCollection(address _collectionAddress)
        public
        view
        returns (uint256)
    {
        return UtilitiesForCollection[_collectionAddress].length;
    }

    //returns all utility for an address
    function getUtilityForAddress(address _address)
        public
        view
        returns (userUtility[] memory)
    {
        return UserUtilities[_address];
    }


    function getUtilityInfo(address nftaddr, uint256 PrevId)
        public
        view
        returns (Utility memory)
    {
        return utilitiesInfo[nftaddr][PrevId];
    }

    function getUtilityDetails(address nftaddr,uint256 tokenId,uint256 PrevId) public view returns(TokenDetail memory)
    {
    return UtilityForToken[nftaddr][tokenId][PrevId];
    }

    function findPrivlegeDetail(address addr, uint256 PrevId)
        public
        view
        returns (uint256, userUtility memory)
    {
        userUtility[] storage allUtility = UserUtilities[addr];
        for (uint256 i = 0; i < allUtility.length; i++) {
            if (
                allUtility[i].utilityId == PrevId &&
                !allUtility[i].transferred &&
                !allUtility[i].used
            ) {
                return (i, allUtility[i]);
            }
        }
        revert("Utility not found at address");
    }

    function findUtilityHolderIndex(
        address collectionAddress,
        address _holder,
        uint256 PrevId
    ) public view returns (uint256) {
        address[] memory holders = utilitiesInfo[collectionAddress][PrevId]
            .holders;
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == _holder) {
                return i;
            }
        }
        revert("Holder not found at Utilities");
    }

    function createUtility(
        address collectionAddress,
        string calldata name,
        bool expirable,
        uint256 expiryTime
    ) external {
        uint256 expiration;
        if (!expirable) {
            expiration = 0;
        } else {
            // expiration = block.timestamp + (expiryTime * 1 days);
            expiration = block.timestamp + (expiryTime + 2 minutes);
        }
        Utility memory newUtility = Utility({
            utilityId: utilityId,
            tokenId: 0,
            collectionAddress: collectionAddress,
            utilityName: name,
            holders: new address[](0), // initialize holders to an empty array
            collectionOwner: msg.sender,
            expirable: expirable,
            expiry: expiration
            // expiry: block.timestamp + expiryTime
        });
        utilitiesInfo[collectionAddress][utilityId] = newUtility;
        UtilitiesForCollection[collectionAddress].push(newUtility);
        emit UtilityCreated(utilityId, name, collectionAddress, msg.sender);
        utilityId++;
    }

    function claimUtility(
        address nftaddr,
        uint256 PrevId,
        uint256 tokenId
    ) public {
        // nft = IERC721(nftaddr);
        // require(nft.ownerOf(tokenId)==msg.sender,"Caller is not the owner of this NFT");
        uint256 UtilityId = utilitiesInfo[nftaddr][PrevId].utilityId;
        //uint256 UtilityId = UtilitiesForCollection[nftaddr][PrevId].id;
        require(
            utilitiesInfo[nftaddr][PrevId].collectionAddress != address(0),
            "Utility is not available"
        );
        require(UtilityId == PrevId, "Utility doesn't exist");
        if (utilitiesInfo[nftaddr][PrevId].expirable == true) {
            require(
                utilitiesInfo[nftaddr][PrevId].expiry >= block.timestamp,
                " Utility has been expired"
            );
        }

        require(
            UtilityForToken[nftaddr][tokenId][PrevId].utilityclaimed == false,
            " Utility has already claimed for this token Id"
        );
        utilitiesInfo[nftaddr][PrevId].holders.push(msg.sender);
        // utility.holders.push(msg.sender);
        string memory name = utilitiesInfo[nftaddr][PrevId].utilityName;
        bool expirable = utilitiesInfo[nftaddr][PrevId].expirable;
        userUtility memory uD = userUtility(
            PrevId,
            nftaddr,
            tokenId,
            name,
            0,
            false,
            false,
            expirable,
            false,
            msg.sender,
            utilitiesInfo[nftaddr][PrevId].expiry
        );
        UserUtilities[msg.sender].push(uD);
        UtilityForToken[nftaddr][tokenId][PrevId].tokenId = tokenId;
        UtilityForToken[nftaddr][tokenId][PrevId].collectionAddress = nftaddr;
        UtilityForToken[nftaddr][tokenId][PrevId].utilityclaimed = true;
        UtilityForToken[nftaddr][tokenId][PrevId].redeemedUtility = false;
        UtilityForToken[nftaddr][tokenId][PrevId].owner = msg.sender;
        UtilityForToken[nftaddr][tokenId][PrevId].expirable = expirable;
        UtilityForToken[nftaddr][tokenId][PrevId].expiry = utilitiesInfo[
            nftaddr
        ][PrevId].expiry;
        // UtilityForToken[nftaddr][tokenId][PrevId].utilityName = name;
        emit UtilityClaimed(PrevId, name, nftaddr, msg.sender);
    }

    function RedeemUtility(
        address collectionAddress,
        uint256 tokenId,
        uint256 PrevId
    ) public {
        require(
            UtilityForToken[collectionAddress][tokenId][PrevId].owner ==
                msg.sender,
            "msg.sender is not the owner of this utility"
        );
        require(
            UtilityForToken[collectionAddress][tokenId][PrevId]
                .redeemedUtility == false,
            "User utility has already been used"
        );
        if (
            UtilityForToken[collectionAddress][tokenId][PrevId].expirable ==
            true
        ) {
            require(
                UtilityForToken[collectionAddress][tokenId][PrevId].expiry >=
                    block.timestamp,
                "User utility has already been expired"
            );}

            UtilityForToken[collectionAddress][tokenId][PrevId]
                .redeemedUtility = true;

            emit UtilityRedemmed(collectionAddress,tokenId,PrevId,msg.sender);     
    }

    function TransferUtility(
        address collectionAddress,
        uint256 tokenId,
        uint256 PrevId,
        address receiver
    ) public {
        //receiver should not be the owner
        require(receiver != UtilityForToken[collectionAddress][tokenId][PrevId].owner, "Cannot transfer to self");
        require(receiver != address(0), "Please provide valid wallet address");
        // require(
        //     UtilityForToken[collectionAddress][tokenId][PrevId].owner ==
        //         msg.sender,
        //     "User Does not own this Utility Id"
        // );
        require (isDelegatorOrOwner(collectionAddress,tokenId,PrevId) == true , "Caller is not the owner or Delegator");
        require(
            UtilityForToken[collectionAddress][tokenId][PrevId]
                .redeemedUtility == false,
            "User utility has already been used"
        );
        if (
            UtilityForToken[collectionAddress][tokenId][PrevId].expirable ==
            true
        ) {
            require(
                UtilityForToken[collectionAddress][tokenId][PrevId].expiry >=
                    block.timestamp,
                "User utility has already been expired"
            );}
            UtilityForToken[collectionAddress][tokenId][PrevId]
                .owner = receiver;
            // UtilityForToken[collectionAddress][tokenId][PrevId]
            //     .transferred = true;
            emit UtilityTransferred(collectionAddress,tokenId,PrevId,receiver);
        
    }

    function setDelegator(address _delegator,address collectionAddress,uint256 tokenId,uint256 PrevId) public {
        require(UtilityForToken[collectionAddress][tokenId][PrevId]
                .owner== tx.origin, "Caller is not the owner");
        UtilityForToken[collectionAddress][tokenId][PrevId]
                .delegator=_delegator;

    }

    function isDelegatorOrOwner(address collectionAddress,uint256 tokenId,uint256 PrevId) public view returns (bool){
        if(UtilityForToken[collectionAddress][tokenId][PrevId]
                .delegator == msg.sender || UtilityForToken[collectionAddress][tokenId][PrevId]
                .owner== msg.sender){
                 return true;
                }

        else {
            return false;
        }
                
    }

    function ownerOf(address collectionAddress,uint256 tokenId,uint256 PrevId) public view returns (address owner){
        return UtilityForToken[collectionAddress][tokenId][PrevId]
                .owner;

    }

    
}