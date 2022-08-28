/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin\contracts\token\ERC721\utils\ERC721Holder.sol


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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin\contracts\utils\Context.sol


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

// File: @openzeppelin\contracts\access\Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts\satkev2.sol


pragma solidity ^0.8.16;
contract UnderworldConnection is  Ownable, ERC721Holder {


    uint256 public numberOfBlocksPerRewardUnit;
    uint256 public amountOfStakers;
    uint256 public tokensStaked;
    uint256 immutable public contractCreationBlock;
    IERC20 public TokenExchange;
    IERC20 public TokenReward;
    struct StakeInfo {
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        address AddColle;
        bool currentlyStaked;
        uint256[] Trait;

    }

    struct CollectionInfo {
        bool isActive;
        uint256 reward;
        address AddCollection;
        uint256[] _id;
    }

    struct _traitSpecial {
        uint256 trait1;
        uint256 trait2;
        uint256 trait3;

    }

    /// owner => tokenId => StakeInfo
    //mapping (address =>  mapping(uint256 => StakeInfo)) public stakeLog;

    mapping (address => mapping(address => mapping(uint256 => StakeInfo))) public stakeLog;

    //colecciton->id->owner
    mapping (address => mapping(uint256 => address)) public ownerId;

    /// owner => #NFTsStaked
    mapping (address => uint256) public tokensStakedByUser;

    mapping (address => uint256) public pointUser;

    /// owner and collection => list of all tokenIds that the user has staked
    mapping (address =>  mapping (address =>  uint256[])) public stakePortfolioByUser;
    /// tokenId => indexInStakePortfolio
    mapping(address => mapping (uint256 =>  uint256)) public indexOfTokenIdInStakePortfolio;
    //
    mapping (address => CollectionInfo) public AddressCollection;
    mapping (address => _traitSpecial) public traitSpecial;

    //mapping (address => nftUserInfo) public UserInfo;


    event RewardsHarvested (address owner, uint256 amount);
    event NFTStaked (address owner, uint256 tokenId);
    event NFTUnstaked (address owner, uint256 tokenId);

    constructor( IERC20 _TokenExchange, IERC20 _TokenReward ){
        TokenExchange = _TokenExchange;
        TokenReward = _TokenReward;
        contractCreationBlock = block.number;
        //coinAmountPerRewardUnit = 400 * 10 ** 18; // 10 ERC20 coins per rewardUnit, may be changed later on
        numberOfBlocksPerRewardUnit = 1; // 12 hours per reward unit , may be changed later on
     }

    function stakedNFTSByUser(address owner, address _collection) external view returns (uint256[] memory){
        return stakePortfolioByUser[owner][_collection];
    }


    function pendingRewards(address owner, uint256 tokenId, address _collection) public view returns (uint256){
        StakeInfo memory info = stakeLog[owner][_collection][tokenId];
        CollectionInfo memory infoC = AddressCollection[_collection];
        _traitSpecial memory _trait = traitSpecial[_collection];
        uint256 TotalRewards;
        uint256 SpeciaRewards;
        uint256 coin = 0;
        if(info.lastHarvestBlock < contractCreationBlock || info.currentlyStaked == false) {
            return 0;
        }
        uint256 blocksPassedSinceLastHarvest = block.number - info.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnit * 2) {
            return 0;
        }

        uint256 rewardAmount = blocksPassedSinceLastHarvest / numberOfBlocksPerRewardUnit - 1;
        TotalRewards = rewardAmount * infoC.reward;
        for(uint256 i = 0; i < info.Trait.length; i++){
            if( info.Trait[i] == _trait.trait1  ){
                    coin += 1;
            }
            if(info.Trait[i] == _trait.trait2){
                    coin += 1;

            }
            if( info.Trait[i] == _trait.trait3){
                    coin += 1;
                
            }
        }

        if(coin == 1){
            SpeciaRewards =  (TotalRewards * 50) / 100;
        }if(coin == 2){
            SpeciaRewards =  (TotalRewards * 150) / 100;
        }if(coin == 3){
            SpeciaRewards =  (TotalRewards * 200) / 100;
        }


        return TotalRewards + SpeciaRewards;

    }


    function _SpecialTrait1(address owner, uint256 tokenId, address _collection) public view returns (uint256){
        StakeInfo memory info = stakeLog[owner][_collection][tokenId];
        
        _traitSpecial memory _trait = traitSpecial[_collection];

        uint256 coin = 0;
        uint256 trait = 0;

        for(uint256 i = 0; i < info.Trait.length; i++){
         
            if( info.Trait[i] == _trait.trait1  ){
                    coin += 1;
            }
            if(info.Trait[i] == _trait.trait2){
                    coin += 1;

            }
            if( info.Trait[i] == _trait.trait3){
                    coin += 1;
                
            }
    
        }
        if(coin >= 1){
            trait = 1;
        }else{
            trait = 0;
        }



        return trait;

    }
    function SpecialTrait1(address _collection) public view returns (uint256){
       
        uint256 trait;
        CollectionInfo memory infoC = AddressCollection[_collection];

        require(infoC.isActive == true, "Collection does not exist");
        for(uint256 currentId = 0; currentId < infoC._id.length; currentId++){

          trait += _SpecialTrait1(ownerId[_collection][infoC._id[currentId]], infoC._id[currentId], _collection);
        }

        return trait;

    }



    function _SpecialTrait2(address owner, uint256 tokenId, address _collection) public view returns (uint256){
        StakeInfo memory info = stakeLog[owner][_collection][tokenId];
        
        _traitSpecial memory _trait = traitSpecial[_collection];
        uint256 coin = 0;
        uint256 trait = 0;

        for(uint256 i = 0; i < info.Trait.length; i++){
         
            if( info.Trait[i] == _trait.trait1  ){
                    coin += 1;
            }
            if(info.Trait[i] == _trait.trait2){
                    coin += 1;

            }
            if( info.Trait[i] == _trait.trait3){
                    coin += 1;
                
            }
    
        }
        if(coin >= 2){
            trait = 1;
        }else{
            trait = 0;
        }
        

        return trait;

    }
    function SpecialTrait2(address _collection) public view returns (uint256){
       
        uint256 trait;
        CollectionInfo memory infoC = AddressCollection[_collection];
        
        require(infoC.isActive == true, "Collection does not exist");
        for(uint256 currentId = 0; currentId < infoC._id.length; currentId++){

          trait += _SpecialTrait2(ownerId[_collection][infoC._id[currentId]], infoC._id[currentId], _collection);
        }

        return trait;

    }

    function _SpecialTrait3(address owner, uint256 tokenId, address _collection) public view returns (uint256){
        StakeInfo memory info = stakeLog[owner][_collection][tokenId];
        
        _traitSpecial memory _trait = traitSpecial[_collection];

        uint256 trait = 0;
        uint256 coin = 0;

        for(uint256 i = 0; i < info.Trait.length; i++){
         
            if( info.Trait[i] == _trait.trait1  ){
                    coin += 1;
            }
            if(info.Trait[i] == _trait.trait2){
                    coin += 1;

            }
            if( info.Trait[i] == _trait.trait3){
                    coin += 1;
                
            }
    
        }
        if(coin >= 3){
            trait = 1;
        }else{
            trait = 0;
        }

        return trait;

    }
    function SpecialTrait3(address _collection) public view returns (uint256){
       
        uint256 trait;
        CollectionInfo memory infoC = AddressCollection[_collection];

        require(infoC.isActive == true, "Collection does not exist");
        for(uint256 currentId = 0; currentId < infoC._id.length; currentId++){

          trait += _SpecialTrait3(ownerId[_collection][infoC._id[currentId]], infoC._id[currentId], _collection);
        }

        return trait;

    }


    function SaveRewards(address owner, uint256 tokenId, address _collection)public  returns (bool){
        StakeInfo storage info = stakeLog[owner][_collection][tokenId];
        CollectionInfo memory infoC = AddressCollection[_collection];

        require(infoC.isActive == true, "Collection does not exist");

        uint256 reward = pendingRewards(owner, tokenId, _collection);
        info.lastHarvestBlock = block.number;
        pointUser[owner] = reward + pointUser[owner];
        return true;

    }
    function payEverything(address owner, uint256 tokenId, address _collection) internal {
       StakeInfo storage info = stakeLog[owner][_collection][tokenId];

       uint256 _reward = pendingRewards(owner, tokenId, _collection);

       TokenReward.transfer(msg.sender, pointUser[owner]+_reward);

       info.lastHarvestBlock = block.number;
       pointUser[owner] = 0;
    }

    function AllSavePoint( address _collection )public returns(bool){

        CollectionInfo memory infoC = AddressCollection[_collection];

        require(infoC.isActive == true, "Collection does not exist");
        for(uint256 currentId = 0; currentId < infoC._id.length; currentId++){

            SaveRewards(ownerId[_collection][infoC._id[currentId]], infoC._id[currentId], _collection);
        }

        return true;
    }

    function Isdueno(address add, uint256 _id)public view returns (address){

        return ownerId[add][_id];
    }

    function stake(uint256 tokenId, address _collection,uint256[] memory _trait)  public returns (bool){

        CollectionInfo storage infoC = AddressCollection[_collection];

        require(infoC.isActive == true,
            "Collection does not exist");



       require(IERC721(_collection).ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");


       IERC721(_collection).safeTransferFrom(msg.sender, address(this), tokenId);

        require(IERC721(_collection).ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");

        TokenExchange.transfer(msg.sender, 1 ether);
        StakeInfo storage info = stakeLog[_msgSender()][_collection][tokenId];

        ownerId[_collection][tokenId] = msg.sender;
        infoC._id.push(tokenId);
        info.AddColle = _collection;
        info.stakedAtBlock = block.number;
        info.lastHarvestBlock = block.number;
        info.currentlyStaked = true;
        for(uint256 i = 0; i < _trait.length; i++){
            info.Trait.push(_trait[i]);
        }

        if(tokensStakedByUser[_msgSender()] == 0){
            amountOfStakers += 1;
        }
        tokensStakedByUser[_msgSender()] += 1;
        tokensStaked += 1;
        stakePortfolioByUser[_msgSender()][_collection].push(tokenId);
        uint256  indexOfNewElement = stakePortfolioByUser[_msgSender()][_collection].length - 1;
        indexOfTokenIdInStakePortfolio[_collection][tokenId] = indexOfNewElement;


        // if(!welcomeBonusCollected[tokenId]) {
        //     _mint(_msgSender(), welcomeBonusAmount);
        //     welcomeBonusCollected[tokenId] = true;
        // }

        emit NFTStaked(_msgSender(), tokenId);
        return true;
    }

    function unstake(uint256 tokenId, address _collection) public {
        if(pendingRewards(_msgSender(), tokenId, _collection) > 0){
            harvest(tokenId, _collection);
        }
        StakeInfo storage info = stakeLog[_msgSender()][_collection][tokenId];
        info.currentlyStaked = false;
        IERC721(_collection).safeTransferFrom(address(this), _msgSender(), tokenId);
        
        TokenExchange.transferFrom(_msgSender(),  address(this), 1 ether);
        require(IERC721(_collection).ownerOf(tokenId) == _msgSender(),
            "SPCC: Error while transferring token");
        if(tokensStakedByUser[_msgSender()] == 1){
            amountOfStakers -= 1;
        }
        tokensStakedByUser[_msgSender()] -= 1;
        tokensStaked -= 1;
        stakePortfolioByUser[_msgSender()][_collection][indexOfTokenIdInStakePortfolio[_collection][tokenId]] = 0;
        emit NFTUnstaked(_msgSender(), tokenId);
    }

    function harvest(uint256 tokenId, address _collection) public {

        uint256 rewardAmountInERC20Tokens = pendingRewards(_msgSender(), tokenId, _collection) + pointUser[_msgSender()];
        if(rewardAmountInERC20Tokens > 0) {
            payEverything(_msgSender(), tokenId, _collection);
            emit RewardsHarvested(_msgSender(), rewardAmountInERC20Tokens);
        }
    }

    function harvestBatch(address user, address _collection) external {
        uint256[] memory tokenIds = stakePortfolioByUser[user][_collection];

        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            harvest(tokenIds[currentId], _collection);
        }
    }

    // ADMIN / SETTER FUNCTIONS
    function setNumberOfBlocksPerRewardUnit(uint256 numberOfBlocks) external onlyOwner{
        numberOfBlocksPerRewardUnit = numberOfBlocks;
    }

    function setIdCollection(address _collection) public view returns( uint256[] memory){
        CollectionInfo memory infoC = AddressCollection[_collection];

        return infoC._id;

    }
    function setCollection(address _collection, uint256 reward)public onlyOwner{
        CollectionInfo storage infoC = AddressCollection[_collection];
        infoC.isActive = true;
        infoC.reward = reward * 10 ** 18;
        infoC.AddCollection = _collection;
    }

    function setTraitSpecial(address _collection ,uint256 _trait1, uint256 _trait2, uint256 _trait3)public onlyOwner{
        _traitSpecial storage traits = traitSpecial[_collection];
        traits.trait1 = _trait1;
        traits.trait2 = _trait2;
        traits.trait3 = _trait3;
    }

    function setTokenExchangeAddress(IERC20 newAddress) external onlyOwner{
       // require (newAddress != address(0), "update to zero address not possible");
        TokenExchange = newAddress;
    }

    function setTokenRewardAddress(IERC20 newAddress) external onlyOwner{
       // require (newAddress != address(0), "update to zero address not possible");
        TokenReward = newAddress;
    }

}