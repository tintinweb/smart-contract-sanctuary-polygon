/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

//SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: contracts/libraries/stakeLib.sol

pragma solidity ^0.8.7;


// import "hardhat/console.sol";

library StakeLib {

    event Rewarded(address staker, uint256 amount);

    function bal(address query, address minter) internal view returns (uint16){
        return uint16(IERC721(minter).balanceOf(query));
    }

    function owns(uint256 tokenID,address minter) internal view {
        address owner = ownerOf(tokenID, minter);
        // console.log("Sender " , msg.sender);
        // console.log("Owner ", owner);
        require(msg.sender == owner , "Err");
    }

    function ownsMul(uint256[] memory tokenIDs, address minter) internal view {
        for(uint8 i =0; i< tokenIDs.length; i++){
            require(ownerOf(tokenIDs[i], minter) == msg.sender, "Err");
        }
    }

    function ownerOf(uint256 tokenId, address minter) internal view returns(address) {
        return IERC721(minter).ownerOf(tokenId);
    }

    function getTokensStaked() internal view returns(uint256[] memory tokenIds){
        //get list of tokens that msg.sender holds
        //check which of these tokens are staked
        //add staked tokens to an []
        //return tokens 
    }

    function getApprovalForOne(uint256 tokenId, address minter) internal {
        IERC721(minter).approve(address(this), tokenId);
    }

    function getApprovalForMul(uint256[] memory tokenIds, address minter) internal {
        for(uint8 i = 0; i< tokenIds.length; i++){
            IERC721(minter).approve(address(this), tokenIds[i]);
        }
    }

    function bringHere(uint256 tokenId, address minter) internal {
        IERC721(minter).safeTransferFrom(ownerOf(tokenId, minter), address(this), tokenId);
    }

    function bringHereMul(uint256[] memory tokenIds, address minter) internal {
        for(uint8 i = 0; i< tokenIds.length; i++){
            IERC721(minter).safeTransferFrom(ownerOf(tokenIds[i], minter), address(this), tokenIds[i]);
        }
    }

    function sendBack(uint256 tokenId, address minter, address to) internal {
        IERC721(minter).safeTransferFrom(address(this), to, tokenId);
    }

    function sendBackMul(uint256[] memory tokenIds, address minter, address to) internal {
        for(uint8 i = 0; i< tokenIds.length; i++){
            IERC721(minter).safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }

    function removeApprovalForOne(uint256 tokenId, address minter) internal {
        IERC721(minter).approve(address(0x0), tokenId);
    }

    function removaApprovalForMul(uint256[] memory tokenIds, address minter) internal {
        for(uint8 i = 0; i< tokenIds.length; i++){
            IERC721(minter).approve(address(0x0), tokenIds[i]);
        }
    }

    function calculate(uint256 reward, uint256 noOfBlocks) internal pure returns(uint256){
        return reward * noOfBlocks;
    }

    function payout(address to, uint256 amount, address g4n9, address from) internal {
        IERC20(g4n9).transferFrom(from, to, amount); 
        emit Rewarded(to, amount);   
    }
} 
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: contracts/stake.sol

pragma solidity ^0.8.7;






contract Stake is ERC721Holder, ReentrancyGuard {

    event Staked(address staker, uint256 tokenId);
    event Unstaked(address staker, uint256 tokenId);
    event Rewarded(address staker, uint256 amount);
    event NewAdmin(address newAdmin);
    
    struct Tx {
        address staker;
        uint32 blockStaked;
    }

    mapping(uint256 => Tx) private stakeDetails;

    mapping(uint256 => bool) private currentlyStaked;

    uint256 private rewardAmountPerBlock = 12731717254023;

    address private minter;
    address private g4n9;
    address private admin;

    mapping(address => uint16) private noStaked;

    address[] private haveStaked;
    uint32 private index;
    uint16 private totalStaked;

    constructor(
        address _minter,
        uint256 _reward,
        address _g4n9
    ) {
        index=0;
        g4n9 = _g4n9;
        minter = _minter;
        rewardAmountPerBlock = _reward;
        totalStaked = 0;
        admin = msg.sender;
    }

    modifier onlyAdmin{
        require(msg.sender == admin, "NA");
        _;
    }

    function getallStaked() external view returns(address[] memory){
        return haveStaked;
    }

    function getNoStaked(address query) external view returns(uint16){
        return noStaked[query];
    }


    //change reward amount
    function changeReward(uint256 _reward) external onlyAdmin {
        rewardAmountPerBlock = _reward;
    }

    //change admin address
    function changeAdmin(address _new) external onlyAdmin {
        admin = _new;
        emit NewAdmin(_new);
    }

    function hasStaked() internal view returns(bool){
        for(uint32 i = 0; i< haveStaked.length; i++ ){
            if(haveStaked[i] == msg.sender){
                return true;
            }
        }
        return false;
    }

    //withdraw remaining $g4n9 from contract
    function withdraw() external onlyAdmin {
        uint256 bal = IERC20(g4n9).balanceOf(address(this));
        IERC20(g4n9).transferFrom(address(this), admin, bal);
    } 


    //stake 1
    function stake (uint256 tokenId) external nonReentrant {
        //check that NFT is not already staked
        require(!currentlyStaked[tokenId]);

        //check that msg.sender == owner of tokenID to be staked
        StakeLib.owns(tokenId, minter);

        if(!hasStaked()){
            haveStaked.push(msg.sender);
            index+=1;
        }
    
        //transfer token to this address
        StakeLib.bringHere(tokenId, minter);
        totalStaked++;

        //insert Tx
        stakeDetails[tokenId].staker = msg.sender;
        stakeDetails[tokenId].blockStaked = uint32(block.number);
        
        //add to currently staked
        currentlyStaked[tokenId] = true;

        noStaked[msg.sender]+=1;

        emit Staked(msg.sender, tokenId);
    }

    //stake multiple
    function stakeMul(uint256[] memory tokenIds) external nonReentrant{
        //check array size
        require(tokenIds.length <= 40,"limit");
        
        //check that NFTs are not already staked
        for(uint8 i = 0; i< tokenIds.length; i++){
            require(!currentlyStaked[tokenIds[i]],"alreadyStaked");
        }

        //check that msg.sender == owner of all tokenIDs to be staked
        StakeLib.ownsMul(tokenIds, minter);

        if(!hasStaked()){            
            haveStaked.push(msg.sender);
            index+=1;
        }

        //transfer tokens to this address
        StakeLib.bringHereMul(tokenIds, minter);

        totalStaked+=uint16(tokenIds.length);


        //insert Txs
        for(uint8 i = 0; i< tokenIds.length; i++){
            stakeDetails[tokenIds[i]].staker = msg.sender;
            stakeDetails[tokenIds[i]].blockStaked = uint32(block.number);
         
            //add to currentlyStaked map
            currentlyStaked[tokenIds[i]] = true;
            emit Staked(msg.sender, tokenIds[i]);
        }

        noStaked[msg.sender]+=uint16(tokenIds.length);

    }

    //unstake 1
    function unstake(uint256 tokenId) external nonReentrant{
        //check that NFT is staked
        require(currentlyStaked[tokenId], "Not Staked");

        //check that msg.sender == owner of tokenID to be unstaked
        // StakeLib.owns(tokenId, minter);
        require(msg.sender == stakeDetails[tokenId].staker,"NS");


        //remove from currently staked
        currentlyStaked[tokenId] = false;

        //transfer token from this address
        StakeLib.sendBack(tokenId, minter, stakeDetails[tokenId].staker);

        totalStaked--;


        //remove approval of NFT
        // StakeLib.removeApprovalForOne(tokenId, minter);

        //payout
        StakeLib.payout(stakeDetails[tokenId].staker, StakeLib.calculate(rewardAmountPerBlock, block.number - stakeDetails[tokenId].blockStaked), g4n9, admin);

        //remove Tx
        delete stakeDetails[tokenId];

        noStaked[msg.sender]-=1;


        emit Unstaked(msg.sender, tokenId);

    }

    //unstake multiple
    function unstakeMul(uint256[] memory tokenIds) external nonReentrant{
        require(tokenIds.length <= 40);//not sure if 10 is too many will have to check

        //setting reusable counter here
        uint8 i = 0;

        //check that NFTs are staked
        for(; i< tokenIds.length; i++){
            require(currentlyStaked[tokenIds[i]]);
        }

        //check that msg.sender == owner of all tokenIDs to be unstaked
        require(staked(msg.sender, tokenIds));

        //reset counter
        i = 0;

        //remove from currently staked
        for(; i< tokenIds.length; i ++){
            currentlyStaked[tokenIds[i]] = false;
        }

        //transfer tokens from this address
        StakeLib.sendBackMul(tokenIds, minter, stakeDetails[tokenIds[0]].staker);

        totalStaked-=uint16(tokenIds.length);

        //remove approval of NFT
        // StakeLib.removaApprovalForMul(tokenIds, minter);

        //payout
        StakeLib.payout(stakeDetails[tokenIds[0]].staker, StakeLib.calculate(rewardAmountPerBlock, calculateTotal(tokenIds)), g4n9, admin);

        //reset counter
        i = 0;

        //remove Txs
        for(; i< tokenIds.length; i++){
            delete stakeDetails[tokenIds[i]];
            
            emit Unstaked(msg.sender, tokenIds[i]);
        }

        noStaked[msg.sender]-=uint16(tokenIds.length);


    }

    function staked(address query, uint256[] memory tokens) internal view returns(bool){
        for(uint8 i =0; i< tokens.length; i++){
            if(stakeDetails[tokens[i]].staker != query){
                return false;
            }
        }
        return true;
    }

    function calculateTotal(uint256[] memory tokenIds) internal view returns(uint256 total) {
        for(uint8 i = 0; i<tokenIds.length; i++){
            total += (block.number - stakeDetails[tokenIds[i]].blockStaked);
        }
    }

    //claim
    function claim() external nonReentrant{
        //get list of tokens msg.sender has staked
        uint256[] memory tokens = getTokensStaked(msg.sender);

        //check that msg.sender is a staker
        require(tokens.length != 0);

        //calculate the total reward due
        uint256 amount = rewardAmountPerBlock * calculateTotal(tokens);

        //set the tokens blockStaked to now
        for(uint16 i = 0; i < tokens.length; i++){
            stakeDetails[tokens[i]].blockStaked = uint32(block.number);
        }

        //payout to msg.sender
        StakeLib.payout(msg.sender, amount, g4n9, admin);
    }

    //get tokens staked
    function getTokensStaked(address query) public view returns(uint256[] memory) {
        uint16 counter =0;
        uint256[] memory tokens = new uint256[](noStaked[query]);
        for(uint16 i =1; i<=10000; i++){
            if(stakeDetails[i].staker == query){
                tokens[counter] = i;
                counter ++;
            }
        }
        return tokens;
    }

    function getTotalPayout(address query) external view returns(uint256){
        uint16 counter =0;
        uint256[] memory tokens = new uint256[](noStaked[query]);
        for(uint16 i =1; i<=10000; i++){
            if(stakeDetails[i].staker == query){
                tokens[counter] = i;
                counter ++;
            }
        }
        uint256 result=0;
        for(uint16 i = 0; i< tokens.length; i++){
            result += (block.number - stakeDetails[tokens[i]].blockStaked) * rewardAmountPerBlock;
        }
        return result;
    }

    function getAddresses() external view returns(address[] memory){
        return haveStaked;
    }

    function getIndex() external view returns(uint32){
        return index;
    }
    
    function getTotalStaked() external view returns(uint16){
        return totalStaked;
    }



}