/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// File: Precious Capital/NftStake.sol



pragma solidity ^0.8.6;






interface IERC1155{
    struct nftSale{
        uint tokenId;
        uint price;
        bool status;
        bool bought;
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function existTokenId(
        uint _id
    ) external view returns(bool);

    function getNftSaleData(
        uint _id
    ) external view returns(nftSale memory data);
}


interface ICO{
    function getConversion_AcceptedToken_To_DefaultToken(uint _amount) external view returns(uint _total);
}

contract StakeContract is Ownable, ReentrancyGuard, ERC1155Holder {
    uint MAX_VALUE = (2 ** 256) - 1;
    // nfts contract address 
    address public nfts;

    // the token address to be used for pay rewards
    address public rewardToken;

   // the token address to be used for pay rewards
    address public icoContract;

    // address with balance to be used to pay rewards
    address public rewardWallet;

    // minimum stake time in seconds
    uint256 public MST;

    // nft sale address used to put price of the nft in stake
    address public nftSaleAddress;

    // struct of nftsale data in Sale Contract
     struct nftSale{
        uint tokenId;
        uint price;
        bool status;
        bool bought;
    }

    // the Stake
    struct Stake {
        // stake Type
        uint256 stakeTypeIndex;
        // opening timestamp
        uint256 startDate;
        // amount staked
    	uint256 amount;
        // is active or not
    	bool active;
        // total of the Nft(s) value
        uint valueStake; 
    }

    // the StakeType
    struct StakeType {
        uint256 tokenId;
        uint256 apy; // Annual Percentage Yield (1=1%)
        uint256 PCSUnitPrice;
    	bool status; // true=actived, false=disabled
    }

    // stakes of address
    mapping(address => Stake[50]) public stakesOf;

    // stake Type List
    StakeType[] public stakeTypeList;

    event Set_TokenContracts(
        address rewardToken,
        address nfts,
        address nftsAddress,
        address icoContract
    );

    event Set_RewardWallet(
        address rewardWallet
    );

    event Set_MST(
        uint256 MST
    );

    event Set_StakeType(
        uint256 index,
        uint256 indexed tokenId,
        uint256 apy,
        uint256 PCSUnitPrice,
        bool status
    );

    event AddedStake(
        uint256 stakeTypeIndex,
        uint256 indexed tokenId,
        uint256 startDate,
        uint256 amount,
        address indexed ownerStake
    );

    event WithdrawStake(
        uint256 _withdrawType,
        uint256 stakeTypeIndex,
        uint256 indexed tokenId,
        uint256 startDate,
        uint256 withdrawDate,
        uint256 interest,
        uint256 amount,
        address indexed ownerStake
    );

    constructor(address _rewardToken, address _nfts, address _nftSaleAddress, address _icoContract) {
        setTokenContracts(_rewardToken, _nfts, _nftSaleAddress, _icoContract);
        setRewardWallet(owner());
        setMST(2592000); // 30 days in seconds

    }

    function setTokenContracts(address _rewardToken, address _nfts, address _nftSaleAddress, address _icoContract) public onlyOwner {
        rewardToken = _rewardToken;
        nfts = _nfts;
        nftSaleAddress = _nftSaleAddress;
        icoContract = _icoContract;
        emit Set_TokenContracts(_rewardToken, _nfts, _nftSaleAddress, _icoContract);
    }

    function setRewardWallet(address _newVal) public onlyOwner {
        rewardWallet = _newVal;
        emit Set_RewardWallet(_newVal);
    }

    function setMST(uint256 _newVal) public onlyOwner {
        MST = _newVal;
        emit Set_MST(_newVal);
    }

    function setStakeType(uint256 _tokenId, uint256 _apy, bool _status) public onlyOwner {
        require(stakeTypeList.length < MAX_VALUE,"Reached Limit of Staking!");
        require(IERC1155(nftSaleAddress).existTokenId(_tokenId),"Token doesnt exists in Sale!");
        uint _index = getIndexOfCreateStakeType(_tokenId);
        uint _PCSUnitPrice = IERC1155(nftSaleAddress).getNftSaleData(_tokenId).price;
        if(_index == MAX_VALUE){
            stakeTypeList.push(StakeType(_tokenId,_apy,_PCSUnitPrice,_status));
            _index = stakeTypeList.length - 1; 
        }else{         
        stakeTypeList[_index].tokenId = _tokenId;
        stakeTypeList[_index].apy = _apy;
        stakeTypeList[_index].PCSUnitPrice = _PCSUnitPrice;
        stakeTypeList[_index].status = _status;
        }
        emit Set_StakeType(_index, _tokenId, _apy, _PCSUnitPrice, _status);
    }

    function calculateInterest(uint256 _stakeTypeIndex, uint256 _stakeStartDate, uint256 _stakeAmount) public view returns (uint256) {
        uint256 apy = stakeTypeList[_stakeTypeIndex].apy;
        uint256 PCSUnitPrice = stakeTypeList[_stakeTypeIndex].PCSUnitPrice;

        // APY per year = amount * APY / 100
        uint256 interest_per_year = ((_stakeAmount*PCSUnitPrice) * apy) / 100;

        // number of seconds since opening date
        uint256 num_seconds = block.timestamp - _stakeStartDate;

        // calculate interest by a rule of three
        //  seconds of the year: 31536000 = 365*24*60*60
        //  interest_per_year   -   31536000
        //  interest            -   num_seconds
        //  interest = num_seconds * interest_per_year / 31536000
        return (num_seconds * interest_per_year) / 31536000;
    }

    function getIndexOfCreateStakeType(uint _id) private view returns (uint) {
        uint index = MAX_VALUE;
        for(uint256 i=0; i< (stakeTypeList.length > 0 ? stakeTypeList.length : 0); i++){
            if(stakeTypeList[i].tokenId ==  _id){
                index = i;
            }
        }
        // return -1 if there is not an index, otherwise return the index of the current position of that type of stake
        return index; 
    }

    function getIndexToCreateStake(address _account) private view returns (uint256) {
        uint256 index = 50;
        for(uint256 i=0; i<stakesOf[_account].length; i++){
            if(!stakesOf[_account][i].active){
                index = i;
            }
        }
        // if (index < 50)  = limit not reached
        // if (index == 50) = limit reached
        return index; 
    }

    function getPublicNftData(uint _id) public view returns(nftSale memory data){
        nftSale memory temp = nftSale(
            _id,
            IERC1155(nftSaleAddress).getNftSaleData(_id).price,
            IERC1155(nftSaleAddress).getNftSaleData(_id).status,
            IERC1155(nftSaleAddress).getNftSaleData(_id).bought
            );
        return temp;
    }

    // anyone can create a stake
    function createStake(uint256 _stakeTypeIndex, uint256 _amount) external {
        require(stakeTypeList[_stakeTypeIndex].status, "_stakeTypeIndex is not valid or is not active");
        uint256 index = getIndexToCreateStake(msg.sender);
        require(index < 50, "stakes limit reached");
        uint256 tokenId = stakeTypeList[_stakeTypeIndex].tokenId;
        // store the tokens of the user in the contract
        // requires approve
        IERC1155(nfts).safeTransferFrom(_msgSender(), address(this), tokenId, _amount, "");
        // create the stake
        stakesOf[msg.sender][index] = Stake(_stakeTypeIndex, block.timestamp, _amount, true,IERC1155(nftSaleAddress).getNftSaleData(tokenId).price * _amount);
        emit AddedStake(_stakeTypeIndex, tokenId, block.timestamp, _amount, msg.sender);
    }

    function withdrawStake(uint256 _arrayIndex, uint256 _withdrawType) external nonReentrant { // _withdrawType (1=normal withdraw, 2=withdraw only rewards)
        require(_withdrawType>=1 && _withdrawType<=2, "invalid _withdrawType");
        // Stake should exists and opened
        require(_arrayIndex < stakesOf[msg.sender].length, "Stake does not exist");
        Stake memory stk = stakesOf[msg.sender][_arrayIndex];
        require(stk.active, "This stake is not active");
        require((block.timestamp - stk.startDate) >= MST, "the minimum stake time has not been completed yet");
        uint256 tokenId = stakeTypeList[stk.stakeTypeIndex].tokenId;

        // get the interest
        uint256 interest = ICO(icoContract).getConversion_AcceptedToken_To_DefaultToken(calculateInterest(stk.stakeTypeIndex, stk.startDate, stk.amount));

        // transfer the interes from rewardWallet, it has to have enough funds approved
        IERC20(rewardToken).transferFrom(rewardWallet, msg.sender, interest);

        if(_withdrawType == 1){
            // transfer the NFTs from the contract itself
            IERC1155(nfts).safeTransferFrom(address(this), msg.sender, tokenId, stk.amount, "");
            // stake closing
            delete stakesOf[msg.sender][_arrayIndex];
        }else{
            // restart stake
            stakesOf[msg.sender][_arrayIndex].startDate = block.timestamp;
        }

        emit WithdrawStake(_withdrawType, stk.stakeTypeIndex, tokenId, stk.startDate, block.timestamp, interest, stk.amount, msg.sender);
    }

    function getStakesOf(address _account) external view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory){
        uint256 stakesLength = stakesOf[_account].length;
        uint256[] memory tokenIdList = new uint256[](stakesLength);
        uint256[] memory startDateList = new uint256[](stakesLength);
        uint256[] memory amountList = new uint256[](stakesLength);
        uint256[] memory interestList = new uint256[](stakesLength);
        bool[] memory activeList = new bool[](stakesLength);

        for(uint256 i=0; i<stakesLength; i++){
            Stake memory stk = stakesOf[_account][i];
            tokenIdList[i] = stakeTypeList[stk.stakeTypeIndex].tokenId;
            startDateList[i] = stk.startDate;
            amountList[i] = stk.amount;
            interestList[i] = ICO(icoContract).getConversion_AcceptedToken_To_DefaultToken(calculateInterest(stk.stakeTypeIndex, stk.startDate, stk.amount));
            activeList[i] = stk.active;
        }

        return (tokenIdList, startDateList, amountList, interestList, activeList);
    }

    function getStakesByDate(address _account, uint startTimeStamp ,uint finalTimeStamp) external view returns(uint _totalStaked){
        uint256 stakesLength = stakesOf[_account].length;
        uint _amount = 0;
        for(uint i = 0; i < stakesLength; i++){
            if(stakesOf[_account][i].active && stakesOf[_account][i].startDate >= startTimeStamp && stakesOf[_account][i].startDate <= finalTimeStamp){
                _amount += stakesOf[_account][i].valueStake;
            }
        }
        return _amount;
    }


}