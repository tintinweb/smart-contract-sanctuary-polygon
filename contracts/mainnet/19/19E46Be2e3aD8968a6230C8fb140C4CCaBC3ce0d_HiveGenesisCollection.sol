//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

///@notice using custom ERC721, same as @openzeppelin with an additional checkOwner function
import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IUniswapV2Router02.sol";

///@notice this is a copy of the HiveNFTTest with additional functions to help with testing
contract HiveGenesisCollection is ERC721, Ownable, VRFConsumerBase {

    using SafeERC20 for IERC20;

    uint constant maxMintPerTransaction = 5;
    
    ///@notice this is used to calculate the percent (ie 7% = 70 / 1000)
    uint constant BASIS_POINTS = 1000;

    uint constant maxSupply = 40000;

    uint public minted;

    IERC20 honeyContract;

    bool public isPublicMint;

    IUniswapV2Router02 uniswapV2Router;

    //Percent of mint to sell back into liquidity pool, set to 100% initially but can adjust
    uint percentToSell = 1000;

    //Tax to claim honey rewards
    uint public claimTax = 0;

    //Max amount the claim tax can be set (15%)
    uint public constant maxClaimTax = 150;


    ///@notice this is a struct that keeps track of all the reward rates for the tokens
    struct EmissionRate {
        uint customMultiplier;
        uint[] rates;
        uint[] ranges;
        uint timeSet;
    }

    ///@notice this is a list that holds the information on the rewards rates
    EmissionRate[] emissionRates;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint public currentSupply = 0;

    address treasuryPool;
    address charity;

    IRewardPool rewardPool;

    uint public rewardPoolPercent = 400;

    //No of days to pay the recurring maintanance fee. - 30 Days
    uint public constant subscriptionInterval = 30 days;

    ///@notice fee in matic to pay in order to keep claiming rewards
    uint public monthlyTributeFee = 3 ether;

    //Initial time period with restrictions
    uint specialTimePeriod;

    //Determines if only whitelisted opperators can use fransferFrom
    bool restrictedTrading = true;

    ///Maps

    /// @notice Mapping is used to keep track of the unminted token ids
    mapping(uint => uint) tokenIdMapping;

    /// @notice mapping used to set custom token generation for winners of the queen auction
    mapping(uint => uint) customEmissionRate;

    /// @notice mapping used to track mint requests to the address that requested it, sent to chainlink VRF
    mapping(bytes32 => address) VRFRequests;

    /// @notice mapping used to determine if an opperator is allowed to transfer the token on behalf of a user
    mapping(address => bool) whitelistedOpperators;

    ///@notice this is the mapping used to calculate token rewards, maps from token id to timestamp
    mapping(uint256 => uint256) private lastClaimedTimestamp;

    ///@notice this is a mapping that keeps track of the rewards rate claimed when updating.
    mapping(uint => uint) rewardsIndexLastClaimed;

    ///@notice this mapping keeps track of when the nft has to pay next
    mapping(uint => uint) public nextTimePeriodToPayFee;

    ///@notice this is used to keep track of number of nfts minted
    mapping(address => uint) numMinted;

    struct FeeAllocation {
        address wallet;
        uint percent;
    }

    // List of wallet addresses and percentages to allocate mint fees
    FeeAllocation[] feeAllocations;


    ///Events

    ///@notice this event is emitted for a single token 
    event RewardClaimed(address Sender, uint256 amount);

    string BASE_URI;


     /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     */
    constructor(address _honeyAddress, address _charity, address _rewardPool, address _VRFCoordinator, address _linkToken) 
        VRFConsumerBase(
            _VRFCoordinator, // VRF Coordinator
            _linkToken  // LINK Token
        )
        ERC721("Hive Genesis Collection", "HGC")
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 ether; // 0.0001 LINK (Varies by network)

        honeyContract = IERC20(_honeyAddress);

        charity = _charity;

        rewardPool = IRewardPool(_rewardPool);

        ///@notice get the sushiswap router on polygon
        uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

        //Approve the sushiswap contract to swap honey
        honeyContract.approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, 2**256-1);

    }

    /**
    * @dev Mint set amount of nfts
    * @notice The nfts don't get minted immediatly, but after a short delay chainlink will mint the requested nfts using a verifiable random number
    */
    function publicMint(uint _amount) external {

        require(isPublicMint, "Can't mint yet");
        require(_amount <= maxMintPerTransaction, "Attempting to mint too many at once");
        require(_amount + minted <= maxSupply, "Attempting to mint over max supply");
        require(LINK.balanceOf(address(this)) >= fee * _amount, "Not enough LINK - fill contract with faucet");

        if(block.timestamp < specialTimePeriod) {

            ///notice for the first 6 days we are limiting the number of nfts that can be in a wallet at once
            require(numMinted[msg.sender] + _amount < 11, "Can't have more than 10 nfts currently");

            numMinted[msg.sender] += _amount;

        }
        
        uint price = getItemPrice() * _amount;

        minted += _amount;

        // Transfer tokens to the reward pool and sell some to the liquidity pool
        splitAndTransferTokens(msg.sender, price);

        //For each nft minted, it will make a request for a random number from chainlink, and then chainlink will do the actual minting after a small delay
        for(uint i = 0; i < _amount; i++) {

            VRFRequests[getRandomNumber()] = msg.sender;

        }

    }

    /**
    * @dev Takes a randomNumber and creates an index within the range of nfts that can be minted, and mints
    */
    function mintRandom(uint _randomNumber, address _reciepient) internal {

        uint range = maxSupply - currentSupply;

        //Get a random number within the proper range
        uint index = ((_randomNumber % range) + 1);

        mintInternal(index, range, _reciepient);

    }

    function mintInternal(uint _index, uint _range, address _recipient) internal  {

        //Retrieve value set in the token mapping, value can range from 0 - maxSupply, if value is not zero, the token id to mint is the value set 
        uint value = tokenIdMapping[_index];

        if(value == 0) {
            //Value has not been set, so the token id to mint is the index chosen
            value = _index;
        }
        
        //mint the chosen tokenId
        _mint(_recipient, value);
        
        //now the range will be reduced by 1, so we need to set the value at index to the value at the end of the range,
        //if the end value is zero then set index's value to be the range
        uint finalValue = tokenIdMapping[_range];

        if(finalValue > 0) {
            //value is non zero and we no longer need it stored, so deleting it to refund caller some gas
            delete tokenIdMapping[_range];
        } else {
            //value is zero, so will use the token index  
            finalValue = _range;
        }

        //set the value of the end index to the chosen index, so that tokenId will still be chosen eventually
        tokenIdMapping[_index] = finalValue;

        uint time = block.timestamp;

        //Mark the timestamp of when minted, this is used to calculated rewards rate
        lastClaimedTimestamp[value] = time; 

        nextTimePeriodToPayFee[value] = time + subscriptionInterval;   
        
        currentSupply++;

    }

    /** 
     * Requests randomness 
    */
    function getRandomNumber() internal returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }

    /**
     * @dev Callback function used by VRF Coordinator, uses the number to mint a random nft
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {

        address owner = VRFRequests[requestId];

        // delete the request id to refund some gas, as its isnt needed anymore
        delete VRFRequests[requestId];
        
        //Call the function that mints the nft for the user
        mintRandom(randomness, owner);
       
    }

    ///@notice splits the mint price and sends the the appropriate pools, selling some honey to the liquidity pool in the process
    function splitAndTransferTokens(address from, uint amount) internal {

        // Get amount allocated to the reward pool and transfer to it
        uint toRewardPool = (amount * rewardPoolPercent) / (BASIS_POINTS);
        honeyContract.transferFrom(from, address(rewardPool), toRewardPool);

        // Get the rest of the tokens, and transfer to this contract
        amount -= toRewardPool;
        honeyContract.transferFrom(from, address(this), amount);

        if(percentToSell > 0) {

            //Get the percent that will be sold to the liquidity pool for matic to keep honey liquid while minting
            uint toSell = (amount * percentToSell) / BASIS_POINTS;

            address[] memory path = new address[](2);
            path[0] = address(honeyContract);
            path[1] = uniswapV2Router.WETH();

            //TODO: make sure this is a good deadline to set, im sure its fine because its already being included in the transaction if this code is running
            uint deadline = block.timestamp + 15;
            
            uniswapV2Router.swapExactTokensForETH(toSell, 0, path, address(this), deadline);

        }

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
            require(ownerOf(id) == msg.sender, "Reward claimer is not the owner of the NFT");
           
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

    //Pay maintenance fee
    function monthlyMaintenance(uint id, uint numMonths) external payable {

        uint feeToPay = maintenanceFeeToPay(numMonths);

        require(msg.value == feeToPay, "Insufficient amount to pay!");

        uint nextTime = nextTimePeriodToPayFee[id] + (numMonths * subscriptionInterval);

        //make sure the amount of time being purchased doesn't cover maintanence for over 90 days
        require((block.timestamp + 90 days) <= nextTime, "Can only maintain up to 90 days in advance");

        nextTimePeriodToPayFee[id] = nextTime;
        //Transfer
        (bool sent,) = payable(treasuryPool).call{value: msg.value}("");
        require(sent, "Failed to send matic");
    }

    function payMultipleMaintanceFees(uint[] calldata ids, uint numMonths) external payable {

        uint feeToPay = maintenanceFeeToPay(numMonths) * ids.length;

        require(msg.value == feeToPay, "Insufficient amount to pay!");

        uint nextTime;

        for(uint i = 0; i < numMonths; i++) {

            nextTime = nextTimePeriodToPayFee[ids[i]] + (numMonths * subscriptionInterval);

            //make sure the amount of time being purchased doesn't cover maintanence for over 90 days
            require((block.timestamp + 90 days) <= nextTime, "Can only maintain up to 90 days in advance");

            nextTimePeriodToPayFee[ids[i]] = nextTime;
        }

        //Transfer
        (bool sent,) = payable(treasuryPool).call{value: msg.value}("");
        require(sent, "Failed to send matic");

    }
    
    //View functions

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
            return (customEmissions * _emissionRate.customMultiplier / BASIS_POINTS);
        }

        for(uint i = 0; i < _emissionRate.rates.length; i++) {

            if(_tokenId < _emissionRate.ranges[i]) {
                return  _emissionRate.rates[i];
            }

        }

        return 0;

    }

    // Returns the price of item which will be incremented t0 0.5 Hives after every 8000 NFT
	function getItemPrice() public view returns (uint256) {
		return 10 ether + (0.5 ether * (minted / 8000));
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

    /**
    * @dev gets all nfts of a wallet within a range, this is used by the frontend.
    * range is included as the request to loop through all 40k tokenIds may be rejected
    */
    function getTokensOwnedByWallet(address _address, uint startingIndex, uint endingIndex) external view returns(uint[] memory) {

        uint[] memory tempTokenIds = new uint[](maxSupply);
        uint count = 0;

        for(uint i = startingIndex; i < endingIndex; i++) {

            //gets owner without reverting if token is owned by noone
            if(checkOwner(i) == _address) {
                tempTokenIds[count] = i;
                count++;
            }

        }

        uint[] memory finalTokenIds = new uint[](count);

        for(uint j = 0; j < count; j++) {

            finalTokenIds[j] = tempTokenIds[j];

        }

        return finalTokenIds;

    }


    //Returns total maintananceFee to pay for the given token ID//
    function maintenanceFeeToPay(uint numMonths) public view returns(uint) {
        
        return  numMonths * monthlyTributeFee;
    }

    //Returns bool, whether maintainance fee is paid or not.
    function isMaintenanceFeePaid(uint id) public view returns(bool) {
        return (nextTimePeriodToPayFee[id] > block.timestamp);
    }

     // ERC721 functions

    /**
    * @dev Returns whether `spender` is allowed to manage `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    * @notice If the spender isn't the owner, it will require the opperator to be whitelisted and approved, or no restictions 
    */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || ((getApproved(tokenId) == spender || isApprovedForAll(owner, spender)) && (whitelistedOpperators[spender] || !restrictedTrading)));
    }

     /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     * overridden to allow the BASEURI to be set
     */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    // owner functions 

    /**
    * @dev Sets the percent of the mint cost that will be sold to matic
    * Requires the sender to be the owner of this address
    */
    function setPercentToSell(uint _percent) external onlyOwner {

        require(_percent <= BASIS_POINTS, "Percent can't be above 100");
        percentToSell = _percent;

    }

    /**
    * @dev Sets the ability of a contract to transfer these nfts on behalf of the owner
    * Requires the sender to be the owner of this address
    */
    function updateWhitelistedOpperators(address _address, bool value) external onlyOwner {

        whitelistedOpperators[_address] = value;

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
    * @dev Opens up the public mint, and stops premint
    * Requires the sender to be the owner of this address
    */
    function SetMintingPublic() external onlyOwner {

        isPublicMint = true;

    }

    /**
    * @dev Mints nfts of the specified tokenId, which will be used to airdrop the queens won in the queen auction, and some to vc's/team members.
    * Requires the sender to be the owner of this address, and the public mint to not be live
    */
    function queenMint(uint[] calldata _tokenIds, uint[] calldata _emissionRates, address[] calldata _reciepients) external onlyOwner {

        require(isPublicMint == false, "Cannot call when minting is public");

        require(_tokenIds.length == _emissionRates.length && _tokenIds.length == _reciepients.length, "Lists are not the same size");


        uint range = maxSupply - minted;

        for(uint i = 0; i < _tokenIds.length; i++) {


            mintInternal(_tokenIds[i], range, _reciepients[i]);

            if(_emissionRates[i] > 0) {

                customEmissionRate[_tokenIds[i]] = _emissionRates[i];

            }

            range--;

        }

        minted += _tokenIds.length;

    }


    /**
    * @dev Mints aggreed upon amount to vc investors using chainlink to generate a randomnumber an mint the nft
    * Requires the sender to be the owner of this address
    */
    function VCMint(uint _amount, address _reciepient) external onlyOwner {

        require(isPublicMint == false, "Cannot call when minting is public");

        minted += _amount;

        //For each nft minted, it will make a request for a random number from chainlink, and then chainlink will do the actual minting
        for(uint i = 0; i < _amount; i++) {

            VRFRequests[getRandomNumber()] = _reciepient;

        }

    }

    /**
    * @dev Sets the ipfs address where the metadata of this collection is stored
    * Requires the sender to be the owner of this address
    */

    function SetBaseURI(string memory _uri) external onlyOwner {

        BASE_URI = _uri;

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
    * @dev Change the monthly maintance fee cost required in order to claim rewards
    */
    function setMonthlyTributeFee(uint _fee) external onlyOwner {

        monthlyTributeFee = _fee;

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
    * @dev sets the liquidity pool to sell honey to
    * Requires the caller to be the owner of the contract
    */
    function setLiquidityPool(address _routerAddress) external onlyOwner {

        require(_routerAddress != address(0), "Zero Address");

        if(address(uniswapV2Router) != address(0)) {

            //remove approval to transfer honey from the previous router
            honeyContract.approve(address(uniswapV2Router), 0);

        }

         ///@notice get the sushiswap router on polygon
        uniswapV2Router = IUniswapV2Router02(_routerAddress);

        //Approve the router contract to swap honey
        honeyContract.approve(_routerAddress, 2**256-1);

    }

    /**
    * @dev sets restrictions on whitelisted addresses exclusively calling transferFrom
    */
    function setRestrictedTrading(bool value) external onlyOwner {
        restrictedTrading = value;
    }

    /**
    * @dev sets a time window with special restrictions
    * this can only be set once, and will be done on launch, called by the owners
    */
    function startTimePeriod() external onlyOwner {

        require(specialTimePeriod == 0, "Can only call once");

        // Setting the 6 day time period which has special restrictions to start on deployment
        specialTimePeriod = block.timestamp + (6 days);

    }

    /**
    * @dev This allows the contract to revieve matic by selling honey to the liquidity pool
    */
    receive() external payable {}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 * @notice added a function (checkOwner) to get owner of a token without risk of reverting if owner is null address
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    ///@notice changed from private to internal to allow to check balance
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
    * @dev Addition that allows viewing owners of tokens without reverting if owner is null address
    */
    function checkOwner(uint _tokenId) internal view returns(address) {

        return _owners[_tokenId];

    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
interface IRewardPool {

    function ClaimReward(uint _amount, address _address) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}