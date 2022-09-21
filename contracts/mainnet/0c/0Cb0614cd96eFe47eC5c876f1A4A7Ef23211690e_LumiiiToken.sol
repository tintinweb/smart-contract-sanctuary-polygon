// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;


import "./LumiiiGovernance.sol";
import "./LumiiiReflections.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LumiiiToken is Context, IERC20, LumiiiGovernance, LumiiiReflections {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    constructor (address charityWallet, address opsWallet, address routerAddress) public {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Create a uniswap pair for this new token 

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // Set charity and ops wallets
        _charityWallet = charityWallet;
        _opsWallet = opsWallet;
        
        //exclude owner, contract, charity wallet, and ops wallet from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Exclude charity and ops wallet from rewards
        excludeFromReward(_charityWallet);
        excludeFromReward(_opsWallet);
        excludeFromReward(address(0));
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /** 
        @notice Returns name of token
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /** 
        @notice Returns symbol of token
    */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /** 
        @notice Returns symbol of token
    */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /** 
        @notice Returns total supply of token
    */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /** 
        @notice Returns token balance for an account
        @param account The address to check balance of
    */
    function balanceOf(address account) public view override returns (uint256) {
        // If account is excluded from fees, return true amount owned
        if (_isExcluded[account]) return _tOwned[account];
        // Return reflected amount owned converted to true amount
        return tokenFromReflection(_rOwned[account]);
    }

    /** 
        @notice Transfers tokens from msg.sender to recipient
        @param recipient address of transfer recipient
        @param amount token amount to transfer
    */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        _moveDelegates(_delegates[msg.sender], _delegates[recipient], amount);
        return true;
    }

    /** 
        @notice Delegate votes from msg.sender to delegatee
        @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        uint256 delegatorBalance = balanceOf(msg.sender);

        address currentDelegate = _delegates[msg.sender]; // Will be 0 address if msg.sender has no delegates
        _delegates[msg.sender] = delegatee;

        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
        @notice Get allowance for a user
        @param owner address giving allowance
        @param spender address spending tokens from owner
    */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
        @notice Approve user to spend tokens from msg.sender
        @param spender address of user spending tokens
        @param amount token amount to approve
    */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /** 
        @notice Transfers tokens from sender to recipient
        @param sender Address to send tokens from
        @param recipient Address receiving tokens
        @param amount Amount to transfer
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "amount exceeds allowance"));
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
        return true;
    }

    /** 
        @notice Increase allowance of a user
        @param spender Address to increase allowance of
        @param addedValue Amount to increase allowance by
    */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /** 
        @notice Decrease allowance of a user
        @param spender Address to decrease allowance of
        @param subtractedValue Amount to decrease allowance by
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "decreased allowance below zero"));
        return true;
    }

    /** 
        @notice Set a new charity walllet
        @param newWallet Address of new charity wallet
    */
    function setCharityWallet(address newWallet) external onlyOwner() {
        // Include old wallet
        includeInReward(_charityWallet);

        _charityWallet = newWallet;

        //Exclude new wallet
        excludeFromReward(_charityWallet);
    }

    /** 
        @notice Set new operations wallet
        @param newWallet Address of new operations wallet
    */
    function setOpsWallet(address newWallet) external onlyOwner() {
        // Include old wallet
        includeInReward(_opsWallet);

        _opsWallet = newWallet;

        // Exclude new wallet
        excludeFromReward(_opsWallet);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    /** 
        @notice Helper function for approve
    */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from zero address");
        require(spender != address(0), "approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /** 
        @notice Helper function for transfer. Checks if transfer is valid, fees are taken, and if liquidity swap
        should occour
    */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        // Check if transfer is valid
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer to zero address");
        require(amount > 0, "amount not greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "amount exceeds maxTxAmount");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        // check balance and add liquidity if needed
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    /** 
        @notice Swap tokens of local liquidity pool and add to uniswap pool
    */
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /** 
        @notice Swaps LUMIII token for ETH
    */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /** 
        @notice Add liquidity to uniswap pool
    */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    // function deliver(uint256 tAmount) public {
    //     address sender = _msgSender();
    //     require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    //     (uint256 rAmount,,) = _getValues(tAmount);
    //     _rOwned[sender] = _rOwned[sender].sub(rAmount);
    //     _rTotal = _rTotal.sub(rAmount);
    //     _tFeeTotal = _tFeeTotal.add(tAmount);
    // }

}

pragma solidity ^0.6.6;

import "./LumiiiStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LumiiiGovernance is LumiiiStorage, Ownable{
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /** 
        @notice Gets prior number of votes for an account as of given blockNumber
        @param account Address of account to check
        @param blockNumber Block number to get votes at
    */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "LIFE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // Check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Check implicit zero balance -> returning here
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        // Binary search
        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /** 
        @notice Gets current votes for an account
        @param account Address to get votes of
    */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /** 
        @notice Get delegatee for an address delegating
        @param delegator Address to get delegatee for
    */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /** 
        @notice Move delegates from srcRep address to dstRep. If ether are the address, delegates are
        increased/decreased accordingly rather than moved.
        @param srcRep Address to move delegates from 
        @param dstRep Address to move delegates to
        @param amount Amount of delegates to mvoe
    */
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                ? checkpoints[srcRep][srcRepNum - 1].votes
                : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep]; 
                uint256 dstRepOld = dstRepNum > 0
                ? checkpoints[dstRep][dstRepNum - 1].votes
                : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /** 
        @notice Writes new checkpoint for delegatee with new votes and block number
        @param delegatee Address for new checkppint
        @param nCheckpoints Number of checkpoints for delegatee
        @param oldVotes Number of votes for delegatee at old checkpoint
        @param newVotes Number of votes for delegatee at new checkpoint
    */
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        require(block.number < 2**32, "block number exceeds 32 bits");
        uint32 blockNumber = uint32(block.number);

        if (
        nCheckpoints > 0 &&
        checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes); // Checkpoint object
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}

