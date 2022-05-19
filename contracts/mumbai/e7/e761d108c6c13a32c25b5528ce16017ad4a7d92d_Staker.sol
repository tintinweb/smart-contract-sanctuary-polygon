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

//add support for finding decimals of erc20
abstract contract IERC20Extented is IERC20 {
    function decimals() virtual public view returns (uint8);
}

contract Staker is ERC1155Holder, ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    event PaymentReceived(address from, uint256 amount);

    uint256 public nftCount;
    uint256 public ethValue = 2350;
    //uint256 costId;
    uint256 public debug1;
    uint256 public debug2;
    //uint256 public debug3;

    struct NFT {
        string tokenName;
        bool paused;
        bool rewardToken;
        address stakingToken;
        uint16 stakeType;
        uint16 stakeID;
        uint16 APY;
        uint16[] stakeList;
        uint64 stakingDuration;
        uint256 stakeValue;
        uint256 totalStake;
        uint16 rewardCost;
        mapping(address => uint256) userStartTime;
        mapping(address => uint256) userEndTime;
        mapping(address => uint256) rewards;
        mapping(address => uint256) stakedBalance;
        mapping(uint16 => address) stakedAssets;
    }
    NFT[] public nfts;

    /*struct PAIR {
        uint16 stakeId;
        uint16 rewardId;
        bool enabled;
        uint16 costReward;
        uint16 costSwap;
    }
    PAIR[] public pairs; */

    uint256 constant internal _precision = 1E18;

    constructor() payable {        
        //add eth as first set so it can be used to collect fees
        AddNFT("ethereum", address(0), false, 1, 365, 0, 50, ethValue, 0);
        unpause(0);
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /*function pairData(uint256 _stakeId, uint256 _rewardId) public view returns (bool, uint16, uint16) {
        bool _enabled = true;
        uint16 _costReward;
        uint16 _costSwap;

        for (uint16 i = 0; i < pairs.length; i += 1) {
            if (pairs[i].stakeId == _stakeId && pairs[i].rewardId == _rewardId) {
                _enabled = pairs[i].enabled;
                _costReward = pairs[i].costReward;
                _costSwap = pairs[i].costSwap;
            }
        }
        return (_enabled, _costReward, _costSwap);
    }
    */

    function test() public onlyOwner {
        AddNFT("afro coin", 0xfC176dd6267f965e055d762474D09b54c638Eea9, true, 20, 0, 0, 0, 1, 0);
		unpause(1);
        AddNFT("classic Movies nft", 0xa7409DB31D48373BffCAD1eA7ba41074705f873F, false, 721, 36500, 0, 100, 100, 10);
		unpause(2);
        AddNFT("Flixu nft 1000", 0xDF137aF0CB56850834f6d601b07f46ab787581F0, false, 1155, 36500, 4, 100, 1000, 0);
		unpause(3);
        AddNFT("Flixu nft 10", 0xDF137aF0CB56850834f6d601b07f46ab787581F0, true, 1155, 0, 0, 0, 10, 0);
		unpause(4);
        AddNFT("classic Movies nft", 0xa7409DB31D48373BffCAD1eA7ba41074705f873F, true, 721, 0, 0, 0, 100, 10);
		unpause(5);
        AddNFT("afro coin", 0xfC176dd6267f965e055d762474D09b54c638Eea9, false, 20, 36500, 0, 100, 1, 0);
		unpause(6);
        AddNFT("Flixu nft 1000", 0xDF137aF0CB56850834f6d601b07f46ab787581F0, true, 1155, 0, 4, 0, 1000, 0);
		unpause(7);
    }

    function setEth(uint256 _cost) external onlyOwner {
        require(_cost > 0, "Staking: not 0");
        ethValue = _cost;
        nfts[0].stakeValue = _cost;
    }

    function AddNFT(string memory _tokenName, address _stakingToken, bool _rewardToken, uint16 _stakeType, uint16 _APY, uint16 _stakeID, uint16 _duration, uint256 _stakeValue, uint16 _rewardCost) public onlyOwner {
        uint256 count;

        //test types before adding
        if (_stakeType == 721) {
            require(IERC721(_stakingToken).supportsInterface(0x80ac58cd),"Staking: not 721");
        } else if (_stakeType == 1155) {
            require(IERC1155(_stakingToken).supportsInterface(0xd9b67a26),"Staking: not 1155");
        } else if (_stakeType == 20) {
            require(IERC20(_stakingToken).totalSupply() > 0,"Staking: not 20");
            require(IERC20Extented(_stakingToken).decimals() > 0,"Staking: missing decimals");
        } else if (_stakeType == 1) {
            //accept ethereum for staking
        } else {
            require(false, "Staking: wrong stake type");
        }

        if (_stakeType != 1155) {
            _stakeID = 0;
        }

        for (uint16 i = 0; i < nftCount; i += 1) {
            if (nfts[i].rewardToken == _rewardToken && nfts[i].stakingToken == _stakingToken && nfts[i].stakeID == _stakeID) {
                count = 1;
                break;
            }
        }
        require(count == 0, "Staking: already exists");
        require(_stakeValue > 0, "Staking: must have value");

        nfts.push();
        nftCount += 1;
        nfts[nftCount-1].tokenName = _tokenName;
        nfts[nftCount-1].stakingToken = _stakingToken;
        nfts[nftCount-1].rewardToken = _rewardToken;
        nfts[nftCount-1].stakeType = _stakeType;
        nfts[nftCount-1].stakeID = _stakeID;
        nfts[nftCount-1].paused = true;
        if (_rewardToken) {
            nfts[nftCount-1].APY = 0;
            nfts[nftCount-1].stakingDuration = 0;
        } else {
            require(_APY > 0, "Staking: must have apy for staking token");
            require(_duration > 0, "Staking: must have duration for staking token");
            nfts[nftCount-1].APY = _APY;
            nfts[nftCount-1].stakingDuration = _duration * 1 days;
        }
        nfts[nftCount-1].rewardCost = _rewardCost;
        if (_stakeType == 20 && !_rewardToken || _stakeType == 1) {
            nfts[nftCount-1].stakeValue = _stakeValue;
        } else {
            nfts[nftCount-1].stakeValue = _stakeValue * _precision;
        }
    }

    function updateNFT(uint256 id, string memory _tokenName, uint16 _APY, uint16 _duration, uint256 _stakeValue, uint16 _rewardCost) external onlyOwner {
        require(id < nftCount, "Staking: id does not exist");
        require(_stakeValue > 0, "Staking: must have value");

        if (!nfts[id].rewardToken) {
            require(_APY > 0, "Staking: must have apy for staking token");
            require(_duration > 0, "Staking: must have duration for staking token");
        }

        nfts[id].tokenName = _tokenName;
        nfts[id].APY = _APY;
        nfts[id].rewardCost = _rewardCost;
        nfts[id].stakingDuration = _duration * 1 days;
        nfts[id].stakeValue = _stakeValue * _precision;
    }

    function userData(uint256 id) public view returns (uint256, uint256, uint256, uint256) {
        return (nfts[id].userStartTime[msg.sender], nfts[id].rewards[msg.sender], nfts[id].stakedBalance[msg.sender], _calculateRewards(msg.sender, id));
    }

    /*
    function userStart(uint256 id) public view returns (uint256) {
        return (nfts[id].userStartTime[msg.sender]);
    }

    function userRewards(uint256 id) public view returns (uint256) {
        return (nfts[id].rewards[msg.sender]);
    }

    function userBalance(uint256 id) public view returns (uint256) {
        return (nfts[id].stakedBalance[msg.sender]);
    }

    function userPending(uint256 id) public view returns (uint256) {
        return (_calculateRewards(msg.sender, id));
    }
    */

    function swap(uint256 payId, uint256 receiveId, uint16[] memory tokenIds, uint256 count) payable external nonReentrant {
        uint256 reward;

        require(nfts[payId].rewardToken, "Staking: can't use this token as payment");
        require(nfts[receiveId].rewardToken, "Staking: can't use this token as payment");

        //transfer asset to contract
        _stake(payId, tokenIds, count);

        //give credit for asset
        if (nfts[payId].stakeType == 721) {
            require(tokenIds.length > 0, "Staking: No tokenIds provided");
            reward = tokenIds.length * nfts[payId].stakeValue;
            count = tokenIds.length;
        } else if (nfts[payId].stakeType == 20 || nfts[payId].stakeType == 1155) {
            require(count > 0,"Staking: not zero");
            reward = count * nfts[payId].stakeValue;
        }  else if (nfts[payId].stakeType == 1) {
            reward = msg.value * ethValue;
            count = msg.value;
        }

        nfts[payId].rewards[msg.sender] += reward;

        //take ownership
        if (nfts[payId].stakeType == 721) {
            for (uint16 i = 0; i < tokenIds.length; i += 1) {
                nfts[payId].stakedAssets[tokenIds[i]] = owner();
            }
        }

        nfts[payId].stakedBalance[msg.sender] -= count;
        nfts[payId].stakedBalance[owner()] += count;

        //send token to new owner
        _getReward(payId, receiveId, reward);
    }
     
    function stake(uint256 id, uint16[] memory tokenIds, uint256 count) payable external nonReentrant {
        _stake(id, tokenIds, count);
    }

    /// @notice Stakes user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be staked
    function _stake(uint256 id, uint16[] memory tokenIds, uint256 count) internal {
        uint256 amount;
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;
        
        require(id < nftCount, "Staking: id does not exist");
        require(Address.isContract(msg.sender) == false, "Staking: no contracts");
        require(nfts[id].paused == false, "Staking: is paused");

        if (nfts[id].stakeType == 721) {
            require(tokenIds.length != 0, "Staking: No tokenIds provided");
            stakingToken721 = IERC721(nfts[id].stakingToken);

            require(stakingToken721.isApprovedForAll(msg.sender, address(this)) == true,
                "Staking: First must setApprovalForAll in the NFT to this contract");

            for (uint16 i = 0; i < tokenIds.length; i += 1) {
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
            count = amount;

        } else if (nfts[id].stakeType == 1155) {
            require(count > 0, "Staking: count must be > 0");
            stakingToken1155 = IERC1155(nfts[id].stakingToken);
            require(stakingToken1155.balanceOf(msg.sender, nfts[id].stakeID) >= count, "Staking: not owner of this count of NFT");
            require(stakingToken1155.isApprovedForAll(msg.sender, address(this)) == true,
                "Staking: First must setApprovalForAll in the NFT to this contract");

            // Transfer user's NFTs to the staking contract
            stakingToken1155.safeTransferFrom(msg.sender, address(this), nfts[id].stakeID, count, bytes(""));

            // Save who is the staker/depositor of the token
            //nfts[id].stakedBalance[msg.sender] += count;
            //nfts[id].totalStake += count;

        } else if (nfts[id].stakeType == 20) {
            require(count > 0, "Staking: count must be > 0");
            stakingToken20 = IERC20(nfts[id].stakingToken);

            require(stakingToken20.balanceOf(msg.sender) >= count, "Staking: not owner of this balance of token");
            require(stakingToken20.allowance(msg.sender, address(this)) >= count,
                "Staking: First must set allowance in the token to this contract");

            // Transfer user's NFTs to the staking contract
            stakingToken20.transferFrom(msg.sender, address(this), count);

            // Save who is the staker/depositor of the token
            //nfts[id].stakedBalance[msg.sender] += count;
            //nfts[id].totalStake += count;

        } else if (nfts[id].stakeType == 1) {
            require(msg.value > 0, "Staking: not received any ethereum");
            count = msg.value;

            // Save who is the staker/depositor of the token
            //nfts[id].stakedBalance[msg.sender] += msg.value;
            //emit Staked(msg.sender, msg.value, tokenIds);
            //nfts[id].totalStake += msg.value;
        }

        nfts[id].stakedBalance[msg.sender] += count;
        nfts[id].totalStake += count;

        if (!nfts[id].rewardToken) {
            if (nfts[id].userStartTime[msg.sender] == 0) {
                nfts[id].userStartTime[msg.sender] = block.timestamp;
                nfts[id].userEndTime[msg.sender] = block.timestamp + nfts[id].stakingDuration;
            }
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
        require(id < nftCount, "Staking: id does not exist");

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

            //nfts[id].stakedBalance[msg.sender] -= 0;
            //nfts[id].totalStake -= amount;

        } else if (nfts[id].stakeType == 1155) {
            stakingToken1155 = IERC1155(nfts[id].stakingToken);

            if (stakingToken1155.balanceOf(address(this), nfts[id].stakeID) < nfts[id].stakedBalance[msg.sender]) {
                amount = stakingToken1155.balanceOf(address(this), nfts[id].stakeID);
            } else {
                amount = nfts[id].stakedBalance[msg.sender];
            }            
            //nfts[id].stakedBalance[msg.sender] = 0;
            //nfts[id].totalStake -= amount;

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
            //nfts[id].stakedBalance[msg.sender] = 0;
            //nfts[id].totalStake -= amount;

            if (amount > 0) {
                //debug1 = amount;
                SafeERC20.safeTransfer(stakingToken20, msg.sender, amount);
            } else {
                //debug2 = 1;
            }

        } else if (nfts[id].stakeType == 1) {

            if (address(this).balance < nfts[id].stakedBalance[msg.sender]) {
                amount = address(this).balance;
            } else {
                amount = nfts[id].stakedBalance[msg.sender];
            }

            //nfts[id].stakedBalance[msg.sender] = 0;

            if (amount > 0) {
                payable(msg.sender).transfer(amount);
            //} else {
            //    debug1=999;
            }
        }

        nfts[id].stakedBalance[msg.sender] = 0;
        nfts[id].totalStake -= amount;
    }

    function cost(uint256 stakeId, uint256 rewardId) public view returns (uint256) {
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;
        uint256 amount;
        uint256 count;
        uint16 rate;

        //require(Address.isContract(msg.sender) == false, "Staking: No contracts");
        require(stakeId < nftCount, "Staking: id does not exist");
        require(rewardId < nftCount, "Staking: id does not exist");
        //require(!nfts[stakeId].rewardToken, "Staking: this token must be staked");
        //require(nfts[rewardId].rewardToken, "Staking: this token cannot be claimed");

        // update the current reward balance
        //uint256 reward = nfts[stakeId].rewards[msg.sender];
        uint256 reward = _calculateRewards(msg.sender, stakeId);
        //require(reward > 0, "Staking: no rewards to pay out");
        //require(nfts[rewardId].totalStake > 0, "Staking: no reward balance available to pay out");

        if (nfts[rewardId].rewardCost > 0) {
            rate = nfts[rewardId].rewardCost;
        } else {
            rate = nfts[stakeId].rewardCost;
        }

        if (nfts[rewardId].stakeType == 721) {
            stakingToken721 = IERC721(nfts[rewardId].stakingToken);
            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            //amount of eth in gwei
            amount = count * nfts[rewardId].stakeValue * rate / 100 / ethValue;

        } else if (nfts[rewardId].stakeType == 1155) {
            stakingToken1155 = IERC1155(nfts[rewardId].stakingToken);
            //require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            count = reward / nfts[rewardId].stakeValue;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            amount = count * nfts[rewardId].stakeValue * rate / 100 / ethValue;

        } else if (nfts[rewardId].stakeType == 20) {
            stakingToken20 = IERC20(nfts[rewardId].stakingToken);
            //require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            count = (10 ** IERC20Extented(nfts[rewardId].stakingToken).decimals()) * reward / nfts[rewardId].stakeValue;
            //debug2 = reward;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            //debug1 = count;

            amount = count * nfts[rewardId].stakeValue / (10 ** IERC20Extented(nfts[rewardId].stakingToken).decimals());
            //debug2 = amount;

            amount = amount * rate / 100 / ethValue;
            //debug3 = amount;
            //amount = _precision * count * nfts[rewardId].stakeValue * rate / 100 / ethValue / (10 ** IERC20Extented(nfts[rewardId].stakingToken).decimals());

            //amount = count * nfts[rewardId].stakeValue * rate / 100 / ethValue / (10 ** IERC20Extented(nfts[rewardId].stakingToken).decimals());
        }

        return (amount);
    }

    function getReward(uint256 stakeId, uint256 rewardId, uint256 count) payable public nonReentrant {
        require(!nfts[stakeId].rewardToken, "Staking: this token must be staked");
        _getReward(stakeId, rewardId, count);
    }

    function _getReward(uint256 stakeId, uint256 rewardId, uint256 _count) internal {
        IERC721 stakingToken721;
        IERC1155 stakingToken1155;
        IERC20 stakingToken20;
        uint256 amount;
        uint256 i;
        uint256 count;
        uint256 j;
        uint256 reward;
        uint256 rewardCost;

        require(Address.isContract(msg.sender) == false, "Staking: No contracts");
        require(stakeId < nftCount, "Staking: id does not exist");
        require(rewardId < nftCount, "Staking: id does not exist");
        require(nfts[rewardId].rewardToken, "Staking: this token cannot be claimed");
        //require(nfts[rewardId].stakeValue > 0,"Staking value is 0");

        // update the current reward balance
        _updateRewards(stakeId);
        reward = nfts[stakeId].rewards[msg.sender];
        //debug2 = reward;
        //require(_count < reward, "Staking: cannot claim more than reward balance");
        //allow partial claim of reward
        if (_count > 0 && count < reward) {
            reward = _count;
        }
        rewardCost = cost(stakeId,rewardId);

        require(reward > 0, "Staking: no rewards to pay out");
        require(msg.value >= rewardCost, "Staking: must pay cost to claim reward");
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

            amount = count * nfts[rewardId].stakeValue;

        } else if (nfts[rewardId].stakeType == 1155) {
            stakingToken1155 = IERC1155(nfts[rewardId].stakingToken);

            //debug1 = reward;

            count = reward / nfts[rewardId].stakeValue;
            //debug2 = count;

            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            amount = count * nfts[rewardId].stakeValue;
            //debug3 = amount;

            stakingToken1155.safeTransferFrom(address(this), msg.sender, nfts[rewardId].stakeID, count, bytes(""));

        } else if (nfts[rewardId].stakeType == 20) {
            stakingToken20 = IERC20(nfts[rewardId].stakingToken);
            //require(nfts[rewardId].totalStake > 0, "Staking: no balance for rewards");

            //count = _precision * reward / nfts[rewardId].stakeValue;

            //require(reward > 0, "error 1");
            //count = reward / nfts[rewardId].stakeValue;
            //require(count > 0, "error 2");
            count = (10 ** IERC20Extented(nfts[rewardId].stakingToken).decimals()) * reward / nfts[rewardId].stakeValue;
            //require(count > 0, "error 3");
 
            if (count > nfts[rewardId].totalStake) {
                count = nfts[rewardId].totalStake;
            }

            amount = count * nfts[rewardId].stakeValue / (10 ** IERC20Extented(nfts[rewardId].stakingToken).decimals());
            //require(count > 0, "error 4");

            //require(amount > 0, "error 5");
            //amount = coun
            //debug1 = amount;
            //debug2 = count;
            //stakingToken20.safeTransfer(msg.sender, count);
            SafeERC20.safeTransfer(stakingToken20, msg.sender, count);
        }

        //require(nfts[rewardId].totalStake >= count, "error 6");
        nfts[rewardId].totalStake -= count;
        //debug1 = amount;
        //debug2 = nfts[rewardId].rewards[msg.sender];
        //require(nfts[stakeId].rewards[msg.sender] >= amount, "error 7");
        nfts[stakeId].rewards[msg.sender] -= amount;

        //refund overpayment
        if (msg.value - rewardCost > 0) {
            payable(msg.sender).transfer(msg.value - rewardCost);
        }

        //allocate fee to owner
        if (rewardCost > 0) {
            nfts[0].stakedBalance[owner()] += rewardCost;
        }
    }

    // pause staking
    function pause(uint256 id) external onlyOwner {
        require(id < nftCount, "Staking: id does not exist");
        nfts[id].paused = true;
    }

    // unpause staking
    function unpause(uint256 id) public onlyOwner {
        require(id < nftCount, "Staking: id does not exist");
        nfts[id].paused = false;
    }

    function updateRewards(uint256 id) external nonReentrant {
        require(id < nftCount, "Staking: id does not exist");
        _updateRewards(id);
    }

    /**
     * @notice function that update pending rewards
     * and shift them to rewardsToClaim
     * @dev update rewards claimable
     * and check the time spent since deposit for the `msg.sender`
     */
    function _updateRewards(uint256 id) internal {
        require(id < nftCount, "Staking: id does not exist");

        //uint256 endPeriod = nfts[id].userStartTime[msg.sender] + nfts[id].stakingDuration;
        uint256 endPeriod = nfts[id].userEndTime[msg.sender];
        //uint256 calRewards = _calculateRewards(msg.sender, id);

        nfts[id].rewards[msg.sender] = _calculateRewards(msg.sender, id);

        nfts[id].userStartTime[msg.sender] = (block.timestamp >= endPeriod)
            ? endPeriod
            : block.timestamp;
    }

    /**
     * @notice calculate rewards based on the `APY`, `_percentageTimeRemaining()`
     * @dev the higher is the precision and the more the time remaining will be precise
     * @param stakeHolder, address of the user to be checked
     * @return uint256 amount of claimable tokens of the specified address
     */
    function _calculateRewards(address stakeHolder, uint256 id) internal view returns (uint256) {
        uint256 cal;
        require(id < nftCount, "Staking: id does not exist");
        //require(!nfts[id].rewardToken, "Staking: this token is not staked");

        if (nfts[id].stakedBalance[stakeHolder] == 0 || nfts[id].rewardToken) {
            cal = 0;
        } else {
            cal = nfts[id].stakedBalance[stakeHolder] * nfts[id].APY * _percentageTimeRemaining(stakeHolder, id) * nfts[id].stakeValue / _precision / 100;
        }

        //uint256 balance = nfts[id].stakedBalance[stakeHolder];
        //uint256 remaining = _percentageTimeRemaining(stakeHolder, id);

            
        //if (nfts[id].stakeType == 20) {
        //    require(IERC20Extented(nfts[id].stakingToken).decimals() > 0,"Staking: problem with decimals");
        //    cal = cal / (10 ** IERC20Extented(nfts[id].stakingToken).decimals());
        //}

        //cal = cal + nfts[id].rewards[stakeHolder];

        //uint256 cal = (((nfts[id].stakedBalance[stakeHolder] * nfts[id].APY) *
        //        _percentageTimeRemaining(stakeHolder, id)) / (_precision * 100)) * (nfts[id].stakeValue) +
        //    nfts[id].rewards[stakeHolder];

        return (cal + nfts[id].rewards[stakeHolder]);
    }

    /**
     * @notice function that returns the remaining time in seconds of the staking period
     * @dev the higher is the precision and the more the time remaining will be precise
     * @param stakeHolder, address of the user to be checked
     * @return uint256 percentage of time remaining * precision
     */
    function _percentageTimeRemaining(address stakeHolder, uint256 id) internal view returns (uint256) {
        uint256 startTime;

        require(id < nftCount, "Staking: id does not exist");
        //require(nfts[id].stakingDuration > 0, "Staking: duration is 0");

        //uint256 endPeriod = nfts[id].userStartTime[stakeHolder] + nfts[id].stakingDuration;
        uint256 endPeriod = nfts[id].userEndTime[msg.sender];

        if (endPeriod > block.timestamp) {
            startTime = nfts[id].userStartTime[stakeHolder];
            //uint256 timeRemaining = nfts[id].stakingDuration - (block.timestamp - startTime);
            uint256 timeRemaining = nfts[id].stakingDuration - (block.timestamp - startTime);
            return
                (_precision * (nfts[id].stakingDuration - timeRemaining)) /
                nfts[id].stakingDuration;
        }
        startTime = nfts[id].stakingDuration - (endPeriod - nfts[id].userStartTime[stakeHolder]);
        return (_precision * (nfts[id].stakingDuration - startTime)) / nfts[id].stakingDuration;
    }

    //event RewardAdded(uint256 reward);
    //event Staked(address indexed user, uint256 amount, uint16[] tokenIds);
    //event Withdrawn(address indexed user, uint256 amount, uint16[] tokenIds);
}