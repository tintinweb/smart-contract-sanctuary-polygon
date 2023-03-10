/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IACO2 {
    function totalSupply() external view returns (uint256);
    function mint(uint256 _amount, address _user) external;
}

interface ICBY {
    function balanceOf(address _user) external view returns(uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ICarbifyCollection {
    function totalSupply(uint256 _id) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract Stake {
    address public owner;

    //Contracts (CBY, ACO2, Carbify Assets Collection) instance varibales 
    ICarbifyCollection internal immutable carbifyCollection;
    ICBY internal immutable cby;
    IACO2 internal immutable aco2;

    // Variables to store IDs of LandPlots Asset Collection
    uint256 public nftreesId;
    uint256 public standardPlotId;
    uint256 public premiumPlotId;
    uint256 public genesisPlotId;

    // Reward amount to be given to Tree holder per YEAR
    uint256 public perTreeReward;

    // Varibale to store no. of ACO2s claimed from the staking pool;
    uint256 aco2ClaimedStakingPool;

    uint256 public maxStakeStandard = 15;
    uint256 public maxStakePremium = 30;
    uint256 public maxStakeGenesis = 50;
    uint256 public stakingFees;
    uint256 public unstakePercentage = 2;
    uint256 public totalStakedOnStandard;
    uint256 public totalStakedOnPremium;
    uint256 public totalStakedOnGenesis;
    uint256 constant public STANDARD_BONUS = 80;
    uint256 constant public PREMIUM_BONUS = 90;
    uint256 constant public GENESIS_BONUS = 100;
    uint256 constant public STANDARD_REWARD = 20;
    uint256 constant public PREMIUM_REWARD = 30;
    uint256 constant public GENESIS_REWARD = 50;
    uint256 constant internal SECONDS_IN_DAY = 60;
    enum Plots { STANDARD, PREMIUM, GENESIS }
    struct Staking {
        uint256[] NFTreeAmount;
        uint256[] time;
        Plots[] plot;
        uint256[] withdraws;
        uint256[] withdrawTime;
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
    
    constructor(address _aco2, address _cby, address _carbifyCollection) {
        // Assigning initital plot IDs
        standardPlotId = 28748568534080502582852831881731188584351152061455937249726854950940951193360;
        premiumPlotId = 28748568534080502582852831881731188584351152061455937249726854949841439563084;
        genesisPlotId = 28748568534080502582852831881731188584351152061455937249726854948741927929308;

        // Batch 1 token ID
        nftreesId = 28748568534080502582852831881731188584351152061455937249726854947642416301532;
        
        // Initializing tokens and asset contract instances
        aco2 = IACO2(_aco2);
        cby = ICBY(_cby);
        carbifyCollection = ICarbifyCollection(_carbifyCollection);

        owner = msg.sender; 
        perTreeReward = 175 * 10**decimals();
        stakingFees = 5 * 10**decimals();
    }

    function decimals() public pure returns(uint256) {
        return 18;
    }

    // Function to return ACO2 generation per year per tree
    function getPerTreeAco2perYear() public view returns(uint256) {
        return 4 * perTreeReward;
    }

    // Function to return ACO2 generation per day per tree
    function getPerTreeAco2PerDay() public view returns(uint256) {
        return getPerTreeAco2perYear() / uint256(365);
    }

    // Function to return ACO2 generation per hour per tree
    function getPerTreeAco2PerHour() public view returns(uint256) {
        return getPerTreeAco2perYear() / uint256(365) / 24;
    }

    // Function to return ACO2 generation per minute per tree
    function getPerTreeAco2PerMin() public view returns(uint256) {
        return getPerTreeAco2perYear() / uint256(365) / 24 / 60;
    }

    // Function to return ACO2s pledged to the staking pool since 1st march caclulated by minutes
    function getAco2InStakingPool() public view returns(uint256) {
        
        // NFTrees sold till March 1, 2023
        uint256 nftreesSold = carbifyCollection.totalSupply(nftreesId);

        // Time(sec) since Epoch to March 1, 2023
        uint startDate = 1677628800;
        uint256 minsSinceMarchOne = ((block.timestamp - startDate) / 60);
        //uint256 minsSinceLastWithdraw = ((stakestakedBalances.staking[msg.sender].withdraws - startDate))
        uint256 totalAco2StakingPool = nftreesSold * getPerTreeAco2PerMin() * minsSinceMarchOne - aco2ClaimedStakingPool;
        
        return totalAco2StakingPool;
    }
    
    function setNftreesId(uint256 _id) onlyOwner external {
        require(_id > 0, "ID cannot be 0");
        nftreesId = _id;
    }
    function setStandardId(uint256 _id) onlyOwner external {
        require(_id > 0, "ID cannot be 0");
        standardPlotId = _id;
    }
    function setPremiumId(uint256 _id) onlyOwner external {
        require(_id > 0, "ID cannot be 0");
        premiumPlotId = _id;
    }
    function setGenesisId(uint256 _id) onlyOwner external {
        require(_id > 0, "ID cannot be 0");
        genesisPlotId = _id;
    }
    function setPerTreeReward(uint256 _amount) onlyOwner external {
        require(_amount != 0, "Reward cannot be 0");
        perTreeReward = _amount * 10**decimals();
    }

    // Function to get total numbers of NFTrees sold
    function getNFTreeSupply() public view returns(uint256) {
        return carbifyCollection.totalSupply(nftreesId);
    }
    
    // Function to fetch total staked trees on all plots
    function getTotalStakedTrees() public view returns(uint256) {
        return (totalStakedOnStandard + totalStakedOnPremium + totalStakedOnGenesis);
    }

    // Function to get no. of unstaked trees
    function getUnstakedTrees() public view returns(uint256) {
        return (getNFTreeSupply() - totalStakedOnStandard - totalStakedOnPremium - totalStakedOnGenesis);
    }

    // Function to get the staked NFTrees on particular plot
    function _getStakedAmountOnPlot(Plots plot, address user) internal view returns (uint256) {
        uint256 amount;
        for(uint256 i = 0; i < stakedBalances[user].NFTreeAmount.length; i++) {
            if(stakedBalances[user].plot[i] == plot) {
                amount += stakedBalances[user].NFTreeAmount[i];
            }
        }
        return amount;
    }

    function getStakedAmountOnStandard(address user) public view returns (uint256) {
        return _getStakedAmountOnPlot(Plots.STANDARD, user);
    }

    function getStakedAmountOnPremium(address user) public view returns (uint256) {
        return _getStakedAmountOnPlot(Plots.PREMIUM, user);
    }

    function getStakedAmountOnGenesis(address user) public view returns (uint256) {
        return _getStakedAmountOnPlot(Plots.GENESIS, user);
    }

    // Function to get staked amount on all trees
    function getStakedAmount(address _user) isAddressNotNull(_user) external view returns(uint256) {
        uint256 amount;
        for(uint256 i = 0; i < stakedBalances[_user].NFTreeAmount.length; i++) {
            amount += stakedBalances[_user].NFTreeAmount[i];
        }
        return(amount);
    }

    function _stake(uint256 _amountNFTree, uint256 _plotMaxStake, uint256 _plotId, Plots _plot) internal {
        // Check for NFTrees amount and Allowance
        require(carbifyCollection.balanceOf(msg.sender, nftreesId) >= _amountNFTree && carbifyCollection.balanceOf(msg.sender, nftreesId) != 0, "Not enough NFTrees available to stake");
        require(carbifyCollection.isApprovedForAll(msg.sender, address(this)), "Stake contract not approved for NFTrees.");

        // 1 NFTree staking will cost 5cby
        uint256 cbyAmount = stakingFees * _amountNFTree;
        require(cby.balanceOf(msg.sender) > cbyAmount, "Not Enough $CBY available");
        require(cby.allowance(msg.sender, address(this)) >= cbyAmount, "Not Enough $CBY allowed to STAKE contract!");
        
        // Get the staked amount of NFTrees on particular plot
        uint256 amountStaked = _getStakedAmountOnPlot(_plot, msg.sender);
        
        // Check if nftrees are less than max limit of staking on plots
        require(amountStaked + _amountNFTree <= carbifyCollection.balanceOf(msg.sender, _plotId) * _plotMaxStake, "Not enough space available on your plots.");
        
        // Transfer staking fee and trees to this contract
        cby.transferFrom(msg.sender, address(this), cbyAmount);
        carbifyCollection.safeTransferFrom(msg.sender, address(this), nftreesId, _amountNFTree, "");
    
        stakedBalances[msg.sender].NFTreeAmount.push(_amountNFTree);
        stakedBalances[msg.sender].plot.push(_plot);
        stakedBalances[msg.sender].time.push(block.timestamp);
        stakedBalances[msg.sender].withdraws.push(0);
        stakedBalances[msg.sender].withdrawTime.push(1677628800);
    }

    function stakeOnStandard(uint256 _amountNFTree) public {
        _stake(_amountNFTree, maxStakeStandard, standardPlotId, Plots.STANDARD);
        totalStakedOnStandard += _amountNFTree;
    }

    function stakeOnPremium(uint256 _amountNFTree) public {
        _stake(_amountNFTree, maxStakePremium, premiumPlotId, Plots.PREMIUM);
        totalStakedOnPremium += _amountNFTree;
    }

    function stakeOnGenesis(uint256 _amountNFTree) public {
        _stake(_amountNFTree, maxStakeGenesis, genesisPlotId, Plots.GENESIS);
        totalStakedOnGenesis += _amountNFTree;
    }

    // Function to delete the last elemnt of array
    function _unstakeCleanup() internal {
        stakedBalances[msg.sender].NFTreeAmount.pop();
        stakedBalances[msg.sender].time.pop();
        stakedBalances[msg.sender].plot.pop();
        stakedBalances[msg.sender].withdraws.pop();
    }

    function _unstake(uint256 _amount, Plots _plot) internal {
        uint256 stakedAmount = _getStakedAmountOnPlot(_plot, msg.sender);
        require(_amount <= stakedAmount, "Not enough trees staked on this plot");

        // Reverse deleting the staked amount for performance and space (using pop())
        for(uint256 i = stakedBalances[msg.sender].NFTreeAmount.length-1; i >= 0; i--) {

            // Checks last element in array and deletes it if equal
            // If amount is greater then pops last element
            // If amount is less then subtracts the amount from last element and exits th loop
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
        carbifyCollection.safeTransferFrom(address(this), msg.sender, nftreesId, _amount, "");
        cby.transfer(msg.sender, (stakingFees - ((stakingFees * unstakePercentage) / 100)) * _amount);
    }

    function unstakeStandard(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0 value");
        _unstake(_amount, Plots.STANDARD);
        totalStakedOnStandard -= _amount;
    }

    function unstakePremium(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0 value");
        _unstake(_amount, Plots.PREMIUM);
        totalStakedOnPremium -= _amount;
    }

    function unstakeGenesis(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0 value");
        _unstake(_amount, Plots.GENESIS);
        totalStakedOnGenesis -= _amount;
    }

    // Function to calculate ACO2 left in the staking pool (after giving back reward to staked trees)
    function _getReaminingAco2InStakingPool() internal view returns(uint256) {

        // Aco2 left from premium plots
        uint256 totalACO2LeftForPremium = (getPerTreeAco2PerMin() - (getPerTreeAco2PerMin() * PREMIUM_BONUS) / 100) * totalStakedOnPremium;
        uint256 totalACO2LeftForStandard = (getPerTreeAco2PerMin() - (getPerTreeAco2PerMin() * STANDARD_BONUS) / 100) * totalStakedOnStandard;
        uint256 totalACO2OfUnstakedTrees = getUnstakedTrees() * getPerTreeAco2PerMin();

        return totalACO2OfUnstakedTrees + totalACO2LeftForStandard + totalACO2LeftForPremium;
    }

    // Function returns ACO2 reward available from staking pool for all genesis staked trees
    function _getAco2PoolRewardGenesis() internal view returns(uint256) {
        return (((totalStakedOnGenesis * GENESIS_REWARD) * _getReaminingAco2InStakingPool() / uint256(100) / (totalStakedOnGenesis * GENESIS_REWARD + totalStakedOnPremium * PREMIUM_REWARD + totalStakedOnStandard * STANDARD_REWARD)) / 100 / 100 / 100) / totalStakedOnGenesis;
    }

    // Function returns ACO2 reward available from staking pool for all premium staked trees
    function _getAco2PoolRewardPremium() internal view returns(uint256) {
        return (((totalStakedOnPremium * PREMIUM_REWARD) * _getReaminingAco2InStakingPool() / uint256(100) / (totalStakedOnGenesis * GENESIS_REWARD + totalStakedOnPremium * PREMIUM_REWARD + totalStakedOnStandard * STANDARD_REWARD)) / 100 / 100 / 100) / totalStakedOnPremium;
    }

    // Function returns ACO2 reward available from staking pool for all standard staked trees
    function _getAco2PoolRewardStandard() internal view returns(uint256) {
        return (((totalStakedOnStandard * STANDARD_REWARD) * _getReaminingAco2InStakingPool() / uint256(100) / (totalStakedOnGenesis * GENESIS_REWARD + totalStakedOnPremium * PREMIUM_REWARD + totalStakedOnStandard * STANDARD_REWARD)) / 100 / 100 / 100) / totalStakedOnStandard;
    }

    // function _withdrawReward(Plots _plot, uint256 _bonus) internal {
    //     uint256 reward;
    //     for(uint256 i = 0; i < stakedBalances[msg.sender].NFTreeAmount.length; i++) {
    //         if(stakedBalances[msg.sender].plot[i] == _plot) {
    //             uint256 daysStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / SECONDS_IN_DAY;
    //             uint256 withdraws = stakedBalances[msg.sender].withdraws[i];
    //             if(daysStaked - withdraws > 0) {
    //                 uint256 nftreePercentage = ((getNFTreeSupply() * stakedBalances[msg.sender].NFTreeAmount[i]*10)/100)/100;
    //                 uint256 dayReward = (nftreePercentage * _bonus) / 100;
    //                 reward += (daysStaked - withdraws) * dayReward;
    //                 stakedBalances[msg.sender].withdraws[i] += 1;
    //             }
    //         }
    //     }
    //     require(reward > 0, "Reward Not Available Yet!");
    //     aco2.transferFrom(stakingPool, msg.sender, reward);
    // }

    function calculateAvailableReward(address _user) isAddressNotNull(_user) external view returns (uint256){
        uint256 stakingPoolReward;
        uint256 stakingBonusReward;
        for(uint256 i = 0; i < stakedBalances[_user].NFTreeAmount.length; i++) {
            if(stakedBalances[_user].plot[i] == Plots.STANDARD) {

                // For reward from Staking Pool
                uint256 withdrawMins =  (block.timestamp - stakedBalances[msg.sender].withdrawTime[i]) / 60;
                if (withdrawMins > 0) {
                    stakingPoolReward += (_getAco2PoolRewardStandard() * withdrawMins * stakedBalances[msg.sender].NFTreeAmount[i]) / totalStakedOnStandard;
                }

                // For reward from Staking Trees
                uint256 minStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / 60;
                withdrawMins = stakedBalances[msg.sender].withdraws[i];
                if(minStaked - withdrawMins > 0) {
                    stakingBonusReward += stakedBalances[msg.sender].NFTreeAmount[i] * (minStaked - withdrawMins) * ((STANDARD_BONUS * getPerTreeAco2PerMin() / 100)  + getPerTreeAco2PerMin());
                }
            }
            else if(stakedBalances[_user].plot[i] == Plots.PREMIUM) {
                // For reward from Staking Pool
                uint256 withdrawMins =  (block.timestamp - stakedBalances[msg.sender].withdrawTime[i]) / 60;
                if (withdrawMins > 0) {
                    stakingPoolReward += (_getAco2PoolRewardPremium() * withdrawMins * stakedBalances[msg.sender].NFTreeAmount[i]) / totalStakedOnPremium;
                }

                // For reward from Staking Trees
                uint256 minStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / 60;
                withdrawMins = stakedBalances[msg.sender].withdraws[i];
                if(minStaked - withdrawMins > 0) {
                    stakingBonusReward += stakedBalances[msg.sender].NFTreeAmount[i] * (minStaked - withdrawMins) * ((PREMIUM_BONUS * getPerTreeAco2PerMin() / 100)  + getPerTreeAco2PerMin());
                }
            }
            else if(stakedBalances[_user].plot[i] == Plots.GENESIS) {
                
                // For reward from Staking Pool
                uint256 withdrawMins =  (block.timestamp - stakedBalances[msg.sender].withdrawTime[i]) / 60;
                if (withdrawMins > 0) {
                    stakingPoolReward += (_getAco2PoolRewardGenesis() * withdrawMins * stakedBalances[msg.sender].NFTreeAmount[i]) / totalStakedOnGenesis;
                }

                // For reward from Staking Trees
                uint256 minStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / 60;
                withdrawMins = stakedBalances[msg.sender].withdraws[i];
                if(minStaked - withdrawMins > 0) {
                    stakingBonusReward += stakedBalances[msg.sender].NFTreeAmount[i] * (minStaked - withdrawMins) * ((GENESIS_BONUS * getPerTreeAco2PerMin() / 100)  + getPerTreeAco2PerMin());
                }
            }
        }
        return stakingPoolReward + stakingBonusReward;
    }

    function _withdrawReward(uint256 _aco2PoolRewardPlot, uint256 _totalStakedOnPlot, uint256 _bonus, Plots _plot) internal {
        uint256 stakingPoolReward;
        uint256 stakingBonusReward;
        //uint256 perTreePoolRewardGenesisPerMin = _getAco2PoolRewardGenesis() / totalStakedOnGenesis;
        //uint256 perTreePoolRewardPlotPerMin = _aco2PoolRewardPlot / _totalStakedOnPlot;
        for(uint256 i = 0; i < stakedBalances[msg.sender].NFTreeAmount.length; i++) {
            if(stakedBalances[msg.sender].plot[i] == _plot) {

                // For reward from Staking Pool
                uint256 withdrawMins =  (block.timestamp - stakedBalances[msg.sender].withdrawTime[i]) / 60;
                if (withdrawMins > 0) {
                    stakingPoolReward += (_aco2PoolRewardPlot * withdrawMins * stakedBalances[msg.sender].NFTreeAmount[i]) / _totalStakedOnPlot;
                    stakedBalances[msg.sender].withdrawTime[i] = block.timestamp;
                }

                // For reward from Staking Trees
                uint256 minStaked = (block.timestamp - stakedBalances[msg.sender].time[i]) / 60;
                withdrawMins = stakedBalances[msg.sender].withdraws[i];
                if(minStaked - withdrawMins > 0) {
                    stakingBonusReward += stakedBalances[msg.sender].NFTreeAmount[i] * (minStaked - withdrawMins) * ((_bonus * getPerTreeAco2PerMin() / 100)  + getPerTreeAco2PerMin());
                    stakedBalances[msg.sender].withdraws[i] += minStaked - withdrawMins;
                }
            }
        }
        require(stakingPoolReward + stakingBonusReward >= 1, "Reward not available yet");
        aco2.mint(stakingPoolReward + stakingBonusReward, msg.sender);
    }

    function withdrawStandard() public {
        require(getStakedAmountOnStandard(msg.sender) != 0, "Trees not staked on Standard!");
        _withdrawReward(_getAco2PoolRewardStandard(), totalStakedOnStandard, STANDARD_BONUS, Plots.STANDARD);
    }

    function withdrawPremium() public {
        require(getStakedAmountOnPremium(msg.sender) != 0, "Trees not staked on Premium!");
        _withdrawReward(_getAco2PoolRewardPremium(), totalStakedOnPremium, PREMIUM_BONUS, Plots.PREMIUM);
    }

    function withdrawGenesis() public {
        require(getStakedAmountOnGenesis(msg.sender) != 0, "Trees not staked on Genesis!");
        _withdrawReward(_getAco2PoolRewardGenesis(), totalStakedOnGenesis, GENESIS_BONUS, Plots.GENESIS);
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