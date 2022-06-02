/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// File: contracts/OddStaking.sol


pragma solidity ^0.8.7;





contract OddStaking is Ownable{

    IERC721 oddContract;
    IERC20 pickles;

    bool paused = true;

    struct StakingInfo {
        address owner;
        uint256 timestamp;
    }

    struct StakingInfoOdds {
        uint256 tokenId;
        uint256 timestamp;
        uint256 rewards;
    }

    mapping(uint256 => StakingInfo) public idToToken;
    mapping(address => uint256[]) public stakingsByOwner;


    constructor() {}


    function stake(uint256 _id) external {

        require(!paused, "Contract Paused");
        require (msg.sender == oddContract.ownerOf(_id), "Sender must be the owner");
        require(oddContract.isApprovedForAll(msg.sender, address(this)));

        StakingInfo memory staking = StakingInfo(msg.sender, block.timestamp);
        idToToken[_id] = staking;
        stakingsByOwner[msg.sender].push(_id);
        oddContract.transferFrom(msg.sender, address(this), _id);

    }

    function unstake(uint256 _id) internal {

        StakingInfo storage staking = idToToken[_id];
        uint256[] storage stakedOdds = stakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedOdds.length; index++) {
            if (stakedOdds[index] == _id) {
                break;
            }
        }
        require(index < stakedOdds.length, "Odds not found");
        stakedOdds[index] = stakedOdds[stakedOdds.length - 1];
        stakedOdds.pop();
        staking.owner = address(0);
        oddContract.transferFrom(address(this), msg.sender, _id);

    }

    function claimOddRewards(uint256 _id, bool unstaked) external {

        require(!paused, "Contract Paused");
        uint256 netRewards = _claimOdds(_id);
        

        if (unstaked) {
            unstake(_id);
        }

        if (netRewards > 0) {
            require(pickles.transfer(msg.sender, netRewards));
        }

    }

    function _claimOdds(uint256 _id) internal returns (uint256) {

        require(oddContract.ownerOf(_id) == address(this), "The Odd must be staked");
        StakingInfo storage staking = idToToken[_id];
        require(staking.owner == msg.sender, "Sender must be the owner");

        uint256 rewards = calculateOddReward(_id);
        staking.timestamp = block.timestamp;

        return rewards;

    }

    function calculateOddReward(uint256 _id) public view returns (uint256) {

        require(oddContract.ownerOf(_id) == address(this), "The Odd must be staked");
        uint256 balance = pickles.balanceOf(address(this));
        uint256 dayCount = timeStaked(_id);
        if (dayCount < 1 || balance == 0) {
            return 0;
        }
        uint256 n = dayCount - 1;
        uint256 r = (n*n + n) / 2 +  10 * dayCount;
        uint256 reward = r * 1 ether; // convert to wei
        return reward <= balance ? reward : balance;

    }

    function timeStaked(uint256 _id) public view returns (uint256) {
        
        
        StakingInfo storage staking = idToToken[_id];
        uint256 diff = block.timestamp - staking.timestamp;
        return uint256(diff) / (1 days);
        
    }

    function stakingInfoOdds(address owner) public view returns (StakingInfoOdds[] memory) {
        
        uint256 balance = stakedBalanceOf(owner);
        StakingInfoOdds[] memory list = new StakingInfoOdds[](balance);

        for (uint16 i = 0; i < balance; i++) {
            uint256 tokenId = stakingsByOwner[owner][i];
            StakingInfo memory staking = idToToken[tokenId];
            uint256 reward = calculateOddReward(tokenId);
            
            list[i] = StakingInfoOdds(tokenId, staking.timestamp, reward);
        }

        return list;

    }

    function stakedBalanceOf(address owner) public view returns (uint256) {

        return stakingsByOwner[owner].length;
        
    }

    function set_odd_contract(IERC721 _new_address) external onlyOwner {

        oddContract = _new_address;

    }

    function set_pickles_contract(IERC20 _pickles) external onlyOwner {

        pickles = _pickles;

    }

    function toggle_pause() external onlyOwner {
        
        if (paused) {
            paused = false;
        } else {
            paused = true;
        }

    }

    function withdrawal_pickles() external onlyOwner {

        uint256 pickle_balance = pickles.balanceOf(address(this));
        require(pickles.transfer(owner(), pickle_balance));

    }

    function emergencyUnstake(uint256[] memory tokenIds) external onlyOwner {

        require(tokenIds.length <= 50, "50 is max per tx");
        
        for (uint8 i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
        
    }

    function emergencyUnstakeByUser(uint256[] memory tokenIds) external {
        
        require(tokenIds.length <= 50, "50 is max per tx");
        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(oddContract.ownerOf(tokenIds[i]) == address(this), "The Odd must be staked");
            StakingInfo storage staking = idToToken[tokenIds[i]];
            require(staking.owner == msg.sender, "Sender must be the owner");
            unstake(tokenIds[i]);
        }
        
    }


}