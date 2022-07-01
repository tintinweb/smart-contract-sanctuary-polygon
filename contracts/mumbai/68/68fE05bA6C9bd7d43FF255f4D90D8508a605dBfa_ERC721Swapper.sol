// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NFTSwapper.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721Swapper is NFTSwapper, IERC721Receiver{
  
    constructor() NFTSwapper() {}

    function ownerOf(address nft, uint256 tokenId) 
                        public view override returns (address){
        return IERC721(nft).ownerOf(tokenId);
    }

    function transferOwnership(address from, address nftAddress, uint256 tokenId, address to)
                                public override returns(bool){
         IERC721(nftAddress).safeTransferFrom(from, to, tokenId);
         return true;
    }
    function transferBatchOwnership(address from, address[] memory nftAddresses, uint256[] memory tokenIds, address to)
                                public override returns(bool){
        require(nftAddresses.length == tokenIds.length, "ERC721Exchange: transferBatchOwnership: different length");
        for(uint256 i=0; i<nftAddresses.length; i++){
            IERC721(nftAddresses[i]).safeTransferFrom(from, to, tokenIds[i]); 
        } 
         return true;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
                                public pure override returns (bytes4) {
        operator; from; tokenId; data;
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title NFTSwapper
 * Peer to peer swap of multiple NFT.  
 * @author Daniel Gonzalez Abalde aka @DGANFT aka DaniGA#9856.
 * @dev Inherits from this contract for each NFT type. 
 */
abstract contract NFTSwapper is Context
{
    using Counters for Counters.Counter;  

    enum SwapState{ Pending, Deposited, Claimed, Cancelled }
    event SwapStateChanged(uint256 swapId, SwapState state);

    struct Swap{
        uint256 Id;
        SwapState StateA; address OwnerA; address[] NFTContractA; uint256[] tokenIdsA;
        SwapState StateB; address OwnerB; address[] NFTContractB; uint256[] tokenIdsB;      
    }
 
    mapping(uint256=>Swap) private _swaps;
    mapping(address=>uint256[]) private _members; 
    Counters.Counter private _idCounter; 

    constructor() {}

    // ############################  ABSTRACT METHODS ############################
 
    function ownerOf(address nft, uint256 tokenId) public view virtual returns (address);

    function transferOwnership(address from, address nftAddress, uint256 tokenId, address to) public virtual returns(bool);

    function transferBatchOwnership(address from, address[] memory nftAddresses, uint256[] memory tokenIds, address to) public virtual returns(bool);

    // ############################  MODIFIER METHODS ############################
 
    modifier onlyOwnerOf(address account, address[] memory nftAddresses, uint256[] memory tokenIds){
        require(nftAddresses.length == tokenIds.length, "NFTSwapper: onlyOwnerOf: different length");
        for(uint256 i=0; i<nftAddresses.length; i++){
            require(ownerOf(nftAddresses[i], tokenIds[i]) == account, "NFTSwapper: onlyOwnerOf: not the owner");
        }
        _;
    }
    modifier onlyParticipant(uint256 swapId, address account){
        require(_swaps[swapId].OwnerA == account || _swaps[swapId].OwnerB == account, "NFTSwapper: onlyParticipant");
        _;
    }
    modifier existsSwapId(uint256 swapId){
        require(_swaps[swapId].Id > 0, "NFTSwapper: swapId does not exist");
        _;
    }
   
    // ############################  PUBLIC METHODS ############################
 
    /**
    * @dev Register a new swap. This does not transfer any NFT.
    * @param ownerA the address of participant A. 
    * @param nftAddressesA the NFT contracts swapd by participant A.
    * @param tokenIdsA the NFT token id swapd by participant A.
    * @param ownerB the address of participant B. 
    * @param nftAddressesB the NFT contracts swapd by participant B.
    * @param tokenIdsB the NFT token id swapd by participant B.
    * @return swapId the swap id. 
    */
    function register(address ownerA, address[] memory nftAddressesA, uint256[] memory tokenIdsA,
                      address ownerB, address[] memory nftAddressesB, uint256[] memory tokenIdsB) 
                        onlyOwnerOf(ownerA, nftAddressesA, tokenIdsA) 
                        onlyOwnerOf(ownerB, nftAddressesB, tokenIdsB) 
                        public returns (uint256 swapId)
    { 
      require(ownerA != ownerB, "NFTSwapper: register: same owner");
        _idCounter.increment();
        swapId = _idCounter.current();
        _swaps[swapId] = Swap(swapId, SwapState.Pending, ownerA, nftAddressesA, tokenIdsA, SwapState.Pending, ownerB, nftAddressesB, tokenIdsB);
        _members[ownerA].push(swapId);
        _members[ownerB].push(swapId);
        emit SwapStateChanged(swapId, SwapState.Pending);
        return swapId;
    }  
    /**
    * @dev If the swap has not yet taken place, it is irrevocably marked as a cancelled swap and the NFTs are returned to their original owners.
    * @param swapId the swap id. 
    */
    function cancel(uint256 swapId)
                    existsSwapId(swapId) 
                    onlyParticipant(swapId, _msgSender()) public {
        Swap memory e = _swaps[swapId]; 
        require(e.StateA != SwapState.Cancelled && e.StateB != SwapState.Cancelled, "NFTSwapper: state is already cancelled");
        e.StateA = SwapState.Cancelled;
        e.StateB = SwapState.Cancelled;
        _swaps[swapId] = e;
        address thisContract = address(this);
        for(uint256 i=0; i<e.NFTContractA.length; i++){
            if(ownerOf(e.NFTContractA[i], e.tokenIdsA[i]) == thisContract){
                transferOwnership(thisContract, e.NFTContractA[i], e.tokenIdsA[i], e.OwnerA);
            }
        }
        for(uint256 i=0; i<e.NFTContractB.length; i++){
            if(ownerOf(e.NFTContractB[i], e.tokenIdsB[i]) == thisContract){
                transferOwnership(thisContract, e.NFTContractB[i], e.tokenIdsB[i], e.OwnerB);
            }
        }
        emit SwapStateChanged(swapId, SwapState.Cancelled);
    }
    /**  
    * @dev Temporarily deposit the NFTs in this contract in a specific swap.
    * @param swapId the swap id. 
    * @param nftAddresses the NFT contracts swapd by participant .
    * @param tokenIds the NFT token id swapd by participant.
    * Note that nftAddresses and tokenIds parameters are redundant since they are already stored on-chain, 
    * but in this way the depositor has certainty that the swap will be carried out with the expected NFTs.
    */
    function deposit(uint256 swapId, address[] memory nftAddresses, uint256[] memory tokenIds)      
                    onlyOwnerOf(_msgSender(), nftAddresses, tokenIds)
                    existsSwapId(swapId)
                    public returns (bool deposited){
        Swap memory e = _swaps[swapId]; 
        if(e.OwnerA == _msgSender()){
            require(e.StateA == SwapState.Pending, "NFTSwapper: deposit: state is not pending"); 
            require(e.NFTContractA.length == nftAddresses.length, "NFTSwapper: deposit: different length");
            for (uint256 i=0; i<e.NFTContractA.length; i++){
                require(e.NFTContractA[i] == nftAddresses[i], "NFTSwapper: deposit: different NFT contract");
                require(e.tokenIdsA[i] == tokenIds[i], "NFTSwapper: deposit: different token id");
            }
            require(transferBatchOwnership(e.OwnerA, e.NFTContractA, e.tokenIdsA, address(this)), "NFTSwapper: deposit: transfer ownership failed");
            e.StateA = SwapState.Deposited;
            _swaps[swapId] = e;
            emit SwapStateChanged(swapId, SwapState.Deposited);
            deposited = true; 
        }else if(e.OwnerB == _msgSender()){
            require(e.StateB == SwapState.Pending, "NFTSwapper: deposit: state is not pending"); 
            require(e.NFTContractB.length == nftAddresses.length, "NFTSwapper: deposit: different length");
            for (uint256 i=0; i<e.NFTContractB.length; i++){
                require(e.NFTContractB[i] == nftAddresses[i], "NFTSwapper: deposit: different NFT contract");
                require(e.tokenIdsB[i] == tokenIds[i], "NFTSwapper: deposit: different token id");
            }
            require(transferBatchOwnership(e.OwnerB, e.NFTContractB, e.tokenIdsB, address(this)), "NFTSwapper: deposit: operation failed");
            e.StateB = SwapState.Deposited;
            _swaps[swapId] = e;
            emit SwapStateChanged(swapId, SwapState.Deposited);
            deposited = true; 
        }
        deposited = false;
    }
    
    /**
    * @dev Claims completion of a swap. 
    * If both participants have deposit their NFTs, the first to claim trigger the swap and the NFTs are sent to their new owners.
    * @param swapId the swap identifier. 
    */
    function claim(uint256 swapId)
                    existsSwapId(swapId)
                    onlyParticipant(swapId, _msgSender())
                    public
    {
        Swap memory e = _swaps[swapId]; 
        require(e.StateA == SwapState.Deposited, "NFTSwapper: claim: state A is not deposited");
        require(e.StateB == SwapState.Deposited, "NFTSwapper: claim: state B is not deposited");
        require(transferBatchOwnership(address(this), e.NFTContractB, e.tokenIdsB, e.OwnerA), "NFTSwapper: claim: contract to A failed");
        e.StateA = SwapState.Claimed;
        require(transferBatchOwnership(address(this), e.NFTContractA, e.tokenIdsA, e.OwnerB), "NFTSwapper: claim: contract to B failed");
        e.StateB = SwapState.Claimed;
        _swaps[swapId] = e;
        emit SwapStateChanged(swapId, SwapState.Claimed);
    }
    /**
    * @dev Get the state of a swap.
    * @param swapId the swap identifier. 
    */
    function getState(uint256 swapId) existsSwapId(swapId) public view returns (SwapState){  
        Swap memory e = _swaps[swapId];
        if(e.StateA == SwapState.Claimed && e.StateB == SwapState.Claimed){
            return SwapState.Claimed;
        }
        if(e.StateA == SwapState.Pending || e.StateB == SwapState.Pending){
            return SwapState.Pending;
        }
        if(e.StateA == SwapState.Deposited && e.StateB == SwapState.Deposited){
            return SwapState.Deposited;
        }
        if(e.StateA == SwapState.Cancelled || e.StateB == SwapState.Cancelled){
            return SwapState.Cancelled;
        }
        return SwapState.Pending;
    }
    /**
    * @dev Get the swaps of the sender account. 
    */
    function getSwaps() public view returns(uint256[] memory){
        return _members[_msgSender()];
    }
    /**
    * @dev Get a swap of the sender account. 
    */
    function getSwap(uint256 swapId)
          onlyParticipant(swapId, _msgSender())
          public view returns(Swap memory){ 
        return _swaps[swapId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
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