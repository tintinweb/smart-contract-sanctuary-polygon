/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

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

// File: contracts/Reopen/Interfaces/NFTInterface.sol


pragma solidity ^0.8.4;

interface NFTInterface {
    function lock(address unlocker, uint256 id) external;
    function unlock(uint256 id) external;
    function ownerOf(uint256 id) external returns (address);
    function totalSupply() view external returns (uint);
    function transferFrom(address owner, address to, uint id) external ;
}

// File: contracts/Reopen/HoldersYield.sol



pragma solidity ^0.8.4;




contract NFTStakingVault is Ownable, IERC721Receiver {
    uint256 public totalItemsStaked;
    NFTInterface nft;

    struct Stake {
        address owner;
        uint256 stakedAt;
    }

    mapping(address => mapping(uint256 => Stake)) vault;

    event ItemStaked(uint256 tokenId, address owner, uint256 timestamp);
    event ItemUnstaked(uint256 tokenId, address owner, uint256 timestamp);
    event Claimed(address owner, uint256 reward);

    constructor() {
    }

    //--------------------------------------------------------------------
    // FUNCTIONS

    function stake(address _nftAddress, uint256 tokenIds) external {
        nft = NFTInterface(_nftAddress);
        uint256 tokenId;
        uint256 stakedCount;

        tokenId = tokenIds;
        if (vault[_nftAddress][tokenId].owner != address(0)) {
            revert("NFTStakingVault__ItemAlreadyStaked");
        }
        if (nft.ownerOf(tokenId) != msg.sender) {
            revert("NFTStakingVault__NotItemOwner");
        }

        // nft.approve(address(this), tokenId);
        nft.lock(address(this), tokenId);

        vault[_nftAddress][tokenId] = Stake(msg.sender, block.timestamp);

        emit ItemStaked(tokenId, msg.sender, block.timestamp);

        unchecked {
            stakedCount++;
        }
        totalItemsStaked = totalItemsStaked + stakedCount;
    }

    function unstake(
        address _nftAddress,
        uint256 tokenIds,
        uint256 ethAmount_
    ) external {
        _claim(_nftAddress, msg.sender, tokenIds, true, ethAmount_);
    }

    function claim(
        address _nftAddress,
        uint256 tokenIds,
        uint256 ethAmount_
    ) external {
        _claim(_nftAddress, msg.sender, tokenIds, false, ethAmount_);
    }

    function _claim(
        address _nftAddress,
        address user,
        uint256 tokenIds,
        bool unstakeAll,
        uint256 ethAmount_
    ) internal {
        uint256 tokenId;
        uint256 calculatedReward;
        uint256 rewardEarned;

        tokenId = tokenIds;
        if (vault[_nftAddress][tokenId].owner != user) {
            revert("NFTStakingVault__NotItemOwner");
        }
        uint256 _stakedAt = vault[_nftAddress][tokenId].stakedAt;

        uint256 stakingPeriod = block.timestamp - _stakedAt;
        calculatedReward += (stakingPeriod * ethAmount_) / 365 days;

        vault[_nftAddress][tokenId].stakedAt = block.timestamp;

        rewardEarned = calculatedReward;

        emit Claimed(user, rewardEarned);

        if (rewardEarned != 0) {
            payable(user).transfer(rewardEarned);
        }

        if (unstakeAll) {
            _unstake(_nftAddress, user, tokenIds);
        }
    }

    function _unstake(
        address _nftAddress,
        address user,
        uint256 tokenIds
    ) internal {
        uint256 tokenId;
        uint256 unstakedCount;

        tokenId = tokenIds;
        require(vault[_nftAddress][tokenId].owner == user, "Not Owner");

        nft.unlock(tokenId);

        delete vault[_nftAddress][tokenId];

        emit ItemUnstaked(tokenId, user, block.timestamp);

        unchecked {
            unstakedCount++;
        }
        totalItemsStaked = totalItemsStaked - unstakedCount;
    }

    function getTotalRewardEarned(
        address _nftAddress,
        address user,
        uint256 ethAmount_
    ) external view returns (uint256 rewardEarned) {
        uint256 calculatedReward;
        uint256[] memory tokens = tokensOfOwner(_nftAddress, user);

        uint256 len = tokens.length;
        for (uint256 i; i < len; ) {
            uint256 _stakedAt = vault[_nftAddress][tokens[i]].stakedAt;
            uint256 stakingPeriod = block.timestamp - _stakedAt;
            calculatedReward += (stakingPeriod * ethAmount_) / 365 days;
            unchecked {
                ++i;
            }
        }
        rewardEarned = calculatedReward;
    }

    function getRewardEarnedPerNft(
        address _nftAddress,
        uint256 _tokenId,
        uint256 ethAmount_
    ) external view returns (uint256 rewardEarned) {
        uint256 _stakedAt = vault[_nftAddress][_tokenId].stakedAt;
        uint256 stakingPeriod = block.timestamp - _stakedAt;
        uint256 calculatedReward = (stakingPeriod * ethAmount_) / 365 days;
        rewardEarned = calculatedReward;
    }

    function balanceOf(address _nftAddress, address user)
        public
        view
        returns (uint256 nftStakedbalance)
    {
        uint256 supply = nft.totalSupply();
        unchecked {
            for (uint256 i; i <= supply; ++i) {
                if (vault[_nftAddress][i].owner == user) {
                    nftStakedbalance += 1;
                }
            }
        }
    }

    function tokensOfOwner(address _nftAddress, address user)
        public
        view
        returns (uint256[] memory tokens)
    {
        uint256 balance = balanceOf(_nftAddress, user);
        uint256 supply = nft.totalSupply();
        tokens = new uint256[](balance);

        uint256 counter;

        if (balance == 0) {
            return tokens;
        }

        unchecked {
            for (uint256 i; i <= supply; ++i) {
                if (vault[_nftAddress][i].owner == user) {
                    tokens[counter] = i;
                    counter++;
                }
                if (counter == balance) {
                    return tokens;
                }
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function addMoney() public payable returns (string memory) {
        return "Added";
    }

    receive() external payable {}

    fallback() external payable {}
}