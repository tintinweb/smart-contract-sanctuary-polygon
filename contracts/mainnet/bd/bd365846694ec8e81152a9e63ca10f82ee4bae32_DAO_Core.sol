/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

pragma solidity ^ 0.6.6;
/*
          ,/`.
        ,'/ __`.
      ,'_/__ _ _`.
    ,'__/__ _ _  _`.
  ,'_  /___ __ _ __ `.
 '-.._/___ _ __ __  __`.

 The Pyramid generates a halo, karma.
 Karma is used for governance.
*/

contract ColorToken{

	mapping(address => uint256) public balances;
	mapping(address => uint256) public red;
	mapping(address => uint256) public green;
	mapping(address => uint256) public blue;

	uint public _totalSupply;

	mapping(address => mapping(address => uint)) approvals;

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount
	);
	
	function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function addColor(address addr, uint amount, uint _red, uint _green, uint _blue) internal {
		//adding color values to balance
		red[addr] += _red * amount;
		green[addr] += _green * amount;
		blue[addr] += _blue * amount;
	}


  	function RGB_Ratio() public view returns(uint,uint,uint){
  		return RGB_Ratio(msg.sender);
  	}

  	function RGB_Ratio(address addr) public view returns(uint,uint,uint){
  		//returns the color of one's tokens
  		uint weight = balances[addr];
  		if (weight == 0){
  			return (0,0,0);
  		}
  		return ( red[addr]/weight, green[addr]/weight, blue[addr]/weight);
  	}

  	function RGB_scale(address addr, uint numerator, uint denominator) internal view returns(uint,uint,uint){
		return (red[addr] * numerator / denominator, green[addr] * numerator / denominator, blue[addr] * numerator / denominator);
	}

	// Function that is called when a user or another contract wants to transfer funds.
	function transfer(address _to, uint _value, bytes memory _data) public virtual returns (bool) {
		if( isContract(_to) ){
			return transferToContract(_to, _value, _data);
		}else{
			return transferToAddress(_to, _value, _data);
		}
	}
	
	// Standard function transfer similar to ERC20 transfer with no _data.
	// Added due to backwards compatibility reasons.
	function transfer(address _to, uint _value) public virtual returns (bool) {
		//standard function transfer similar to ERC20 transfer with no _data
		//added due to backwards compatibility reasons
		bytes memory empty;
		if(isContract(_to)){
			return transferToContract(_to, _value, empty);
		}else{
			return transferToAddress(_to, _value, empty);
		}
	}



	//function that is called when transaction target is an address
	function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool) {
		moveTokens(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	//function that is called when transaction target is a contract
	function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool) {
		moveTokens(msg.sender, _to, _value);
		ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value, _data);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function colorTransfer(address _to, uint _value) public virtual returns(uint R, uint G, uint B){
		(R, G, B) = moveTokens(msg.sender, _to, _value);
		ColorReceivingContract(_to).colorFallback(msg.sender, _value, R, G, B);

		emit Transfer(msg.sender, _to, _value);
	}

	function moveTokens(address _from, address _to, uint _amount) internal virtual returns(uint red_ratio, uint green_ratio, uint blue_ratio){
		require( _amount <= balances[_from] );

		//mix colors
		(red_ratio, green_ratio, blue_ratio) = RGB_scale( _from, _amount, balances[_from] );
		red[_from] -= red_ratio;
		green[_from] -= green_ratio;
		blue[_from] -= blue_ratio;
		red[_to] += red_ratio;
		green[_to] += green_ratio;
		blue[_to] += blue_ratio;

		//update balances
		balances[_from] -= _amount;
		balances[_to] += _amount;
	}

    function allowance(address src, address guy) public view returns (uint) {
        return approvals[src][guy];
    }
  	
    function transferFrom(address src, address dst, uint amount) public returns (bool){
        address sender = msg.sender;
        require(approvals[src][sender] >=  amount);
        require(balances[src] >= amount);
        approvals[src][sender] -= amount;
        moveTokens(src,dst,amount);
        bytes memory empty;
        emit Transfer(sender, dst, amount, empty);
        return true;
    }

    event Approval(address indexed src, address indexed guy, uint amount);
    function approve(address guy, uint amount) public returns (bool) {
        address sender = msg.sender;
        approvals[sender][guy] = amount;

        emit Approval( sender, guy, amount );
        return true;
    }

    function isContract(address _addr) public view returns (bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		if(length>0) {
			return true;
		}else {
			return false;
		}
	}
}

