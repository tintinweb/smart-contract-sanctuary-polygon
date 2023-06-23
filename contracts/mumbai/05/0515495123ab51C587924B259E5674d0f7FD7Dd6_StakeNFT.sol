// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";


//Reward Token interface
interface Token {

    function transfer(address recipient, uint256 amount) external returns(bool);

    function balanceOf(address account) external view returns(uint256);

}

//NFT staking interface
interface NFT {

    function transferFrom(address from, address to, uint256 tokenId) external;

}


contract StakeNFT is Pausable, Ownable, ReentrancyGuard {

    Token erc20Token;
    NFT nftToken;

    uint256 public planCount;
    uint256 public claimTime = 60;

    /* planId => plan mapping */
    mapping(uint256 => Plan) public plans;
    /* tokenId => token info */
    mapping(uint256 => TokenInfo) public tokenInfos;
    // Mapping owner address to stake token count
    mapping(address => uint256) public userStakeCnt;
    // Mapping from token ID to staker address
    mapping(uint256 => address) public stakers;
    /* address->array index->tokenId */
    mapping(address => mapping(uint256 => uint256)) stakedTokens;
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) stakedTokensIndex;
    //maping for address=> tokenid => claim_timing
    mapping(address => mapping(uint256 => uint256)) public nextClaimTime;
    mapping(address => mapping(uint256 => uint256)) lastClaimTime;

    struct Plan {
        uint256 rewardBal;
        uint256 maxApyPer;
        uint256 maxCount;
        uint256 stakeCount;
        uint256 currCount;
        uint256 maxUsrStake;
        uint256 lockSeconds;
        uint256 expireSeconds;
        uint256 perNFTPrice;
        uint256 closeTS;
    }

    struct TokenInfo {
        uint256 planId;
        uint256 startTS;
        uint256 endTS;
        uint256 claimed;
    }

    event StakePlan(uint256 id);
    event Staked(address indexed from, uint256 planId, uint256[] _ids);
    event UnStaked(address indexed from, uint256[] _ids);
    event Claimed(address indexed from, uint256[] _ids, uint256 amount);
    event RewardPercentage(uint256 rewardPercentage, uint256 reward, uint256 totalreward);

    //Constructor
    constructor(Token _tokenAddress, NFT _nfttokenAddress) {
        require(address(_tokenAddress) != address(0), "Token Address cannot be address 0");
        require(address(_nfttokenAddress) != address(0), "NFT Token Address cannot be address 0");
        erc20Token = _tokenAddress;
        nftToken = _nfttokenAddress;
    }

    //User
    function stakeNFT(uint256 _planId, uint256[] calldata _ids) public whenNotPaused {
        Plan storage plan = plans[_planId];
        require(plan.rewardBal > 0, "Invalid staking plan");
        require(block.timestamp < plan.closeTS, "Plan Expired");
        require(_ids.length > 0, "Invalid arguments");
        require((plan.currCount + _ids.length) <= plan.maxCount, "NFT Collection Staking limit exceeded");
        require((userStakeCnt[_msgSender()] + _ids.length) <= plan.maxUsrStake, "User Staking limit exceeded");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            nftToken.transferFrom(_msgSender(), address(this), id);
            plan.currCount++;
            plan.stakeCount++;
            stakers[id] = _msgSender();
            stakedTokens[_msgSender()][userStakeCnt[_msgSender()]] = _ids[i];
            lastClaimTime[_msgSender()][id] = block.timestamp;
            nextClaimTime[_msgSender()][id] = block.timestamp + claimTime;
            stakedTokensIndex[id] = userStakeCnt[_msgSender()]; // check utility
            userStakeCnt[_msgSender()]++;
            tokenInfos[id] = TokenInfo({
                planId: _planId,
                startTS: block.timestamp,
                endTS: 0,
                claimed: 0
            });
        }
        emit Staked(_msgSender(), _planId, _ids);
    }

    function claimReward(uint256[] calldata _ids) public nonReentrant {
        require(_ids.length > 0, "invalid arguments");
        uint256 totalClaimAmt = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            require(stakers[_ids[i]] == _msgSender(), "NFT does not belong to sender address");
            require(nextClaimTime[msg.sender][_ids[i]] < block.timestamp, "wait till next claimable timing");
            uint256 elapsedTime = block.timestamp - lastClaimTime[msg.sender][_ids[i]];
            uint256 rewardPercentage;
            if (elapsedTime >= 60 && elapsedTime <= 599) {
                rewardPercentage = (elapsedTime / 60) * 10;
            } else if (elapsedTime >= 600) {
                rewardPercentage = 100;
            }
            uint256 reward = (getUnClaimedReward(_ids[i]) * rewardPercentage) / 100;
            require(reward > 0, "You have no rewards to claim.");
            totalClaimAmt = reward; // ading reward to totalclaimamount     
            //only for developer use             
            uint256 rewardacctualpercentage = ((totalClaimAmt * 100) / getUnClaimedReward(_ids[i]));
            emit RewardPercentage(rewardacctualpercentage, totalClaimAmt, getUnClaimedReward(_ids[i]));
            tokenInfos[_ids[i]].claimed += reward;
            lastClaimTime[msg.sender][_ids[i]] = block.timestamp;
            nextClaimTime[msg.sender][_ids[i]] = block.timestamp + claimTime;
        }
        require(totalClaimAmt > 0, "Claim amount invalid.");
        require(erc20Token.transfer(_msgSender(), totalClaimAmt), "Token transfer failed!");
        emit Claimed(_msgSender(), _ids, totalClaimAmt);
    }

    function withdrawNFT(uint256[] calldata _ids) public whenNotPaused nonReentrant {
        require(_ids.length > 0, "Invalid arguments");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(stakers[id] == _msgSender(), "NFT is not staked by sender address");
            require(tokenInfos[id].endTS == 0, "NFT is already unstaked");
            require(block.timestamp > (tokenInfos[id].startTS + plans[tokenInfos[id].planId].lockSeconds), "NFT cannot be unstaked before locking period");
            nftToken.transferFrom(address(this), _msgSender(), id);
            plans[tokenInfos[id].planId].currCount--;
            tokenInfos[id].endTS = block.timestamp;
            unStakeUserNFT(_msgSender(), id); // minus from array, adjust array length
            userStakeCnt[_msgSender()]--;
            stakers[id] = address(0);
            nextClaimTime[msg.sender][id] = 0;
        }
        _claimStakeReward(_msgSender(), _ids);
        emit UnStaked(_msgSender(), _ids);
    }

    //View
    function getCurrentAPR(uint256 planId) public view returns(uint256) {
        require(plans[planId].rewardBal > 0, "Invalid staking plan");
        uint256 perNFTShare;
        uint256 stakingBucket = plans[planId].rewardBal;
        uint256 currstakeCount = plans[planId].currCount == 0 ? 1 : plans[planId].currCount; // avoid divisible by 0 error
        uint256 maxNFTShare = (currstakeCount * plans[planId].perNFTPrice * plans[planId].maxApyPer) / 100;
        if (maxNFTShare < stakingBucket)
            perNFTShare = maxNFTShare / currstakeCount;
        else perNFTShare = stakingBucket / currstakeCount;
        return (perNFTShare * 100) / plans[planId].perNFTPrice;
    }

    //only for developer use // MAKE IT ZERO FOR OTHER USER WHO HAVE NOT STAKED IT, IF IT WANT TO MAKE AVILABLE FOR USER IT IS SHOWING TIMESTAMP VALUE FOR THE OTHER USER
    function getElapsedTime(address _user, uint256 _id) public view returns(uint256) {
        if (stakers[_id] != _user) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp - lastClaimTime[_user][_id];
        return elapsedTime;
    }

    function getRewardPercentage(address _user, uint256 _id) public view returns(uint256) {
        if (stakers[_id] != _user) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp - lastClaimTime[_user][_id];
        uint256 rewardPercentage;
        if (elapsedTime >= 1 && elapsedTime <= 59) {
            return 0;
        }
        if (elapsedTime >= 60 && elapsedTime <= 119) {
            rewardPercentage = 10;
        } else if (elapsedTime >= 120 && elapsedTime <= 179) {
            rewardPercentage = 20;
        } else if (elapsedTime >= 180 && elapsedTime <= 239) {
            rewardPercentage = 30;
        } else if (elapsedTime >= 240 && elapsedTime <= 299) {
            rewardPercentage = 40;
        } else if (elapsedTime >= 300 && elapsedTime <= 359) {
            rewardPercentage = 50;
        } else if (elapsedTime >= 360 && elapsedTime <= 419) {
            rewardPercentage = 60;
        } else if (elapsedTime >= 420 && elapsedTime <= 479) {
            rewardPercentage = 70;
        } else if (elapsedTime >= 480 && elapsedTime <= 539) {
            rewardPercentage = 80;
        } else if (elapsedTime >= 540 && elapsedTime <= 599) {
            rewardPercentage = 90;
        } else if (elapsedTime >= 600) {
            rewardPercentage = 100;
        }
        return rewardPercentage;
    }

    function getUnClaimedReward(uint256 tokenId) public view returns(uint256) {
        require(tokenInfos[tokenId].startTS > 0, "Token not staked");
        uint256 apr;
        uint256 anualReward;
        uint256 perSecondReward;
        uint256 stakeSeconds;
        uint256 reward;
        uint256 matureTS;
        apr = getCurrentAPR(tokenInfos[tokenId].planId);
        anualReward = (plans[tokenInfos[tokenId].planId].perNFTPrice * apr) / 100;
        perSecondReward = anualReward / (365 * 86400);
        matureTS = tokenInfos[tokenId].startTS + plans[tokenInfos[tokenId].planId].expireSeconds;
        if (tokenInfos[tokenId].endTS == 0)
            if (block.timestamp > matureTS)
                stakeSeconds = matureTS - tokenInfos[tokenId].startTS;
            else stakeSeconds = block.timestamp - tokenInfos[tokenId].startTS;
        else if (tokenInfos[tokenId].endTS > matureTS)
            stakeSeconds = matureTS - tokenInfos[tokenId].startTS;
        else
            stakeSeconds = tokenInfos[tokenId].endTS - tokenInfos[tokenId].startTS;
        uint256 multiplier;
        if (tokenId >= 1 && tokenId <= 10) {
            multiplier = 1;
        } else if (tokenId >= 21 && tokenId <= 30) {
            multiplier = 5;
        } else if (tokenId >= 31 && tokenId <= 40) {
            multiplier = 10;
        } else if (tokenId >= 41 && tokenId <= 50) {
            multiplier = 25;
        } else if (tokenId >= 51 && tokenId <= 60) {
            multiplier = 50;
        } else if (tokenId >= 61 && tokenId <= 70) {
            multiplier = 100;
        } else if (tokenId >= 71 && tokenId <= 80) {
            multiplier = 250;
        } else if (tokenId >= 81 && tokenId <= 90) {
            multiplier = 500;
        }
        reward = stakeSeconds * perSecondReward * multiplier;
        reward = reward - tokenInfos[tokenId].claimed;
        return reward;
    }

    function tokensOfStaker(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = userStakeCnt[_owner];
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = stakedTokens[_owner][i];
        }
        return result;
    }

    //Internal
    function _claimStakeReward(address sender, uint256[] calldata _ids) internal {
        require(_ids.length > 0, "invalid arguments");
        uint256 totalClaimAmt = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 claimAmt = getUnClaimedReward(_ids[i]);
            if (claimAmt > 0) {
                tokenInfos[_ids[i]].claimed += claimAmt;
                totalClaimAmt += claimAmt;
            }
        }
        if (totalClaimAmt > 0) {
            emit Claimed(sender, _ids, totalClaimAmt);
            require(erc20Token.transfer(sender, totalClaimAmt), "Token transfer failed!");
        }
    }

    function unStakeUserNFT(address from, uint256 tokenId) internal {
        uint256 lastTokenIndex = userStakeCnt[from] - 1;
        uint256 tokenIndex = stakedTokensIndex[tokenId];
        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = stakedTokens[from][lastTokenIndex];
            stakedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            stakedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        // This also deletes the contents at the last position of the array
        delete stakedTokensIndex[tokenId];
        delete stakedTokens[from][lastTokenIndex];
    }

    //Admin
    function pause() public onlyOwner {
        _pause();
    }

    function setClaimTime(uint256 _claimTime) public onlyOwner {
        claimTime = _claimTime;
    }

    function setStakePlan(
        uint256 id,
        uint256 _rewardBal,
        uint256 _maxApyPer,
        uint256 _maxCount,
        uint256 _maxUsrStake,
        uint256 _lockSeconds,
        uint256 _expireSeconds,
        uint256 _perNFTPrice,
        uint256 _planExpireSeconds
    ) public onlyOwner {
        if (plans[id].maxApyPer == 0) {
            planCount++;
        }
        plans[id].rewardBal = _rewardBal; // Staking reward bucket
        plans[id].maxApyPer = _maxApyPer;
        plans[id].maxCount = _maxCount;
        plans[id].maxUsrStake = _maxUsrStake;
        plans[id].lockSeconds = _lockSeconds; // stake lock seconds
        plans[id].expireSeconds = _expireSeconds; // yield maturity seconds
        plans[id].perNFTPrice = _perNFTPrice;
        plans[id].closeTS = block.timestamp + _planExpireSeconds; // plan closing timestamp
        emit StakePlan(id);
    }

    function transferNFT(address to, uint256 tokenId) public onlyOwner {
        nftToken.transferFrom(address(this), to, tokenId);
    }

    function transferToken(address to, uint256 amount) public onlyOwner {
        require(erc20Token.transfer(to, amount), "Token transfer failed!");
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}