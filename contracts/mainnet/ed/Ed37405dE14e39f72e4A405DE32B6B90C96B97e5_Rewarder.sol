/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface IRewardToken {
    function mint(address to, uint256 amount) external;
}


contract Rewarder is Ownable {

    event ClaimedReward(address to, uint256 amount);

    // nft -> tokenId -> timestamp
    mapping(INFT => mapping(uint256 => uint256)) private _registry;

    IRewardToken public rewardToken;
    uint256      public rewardPerSecond;

    constructor(IRewardToken rewardToken_) {
        rewardToken = rewardToken_;
    }

    receive() external payable {}

    function update() external {
        uint256 amountRewarded = 0;

        for (uint256 i = 0; i < entries.length; i++) {
            INFT nft = entries[i].nft;
            uint256 weight = entries[i].weight;

            for (uint256 j = 0; j < nft.balanceOf(msg.sender); j++) {
                uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, j);

                uint256 checkpoint = _registry[nft][tokenId];

                // Token was registered previously; receipt exists
                if (checkpoint > 0) {
                    uint256 reward = (block.timestamp - checkpoint) * weight * rewardPerSecond;
                    rewardToken.mint(msg.sender, reward);
                    amountRewarded += reward;
                }

                // Update timestamp regardless of if token
                // was previously registered or not.
                _registry[nft][tokenId] = block.timestamp;
            }
        }

        if (amountRewarded > 0) {
            emit ClaimedReward(msg.sender, amountRewarded);
        }
    }

    function pendingReward() external view returns (uint256) {
        uint256 amount = 0;

        for (uint256 i = 0; i < entries.length; i++) {
            INFT nft = entries[i].nft;
            uint256 weight = entries[i].weight;

            for (uint256 j = 0; j < nft.balanceOf(msg.sender); j++) {
                uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, j);

                uint256 checkpoint = _registry[nft][tokenId];

                // Token was registered previously; receipt exists
                if (checkpoint > 0) {
                    uint256 reward = (block.timestamp - checkpoint) * weight * rewardPerSecond;
                    amount += reward;
                }
            }
        }

        return amount;
    }

    function lastCheckpoint(INFT nft, uint256 tokenId) external view returns (uint256) {
        return _registry[nft][tokenId];
    }

    struct Entry {
        INFT nft;
        uint256 weight;
    }

    Entry[] public entries;
    uint256 public entriesCount;

    function entryExists(INFT nft) public view returns (bool) {
        bool exists = false;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].nft == nft) {
                exists = true;
            }
        }
        return exists;
    }

    function getEntryWeight(INFT nft) external view returns (uint256) {
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].nft == nft) {
                return entries[i].weight;
            }
        }
        revert("Entry does not exist");
    }

    // Adds many entries with weight = 1.
    // May be expensive due to O(n^2) complexity.
    function addEntries(INFT[] memory nfts) external onlyOwner {
        for (uint256 i = 0; i < nfts.length; i++) {
            INFT nft = nfts[i];
            if (entryExists(nft)) {
                continue;
            }
            entries.push(Entry({ nft: nft, weight: 1 }));
            entriesCount++;
        }
    }

    function addEntry(INFT nft, uint256 weight) external onlyOwner {
        require(!entryExists(nft), "Entry already exists");

        entries.push(Entry({ nft: nft, weight: weight }));
        entriesCount++;
    }

    function editEntry(INFT nft, uint256 weight) external onlyOwner {
        require(entryExists(nft), "Entry does not exist");

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].nft == nft) {
                entries[i].weight = weight;
            }
        }
    }

    function removeEntry(INFT nft) external onlyOwner {
        require(entryExists(nft), "Entry does not exist");

        // Create copy and clear original
        Entry[] memory copy = new Entry[](entries.length);
        for (uint256 i = 0; i < entries.length; i++) {
            copy[i] = entries[i];
        }
        delete entries;

        // Re-add elements
        for (uint256 i = 0; i < copy.length; i++) {
            // Ignore the entry that is being removed
            if (copy[i].nft == nft) {
                continue;
            }
            entries.push(copy[i]);
        }

        entriesCount--;
    }

    function setRewardPerSecond(uint256 rewardPerSecond_) external onlyOwner {
        rewardPerSecond = rewardPerSecond_;
    }
}