contract DAO_Core is ColorToken{
	// scaleFactor is used to convert Ether into bonds and vice-versa: they're of different
	// orders of magnitude, hence the need to bridge between the two.
	uint256 constant scaleFactor = 0x10000000000000000;
	address payable address0 = address(0);

	// Slope
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;

	// Typical values that we have to declare.
	string constant public name = "Governance Bonds";
	string constant public symbol = "BOND";
	uint8 constant public decimals = 18;

	mapping(address => uint256) public average_ethSpent;
	// For calculating hodl multiplier that factors into resolves minted
	mapping(address => uint256) public average_buyInTimeSum;
	// Array between each address and their number of resolves being staked.
	mapping(address => uint256) public resolveWeight;

	// Array between each address and how much Ether has been paid out to it.
	// Note that this is scaled by the scaleFactor variable.
	mapping(address => int256) public payouts;

	//Fee only happens on buy.  Divs happen on buy and sell
	mapping(address => uint256) public sellSideDivs;

	// The total number of resolves being staked in this contract
	uint256 public dissolvingResolves;

	// For calculating the hodl multiplier. Weighted average release time
	uint public sumOfInputETH;
	uint public sumOfInputTime;
	uint public sumOfOutputETH;
	uint public sumOfOutputTime;

	// Something about invarience.
	int256 public earningsOffset;

	// Variable tracking how much Ether each token is currently worth
	// Note that this is scaled by the scaleFactor variable.
	uint256 public earningsPerResolve;

	//The resolve token contract
	ResolveToken public resolveToken;
	
	constructor() public{
		resolveToken = new ResolveToken( address(this) );
	}

	function fluxFee(uint paidAmount) public view returns(uint fee) {
		//we're only going to count resolve tokens that haven't been burned.
		uint totalResolveSupply = resolveToken.totalSupply() - resolveToken.balanceOf( address(0) );
		if ( dissolvingResolves == 0 )
			return 0;

		//the fee is the % of resolve tokens outside of the contract
		return paidAmount * ( totalResolveSupply - dissolvingResolves ) / totalResolveSupply * sumOfOutputETH / sumOfInputETH;
	}

	// Converts the Ether accrued as resolveEarnings back into bonds without having to
	// withdraw it first. Saves on gas and potential price spike loss.
	event Reinvest( address indexed addr, uint256 reinvested, uint256 dissolved, uint256 bonds, uint256 resolveTax);
	function reinvestEarnings(uint amountFromEarnings) public returns(uint,uint){
		address sender = msg.sender;
		// Retrieve the resolveEarnings associated with the address the request came from.		
		uint upScaleDivs = (uint)((int256)( earningsPerResolve * resolveWeight[sender] ) - payouts[sender]);
		uint totalEarnings = upScaleDivs / scaleFactor;//resolveEarnings(sender);
		require(amountFromEarnings <= totalEarnings, "the amount exceeds total earnings");
		uint oldWeight = resolveWeight[sender];
		resolveWeight[sender] = oldWeight * (totalEarnings - amountFromEarnings) / totalEarnings;
		uint weightDiff = oldWeight - resolveWeight[sender];
		resolveToken.transfer( address0, weightDiff );
		dissolvingResolves -= weightDiff;
		
		// something about invariance
		int withdrawnEarnings = (int)(upScaleDivs * amountFromEarnings / totalEarnings) - (int)(weightDiff*earningsPerResolve);
		payouts[sender] += withdrawnEarnings;
		// Increase the total amount that's been paid out to maintain invariance.
		earningsOffset += withdrawnEarnings;

		// Assign balance to a new variable.
		uint value_ = (uint) (amountFromEarnings);

		// If your resolveEarnings are worth less than 1 szabo, abort.
		if (value_ < 0.000001 ether)
			revert();

		// Calculate the fee
		uint fee = fluxFee(value_);

		// The amount of Ether used to purchase new bonds for the caller
		uint numEther = value_ - fee;

		//resolve reward tracking stuff
		average_ethSpent[sender] += numEther;
		average_buyInTimeSum[sender] += now * scaleFactor * numEther;
		sumOfInputETH += numEther;
		sumOfInputTime += now * scaleFactor * numEther;

		// The number of bonds which can be purchased for numEther.
		uint createdBonds = ethereumToTokens_(numEther);
		uint[] memory RGB = new uint[](3);
  		(RGB[0], RGB[1], RGB[2]) = RGB_Ratio(sender);
		
		addColor(sender, createdBonds, RGB[0], RGB[1], RGB[2]);

		// the amount to be paid to stakers
		uint resolveFee;

		// Check if we have resolves dissolving
		if ( dissolvingResolves > 0 ) {
			resolveFee = fee/2 * scaleFactor;
			sellSideDivs[sender] += fee/2;

			// Fee is distributed to all existing resolve stakers before the new bonds are purchased.
			// rewardPerResolve is the amount(ETH) gained per resolve token from this purchase.
			uint rewardPerResolve = resolveFee / dissolvingResolves;

			// The Ether value per token is increased proportionally.
			earningsPerResolve += rewardPerResolve;
		}

		// Add the createdBonds to the total supply.
		_totalSupply += createdBonds;

		// Assign the bonds to the balance of the buyer.
		balances[sender] += createdBonds;

		emit Reinvest(sender, value_, weightDiff, createdBonds, resolveFee);
		return (createdBonds, weightDiff);
	}

	// Sells your bonds for Ether
	function sellAllBonds() public returns(uint returned_eth, uint returned_resolves, uint initialInput_ETH){
		return sell( balanceOf(msg.sender) );
	}

	function sellBonds(uint amount) public returns(uint returned_eth, uint returned_resolves, uint initialInput_ETH){
		require(balanceOf(msg.sender) >= amount, "Amount is more than balance");
		( returned_eth, returned_resolves, initialInput_ETH ) = sell(amount);
		return (returned_eth, returned_resolves, initialInput_ETH);
	}

	// Big red exit button to pull all of a holder's Ethereum value from the contract
	function getMeOutOfHere() public {
		sellAllBonds();
		withdraw( resolveEarnings(msg.sender) );
	}

	// Gatekeeper function to check if the amount of Ether being sent isn't too small
	function fund() payable public returns(uint createdBonds){
		uint[] memory RGB = new uint[](3);
  		(RGB[0], RGB[1], RGB[2]) = RGB_Ratio(msg.sender);
		return buy(msg.sender, RGB[0], RGB[1], RGB[2]);
  	}
 
	// Calculate the current resolveEarnings associated with the caller address. This is the net result
	// of multiplying the number of resolves held by their current value in Ether and subtracting the
	// Ether that has already been paid out.
	function resolveEarnings(address _owner) public view returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerResolve * resolveWeight[_owner]) - payouts[_owner]) / scaleFactor;
	}

	event Buy( address indexed addr, uint256 spent, uint256 bonds, uint256 resolveTax);
	function buy(address addr, uint _red, uint _green, uint _blue) public payable returns(uint createdBonds){
		//make sure the color components don't exceed limits
		if(_red>1e18) _red = 1e18;
		if(_green>1e18) _green = 1e18;
		if(_blue>1e18) _blue = 1e18;
		
		// Any transaction of less than 1 szabo is likely to be worth less than the gas used to send it.
		if ( msg.value < 0.000001 ether )
			revert();

		// Calculate the fee
		uint fee = fluxFee(msg.value);

		// The amount of Ether used to purchase new bonds for the caller.
		uint numEther = msg.value;

		
		numEther = numEther - fee;

		//resolve reward tracking stuff
		uint currentTime = now;
		average_ethSpent[addr] += numEther;
		average_buyInTimeSum[addr] += currentTime * scaleFactor * numEther;
		sumOfInputETH += numEther;
		sumOfInputTime += currentTime * scaleFactor * numEther;

		// The number of bonds which can be purchased for numEther.
		createdBonds = ethereumToTokens_(numEther);
		addColor(addr, createdBonds, _red, _green, _blue);

		// Add the createdBonds to the total supply.
		_totalSupply += createdBonds;

		// Assign the bonds to the balance of the buyer.
		balances[addr] += createdBonds;

		// Check if we have resolves dissolving
		uint resolveFee;
		if (dissolvingResolves > 0) {
			resolveFee = fee/2 * scaleFactor;
			sellSideDivs[addr] += fee/2;

			// Fee is distributed to all existing resolve holders before the new bonds are purchased.
			// rewardPerResolve is the amount gained per resolve token from this purchase.
			uint rewardPerResolve = resolveFee/dissolvingResolves;

			// The Ether value per resolve is increased proportionally.
			earningsPerResolve += rewardPerResolve;
		}
		emit Transfer(address(0), addr, createdBonds);
		emit Buy( addr, msg.value, createdBonds, resolveFee);
		return createdBonds;
	}

	function avgHodl() public view returns(uint hodlTime){
		return now - (sumOfInputTime - sumOfOutputTime) / (sumOfInputETH - sumOfOutputETH) / scaleFactor;
	}

	function getReturnsForBonds(address addr, uint bondsReleased) public view returns(uint etherValue, uint mintedResolves, uint new_releaseTimeSum, uint new_releaseAmount, uint initialInput_ETH){
		uint output_ETH = tokensToEthereum_(bondsReleased);
		uint input_ETH = average_ethSpent[addr] * bondsReleased / balances[addr];
		// hodl multiplier. because if you don't hodl at all, you shouldn't be rewarded resolves.
		// and the multiplier you get for hodling needs to be relative to the average hodl
		uint buyInTime = average_buyInTimeSum[addr] / average_ethSpent[addr];
		uint cashoutTime = now * scaleFactor - buyInTime;
		uint new_sumOfOutputTime = sumOfOutputTime + average_buyInTimeSum[addr] * bondsReleased / balances[addr];
		uint new_sumOfOutputETH = sumOfOutputETH + input_ETH;
		uint averageHoldingTime = now * scaleFactor - ( sumOfInputTime - sumOfOutputTime ) / ( sumOfInputETH - sumOfOutputETH );
		return (output_ETH, 



			input_ETH 
			* cashoutTime / averageHoldingTime
			* input_ETH / output_ETH,



			new_sumOfOutputTime, new_sumOfOutputETH, input_ETH);
	}

	event Sell( address indexed addr, uint256 bondsSold, uint256 cashout, uint256 resolves, uint256 resolveTax, uint256 initialCash);
	function sell(uint256 amount) internal returns(uint eth, uint resolves, uint initialInput){
		address payable sender = msg.sender;
	  	// Calculate the amount of Ether & Resolves that the holder's bonds sell for at the current sell price.

		uint _sellSideDivs = sellSideDivs[sender] * amount / balances[sender];
		sellSideDivs[sender] -= _sellSideDivs;

		uint[] memory UINTs = new uint[](5);
		(
		UINTs[0]/*ether out*/,
		UINTs[1]/*minted resolves*/,
		UINTs[2]/*new_sumOfOutputTime*/,
		UINTs[3]/*new_sumOfOutputETH*/,
		UINTs[4]/*initialInput_ETH*/) = getReturnsForBonds(sender, amount);

		// magic distribution
		uint[] memory RGB = new uint[](3);
  		(RGB[0], RGB[1], RGB[2]) = RGB_Ratio(sender);
		resolveToken.mint(sender, UINTs[1]/*minted resolves*/, RGB[0], RGB[1], RGB[2]);

		// update weighted average cashout time
		sumOfOutputTime = UINTs[2]/*new_sumOfOutputTime*/;
		sumOfOutputETH = UINTs[3] /*new_sumOfOutputETH*/;

		// reduce the amount of "eth spent" based on the percentage of bonds being sold back into the contract
		average_ethSpent[sender] = average_ethSpent[sender] * ( balances[sender] - amount) / balances[sender];
		// reduce the "buyInTime" sum that's used for average buy in time
		average_buyInTimeSum[sender] = average_buyInTimeSum[sender] * (balances[sender] - amount) / balances[sender];

		// Net Ether for the seller.
	    uint numEthers = UINTs[0]/*ether out*/;

		// Burn the bonds which were just sold from the total supply.
		_totalSupply -= amount;


	    // maintain color density
	    thinColor( sender, balances[sender] - amount, balances[sender]);
	    // Remove the bonds from the balance of the buyer.
	    balances[sender] -= amount;

		// Check if we have resolves dissolving
		if ( dissolvingResolves > 0 ){
			// SellSideDivs are distributed to all remaining resolve holders.
			// rewardPerResolve is the amount gained per resolve thanks to this sell.
			uint rewardPerResolve = _sellSideDivs * scaleFactor/dissolvingResolves;

			// The Ether value per resolve is increased proportionally.
			earningsPerResolve += rewardPerResolve;
		}
		
		
		(bool success, ) = sender.call{value:numEthers}("");
        require(success, "Transfer failed.");

		emit Sell( sender, amount, numEthers, UINTs[1]/*minted resolves*/, _sellSideDivs, UINTs[4] /*initialInput_ETH*/);
		return (numEthers,  	UINTs[1]/*minted resolves*/, UINTs[4] /*initialInput_ETH*/);
	}

	function thinColor(address addr, uint newWeight, uint oldWeight) internal{
		//bonds cease to exist so the color density needs to be updated.
  		(red[addr], green[addr], blue[addr]) = RGB_scale( addr, newWeight, oldWeight);
  	}

	// Allow contract to accept resolve tokens
	event StakeResolves( address indexed addr, uint256 amountStaked, bytes _data );
	function tokenFallback(address from, uint value, bytes calldata _data) external{
		if(msg.sender == address(resolveToken) ){
			resolveWeight[from] += value;
			dissolvingResolves += value;

			// Then we update the payouts array for the "resolve shareholder" with this amount
			int payoutDiff = (int256) (earningsPerResolve * value);
			payouts[from] += payoutDiff;
			earningsOffset += payoutDiff;

			emit StakeResolves(from, value, _data);
		}else{
			revert("no want");
		}
	}

	// Withdraws resolveEarnings held by the caller sending the transaction, updates
	// the requisite global variables, and transfers Ether back to the caller.
	event Withdraw( address indexed addr, uint256 earnings, uint256 dissolve );
	function withdraw(uint amount) public returns(uint){
		address payable sender = msg.sender;
		// Retrieve the resolveEarnings associated with the address the request came from.
		uint upScaleDivs = (uint)((int256)( earningsPerResolve * resolveWeight[sender] ) - payouts[sender]);
		uint totalEarnings = upScaleDivs / scaleFactor;
		require( amount <= totalEarnings && amount > 0 );
		uint oldWeight = resolveWeight[sender];
		resolveWeight[sender] = oldWeight * ( totalEarnings - amount ) / totalEarnings;
		uint weightDiff = oldWeight - resolveWeight[sender];
		resolveToken.transfer( address0, weightDiff);
		dissolvingResolves -= weightDiff;
		
		// something about invariance
		int withdrawnEarnings = (int)(upScaleDivs * amount / totalEarnings) - (int)(weightDiff*earningsPerResolve);
		payouts[sender] += withdrawnEarnings;
		// Increase the total amount that's been paid out to maintain invariance.
		earningsOffset += withdrawnEarnings;


		// Send the resolveEarnings to the address that requested the withdraw.
		(bool success, ) = sender.call{value: amount}("");
        require(success, "Transfer failed.");

		emit Withdraw( sender, amount, weightDiff);
		return weightDiff;
	}

	function moveTokens(address _from, address _to, uint _amount) internal override returns(uint R, uint G, uint B){
		//mix multi-dimensional bond values
		uint totalBonds = balances[_from];
		uint ethSpent = average_ethSpent[_from] * _amount / totalBonds;
		uint buyInTimeSum = average_buyInTimeSum[_from] * _amount / totalBonds;
		average_ethSpent[_from] -= ethSpent;
		average_buyInTimeSum[_from] -= buyInTimeSum;
		average_ethSpent[_to] += ethSpent;
		average_buyInTimeSum[_to] += buyInTimeSum;
		return super.moveTokens(_from, _to, _amount);
	}

	function clockTransfer(address _to, uint _value) public virtual returns(uint ethSpent, uint buyInTimeSum, uint R, uint G, uint B){
		address sender = msg.sender;
		uint totalBonds = balances[sender];
		ethSpent = average_ethSpent[sender] * _value / totalBonds;
		buyInTimeSum = average_buyInTimeSum[sender] * _value / totalBonds;

		(R, G, B) = moveTokens(sender, _to, _value);
		ClockReceivingContract receiver = ClockReceivingContract(_to);
		receiver.clockFallback(sender, _value, ethSpent, buyInTimeSum, R, G, B);

		emit Transfer(sender, _to, _value);
	}

    function buyPrice()
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(_totalSupply == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = fluxFee(_ethereum  );
            uint256 _taxedEthereum = _ethereum + _dividends;
            return _taxedEthereum;
        }
    }

    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(_totalSupply == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = fluxFee(_ethereum  );
            uint256 _taxedEthereum = subtract(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = fluxFee(_ethereumToSpend);
        uint256 _taxedEthereum = subtract(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    

    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= _totalSupply);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = fluxFee(_ethereum );
        uint256 _taxedEthereum = subtract(_ethereum, _dividends);
        return _taxedEthereum;
    }

    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                subtract(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(_totalSupply**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*_totalSupply)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(_totalSupply)
        ;
  
        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (_totalSupply + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            subtract(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract ResolveToken is ColorToken{

	//Sunshine & Rainbows
	string public name = "Resolve Token";
    string public symbol = "RSLV";
    uint8 constant public decimals = 18;
	address public hourglass;

	constructor(address _hourglass) public{
		hourglass = _hourglass;
	}

	modifier hourglassOnly{
		require(msg.sender == hourglass);
		_;
    }

	function mint(address _address, uint _value, uint _red, uint _green, uint _blue) external hourglassOnly(){
		balances[_address] += _value;
		_totalSupply += _value;
		addColor(_address, _value, _red, _green, _blue);
		emit Transfer(address(0), _address, _value);
	}
}

abstract contract ERC223ReceivingContract{
    function tokenFallback(address _from, uint _value, bytes calldata _data) external virtual;
}
abstract contract ColorReceivingContract{
    function colorFallback(address _from, uint _value, uint r, uint g, uint b) external virtual;
}
abstract contract ClockReceivingContract{
    function clockFallback(address _from, uint _value, uint ethSpent, uint time, uint r, uint g, uint b) external virtual;
}