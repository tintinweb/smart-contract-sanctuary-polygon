/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IACO2 {
    function totalSupply() external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

interface ICBY {
    function balanceOf(address _user) external view returns(uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ICarbify {
    function mintNFTree(uint256) external;
    function balanceOf(address _address, uint256 _id) external view returns(uint256);
    function getNFTreeId() external pure returns(uint256);
    function NFTreeSupply() external pure returns(uint256);
    function getStandardId() external pure returns(uint256);
    function getPremiumId() external pure returns(uint256);
    function getGenesisId() external pure returns(uint256);
    function getAco2Id() external pure returns(uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract Stake {
    ICarbify internal immutable carbify;
    ICBY internal immutable cby;
    IACO2 internal immutable aco2;
    address public owner;
    uint256 public maxStakeStandard = 15;
    uint256 public maxStakePremium = 30;
    uint256 public maxStakeGenesis = 50;
    uint256 public stakingFees = 5;
    uint256 public unstakePercentage = 2;
    uint256 constant public STANDARD_BONUS = 80;
    uint256 constant public PREMIUM_BONUS = 90;
    uint256 constant public GENESIS_BONUS = 100;
    uint256 constant public REWARD_PERCENTAGE = 15;
    uint256 constant internal SECONDS_IN_DAY = 60;
    enum Plots { STANDARD, PREMIUM, GENESIS }
    struct Staking {
        uint256[] NFTreeAmount;
        uint256[] time;
        Plots[] plot;
        uint256[] withdraws;
    }
    //mapping from addresses to staked balances
    mapping (address => Staking) internal stakedBalances;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAddressNotNull(address _user) {
        require(_user != address(0), "Address cannot be NULL address");
        _;
    }
    
    constructor(address _aco2, address _cby, address _carbify) {
        aco2 = IACO2(_aco2);
        cby = ICBY(_cby);
        carbify = ICarbify(_carbify);
        owner = msg.sender; 
        stakingFees = stakingFees * 10**decimals();
    }

    function decimals() public pure returns(uint256) {
        return 18;
    }

    //function to get the staked NFTrees on particular plot
    function _getStakedAmountOnPlot(Plots plot) internal view returns (uint256) {
        uint256 amount;
        for(uint256 i = 0; i < stakedBalances[msg.sender].NFTreeAmount.length; i++) {
            if(stakedBalances[msg.sender].plot[i] == plot) {
                amount += stakedBalances[msg.sender].NFTreeAmount[i];
            }
        }
        return amount;
    }

    function getStakedAmountOnStandard() public view returns (uint256) {
        return _getStakedAmountOnPlot(Plots.STANDARD);
    }
    function getStakedAmountOnPremium() public view returns (uint256) {
        return _getStakedAmountOnPlot(Plots.PREMIUM);
    }
    function getStakedAmountOnGenesis() public view returns (uint256) {
        return _getStakedAmountOnPlot(Plots.GENESIS);
    }

    function _stake(uint256 _amountNFTree, uint256 _plotMaxStake, uint256 _plotId, Plots _plot) internal {
        require(carbify.balanceOf(msg.sender, carbify.getNFTreeId()) >= _amountNFTree && carbify.balanceOf(msg.sender, carbify.getNFTreeId()) > 0, "Not enough NFTrees available to stake");
        //1 NFTree staking will cost 5cby
        require(cby.balanceOf(msg.sender) > stakingFees * _amountNFTree, "Not Enough $CBY available");
        require(cby.allowance(msg.sender, address(this)) >= stakingFees * _amountNFTree, "Not Enough $CBY allowed to STAKE contract!");
        //get the staked amount of NFTrees on particular plot
        uint256 amountStaked = _getStakedAmountOnPlot(_plot);
        //check if nftrees are less than max limit of staking on plots
        require(amountStaked + _amountNFTree <= carbify.balanceOf(msg.sender, _plotId) * _plotMaxStake, "Not enough space available on your plots.");
        require(carbify.isApprovedForAll(msg.sender, address(this)), "Stake contract not approved for NFTrees.");
        //transfer staking fee to this contract
        cby.transferFrom(msg.sender, address(this), stakingFees * _amountNFTree);
        carbify.safeTransferFrom(msg.sender, address(this), carbify.getNFTreeId(), _amountNFTree, "");
        //stakedBalances[msg.sender].isStaked = true;
        stakedBalances[msg.sender].NFTreeAmount.push(_amountNFTree);
        stakedBalances[msg.sender].plot.push(_plot);
        stakedBalances[msg.sender].time.push(block.timestamp);
        stakedBalances[msg.sender].withdraws.push(0);
    }

    function stakeOnStandard(uint256 _amountNFTree) public {
        _stake(_amountNFTree, maxStakeStandard, carbify.getStandardId(), Plots.STANDARD);
    }

    function stakeOnPremium(uint256 _amountNFTree) public {
        _stake(_amountNFTree, maxStakePremium, carbify.getPremiumId(), Plots.PREMIUM);
    }

    function stakeOnGenesis(uint256 _amountNFTree) public {
        _stake(_amountNFTree, maxStakeGenesis, carbify.getGenesisId(), Plots.GENESIS);
    }

    function _unstakeCleanup() internal {
        stakedBalances[msg.sender].NFTreeAmount.pop();
        stakedBalances[msg.sender].time.pop();
        stakedBalances[msg.sender].plot.pop();
        stakedBalances[msg.sender].withdraws.pop();
    }

    function _unstake(uint256 _amount, Plots _plot) internal {
        uint256 stakedAmount = _getStakedAmountOnPlot(_plot);
        require(_amount <= stakedAmount, "Not enough trees staked on this plot");
        //reverse deleting the staked amount for performance and space (using pop())
        for(uint256 i = stakedBalances[msg.sender].NFTreeAmount.length-1; i >= 0; i--) {
            if(_amount == stakedBalances[msg.sender].NFTreeAmount[i]) {
                _unstakeCleanup();
                break;
            }
            else if(_amount > stakedBalances[msg.sender].NFTreeAmount[i]) {
                _amount -= stakedBalances[msg.sender].NFTreeAmount[i];
                _unstakeCleanup();
            }
            else if(_amount < stakedBalances[msg.sender].NFTreeAmount[i]) {
                stakedBalances[msg.sender].NFTreeAmount[i] -= _amount;
                break;
            }
        }
        carbify.safeTransferFrom(address(this), msg.sender, carbify.getNFTreeId(), _amount, "");
        cby.transfer(msg.sender, stakingFees - ((stakingFees * unstakePercentage) / 100));
    }

    function unstakeStandard(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0 value");
        _unstake(_amount, Plots.STANDARD);
    }

    function unstakePremium(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0 value");
        _unstake(_amount, Plots.PREMIUM);
    }

    function unstakeGenesis(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0 value");
        _unstake(_amount, Plots.GENESIS);
    }

    function getStakedAmount(address _user) isAddressNotNull(_user) external view returns(uint256) {
        uint256 amount;
        for(uint256 i = 0; i < stakedBalances[_user].NFTreeAmount.length; i++) {
            amount += stakedBalances[_user].NFTreeAmount[i];
        }
        return(amount);
    }

    function calculateAvailableReward(address _user) isAddressNotNull(_user) external view returns (uint256){
        uint256 reward;
        for(uint256 i = 0; i < stakedBalances[_user].NFTreeAmount.length; i++) {
            uint256 daysStaked = (block.timestamp - stakedBalances[_user].time[i]) / SECONDS_IN_DAY;
            uint256 withdraws = stakedBalances[_user].withdraws[i];
            if(daysStaked - withdraws > 0) {
                uint256 nftreePercentage = (carbify.NFTreeSupply() * stakedBalances[_user].NFTreeAmount[i]) / 1000;
                if(stakedBalances[_user].plot[i] == Plots.STANDARD) {
                    uint256 dayReward = (nftreePercentage * STANDARD_BONUS) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                }
                else if(stakedBalances[_user].plot[i] == Plots.PREMIUM) {
                    uint256 dayReward = (nftreePercentage * PREMIUM_BONUS) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                }
                else if(stakedBalances[_user].plot[i] == Plots.GENESIS) {
                    uint256 dayReward = (nftreePercentage * GENESIS_BONUS) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                }
            }
        }
        return reward;
    }

    function withdrawAllReward() external {
        uint256 reward;
        for(uint256 i = 0; i < stakedBalances[msg.sender].NFTreeAmount.length; i++) {
            uint256 daysStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / SECONDS_IN_DAY;
            uint256 withdraws = stakedBalances[msg.sender].withdraws[i];
            if(daysStaked - withdraws > 0) {
                uint256 nftreePercentage = (carbify.NFTreeSupply() * stakedBalances[msg.sender].NFTreeAmount[i]) / 1000;
                if(stakedBalances[msg.sender].plot[i] == Plots.STANDARD) {
                    uint256 dayReward = (nftreePercentage * STANDARD_BONUS) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                    stakedBalances[msg.sender].withdraws[i] += 1;
                }
                else if(stakedBalances[msg.sender].plot[i] == Plots.PREMIUM) {
                    uint256 dayReward = (nftreePercentage * PREMIUM_BONUS) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                    stakedBalances[msg.sender].withdraws[i] += 1;
                }
                else if(stakedBalances[msg.sender].plot[i] == Plots.GENESIS) {
                    uint256 dayReward = (nftreePercentage * GENESIS_BONUS) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                    stakedBalances[msg.sender].withdraws[i] += 1;
                }
            }
        }
        require(reward > 0, "Reward Not Available Yet!");
        aco2.transferFrom(owner, msg.sender, reward);
    }

    function _withdrawReward(Plots _plot, uint256 _bonus) internal {
        uint256 reward;
        for(uint256 i = 0; i < stakedBalances[msg.sender].NFTreeAmount.length; i++) {
            if(stakedBalances[msg.sender].plot[i] == _plot) {
                uint256 daysStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / SECONDS_IN_DAY;
                uint256 withdraws = stakedBalances[msg.sender].withdraws[i];
                if(daysStaked - withdraws > 0) {
                    uint256 nftreePercentage = (carbify.NFTreeSupply() * stakedBalances[msg.sender].NFTreeAmount[i]) / 1000;
                    uint256 dayReward = (nftreePercentage * _bonus) / 100;
                    reward += (daysStaked - withdraws) * dayReward;
                    stakedBalances[msg.sender].withdraws[i] += 1;
                }
            }
        }
        require(reward > 0, "Reward Not Available Yet!");
        aco2.transferFrom(owner, msg.sender, reward);
    }

    function withdrawStandard() public {
        _withdrawReward(Plots.STANDARD, STANDARD_BONUS);
    }

    function withdrawPremium() public {
        _withdrawReward(Plots.PREMIUM, PREMIUM_BONUS);
    }

    function withdrawGenesis() public {
        _withdrawReward(Plots.GENESIS, GENESIS_BONUS);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}