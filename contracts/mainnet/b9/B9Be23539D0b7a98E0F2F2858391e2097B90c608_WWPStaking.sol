/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


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


interface IWWPNFT is IERC721 {}

interface ILYCN {
    function balanceOf(address account) external view returns (uint256);

    function mint(address to, uint256 amount) external;
}

contract WWPStaking is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    ILYCN LYCNContract;
    IWWPNFT WWPNFTContract;

    struct _stStakedTokenInfo {
        uint256 startTime;
        uint256 lastRewardTime;
        address owner;
        uint256 index;
    }

    struct _stStakerInfo {
        uint256 totalRewards;
        uint256 totalStakingTime;
        Counters.Counter tokensBalance;
    }

    struct _stTokenInfo {
        uint256 totalRewards;
        uint256 totalStakingTime;
    }

    mapping(uint256 => _stStakedTokenInfo) public stakedTokenInfo;

    mapping(address => uint256[]) private _tokenOfStakerByIndex;

    Counters.Counter private _totalStakers;

    Counters.Counter private _totalStakedTokens;

    uint256 public minimumStakeTime = 3 days;

    uint256 public rewardPerDay = 12 ether;

    bool public paused = true;

    mapping(uint256 => _stTokenInfo) private _tokenInfo;
    mapping(address => _stStakerInfo) public stakerInfo;
    uint256 public totalRewards;
    uint256 public totalStakingTime;


    event Stake(
        uint256 indexed _token,
        address indexed _from,
        uint256 indexed _time
    );
    event Unstake(
        uint256 indexed _token,
        address indexed _from,
        uint256 indexed _time
    );
    event Payout(
        uint256 indexed _token,
        address indexed _from,
        uint256 _reward,
        uint256 indexed _time
    );

    constructor(address _LYCNAddr, address _WWPNFTAddr) {
        WWPNFTContract = IWWPNFT(_WWPNFTAddr);
        LYCNContract = ILYCN(_LYCNAddr);
    }

    // public
    function stake(uint256 _tokenId) public stakeCompliance(_tokenId) {
        _safeStake(_tokenId);
        emit Stake(_tokenId, _msgSender(), block.timestamp);
    }

    function unstake(uint256 _tokenId) public unstakeCompliance(_tokenId) {
        _safeUnstake(_tokenId);
        emit Unstake(_tokenId, _msgSender(), block.timestamp);
    }

    function collect(uint256 _tokenId) public payoutCompliance(_tokenId) {
        _safeRewardPayout(_tokenId);
    }

    function multiStake(uint256[] memory _tokenIds) public {
        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            stake(_tokenIds[idx]);
        }
    }

    function multiUnstake(uint256[] memory _tokenIds) public {
        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            unstake(_tokenIds[idx]);
        }
    }

    function multiCollect(uint256[] memory _tokenIds) public {
        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            _safeRewardPayout(_tokenIds[idx]);
        }
    }

    function totalStakedTokens() public view returns (uint256) {
        return _totalStakedTokens.current();
    }

    function totalStakers() public view returns (uint256) {
        return _totalStakers.current();
    }

    function tokenOfStakerByIndex(address staker, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < _tokenOfStakerByIndex[staker].length,
            "WWPStaking: staker index out of bounds"
        );
        return _tokenOfStakerByIndex[staker][index];
    }

    function tokenInfo(uint256 tokenId)
        public
        view
        returns (
            uint256 totalStakedTime,
            uint256 totalReward,
            uint256 pendingReward
        )
    {
        uint256 _elapsedTime = elapsedTime(tokenId);
        uint256 _pendingReward = stakedTokenInfo[tokenId].startTime != 0
            ? rewardForTime(_elapsedTime)
            : 0;
        return (
            _tokenInfo[tokenId].totalStakingTime + _elapsedTime,
            _tokenInfo[tokenId].totalRewards,
            _pendingReward
        );
    }

    // Owner
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setMinimumStakePeriod(uint256 _seconds) public onlyOwner {
        minimumStakeTime = _seconds;
    }

    function setRewardPerDay(uint256 _amount) public onlyOwner {
        rewardPerDay = _amount;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // private
    function _safeStake(uint256 _tokenId) private {
        address senderAddress = _msgSender();

        WWPNFTContract.safeTransferFrom(senderAddress, address(this), _tokenId);

        stakedTokenInfo[_tokenId] = _stStakedTokenInfo(
            block.timestamp,
            0 seconds,
            senderAddress,
            stakerInfo[senderAddress].tokensBalance.current()
        );

        _tokenOfStakerByIndex[senderAddress].push(_tokenId);

        if (stakerInfo[senderAddress].tokensBalance.current() == 0) {
            _totalStakers.increment();
        }

        stakerInfo[senderAddress].tokensBalance.increment();

        _totalStakedTokens.increment();
    }

    function _safeUnstake(uint256 _tokenId) private {
        address senderAddress = _msgSender();

        WWPNFTContract.safeTransferFrom(address(this), senderAddress, _tokenId);

        _removeTokenIdFromStaker(
            stakedTokenInfo[_tokenId].index,
            senderAddress
        );

        _safeRewardPayout(_tokenId);

        stakerInfo[senderAddress].tokensBalance.decrement();
        if (stakerInfo[senderAddress].tokensBalance.current() == 0) {
            _totalStakers.decrement();
        }
        _totalStakedTokens.decrement();

        delete stakedTokenInfo[_tokenId];
    }

    function _removeTokenIdFromStaker(uint256 _index, address senderAddress)
        private
    {
        if (_tokenOfStakerByIndex[senderAddress].length == 1) {
            _tokenOfStakerByIndex[senderAddress].pop();
            delete _tokenOfStakerByIndex[senderAddress];
            return;
        }
        uint256 lastTokenIndex = _tokenOfStakerByIndex[senderAddress].length -
            1;

        uint256 lastTokenId = _tokenOfStakerByIndex[senderAddress][
            lastTokenIndex
        ];
        _tokenOfStakerByIndex[senderAddress][_index] = lastTokenId;

        stakedTokenInfo[lastTokenId].index = _index;

        _tokenOfStakerByIndex[senderAddress].pop();
    }

    function _safeRewardPayout(uint256 _tokenId) private {
        if (paused) return;

        address senderAddress = _msgSender();
        uint256 _elapsedTime = elapsedTime(_tokenId);
        uint256 currentReward = rewardForTime(_elapsedTime);

        stakedTokenInfo[_tokenId].lastRewardTime = block.timestamp;

        totalStakingTime += _elapsedTime;
        _tokenInfo[_tokenId].totalStakingTime += _elapsedTime;
        stakerInfo[senderAddress].totalStakingTime += _elapsedTime;

        totalRewards += currentReward;
        _tokenInfo[_tokenId].totalRewards += currentReward;
        stakerInfo[senderAddress].totalRewards += currentReward;

        lycnMintTo(senderAddress, currentReward);
        emit Payout(_tokenId, senderAddress, currentReward, block.timestamp);
    }

    function elapsedTime(uint256 _tokenId) private view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 startTime = stakedTokenInfo[_tokenId].startTime;
        uint256 lastRewardTime = stakedTokenInfo[_tokenId].lastRewardTime;
        if (startTime == 0 && lastRewardTime == 0) return 0;
        uint256 rewardStartTime = (lastRewardTime != 0)
            ? lastRewardTime
            : startTime;

        return currentTime - rewardStartTime;
    }

    function rewardForTime(uint256 _seconds) private view returns (uint256) {
        return _seconds * (rewardPerDay / 1 days);
    }

    function lycnMintTo(address _addr, uint256 _amount) private {
        LYCNContract.mint(_addr, _amount);
    }

    // Modifiers
    modifier stakeCompliance(uint256 _tokenId) {
        require(!paused, "WWPStaking: contract paused");
        address senderAddress = _msgSender();
        require(
            WWPNFTContract.isApprovedForAll(senderAddress, address(this)),
            "WWPStaking: the contract isn't approved to transfer the NFT token"
        );
        address tokenOwner = WWPNFTContract.ownerOf(_tokenId);
        require(
            (tokenOwner != address(this)),
            "WWPStaking: NFT token already staked"
        );
        require(
            (tokenOwner == senderAddress),
            "WWPStaking: only the NFT token owner allowed"
        );
        _;
    }

    modifier unstakeCompliance(uint256 _tokenId) {
        require(
            (stakedTokenInfo[_tokenId].owner != address(0)),
            "WWPStaking: non-existing token"
        );
        require(
            (stakedTokenInfo[_tokenId].owner == _msgSender()),
            "WWPStaking: only the NFT token owner allowed"
        );
        require(
            block.timestamp >=
                stakedTokenInfo[_tokenId].startTime + minimumStakeTime,
            "WWPStaking: the minimum staking time has not elapsed"
        );
        _;
    }
    modifier payoutCompliance(uint256 _tokenId) {
        require(
            (stakedTokenInfo[_tokenId].owner != address(0)),
            "WWPStaking: non-existing token"
        );
        require(
            (stakedTokenInfo[_tokenId].owner == _msgSender()),
            "WWPStaking: only the NFT token owner allowed"
        );
        _;
    }

    // Overrides
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}