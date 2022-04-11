//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHiveGenesisContract {

    function ownerOf(uint256 tokenId) external returns(address);

}

contract HiveMaintenanceFees is Ownable {

    ///@notice this is used to calculate the percent (ie 7% = 70 / 1000)
    uint constant BASIS_POINTS = 1000;

    IHiveGenesisContract hiveGenesis;

    IRewardPool rewardPool;

    IERC20 honeyContract;

    bool setup = true;

    ///@notice this mapping keeps track of when the nft has to pay next
    mapping(uint => uint) public nextTimePeriodToPayFee;

    //No of days to pay the recurring maintanance fee. - 30 Days
    uint public constant subscriptionInterval = 30 days;

    ///@notice this is the mapping used to calculate token rewards, maps from token id to timestamp
    mapping(uint256 => uint256) public lastClaimedTimestamp;

    address public charity;

    address public treasuryPool;

    address public acceptedAddress;

    /// @notice mapping used to set custom token generation for winners of the queen auction
    mapping(uint => uint) public customEmissionRate;

    ///@notice this is a mapping that keeps track of the rewards rate claimed when updating.
    mapping(uint => uint) public rewardsIndexLastClaimed;

    ///@notice this is a struct that keeps track of all the reward rates for the tokens
    struct EmissionRate {
        uint customMultiplier;
        uint[] rates;
        uint[] ranges;
        uint timeSet;
    }

    uint public immutable deploymentTime;

    uint public monthlyTributeFee = 3 ether;

    //Tax to claim honey rewards
    uint public claimTax = 0;

    //Max amount the claim tax can be set (15%)
    uint public constant maxClaimTax = 150;

    event MintTimeSet(uint id, uint time);

    event ClaimTimeSet(uint id, uint time);

    event RewardClaimed(address indexed user, uint amount);

    ///@notice this is a list that holds the information on the rewards rates
    EmissionRate[] emissionRates;

    struct FeeAllocation {
        address wallet;
        uint percent;
    }

    // List of wallet addresses and percentages to allocate mint fees
    FeeAllocation[] feeAllocations;

    constructor(address _HiveGenesis, address _honeyContract, address _charity, address _rewardPool, address _treasuryPool, uint _deploymentTime) {

        hiveGenesis = IHiveGenesisContract(_HiveGenesis);

        rewardPool = IRewardPool(_rewardPool);

        honeyContract = IERC20(_honeyContract);

        treasuryPool = _treasuryPool;

        charity = _charity;

        deploymentTime = _deploymentTime;

    }

    //Pay maintanence fees for multiple nfts, for a set number of months
    function payMultipleMaintenanceFees(uint[] calldata _ids, uint[] calldata _numMonths) external payable {

        uint feePerMonth = monthlyTributeFee;
        uint fee;
        
        require(_numMonths.length == _ids.length, "arrays need to be the same length");

        for(uint i = 0; i < _ids.length; i++) {

            uint numberMonths = _numMonths[i];

            uint nextTimePeriod = nextTimePeriodToPayFee[_ids[i]];

            fee += numberMonths * feePerMonth;

            nextTimePeriod += (numberMonths * subscriptionInterval);

            //make sure the amount of time being purchased doesn't cover maintanence for over 90 days
            require((block.timestamp + 90 days) >= nextTimePeriod, "Can only maintain up to 90 days in advance");

            nextTimePeriodToPayFee[_ids[i]] = nextTimePeriod;

        }

        require(fee == msg.value, "incorrect fee");

        //Transfer
        (bool sent,) = payable(treasuryPool).call{value: msg.value}("");
        require(sent, "Failed to send matic");

    }

    function claimRewards(uint[] calldata ids, uint percentToCharity) external {

        require(percentToCharity <= BASIS_POINTS, "Can't give more than 100% to charity");

        uint id;
        uint amount;

        EmissionRate[] memory rates = emissionRates;
        uint ratesIndex = rates.length - 1;

        for(uint i = 0; i < ids.length; i++) {

            id = ids[i];

            require(isMaintenanceFeePaid(id), "Please pay maintainance fee before claiming reward!");
            require(hiveGenesis.ownerOf(id) == msg.sender, "Reward claimer is not the owner of the NFT");
           
            amount += calculateReward(id, rates);
            
            if(rewardsIndexLastClaimed[id] !=  ratesIndex) {
                rewardsIndexLastClaimed[id] = ratesIndex;
            }

            lastClaimedTimestamp[id] = block.timestamp;

        }

        require(amount > 0, "No tokens to claim");

        internalClaimReward(amount, percentToCharity);

    }

    function internalClaimReward(uint _amount, uint _percentCharity) internal {

        uint toCharity = (_amount * _percentCharity) / BASIS_POINTS;

        uint toUser =  _amount - toCharity;

        if(claimTax > 0) {

            uint tax = (toUser * claimTax) / BASIS_POINTS;

            toUser -= tax;

            rewardPool.ClaimReward(tax, address(this));

        }

        if(toUser > 0) {

            rewardPool.ClaimReward(toUser, msg.sender);

        }

        if(toCharity > 0) {

            rewardPool.ClaimReward(toCharity, charity);

        }

        emit RewardClaimed(msg.sender, _amount);

    }

    //Calculate the reward earned for a paricular token, without rebase
    function calculateReward(uint id, EmissionRate[] memory rates) private view returns(uint256) {

        uint lastClaimed = lastClaimedTimestamp[id];

        uint rewardsIndex = rewardsIndexLastClaimed[id];
        uint emissionLength = emissionRates.length;

        if(rewardsIndex == emissionLength - 1) {

            uint256 timeDifference = block.timestamp - lastClaimed;

            return (timeDifference * internalGetTokenEmissionRate(id, emissionRates[rewardsIndex]));

        } else {

            ///@notice the rewards index isn't the last index in the emission list, meaning the rewards rates have changed since this token last claimed
            uint total;
            uint timeBetween;
            uint updateTime;

            for(uint i = rewardsIndex; i < emissionLength; i++) {

                if(i < emissionLength - 1) {

                    updateTime = rates[i + 1].timeSet;

                    if(lastClaimed > updateTime) {
                        ///@notice this handles the case where a nft was minted after rewards were updated, we skip this reward rate in this case
                        continue;
                    }

                    ///@notice need to find when the next update happened to calculate when this current rate stopped
                    timeBetween = updateTime - lastClaimed;

                    lastClaimed = updateTime;

                } else {

                    ///@notice this is the last in the loop, so there is no future updates
                    timeBetween = block.timestamp - lastClaimed;

                }

                total += (timeBetween * internalGetTokenEmissionRate(id, rates[i]));

            }

            return total;

        }
         
    }

    /**
    * @dev Get the rate of token generation for a nft
    */
    function getTokensEmissionRate(uint _tokenId) external view returns(uint) {

        EmissionRate memory _emissionRate = emissionRates[emissionRates.length - 1]; 

        return internalGetTokenEmissionRate(_tokenId, _emissionRate);

    }

    /**
    * @dev Get the rate of token generation for a nft, internal version to save gas
    */
    function internalGetTokenEmissionRate(uint _tokenId, EmissionRate memory _emissionRate) internal view returns(uint) {

        uint customEmissions = customEmissionRate[_tokenId];

        if(customEmissions > 0) {
            return (customEmissions * _emissionRate.customMultiplier) / BASIS_POINTS;
        }

        for(uint i = 0; i < _emissionRate.rates.length; i++) {

            if(_tokenId < _emissionRate.ranges[i]) {
                return  _emissionRate.rates[i];
            }

        }

        return 0;

    }

    //Calculate the rewards for multiple tokens
    ///@notice this will mostly be called by the front end application
    function getTokenRewards(uint[] calldata ids) external view returns(uint[] memory) {

        EmissionRate[] memory rates = emissionRates;

        uint[] memory rewards = new uint[] (ids.length);

        //calculate the rewards for each token Id
        for(uint i = 0; i < ids.length; i++) {

            uint id = ids[i];

            uint lastClaimed = lastClaimedTimestamp[id];

            uint rewardsIndex = rewardsIndexLastClaimed[id];
            uint emissionLength = emissionRates.length;

            if(rewardsIndex == emissionLength - 1) {

                uint timeDifference = block.timestamp - lastClaimed;

                rewards[i] = (timeDifference * internalGetTokenEmissionRate(id, emissionRates[rewardsIndex]));

            } else {

                ///@notice the rewards index isn't the last index in the emission list, meaning the rewards rates have changed since this token last claimed
                uint total;
                uint timeBetween;
                uint updateTime;

                for(uint j = rewardsIndex; j < emissionLength; j++) {

                    if(j < emissionLength - 1) {

                        updateTime = rates[j + 1].timeSet;

                        if(lastClaimed > updateTime) {
                            ///@notice this handles the case where a nft was minted after rewards were updated, we skip this reward rate in this case
                            continue;
                        }

                        ///@notice need to find when the next update happened to calculate when this current rate stopped
                        timeBetween = updateTime - lastClaimed;

                        lastClaimed = updateTime;

                    } else {

                        ///@notice this is the last in the loop, so there is no future updates
                        timeBetween = block.timestamp - lastClaimed;

                    }

                    total += (timeBetween * internalGetTokenEmissionRate(id, rates[j]));

                }

                rewards[i] = total;

            }


        }

        return rewards;
         
    }

    //Returns bool, whether maintainance fee is paid or not.
    function isMaintenanceFeePaid(uint id) public view returns(bool) {
        return (nextTimePeriodToPayFee[id] > block.timestamp);
    }

    /**
    * @dev used in setup and minting to set the last claimed timestamps
    */
    function setLastClaimed(uint _id, uint _time, bool _isMint) external {

        require(msg.sender == acceptedAddress, "can only be called by accepted address");
        require(_time <= block.timestamp, "has has to be less than current time");

        if (_isMint) {
            require(_time >= deploymentTime, "cant set before deployment time");
            require(lastClaimedTimestamp[_id] == 0, "Already set");
            require(hiveGenesis.ownerOf(_id) != address(0), "Token doesn't exist");
            nextTimePeriodToPayFee[_id] = _time + subscriptionInterval;
            

        } else {
            require(setup, "Can't call after initial setup");
            require(lastClaimedTimestamp[_id] > 0, "Minting time not set");
            require(_time > lastClaimedTimestamp[_id], "time needs to be after previous setting");
        }

        lastClaimedTimestamp[_id] = _time;
    }

    /**
    * @dev set the address that can set values to sync this contract with the nft contract
    * only the owners can call
    */
    function setAcceptedAddress(address _address) external onlyOwner {

        acceptedAddress = _address;

    }

    /**
    * @dev Set the timestamps of every token that has paid maintance on the nft contract past the initial maintanence
    */
    function setMaintanenceFeePaid(uint[] calldata _ids, uint[] calldata _timestamps) external onlyOwner {

        require(setup, "Cant call after initial setup");
        require(_ids.length == _timestamps.length, "Arrays need to be the same length");

        for(uint i = 0; i < _ids.length; i++) {

            nextTimePeriodToPayFee[_ids[i]] = _timestamps[i];

        }

    }

    /**
    * @dev sets the custom emmission rates of queens, can only be called once, and only by the owners
    */
    function setCustomEmmissionsRate(uint[] calldata ids, uint[] calldata values) external onlyOwner {

        require(customEmissionRate[1] == 0, "Rates have already been set");

        require(ids.length == values.length, "Lengths should be the same");

        for(uint i = 0; i < ids.length; i++) {

            customEmissionRate[ids[i]] = values[i];

        }

    }

    /**
    * @dev Changes the token generation rate of the nfts
    * Requires the sender to be the owner of this address
    */
    function setEmissionRates(uint[] calldata _ranges, uint[] calldata _rates, uint _customMultiplier) onlyOwner external {

        require(_ranges.length == _rates.length, "rates and ranges should be the same length");

        emissionRates.push(EmissionRate(_customMultiplier, _rates, _ranges, block.timestamp));

    }


    /**
    @dev set the initial emission rate
    */
    function setInitialEmissionRates(uint[] calldata _ranges, uint[] calldata _rates, uint _customMultiplier) onlyOwner external {

        require(setup, "Can only be called in setup");

        require(_ranges.length == _rates.length, "rates and ranges should be the same length");

        emissionRates.push(EmissionRate(_customMultiplier, _rates, _ranges, deploymentTime));

    }

    /**
    * @dev Change the monthly maintance fee cost required in order to claim rewards
    */
    function setMonthlyTributeFee(uint _fee) external onlyOwner {

        monthlyTributeFee = _fee;

    }

    /**
    * @dev Sets how the fees will be allocated when withdrawn
    * Requires the caller to be the owner of the contract
    */
    function setFeeAllocations(address[] calldata wallets, uint[] calldata percents) external onlyOwner {

        require(wallets.length == percents.length, "wallets and percents need to be the same length");

        if(feeAllocations.length > 0) {
            //delete the previous array to prevent previous values from remaining
            delete feeAllocations;
        }

        uint totalPercent;

        for(uint i = 0; i < wallets.length; i++) {

            FeeAllocation memory feeAllocation = FeeAllocation(wallets[i], percents[i]);

            totalPercent += feeAllocation.percent;
           
            feeAllocations.push(feeAllocation);

        }

        require(totalPercent == BASIS_POINTS, "Total percent does not add to 100%");

    }

    /**
    * @dev Claim the mints not send to the rewards pool, and send the honey + matic to the appropriate wallets, in the appropriate ratio
    * Requires the caller to be the owner of the contract
    */
    function claimFees() external onlyOwner {

        FeeAllocation[] memory _feeAllocations = feeAllocations;

        require(_feeAllocations.length > 0, "Fee allocations not set");

        uint maticBalance = address(this).balance;

        uint honeyBalance = honeyContract.balanceOf(address(this));


        for(uint i = 0; i < _feeAllocations.length; i++) {

            uint maticToClaim = (maticBalance * _feeAllocations[i].percent) / BASIS_POINTS;

            uint honeyToClaim = (honeyBalance * _feeAllocations[i].percent) / BASIS_POINTS;

            if(honeyToClaim > 0) {
                honeyContract.transfer(_feeAllocations[i].wallet, honeyToClaim);
            }

            if(maticToClaim > 0) {

                (bool sent, ) = _feeAllocations[i].wallet.call{value: maticToClaim}("");
                require(sent, "Failed to send Matic");

            }

        }

    }

    /**
    * @dev set a tax on claiming honey
    * Requires the caller to be the owner of the contract
    */
    function setClaimTax(uint _claimTax) external onlyOwner {

        require(_claimTax <= maxClaimTax, "Attempting to set claim tax above max");

        claimTax = _claimTax;

    }

    /**
    * @dev prevents setting the last time claimed for any token other than on mint
    */
    function stopSetup() external onlyOwner {

        setup = false;

    }


    receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
interface IRewardPool {

    function ClaimReward(uint _amount, address _address) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
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