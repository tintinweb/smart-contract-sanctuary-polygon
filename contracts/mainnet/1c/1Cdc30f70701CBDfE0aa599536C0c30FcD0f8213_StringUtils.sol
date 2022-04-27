// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

/**
 * PROPERTY MOGUL
 */


contract PropertyMogul  {
    using SafeMath for uint256;
    using StringUtils for string;

    uint256 private NO_OF_PROPERTIES_TO_PLANT = 1080000;//for final version should be seconds in a day
    uint256 private DEFAULT_MARKET_PRICE = 108000000000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private REFERRAL_VALUE = 740740741;
    uint256 private SAFE_SEEDS_COUNT_FIRST_DEPOSITS = 25;
    uint256 private WITHDRAW_PENALTY = 95;
    uint256 private LAUNCH_SAFEGUARD = 10;
    
    uint256 private NO_OF_SUBURBS = 3;

    uint256 private _devFeeVal = 2;
    uint256 private _devFeeValWithdraw = 3;
    
    bool private _initialized = false;
    address payable private _ownerAddress;
    
    mapping (address => address) public referrals;
    mapping (uint256 => ReferralData) public referralsData;
    mapping (address => uint256) public refIndex;
    mapping (address => uint256) public refferalsAmountData;

    uint256 public _totalRefferalCount;
    uint256 public _totalWallets;
    uint256 public _totalStaked;
    uint256 public _depositCount = 0;
    uint256 public _suburbCount = 0;
    uint256 public _totalWithdrawals = 0;

    uint256 public _startTimeUNIX = 1652832000;
    uint256 private _launchCode = 0;

    mapping (uint256 => Suburb) public _suburbs;
    mapping (address => User) public _users; 

	event InitialPropertyPurchase(address user, uint256 suburb);
	event BuyMoreProperties(address user, uint256 suburb, uint256 noOfProperties, uint256 rentalIncome);
	event SellProperties(address user, uint256 suburb, uint256 noOfProperties);
	event ProjectLaunched();

    struct ReferralData{
        address refAddress;
        uint256 amount;
        uint256 refCount;
    }
    
    struct Suburb {
        string name;
        uint256 marketPrice;
        uint256 totalPurchases;
    } 

    struct User{
        uint256 dateCreated;
        bool exists;
        uint256[] seedProperties;
        uint256[] claimedRentalIncome;
        uint256[] lastPurchased;
        uint256 totalWithdraws;
        uint256[] suburbWithdraws;
        uint256[] suburbPurchases;
    }    


    constructor(address payable ownerAddress, uint256 starTimeUNIX) {
        _ownerAddress = ownerAddress;
        _startTimeUNIX = starTimeUNIX;
        _launchCode = generateRandom();

        if(!StringUtils.equal(_suburbs[0].name, "A"))
        {
            _suburbCount = 3;

            _suburbs[0] = Suburb({
                name: "A",
                marketPrice: DEFAULT_MARKET_PRICE,
                totalPurchases: 0
            });

            _suburbs[1] = Suburb({
                name: "B",
                marketPrice: DEFAULT_MARKET_PRICE,
                totalPurchases: 0
            });

            _suburbs[2] = Suburb({
                name: "C",
                marketPrice: DEFAULT_MARKET_PRICE,
                totalPurchases: 0
            });

        }
    }

    function getLaunchCode() public view returns (uint256)
    {
        require(_startTimeUNIX < block.timestamp, "Contract hasn't started yet.");

        return _launchCode;
    }    

    function withdrawAllRentalIncome() public {
        require(_initialized);
        require(_users[msg.sender].exists);

        for(uint i=0; i<NO_OF_SUBURBS; i++)
        {
            withdrawRentalIncomeForSuburb(i);
        }

        _users[msg.sender].totalWithdraws = SafeMath.add(_users[msg.sender].totalWithdraws, 1);
        _totalWithdrawals = SafeMath.add(_totalWithdrawals, 1);
    }

    function rentalIncomeInCurrency(address adr, uint256 suburb) public view returns(uint256) {
        uint256 hasSeeds = getRentalIncome(adr, suburb);
        uint256 seedValue = calculatePropertySell(hasSeeds, suburb);
        return seedValue;
    }

    function allRentalIncomeInCurrency(address adr) public view returns(uint256) {
        uint256 seedValue = 0; 

        for(uint i=0; i<NO_OF_SUBURBS; i++)
        {
            uint256 hasSeeds = getRentalIncome(adr, i);
            seedValue += calculatePropertySell(hasSeeds, i);
        }

        return seedValue;
    }

    function startBuyingProperty(address ref, uint256 launchCode) public payable
    {
        uint256 blockTimestamp = block.timestamp;

        require(_startTimeUNIX < blockTimestamp, "Contract hasn't started yet.");

        require(_launchCode == launchCode, "Launch code incorrect.");        

        initUser(msg.sender);
        
        _initialized = true;

        // Get the suburb to buy into.
        uint256 lastDigitTimestamp = blockTimestamp % 10;

        if(lastDigitTimestamp >= 0 && lastDigitTimestamp <= 2)
            lastDigitTimestamp = 0;
        else if(lastDigitTimestamp > 2 && lastDigitTimestamp <= 5)
            lastDigitTimestamp = 1;
        else if(lastDigitTimestamp > 5 && lastDigitTimestamp <= 9)
            lastDigitTimestamp = 2;        
    
        buyPropertiesWithReferral(ref, lastDigitTimestamp, 1);
        

        emit InitialPropertyPurchase(msg.sender, lastDigitTimestamp);

    }

    function initUser(address adr) private {
        if(!_users[msg.sender].exists)
        {
            // Add user.
            //_users[msg.sender] = 1;
            User storage user = _users[adr];
            user.dateCreated = block.timestamp;
            user.exists = true;
            user.totalWithdraws = 0;

            for(uint i=0; i<NO_OF_SUBURBS; i++)
            {
                user.seedProperties.push(0);
                user.lastPurchased.push(0);
                user.claimedRentalIncome.push(0);
                user.suburbWithdraws.push(0);
                user.suburbPurchases.push(0);
            }

            _totalWallets++;

            _users[adr] = user;
        }
    }
    
    function buyProperties(address ref, uint256 suburb) public payable {
        buyPropertiesWithReferral(ref, suburb, 0);
        
    }

    function buyPropertiesWithReferral(address ref, uint256 suburb, uint256 initialPurchase) private {

        require(_initialized);
        require(_users[msg.sender].exists);

        uint256 balance = address(this).balance;
        uint256 value = msg.value;
        uint256 balanceSubValue = SafeMath.sub(balance,value);
        uint256 seedsBought = calculatePropertyBuy(value,balanceSubValue, suburb);

        seedsBought = SafeMath.sub(seedsBought,devFee(seedsBought));
        
        uint256 fee = devFee(msg.value);
        _ownerAddress.transfer(fee);

        _totalStaked += value;
        _depositCount++;
        
        _users[msg.sender].claimedRentalIncome[suburb] = SafeMath.add(_users[msg.sender].claimedRentalIncome[suburb], seedsBought); 
        _users[msg.sender].suburbPurchases[suburb] = SafeMath.add(_users[msg.sender].suburbPurchases[suburb], msg.value);
        
        uint256 seedsUsed = getAllRentalIncome(msg.sender); //getRentalIncome(msg.sender, suburb);
        uint256 newMiners = SafeMath.div(seedsUsed,NO_OF_PROPERTIES_TO_PLANT);
        
        // Ensure the first 25 deposits are assigned the amount of properties corresponding to their
        // deposit amount.
        if(_depositCount <= SAFE_SEEDS_COUNT_FIRST_DEPOSITS)
        {
            uint256 depositAmount = msg.value / 10000000000000000000;

            if(depositAmount < newMiners)
                newMiners = newMiners / LAUNCH_SAFEGUARD;

        }        
        
        _suburbs[suburb].totalPurchases = SafeMath.add(_suburbs[suburb].totalPurchases, value);

        reinvest(ref, suburb, seedsUsed, newMiners, initialPurchase);
    }

    function buyMoreProperties(address ref, uint256 suburb) public
    {
        uint256 seedsUsed = getAllRentalIncome(msg.sender); //getRentalIncome(msg.sender, suburb);
        uint256 newMiners = SafeMath.div(seedsUsed, NO_OF_PROPERTIES_TO_PLANT);

        reinvest(ref, suburb, seedsUsed, newMiners, 0);
        
    }

    function reinvest(address ref, uint256 suburb, uint256 seedsUsed, uint256 newMiners, uint256 initialPurchase) private {
        require(_initialized);
        require(_users[msg.sender].exists);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }


        _users[msg.sender].seedProperties[suburb] = SafeMath.add(_users[msg.sender].seedProperties[suburb], newMiners);

        
        // Remove all rental income.
        for(uint256 i=0; i<NO_OF_SUBURBS; i++)
        {
            _users[msg.sender].claimedRentalIncome[i] = 0;
        }
    
        _users[msg.sender].lastPurchased[suburb] = block.timestamp;

        if(referrals[msg.sender] != address(0) && refferalsAmountData[referrals[msg.sender]]==0){
            initUser(referrals[msg.sender]);

            _totalRefferalCount = _totalRefferalCount.add(1);
            refIndex[referrals[msg.sender]] = _totalRefferalCount;
        }

        if(referrals[msg.sender] != address(0) && initialPurchase == 1){
            //send referral seeds
            _users[referrals[msg.sender]].claimedRentalIncome[suburb] = SafeMath.add(_users[referrals[msg.sender]].claimedRentalIncome[suburb], SafeMath.div(seedsUsed.mul(100000000),REFERRAL_VALUE)); 


            uint256 currentIndex = refIndex[referrals[msg.sender]];
            refferalsAmountData[referrals[msg.sender]] = refferalsAmountData[referrals[msg.sender]].add(_users[referrals[msg.sender]].claimedRentalIncome[suburb]);
            referralsData[currentIndex] = ReferralData({
                refAddress: referrals[msg.sender],
                amount: referralsData[currentIndex].amount.add(SafeMath.div(seedsUsed.mul(100000000),REFERRAL_VALUE)),
                refCount: referralsData[currentIndex].refCount.add(1)
            });
        }


        //boost market to nerf miners hoarding
        _suburbs[suburb].marketPrice = SafeMath.add(_suburbs[suburb].marketPrice, SafeMath.div(seedsUsed,5));

        emit BuyMoreProperties(msg.sender, suburb, newMiners, seedsUsed);

    }
        
    function getPageInfo() public view returns(uint256[] memory)
    {
        uint256[] memory results = new uint256[](100);        

        results[0] = (address(this).balance);
        results[1] = _startTimeUNIX;
        results[2] = _totalWallets;
        results[3] = _totalStaked;
        results[4] = _totalWithdrawals;

        for(uint i=0; i<NO_OF_SUBURBS; i++)
        {
            results[5 + i] = _suburbs[i].totalPurchases; //propertyPriceInSuburb(i);
        }  

        for(uint i=0; i<NO_OF_SUBURBS; i++)
        {
            results[5 + NO_OF_SUBURBS + i] = propertyPriceInSuburb(i);
        }        

        return results;
        
    }      

    function getUserInfo(address adr) public view returns(uint256[] memory)
    {
        uint256[] memory results = new uint256[](100);        

        if(_users[adr].exists)
        {            
            uint256 totalRentalIncome = allRentalIncomeInCurrency(adr);
            uint256 totalNoOfProperties = getAllMyProperties(adr);
            results[0] = (totalRentalIncome);
            results[1] = (totalNoOfProperties);
            results[2] = _users[msg.sender].totalWithdraws;

            for(uint i=0; i<NO_OF_SUBURBS; i++)
            {
                results[3 + i] = getMyProperties(adr, i);
            }
            
            for(uint i=0; i<NO_OF_SUBURBS; i++)
            {
                results[3 + NO_OF_SUBURBS + i] = _users[msg.sender].suburbWithdraws[i];
            }

            for(uint i=0; i<NO_OF_SUBURBS; i++)
            {
                results[3 + NO_OF_SUBURBS + NO_OF_SUBURBS + i] = _users[msg.sender].suburbPurchases[i];
            }

        }

        return results;

    } 

    function propertyPriceInSuburb(uint256 suburb) public view returns(uint256)
    {
        uint256 value = 50 ether;
        uint256 balance = address(this).balance;
        
        uint256 seedsBought = calculatePropertyBuy(value, balance, suburb);
        seedsBought = SafeMath.sub(seedsBought,devFee(seedsBought));

        uint256 noOfPropertiesPurchasable = SafeMath.div(seedsBought, NO_OF_PROPERTIES_TO_PLANT);
        uint256 pricePerProperty = value/noOfPropertiesPurchasable;

        return pricePerProperty;
        
    }            
    
    function calculatePropertySell(uint256 seeds, uint256 suburb) public view returns(uint256) {
        return calculateTrade(seeds, _suburbs[suburb].marketPrice, _suburbs[suburb].totalPurchases);
    }

    function calculatePropertySellManualBalance(uint256 seeds, uint256 suburb, uint256 balance) public view returns(uint256) {
        return calculateTrade(seeds, _suburbs[suburb].marketPrice, balance);
    }
    
    function calculatePropertyBuy(uint256 eth,uint256 contractBalance, uint256 suburb) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, _suburbs[suburb].marketPrice);
    }
    
    function calculatePropertyBuySimple(uint256 eth, uint256 suburb) public view returns(uint256) {
        return calculatePropertyBuy(eth, _suburbs[suburb].totalPurchases, _suburbs[suburb].marketPrice);
    }    
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getTotalPurchasesSuburb(uint256 suburb) public view returns(uint256) {
        return _suburbs[suburb].totalPurchases;
    }
    
    function getMyProperties(address adr, uint256 suburb) public view returns(uint256) {

        return _users[adr].seedProperties[suburb];

    }

    function getAllMyProperties(address adr) public view returns(uint256) {
        uint256 total = 0;
        
        for(uint i=0; i<NO_OF_SUBURBS; i++)
        {
            total += getMyProperties(adr, i);
        }

        return total;
    }

    function getAllRentalIncome(address adr) public view returns(uint256)
    {
        uint256 rentIncome = 0;

        for(uint i=0; i<NO_OF_SUBURBS; i++)
        {
            rentIncome += getRentalIncome(adr, i);
        }

        return rentIncome;
    }
    
    function getRentalIncome(address adr, uint256 suburb) public view returns(uint256) {
        
        uint256 rentIncome = 0;

        rentIncome = SafeMath.add(_users[adr].claimedRentalIncome[suburb], getRentalIncomeSinceLastPurchased(adr, suburb));

        return rentIncome;
    }
    

    function getRentalIncomeSinceLastPurchased(address adr, uint256 suburb) public view returns(uint256) {
        uint256 rentIncomeSinceLastPurchased = 0;
        uint256 subTimestamp = 0;

        if(_users[adr].lastPurchased[suburb] > 0)
        {
                subTimestamp = SafeMath.sub(block.timestamp, _users[adr].lastPurchased[suburb]);
                uint256 secondsPassed = min(NO_OF_PROPERTIES_TO_PLANT, subTimestamp);
                rentIncomeSinceLastPurchased = SafeMath.mul(secondsPassed, _users[adr].seedProperties[suburb]);

        }        
        
        return rentIncomeSinceLastPurchased;
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) 
    {
        uint256 total = 0;

        if(rt > 0)
        {

            uint256 rtCalc = SafeMath.mul(PSNH,rt);
            uint256 rsCalc = SafeMath.mul(PSN,rs);
            uint256 rtRsCalc = SafeMath.add(rsCalc, rtCalc);
            uint256 psnhRtRsCalc = SafeMath.div(rtRsCalc,rt); 
            uint256 psnhAdd = SafeMath.add(PSNH, psnhRtRsCalc);
            uint256 psnAdd = SafeMath.mul(PSN,bs);
            total = SafeMath.div(psnAdd, psnhAdd);
        }

        return total;
    }

    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,_devFeeVal),100);
    }

    function devFeeWithdraw(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,_devFeeValWithdraw),100);
    }

    function withdrawRentalIncomeForSuburb(uint256 suburb) private {
        require(_initialized);
        require(_users[msg.sender].exists);
        require(address(this).balance > 0, "Contract balance is 0.");

        uint256 hasSeeds = getRentalIncome(msg.sender, suburb);

        if(hasSeeds > 0)
        {
            
        
            uint256 seedValue = calculatePropertySell(hasSeeds, suburb);
            
            if(address(this).balance <= seedValue)
                seedValue = address(this).balance;
            
            uint256 fee = devFeeWithdraw(seedValue);
            uint256 amountToWithdraw = SafeMath.sub(seedValue,fee);


            _users[msg.sender].claimedRentalIncome[suburb] = 0;
            _users[msg.sender].lastPurchased[suburb] = block.timestamp;

            _users[msg.sender].suburbWithdraws[suburb] = SafeMath.add(_users[msg.sender].suburbWithdraws[suburb], 1);

            _users[msg.sender].seedProperties[suburb] = SafeMath.div(SafeMath.mul(_users[msg.sender].seedProperties[suburb], (100 - (10 * _users[msg.sender].suburbWithdraws[suburb]))), 100);

            _suburbs[suburb].marketPrice = SafeMath.add(_suburbs[suburb].marketPrice, hasSeeds);
            
            _ownerAddress.transfer(fee);

            payable (msg.sender).transfer(amountToWithdraw);

            emit SellProperties(msg.sender, suburb, seedValue);
        }

    }

    function generateRandom() private view returns (uint) {
        uint randNonce = 0;
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;

        return random;
    }


    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) public pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}