pragma solidity ^0.6.6;

import "./LumiiiStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LumiiiReflections is LumiiiStorage, Ownable {
    /// @notice event emitted when SwapAndLiquifyEnabled is updated
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    /// @notice event emitted when tokens are swapped and liquified
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /// @notice event emitted when transfer occours
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice modifier to show that contract is in swapAndLiquify
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /** 
        @notice Caclulate tax fees for transfer amount
        @param _amount Amount to calculate tax on
    */
    function calculateFees(uint256 _amount) public view returns (uint256, uint256, uint256, uint256) {
        uint256 tax = _amount.mul(_taxFee).div(10**2);
        uint256 liquidity= _amount.mul(_liquidityFee).div(10**2);
        uint256 charity = _amount.mul(_charityFee).div(10**2);
        uint256 ops = _amount.mul(_opsFee).div(10**2);

        return (tax, liquidity, charity, ops);
    }
    
    /** 
        @notice Sets maxTxPercent
    */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    /** 
        @notice Sets new fees
    */
    function setFees(uint256 taxFee, uint256 liquidityFee, uint256 charityFee, uint256 opsFee) external onlyOwner() {
        require(opsFee + taxFee + liquidityFee + charityFee <= 10);

        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _charityFee = charityFee;
        _opsFee = opsFee;

    }

    /** 
        @notice Enable/disable swapAndLiquify 
    */
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /** 
        @notice Get true and reflected values for a transfer amount
        @param tAmount true amount being transfered
    */
    function _getValues(uint256 tAmount) internal view returns (uint256, valueStruct memory, valueStruct memory) {
        // Get the true transfer, fee, and liquidity values
        valueStruct memory tValues = _getTValues(tAmount);
        // Get the reflected amount, trasfer amount, and reflected fee
        (uint256 rAmount, valueStruct memory rValues) = _getRValues(tAmount, tValues.fee, tValues.liquidity, 
                                                         tValues.charity, tValues.ops,  _getRate());

        return (rAmount, rValues, tValues);
    }

    /** 
        @notice Gets true values for transfer amount
        @param tAmount true amount being transfered
    */
    function _getTValues(uint256 tAmount) internal view returns (valueStruct memory) {
        // Get the tax fee for true amount
        valueStruct memory tValues;
        // Get tax amount
        (tValues.fee, tValues.liquidity, tValues.charity, tValues.ops) = calculateFees(tAmount);
        // Substract tax fee and liquidity fee from true amount, result is the true transfer amount
        tValues.transferAmount = tAmount.sub(tValues.fee).sub(tValues.liquidity).sub(tValues.charity).sub(tValues.ops);
        return tValues;
    }

     /** 
        @notice Gets reflected values for transfer amount
        @param tAmount true amount being transfered
        @param tFee true rewards tax amount
        @param tLiquidity true liquidity tax amount
        @param tCharity true charity tax amount
        @param tOps true operations tax amount
        @param currentRate current rate of conversion between true and reflected space
    */
    function _getRValues(uint256 tAmount, uint256 tFee, 
                         uint256 tLiquidity,  uint256 tCharity, 
                         uint256 tOps,  uint256 currentRate 
    ) internal pure returns (uint256, valueStruct memory) {
        valueStruct memory rValues;
        // Covert true amount to reflected amount using current conversion rate
        uint256 rAmount = tAmount.mul(currentRate);
        rValues.fee = tFee.mul(currentRate);
        // Calcualte reflected liquidity fee 
        rValues.liquidity = tLiquidity.mul(currentRate);
        // Get reflected charity fee
        rValues.charity = tCharity.mul(currentRate);
        // Get reflected operations fee
        rValues.ops = tOps.mul(currentRate);
        // Subtract reflexed tax and liqudity fee from reflected amount, result is reflected transfer amouunts
        rValues.transferAmount = rAmount.sub(rValues.fee).sub(rValues.liquidity).sub(rValues.charity).sub(rValues.ops);
        return (rAmount, rValues);
    }

    /** 
        @notice Adds liquidty to local pool
        @param tLiquidity Amount of liquidity to add
    */
    function _takeLiquidity(uint256 tLiquidity) internal {
        // Get conversion rate
        uint256 currentRate =  _getRate();
        // Calculate reflected liquidty
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        // Add reflected liqduity to contract balance
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        // If contract is excluded from reflection fees, add true liqiduity
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    /** 
        @notice Adds charity to charity wallet
        @param tCharity Amount of charity to add
    */
    function _takeCharity(uint256 tCharity) internal {
         // Get conversion rate
        uint256 currentRate =  _getRate();
        // Calculate reflected charity
        uint256 rCharity = tCharity.mul(currentRate);
        // Add reflected charity to contract balance
        _rOwned[_charityWallet] = _rOwned[_charityWallet].add(rCharity);
        // If contract is excluded from reflection fees, add true charity
        if(_isExcluded[_charityWallet])
            _tOwned[_charityWallet] = _tOwned[_charityWallet].add(tCharity);
    }

    /** 
        @notice Adds operation fee to operation wallet
        @param tOps Amount of operation fees to add
    */
    function _takeOps(uint256 tOps) internal {
         // Get conversion rate
        uint256 currentRate =  _getRate();
        // Calculate reflected charity
        uint256 rOps = tOps.mul(currentRate);
        // Add reflected charity to contract balance
        _rOwned[_opsWallet] = _rOwned[_opsWallet].add(rOps);
        // If contract is excluded from reflection fees, add true charity
        if(_isExcluded[_opsWallet])
            _tOwned[_opsWallet] = _tOwned[_opsWallet].add(tOps);
    }

    /// @notice Gets the rate of conversion r-space and t-space
    function _getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        // rSupply: unexcluded reflected total, tSupply: unexcluded true total
        return rSupply.div(tSupply); // Percentage of reflections each non-exluded holder will receive
    }

    /// @notice gets true and reflected supply for unexcluded accounts
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        // Account for wallet addresses that are exluded from reward => Allows for higher refleciton percentage
        // Subtract them from rSupply, tSupply
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /** 
        @notice Account for (rewards) fee in true and reflected spaces
        @param rFee reflected fee amount
        @param tFee true fee amount
    */
    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        // Caluclate new reflected total
        _rTotal = _rTotal.sub(rFee);
        // Add true fee to true fee total
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /// @notice Remove all fees
    function removeAllFee() internal {
        if(_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0 && _opsFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousOpsFee = _opsFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _opsFee = 0;
    }
    
    /// @notice Restore all fees to previous value
    function restoreAllFee() internal {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _opsFee = _previousOpsFee;
    }
  

    /** 
        @notice Converts reflected to true amount
        @param rAmount Reflect token amount o convert
    */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        // Get the current reflection conversion rate
        uint256 currentRate =  _getRate();
        // Return reflected amount divided by current rate, equal to tAmount
        // rAmount / (rSupply/tSupply) = rAmount * (tSupply/rSupply) = tAmount
        return rAmount.div(currentRate);
    }
 
    /** 
        @notice Converts true to reflected amount 
        @param tAmount True amount to convert
        @param deductTransferFee Bool to check if fees should be deducted
    */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,valueStruct memory rValues,) = _getValues(tAmount);
            return rValues.transferAmount;
        }
    }
    
    /** 
        @notice Excludes a user from rewards and fees
        @param account Address to exclude
    */
    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, 'We can not exclude Uniswap router.');
        _isExcludedFromFee[account] = true;
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /** 
        @notice Include a user in rewards and fees
        @param account Address to include
    */
    function includeInReward(address account) public onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        _isExcludedFromFee[account] = false;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /// @notice Check if account is excluded
    function isExcluded(address account) public view returns (bool) {
      return _isExcluded[account];
    }

    /** 
        @notice Transfer helper to account for different transfer types
        @param sender Transfer sender
        @param recipient Transfer recipient
        @param amount Transfer amount
        @param takeFee Bool indicating if fees should be taken
    */
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee)
            removeAllFee();
        
        // Check if sendeer/recipient are excluded, if so _transferFromExcluded, otherwise _transferStandard
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    /// @notice Transfer helper for when both sender/recipient are included in rewards and fees
    function _transferStandard(address sender, address recipient, uint256 tAmount) internal {
        // Convert from true to reflected space
        (uint256 rAmount, valueStruct memory rValues, valueStruct memory tValues) = _getValues(tAmount);

        // Subtract reflected amount from sender
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // Add reflected transfer amount to recipient (taxed are deduceted)
        _rOwned[recipient] = _rOwned[recipient].add(rValues.transferAmount);
        // Take liqduity from transfer
        _takeLiquidity(tValues.liquidity);
        // Take charity fee from transfer
        _takeCharity(tValues.charity);
        // Take operations fee from transfer
        _takeOps(tValues.ops);
        // Update reflected total and true fee total
        _reflectFee(rValues.fee, tValues.fee);
        emit Transfer(sender, recipient, tValues.transferAmount);
    }

    /// @notice Transfer helper for when sender is included but recipient isnt
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 rAmount, valueStruct memory rValues, valueStruct memory tValues) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tValues.transferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.transferAmount);           
        _takeLiquidity(tValues.liquidity);
        // Take charity fee from transfer
        _takeCharity(tValues.charity);
        // Take operations fee from transfer
        _takeOps(tValues.ops);
        _reflectFee(rValues.liquidity, tValues.liquidity);
        emit Transfer(sender, recipient, tValues.liquidity);
    }
    
    /// @notice Transfer helper for when recipient is included but sender isnt
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 rAmount, valueStruct memory rValues, valueStruct memory tValues) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.transferAmount);   
        _takeLiquidity(tValues.liquidity);
        // Take charity fee from transfer
        _takeCharity(tValues.charity);
        // Take operations fee from transfer
        _takeOps(tValues.ops);
        _reflectFee(rValues.fee, tValues.fee);
        emit Transfer(sender, recipient, tValues.transferAmount);
    }

    /// @notice Transfer helper for when both sender/recipient are excluded from rewards and fees
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 rAmount, valueStruct memory rValues, valueStruct memory tValues) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tValues.transferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.transferAmount);        
        _takeLiquidity(tValues.liquidity);
        _reflectFee(rValues.liquidity, tValues.liquidity);
        emit Transfer(sender, recipient, tValues.transferAmount);
    }
    

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LumiiiStorage {
    using SafeMath for uint256;
    using Address for address;

    /// @notice Reflected amount owned for each address
    mapping(address => uint256) internal _rOwned;
    /// @notice True amount owned for each address
    mapping(address => uint256) internal _tOwned;
    /// @notice Allowance for each address
    mapping(address => mapping(address => uint256)) internal _allowances;

    /// @notice Fee exclusion for each address
    mapping(address => bool) internal _isExcludedFromFee;

    /// @notice Rewards exclusion for each address
    mapping(address => bool) internal _isExcluded;

    /// @notice Each accounts delegates
    mapping(address => address) internal _delegates;
    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice Excluded addressess
    address[] internal _excluded;

    address _charityWallet;
    address _opsWallet;

    /// @notice Max uint256 values
    uint256 internal constant MAX = ~uint256(0);
    /// @notice True total
    uint256 internal _tTotal = 10000  * 10**6 * 10**18;
    /// @notice Reflected total
    uint256 internal _rTotal = (MAX - (MAX % _tTotal));
    /// @notice True fee total
    uint256 internal _tFeeTotal;

    string internal _name = "LumiiiToken";
    string internal _symbol = "LUMIII";
    uint8 internal _decimals = 18;

    /// @notice Reflection tax fee
    uint256 public _taxFee = 3;
    uint256 internal _previousTaxFee = _taxFee;

    /// @notice Liquidity tax fee
    uint256 public _liquidityFee = 3;
    uint256 internal _previousLiquidityFee = _liquidityFee;

    /// @notice Charity tax fee
    uint256 public _charityFee = 1;
    uint256 internal _previousCharityFee = _charityFee;

    /// @notice operations fee
    uint256 public _opsFee = 3;
    uint256 internal _previousOpsFee = _opsFee;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    /// @notice Max tax amount
    uint256 public _maxTxAmount = 50 * 10**6 * 10**18;
    /// @notice Token threshold for adding to uniswap liquidity pool
    uint256 internal numTokensSellToAddToLiquidity = 5 * 10**6 * 10**18;

    /// @notice Struct for getValues functions
    struct valueStruct {
        uint256 transferAmount;
        uint256 fee;
        uint256 liquidity;
        uint256 charity;
        uint256 ops;
    }

    /// @notice Struct for checkpoints
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.2;

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