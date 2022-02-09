/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function deposit(address to, uint256 amount) external returns (bool);
    function withdraw(address from, uint256 amount) external returns (bool);
    function sendTo(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
contract UniswapV2Router02 {

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts)  {}

  function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts){}

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts){}
  
  function WETH() external pure returns (address){}
}

contract DAPP_MANAGER  {
    UniswapV2Router02 private constant router = UniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address private constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
   

    IERC20 HTGToken ;
    IERC20 USDToken ;

    uint256 public price;
    address public  owner;
    uint256 public  fees; 

    address public  admin;

    
 
    constructor(uint256 inittialPrice_, address usdToken, address htgToken)   {  
        owner = msg.sender;
        admin = msg.sender;
        fees =  70; //=> 50/100 = 0.7%

        price = inittialPrice_;
        USDToken = IERC20(usdToken);
        HTGToken = IERC20(htgToken);
    }  

    /// Modifies a function to only run if sent by `role` or the contract's `owner`.
    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized: not owner or role");
        _;
    }

    function changeUSD(address usdToken) public onlyOwner returns (bool) {
        USDToken = IERC20(usdToken);
        return true;
    }

    function changeHTG(address htgToken) public onlyOwner returns (bool) {
        HTGToken = IERC20(htgToken);
        return true;
    }

    function changeFee(uint256 fee_) public onlyOwner returns (bool) {
        require(msg.sender == owner, "Only owner can set the fee");
        fees = fee_;
        return true;
    }

    function changePriceSOS(uint256 pricce_) public onlyOwner returns (bool) {
        price = pricce_;
        return true;
    }

    function changeAdmin(address admin_) public onlyOwner returns (bool) {
     require(admin_ != address(0) , "Collector can't be null");
	 admin = admin_;
     return true;
    }


    function buyHTG(uint256 usd) public  returns (bool) {
        
        require(usd > 0, "Usd amount can't be zero");
        require(USDToken.balanceOf(msg.sender) >= usd, "Token not enough");
        require(price > 0, "Price has not been define");


        uint256 taxes  = div(mul(usd,fees), 10**4); 
        uint256 usdTaxed = usd - taxes;
        uint256 tokens = div(mul(usdTaxed, price), 1000);

        USDToken.transferFrom(msg.sender, address(this), usdTaxed + (taxes/2));
        USDToken.transferFrom(msg.sender, admin, taxes/2);


        // address[] memory path = new address[](2);
        // path[0] = address(USDToken);
        // path[1] =  router.WETH();
        // //Swap the USD to token
        // router.swapExactTokensForETH(
        // taxes/3,
        // 0,
        // path,
        // msg.sender,
        // block.timestamp
        // );
        
        HTGToken.deposit(address(this), tokens);
        HTGToken.transfer(msg.sender, tokens);

        return true;
    }


    function sellHTG(uint256 tokens) public returns (bool) {

        require(tokens > 0, "Usd amount can't be zero");
        require(HTGToken.balanceOf(msg.sender) >= tokens, "Token not enough");
        require(price > 0, "Price has not been define");


        uint256 usd = mul(div(tokens, price), 1000);
        uint256 taxes  = div(mul(usd,fees), 10**4); 
        uint256 usdTaxed = usd - taxes;

        USDToken.transfer(msg.sender, usdTaxed);
        USDToken.transfer(admin, taxes/2);

        // address[] memory path = new address[](2);
        // path[0] = address(USDToken);
        // path[1] =  router.WETH();
        // //Swap the USD to token
        // router.swapExactTokensForETH(
        // taxes/3,
        // 0,
        // path,
        // msg.sender,
        // block.timestamp
        // );
        

        HTGToken.transferFrom(msg.sender, address(this), tokens);
        HTGToken.withdraw(address(this), tokens);

        return true;
    }


    function sendHTG(address from, address to,  uint256 tokens) public returns (bool) {

        require(tokens > 0, "Tokens amount can't be zero");
        require(HTGToken.balanceOf(msg.sender) >= tokens, "Token not enough");

        HTGToken.sendTo(from, to , tokens);

        return true;
    }


    function swap(address tok_in,address tok_out, uint amount) public
    {

        IERC20 token1  = IERC20(tok_in);
        IERC20 token2  = IERC20(tok_out);

        uint usdAmount = amount;

        if( HTGToken == token1){
                //Verification requiement
                require(amount > 0, "Usd amount can't be zero");
                require(HTGToken.balanceOf(msg.sender) >= amount, "Token not enough");
                require(price > 0, "Price has not been define");

             
                uint256 usd = mul(div(amount, price), 1000); // Convert htg to usd
                uint256 taxes  = div(mul(usd,fees), 10**4);  // calculate fees
                uint256 usdTaxed = usd - taxes; // remove fees total amount

                USDToken.transfer(admin, taxes/3); //Send a part of the fee to admin and leave the for liquidity




                address[] memory path2 = new address[](2);
                path2[0] = address(USDToken);
                path2[1] =  router.WETH();
                //Swap the USD to token
                router.swapExactTokensForETH(
                taxes/3,
                0,
                path2,
                msg.sender,
                block.timestamp
                );


                //Burn TGOUD tokens 
                HTGToken.transferFrom(msg.sender, address(this), amount);
                HTGToken.withdraw(address(this), amount);

                //Transfer USD to the smart Contract
                USDToken.transferFrom(
                    msg.sender,
                    address(this),
                    usdTaxed
                    );

                // Draw the path

                 address[] memory path;
                if (tok_out == WETH) {
                    path = new address[](2);
                    path[0] = address (USDToken);
                    path[1] = address (WETH);
                } else {
                    path = new address[](3);
                    path[0] = address (USDToken);
                    path[1] = address (WETH);
                    path[2] = address (tok_out);
                }


            
                //Allow Quickswap to use the amount of usd
                USDToken.approve(address(router), usdAmount);

                //Swap the USD to token
                router.swapExactTokensForTokens(
                usdTaxed,
                0,
                path,
                msg.sender,
                block.timestamp
                );

        }
        else if( HTGToken == token2){
              
                // Draw the path
                address[] memory path;
                if (tok_in == WETH) {
                    path = new address[](2);
                    path[0] = address (WETH);
                    path[1] = address (USDToken);
                } else 
                {
                    path = new address[](3);
                    path[0] = address (tok_in);
                    path[1] = address (WETH);
                    path[2] = address (USDToken);
                }

                //Allow Quickswap to use the amount of usd
                token1.approve(address(router), amount);

                //Swap the USD to token
                uint[] memory  amounts = router.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
                );

                uint amountOut = amounts[2];
                uint256 taxes  = div(mul(amountOut,fees), 10**4); 
                uint256 usdTaxed = amountOut - taxes;
                uint256 tokens = div(mul(usdTaxed, price), 1000);

                USDToken.transferFrom(msg.sender, address(this), usdTaxed + (taxes/3));
                USDToken.transferFrom(msg.sender, admin, taxes/3);



                address[] memory path2 = new address[](2);
                path2[0] = address(USDToken);
                path2[1] =  router.WETH();
                //Swap the USD to token
                router.swapExactTokensForETH(
                taxes/3,
                0,
                path2,
                msg.sender,
                block.timestamp
                );



                HTGToken.deposit(address(this), tokens);
                HTGToken.transfer(msg.sender, tokens);
        }
        else{
                //Transfer token1 to the smart Contract
                token1.transferFrom(
                msg.sender,
                address(this),
                usdAmount
                );

                // Draw the path
                address[] memory path;
                if (tok_in == WETH || tok_out == WETH) {
                    path = new address[](2);
                    path[0] = address (tok_in);
                    path[1] = address (tok_out);
                } else {
                    path = new address[](3);
                    path[0] = address (tok_in);
                    path[1] = address (WETH);
                    path[2] = address (tok_out);
                }

                //Allow Quickswap to use the amount of usd
                token1.approve(address(router), usdAmount);

                //Swap the USD to token
                router.swapExactTokensForTokens(
                amount,
                0,
                path,
                msg.sender,
                block.timestamp
                );
        }
       
    }

   function amountsOut(address tok_in,address tok_out, uint amount) public view returns(uint[] memory amounts)
    {

            IERC20 token1  = IERC20(tok_in);
            IERC20 token2  = IERC20(tok_out);


            uint usdAmount = amount;

            if( HTGToken == token1){
            
                    uint256 usd = mul(div(amount, price), 1000); // Convert htg to usd
                    uint256 taxes  = div(mul(usd,fees), 10**4);  // calculate fees
                    uint256 usdTaxed = usd - taxes; // remove fees total amount

        
                    // Draw the path
                    address[] memory path;
                    path = new address[](3);
                    path[0] = address (USDToken);
                    path[1] = address (WETH);
                    path[2] = address (tok_out);
                    
                    return router.getAmountsOut(usdTaxed, path);

            }else if( HTGToken == token2){
            
              
                    // Draw the path
                    address[] memory path;
                    path = new address[](3);
                    path[0] = address (tok_in);
                    path[1] = address (WETH);
                    path[2] = address (USDToken);

                    uint[] memory  amounts_ = router.getAmountsOut(amount, path);

                    uint amountOut = amounts_[2];
                    uint taxes  = div(mul(amountOut,fees), 10**4); 
                    uint usdTaxed = amountOut - taxes;
                    uint tokens = div(mul(usdTaxed, price), 1000);

                    uint[] memory  amountsFinal = new uint[](4);
                    amountsFinal[0] = amounts_[0];
                    amountsFinal[1] = amounts_[1] ;
                    amountsFinal[2] = amounts_[2] ;
                    amountsFinal[3] = tokens;
                      
                    return amountsFinal;

            }else{
                
                address[] memory path;
                if (tok_in == WETH || tok_out == WETH) {
                    path = new address[](2);
                    path[0] = address (tok_in);
                    path[1] = address (tok_out);
                } else {
                    path = new address[](3);
                    path[0] = address (tok_in);
                    path[1] = address (WETH);
                    path[2] = address (tok_out);
                }

                return router.getAmountsOut(usdAmount, path);
            }
        

    }


    function getUSDReserve() public view  returns(uint256){
        return USDToken.balanceOf(address(this));
    }

    function getHTGReserve() public view returns(uint256){
        return HTGToken.totalSupply();
    }







    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 ) {
        uint256 c = a * b;
        
        assert(a == 0 || c / a == b);
            return c;
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 ) {
        assert(b > 0);
        uint256	c = a / b;
        return c;
    }
}