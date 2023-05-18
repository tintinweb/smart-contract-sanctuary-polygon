/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/PreSale.sol



pragma solidity =0.8.4;



contract PreSale{

    address public wethAddress;
    address public tokenAddress;
    address public usdtAddress;
    address payable public catchalAddress;
    address public pairUsdtWethAddress;
    uint public preSalePriceMul10Pow18;
    uint public referralComissionMul10Pow3;
    address payable private owner;
    uint public soldAmount;

    IERC20 TOKEN;
    IERC20 USDT;

    mapping (address => address payable) public referrals;
    
    
    function setConfigs(
        address _wethAddress,
        address _tokenAddress,
        address _usdtAddress,
        address payable _catchalAddress,
        address _pairUsdtWethAddress,
        uint _preSalePriceMul10Pow18,
        uint _referralComissionMul10Pow3
    
    ) public onlyOwner{
        require(_wethAddress!=address(0),"Inavlid wethAddress");
        require(_tokenAddress!=address(0),"Inavlid tokenAddress");
        require(_usdtAddress!=address(0),"Inavlid usdtAddress");
        require(_catchalAddress!=address(0),"Inavlid catchalAddress");
        require(_pairUsdtWethAddress!=address(0),"Inavlid pairUsdtWethAddress");

        require(_preSalePriceMul10Pow18>0,"Invalid Pre-Sale price");
        require(_referralComissionMul10Pow3>0,"Invalid Pre-Sale commission");

        wethAddress = _wethAddress;
        tokenAddress = _tokenAddress;
        TOKEN = IERC20(tokenAddress);
        usdtAddress = _usdtAddress;
        USDT = IERC20(usdtAddress);
        catchalAddress = _catchalAddress;
        pairUsdtWethAddress = _pairUsdtWethAddress;
        preSalePriceMul10Pow18 = _preSalePriceMul10Pow18;
        referralComissionMul10Pow3 = _referralComissionMul10Pow3;
    }
    
    function buy(address payable _referral_address,uint _usdtAmount) payable public {
        require(_usdtAmount>0 || msg.value>0,"One of USDT Amount or ETH Amount must be set");

        //pay referral commission
        (uint _paidCommissionUsdt,uint _paidCommissionEth) = _payCommision(_referral_address,_usdtAmount,msg.value);
        

        //send bought token
        uint tokenAmount;
        if(_usdtAmount>0){
            USDT.transferFrom(
                msg.sender,
                catchalAddress,
                _usdtAmount - _paidCommissionUsdt
            );
            tokenAmount += _usdtAmount * preSalePriceMul10Pow18 / 1e18; // 10**18 is for pre-sale price
        }
        if(msg.value>0){
            catchalAddress.transfer(msg.value - _paidCommissionEth); // address(this).balance
            uint decimals = (block.chainid==56)?1e36:1e24;// usdt decimals in BNB is 18 and other chains is 6. second 10**18 is for eth decimals
            tokenAmount += msg.value * getEthPrice() * preSalePriceMul10Pow18 / decimals; 
        }

        TOKEN.transferFrom(
            catchalAddress,
            msg.sender,
            tokenAmount
        );
        soldAmount += tokenAmount;
    }

    function _payCommision(address payable _referral_address,uint _usdt_amount,uint _eth_amount) private returns(uint,uint){
        //check referal address
        if(referrals[msg.sender]==address(0) && _referral_address!=address(0)){
            referrals[msg.sender] = _referral_address;
        }
        if(referrals[msg.sender]==address(0)) return (0,0);

        // pay usdt commission
        uint _commissionUsdt = 0;
        if(_usdt_amount>0){
            _commissionUsdt = _usdt_amount*referralComissionMul10Pow3/1e3;
            USDT.transferFrom(
                msg.sender,
                referrals[msg.sender],
                _commissionUsdt
            );
        }
        // pay eth commission
        uint _commissionEth = 0;
        if(_eth_amount>0){
            _commissionEth = _eth_amount*referralComissionMul10Pow3/1e3;
            referrals[msg.sender].transfer(_commissionEth);
        }
        return (_commissionUsdt,_commissionEth);
    }

    function getEthPrice() public view returns (uint256) {
        
        //Get ETH price
        IUniswapV2Pair pairContract = IUniswapV2Pair(pairUsdtWethAddress);
        (uint112 reserve0,uint112 reserve1,) = pairContract.getReserves();

        // Ensure the token order is correct (token0 must be the one with a smaller address)
        if (usdtAddress > wethAddress) {
            return (uint256(reserve1) * 1e18) / reserve0;
        } else {
            return (uint256(reserve0) * 1e18) / reserve1;
        }
    }

    //Ownership
    constructor() {
        owner = payable(msg.sender);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    // fallback function to receive BNB
    receive() external payable {}
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}