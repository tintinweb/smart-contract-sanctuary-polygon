// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/******************************************************************************\

* Custom implementation of the StakingRewards contract by Synthetix.
* Can stake any NFT 721 and receive reward in any ERC20
/******************************************************************************/

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";

contract Staker is ERC1155Holder, ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    event PaymentReceived(address from, uint256 amount);

    uint256 public nftCount;
    uint256 costId;

    struct NFT {
        bool paused;
        bool deposit;
        address stakingToken;
        uint16 stakeType;
        uint16 stakeID;
        uint16 APY;
        uint16[] stakeList;
        uint32 stakingDuration;
        uint256 stakeValue;
        uint256 totalStake;
        uint16 rewardCost;
        mapping(address => uint256) userStartTime;
        mapping(address => uint256) rewards;
        mapping(address => uint256) stakedBalance;
        mapping(uint16 => address) stakedAssets;
    }
    NFT[] public nfts;

    uint256 internal _precision = 1E6;

    constructor() payable {        
        //AddNFT(0x7039738f73BA6afd8DD199481bCF347AE1e4b577, 0xA1E25BF0540225520a9c2367dd9301C46C9A6c40, 356, 0, 50, 1000, 1);
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function AddNFT(address _stakingToken, bool _deposit, uint16 _stakeType, uint16 _APY, uint16 _stakeID, uint16 _duration, uint256 _stakeValue, uint16 _rewardCost) public payable onlyOwner {

        //test types before adding
        if (_stakeType == 721) {
            require(IERC721(_stakingToken).supportsInterface(0x80ac58cd),"Staking: not 721");
        } else if (_stakeType == 1155) {
            require(IERC1155(_stakingToken).supportsInterface(0xd9b67a26),"Staking: not 1155");
        } else if (_stakeType == 20) {
            require(IERC20(_stakingToken).totalSupply() > 0,"Staking: not 20");
        } else if (_stakeType == 1) {
            //accept ethereum for staking
        } else {
            require(false, "Staking: wrong stake type");
        }

        nfts.push();
        nftCount += 1;
        nfts[nftCount-1].stakingToken = _stakingToken;
        nfts[nftCount-1].deposit = _deposit;
        nfts[nftCount-1].stakeType = _stakeType;
        nfts[nftCount-1].stakeID = _stakeID;
        nfts[nftCount-1].paused = true;
        nfts[nftCount-1].APY = _APY;
        nfts[nftCount-1].rewardCost = _rewardCost;
        nfts[nftCount-1].stakingDuration = _duration * 1 days;
        nfts[nftCount-1].stakeValue = _stakeValue;
    }

    /// @notice Stakes user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be staked
    function stake(uint16[] memory tokenIds, uint256 id, uint256 count) payable external nonReentrant {
        uint256 amount;
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;
        
        require(Address.isContract(msg.sender) == false, "Staking: no contracts");
        require(nfts[id].paused == false, "Staking: is paused");

        if (nfts[id].stakeType == 721) {
            require(tokenIds.length != 0, "Staking: No tokenIds provided");
            stakingToken721 = IERC721(nfts[id].stakingToken);

            require(stakingToken721.isApprovedForAll(msg.sender, address(this)) == true,
                "Staking: First must setApprovalForAll in the NFT to this contract");

            for (uint256 i = 0; i < tokenIds.length; i += 1) {
                require(tokenIds[i] > 0, "Staking: id 0 not supported");
                require(stakingToken721.ownerOf(tokenIds[i]) == msg.sender, "Staking: not owner of NFT");

                // Transfer user's NFTs to the staking contract
                stakingToken721.transferFrom(msg.sender, address(this), tokenIds[i]);

                // Increment the amount which will be staked
                amount += 1;
                // Save who is the staker/depositor of the token
                nfts[id].stakedAssets[tokenIds[i]] = msg.sender;
                nfts[id].stakeList.push(tokenIds[i]);
            }

            nfts[id].stakedBalance[msg.sender] += amount;
            nfts[id].totalStake += amount;

        } else if (nfts[id].stakeType == 1155) {
            require(count > 0, "Staking: count must be > 0");
            stakingToken1155 = IERC1155(nfts[id].stakingToken);
            require(stakingToken1155.balanceOf(msg.sender, nfts[id].stakeID) >= count, "Staking: not owner of this count of NFT");
            require(stakingToken1155.isApprovedForAll(msg.sender, address(this)) == true,
                "Staking: First must setApprovalForAll in the NFT to this contract");

            // Transfer user's NFTs to the staking contract
            stakingToken1155.safeTransferFrom(msg.sender, address(this), nfts[id].stakeID, count, bytes(""));

            // Save who is the staker/depositor of the token
            nfts[id].stakedBalance[msg.sender] += count;
            nfts[id].totalStake += count;

        } else if (nfts[id].stakeType == 20) {
            require(count > 0, "Staking: count must be > 0");
            stakingToken20 = IERC20(nfts[id].stakingToken);

            require(stakingToken20.balanceOf(msg.sender) >= count, "Staking: not owner of this balance of token");
            require(stakingToken20.allowance(msg.sender, address(this)) >= count,
                "Staking: First must set allowance in the token to this contract");

            // Transfer user's NFTs to the staking contract
            stakingToken20.transferFrom(msg.sender, address(this), count);

            // Save who is the staker/depositor of the token
            nfts[id].stakedBalance[msg.sender] += count;
            nfts[id].totalStake += count;

        } else if (nfts[id].stakeType == 1) {
            require(msg.value > 0, "Staking: not received any ethereum");

            // Save who is the staker/depositor of the token
            nfts[id].stakedBalance[msg.sender] += msg.value;
            emit Staked(msg.sender, msg.value, tokenIds);
        }
    }

    /// @notice Withdraws staked user's NFTs
    function withdraw(uint256 id) public nonReentrant {
        uint256 amount;
        uint256 i;
        uint16 j;
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;

        require(Address.isContract(msg.sender) == false, "Staking: no contracts");

        if (nfts[id].stakeType == 721) {
            stakingToken721 = IERC721(nfts[id].stakingToken);

            if (nfts[id].stakedBalance[msg.sender] > 0) {
                for (i = 0; i < nfts[id].stakedBalance[msg.sender]; i += 1) {
                    for (j = 0; j < nfts[id].stakeList.length; j += 1) {
                        if (nfts[id].stakeList[j] > 0 && nfts[id].stakedAssets[nfts[id].stakeList[j]] == msg.sender) {
                            // Transfer user's NFTs back to user
                            stakingToken721.safeTransferFrom(address(this), msg.sender, nfts[id].stakeList[j]);

                            // Increment the amount which will be withdrawn
                            amount += 1;
                            // Cleanup stakedAssets for the current tokenId
                            nfts[id].stakedAssets[nfts[id].stakeList[j]] = address(0);
                            nfts[id].stakeList[j] = 0;
                            break;
                        }
                    }
                }
            }

            nfts[id].stakedBalance[msg.sender] -= 0;
            nfts[id].totalStake -= amount;

        } else if (nfts[id].stakeType == 1155) {
            stakingToken1155 = IERC1155(nfts[id].stakingToken);

            if (stakingToken1155.balanceOf(address(this), nfts[id].stakeID) < nfts[id].stakedBalance[msg.sender]) {
                amount = stakingToken1155.balanceOf(address(this), nfts[id].stakeID);
            } else {
                amount = nfts[id].stakedBalance[msg.sender];
            }            
            nfts[id].stakedBalance[msg.sender] = 0;
            nfts[id].totalStake -= amount;

            if (amount > 0) {
                stakingToken1155.safeTransferFrom(address(this), msg.sender, nfts[id].stakeID, amount, bytes(""));
            }

        } else if (nfts[id].stakeType == 20) {
            stakingToken20 = IERC20(nfts[id].stakingToken);

            if (stakingToken20.balanceOf(address(this)) < nfts[id].stakedBalance[msg.sender]) {
                amount = stakingToken20.balanceOf(address(this));
            } else {
                amount = nfts[id].stakedBalance[msg.sender];
            }
            nfts[id].stakedBalance[msg.sender] = 0;
            nfts[id].totalStake -= amount;

            if (amount > 0) {
                stakingToken20.transferFrom(address(this), msg.sender, amount);
            }

        } else if (nfts[id].stakeType == 1) {
 
            if (address(this).balance < nfts[id].stakedBalance[msg.sender]) {
                amount = address(this).balance;
            } else {
                amount = nfts[id].stakedBalance[msg.sender];
            }

            nfts[id].stakedBalance[msg.sender] = 0;

            if (amount > 0) {
                payable(msg.sender).transfer(amount);
            }
        }
    }

    function cost(uint256 stakeId, uint256 rewardId) public view returns (uint256) {
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;
        uint256 amount;
        uint256 count;

        require(Address.isContract(msg.sender) == false, "Staking: No contracts");
        require(nfts[rewardId].deposit, "Staking: this token cannot be claimed");

        // update the current reward balance
        uint256 reward = nfts[stakeId].rewards[msg.sender];
        require(reward > 0, "Staking: no rewards to pay out");
        require(nfts[rewardId].totalStake > 0, "Staking: no reward balance available to pay out");

        if (nfts[rewardId].stakeType == 721) {
            stakingToken721 = IERC721(nfts[rewardId].stakingToken);
            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

        } else if (nfts[rewardId].stakeType == 1155) {
            stakingToken1155 = IERC1155(nfts[rewardId].stakingToken);
            require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

        } else if (nfts[rewardId].stakeType == 20) {
            stakingToken20 = IERC20(nfts[rewardId].stakingToken);
            require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

        }

        amount = count * nfts[rewardId].stakeValue * (nfts[rewardId].rewardCost / 100);
        return (amount);
    }

    function getReward(uint256 stakeId, uint256 rewardId) payable public nonReentrant {
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;
        uint256 amount;
        uint256 i;
        uint256 count;
        uint256 j;

        require(Address.isContract(msg.sender) == false, "Staking: No contracts");
        require(nfts[rewardId].deposit, "Staking: this token cannot be claimed");
        require(msg.value >= 99 * cost(stakeId,rewardId) / 100, "Staking: must pay cost to claim reward");

        // update the current reward balance
        _updateRewards(stakeId);
        uint256 reward = nfts[stakeId].rewards[msg.sender];
        require(reward > 0, "Staking: no rewards to pay out");
        require(nfts[rewardId].totalStake > 0, "Staking: no reward balance available to pay out");

        if (nfts[rewardId].stakeType == 721) {
            stakingToken721 = IERC721(nfts[rewardId].stakingToken);
            amount = reward / nfts[rewardId].stakeValue;

            if (amount > nfts[rewardId].totalStake) {
                amount = nfts[rewardId].totalStake;
            }

            if (amount > 0) {
                for (i = 0; i < amount; i += 1) {
                    for (j = 0; j < nfts[rewardId].stakeList.length; j += 1) {
                        if (nfts[rewardId].stakeList[j] > 0) {
                            // Transfer user's NFTs
                            stakingToken721.safeTransferFrom(address(this), msg.sender, nfts[rewardId].stakeList[j]);

                            // Increment the amount which will be withdrawn
                            count += 1;
                            // Cleanup stakedAssets for the current tokenId
                            nfts[rewardId].stakedAssets[nfts[rewardId].stakeList[j]] = address(0);
                            nfts[rewardId].stakeList[j] = 0;
                            break;
                        }
                    }
                }
            }

        } else if (nfts[rewardId].stakeType == 1155) {
            stakingToken1155 = IERC1155(nfts[rewardId].stakingToken);
            require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            stakingToken1155.safeTransferFrom(address(this), msg.sender, nfts[rewardId].stakeID, count, bytes(""));

        } else if (nfts[rewardId].stakeType == 20) {
            stakingToken20 = IERC20(nfts[rewardId].stakingToken);
            require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            stakingToken20.safeTransfer(msg.sender, count);
        }

        nfts[rewardId].totalStake -= count;
        amount = count * nfts[rewardId].stakeValue;
        nfts[rewardId].rewards[msg.sender] -= amount;
    }

    // pause staking
    function pause(uint256 id) external onlyOwner {
        nfts[id].paused = true;
    }

    // unpause staking
    function unpause(uint256 id) external onlyOwner {
//        require(nfts[id].rewardRate > 0, "Staking: Reward is 0, use notifyRewardAmount");
//        require(nfts[id].rewardsDuration > 0, "Staking: Duration is 0, use setRewardsDuration");
        nfts[id].paused = false;
    }

    function updateRewards(uint256 id) external nonReentrant {
        _updateRewards(id);
    }

    /**
     * @notice function that update pending rewards
     * and shift them to rewardsToClaim
     * @dev update rewards claimable
     * and check the time spent since deposit for the `msg.sender`
     */
    function _updateRewards(uint256 id) internal {
        uint256 endPeriod = nfts[id].userStartTime[msg.sender] + nfts[id].stakingDuration;

        nfts[id].rewards[msg.sender] = _calculateRewards(msg.sender, id);
        nfts[id].userStartTime[msg.sender] = (block.timestamp >= endPeriod)
            ? endPeriod
            : block.timestamp;
    }

    /**
     * @notice calculate rewards based on the `APY`, `_percentageTimeRemaining()`
     * @dev the higher is the precision and the more the time remaining will be precise
     * @param stakeHolder, address of the user to be checked
     * @return uint amount of claimable tokens of the specified address
     */
    function _calculateRewards(address stakeHolder, uint256 id)
        internal
        view
        returns (uint)
    {
        if (nfts[id].stakedBalance[stakeHolder] == 0) {
            return 0;
        }

        return
            (((nfts[id].stakedBalance[stakeHolder] * nfts[id].APY) *
                _percentageTimeRemaining(stakeHolder, id)) / (_precision * 100)) * (nfts[id].stakeValue) +
            nfts[id].rewards[stakeHolder];
    }

    /**
     * @notice function that returns the remaining time in seconds of the staking period
     * @dev the higher is the precision and the more the time remaining will be precise
     * @param stakeHolder, address of the user to be checked
     * @return uint percentage of time remaining * precision
     */
    function _percentageTimeRemaining(address stakeHolder, uint256 id)
        internal
        view
        returns (uint)
    {
        uint startTime;
        uint256 endPeriod = nfts[id].userStartTime[stakeHolder] + nfts[id].stakingDuration;

        if (endPeriod > block.timestamp) {
            startTime = nfts[id].userStartTime[stakeHolder];
            uint timeRemaining = nfts[id].stakingDuration -
                (block.timestamp - startTime);
            return
                (_precision * (nfts[id].stakingDuration - timeRemaining)) /
                nfts[id].stakingDuration;
        }
        startTime = nfts[id].stakingDuration - (endPeriod - nfts[id].userStartTime[stakeHolder]);
        return (_precision * (nfts[id].stakingDuration - startTime)) / nfts[id].stakingDuration;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint16[] tokenIds);
    event Withdrawn(address indexed user, uint256 amount, uint16[] tokenIds);
}