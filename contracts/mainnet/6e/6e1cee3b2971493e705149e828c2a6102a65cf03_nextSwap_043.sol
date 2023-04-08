/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-07
*/

/**
 *Submitted for verification at FtmScan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT

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



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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


pragma solidity ^0.8.0;


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



contract nextSwap_043 is Context, Ownable {
    mapping(address => uint256) private initialLiquidity;
    mapping(address => uint256) private deposits;
    mapping(address => uint256) private tax;
    mapping(address => address) private taxrecipient;
    address private platformFeeRecipient;
    

    constructor () {
        platformFeeRecipient=msg.sender;
        
    }


    

    function setPlaformFeeRecipient(address platformfeerec) public onlyOwner {
        platformFeeRecipient=platformfeerec;
    }


    function addToken(address a, uint256 tax1, address taxrecipient1, uint256 priceBNB) public {

        require(initialLiquidity[a]==0,'This token has already been added to nextswap.');
        // tax can't be greater than 50/1000 
        require(tax1 < 50, 'Tax can not be more than 5 percent');

        //priceBNB is in cents
        uint256 amtInitialLiquidity = (20000 * 10 ** 20)/priceBNB;

        initialLiquidity[a]=amtInitialLiquidity;
        tax[a]=tax1;
        taxrecipient[a]=taxrecipient1;
    }


    function depositsOf(address a) public view returns (uint256) 
    {
        return deposits[a];
    }   

    function initialliquidityOf(address a) public view returns (uint256) 
    {
        return initialLiquidity[a];
    }

    function remoteBalanceOf(address a) public view returns (uint256)
    {
        return IERC20(a).balanceOf(address(this));
    }

    function B4Testimate(address a, uint256 bnbamt) public view returns (uint256) {
        
        uint256 deposits1=deposits[a];
        uint256 initialiquiditynow=initialLiquidity[a];
        uint256 tokens=IERC20(a).balanceOf(address(this));
        uint256 tokenbalance=tokens;
        uint256 subtotal=bnbamt;
        uint256 tokentax=(subtotal*tax[a])/1000;

       // platform fee is 1%
        uint256 platformfee=(subtotal * 15)/1000;
        uint256 bnbamount=subtotal-(tokentax+platformfee);

        uint256 tnow=(tokens*bnbamount)/(initialiquiditynow+deposits1);
        

        deposits1=deposits1+bnbamount;
        tokens=tokens-tnow;

        uint256 totaltokens=(tokens*bnbamount)/(initialiquiditynow+deposits1);
        if (totaltokens>tokenbalance) {totaltokens=tokenbalance;}

        return totaltokens;            

    }

    function T4Bestimate(address a, uint256 tokensamt) public view returns (uint256) {
        
        uint256 deposits1=deposits[a];
        uint256 initialiquidity=initialLiquidity[a];
        uint256 tokens=IERC20(a).balanceOf(address(this));
        
        uint256 bnow=(tokensamt*(initialiquidity+deposits1))/tokens;
        

        if (deposits1>bnow)
        {
            deposits1=deposits1-bnow;
        }
        tokens=tokens+tokensamt;

        uint256 subtotalbnb=(tokensamt*(initialiquidity+deposits1))/tokens;

        uint256 tokentax=(subtotalbnb*tax[a])/1000;
        uint256 platformfee=(subtotalbnb * 15)/1000;
        uint256 bnbamount=subtotalbnb-(tokentax+platformfee);

        if (bnbamount> (initialLiquidity[a] +deposits[a]) )
        {
            bnbamount=(initialLiquidity[a]+deposits[a]);
        }

        return bnbamount;

    }

    function swapBNBForTokens(address a) public payable {
        
        uint256 deposits1=deposits[a];
        uint256 initialiquiditynow=initialLiquidity[a];
        uint256 tokens=IERC20(a).balanceOf(address(this));
        uint256 tokenbalance=tokens;
        uint256 subtotal=msg.value;
        uint256 tokentax=(subtotal*tax[a])/1000;

       // platform fee is 1.5%
        uint256 platformfee=(subtotal * 15)/1000;
        uint256 bnbamount=subtotal-(tokentax+platformfee);

        payable(taxrecipient[a]).transfer(tokentax);
        payable(platformFeeRecipient).transfer(platformfee);
        

        uint256 tnow=(tokens*bnbamount)/(initialiquiditynow+deposits1);
        

        deposits1=deposits1+bnbamount;
        tokens=tokens-tnow;

        uint256 totaltokens=(tokens*bnbamount)/(initialiquiditynow+deposits1);
        if (totaltokens>tokenbalance) {totaltokens=tokenbalance;}

        IERC20(a).transfer(msg.sender,totaltokens);


    }



        function swapBNBAmtForTokens(uint256 amt, address a, address recipient) private {
        
        uint256 deposits1=deposits[a];
        uint256 initialiquiditynow=initialLiquidity[a];
        uint256 tokens=IERC20(a).balanceOf(address(this));
        uint256 tokenbalance=tokens;
        uint256 subtotal=amt;
        uint256 tokentax=(subtotal*tax[a])/1000;

       // platform fee is 1.5%
        uint256 platformfee=(subtotal * 15)/1000;
        uint256 bnbamount=subtotal-(tokentax+platformfee);

        payable(taxrecipient[a]).transfer(tokentax);
        payable(platformFeeRecipient).transfer(platformfee);
        

        uint256 tnow=(tokens*bnbamount)/(initialiquiditynow+deposits1);
        

        deposits1=deposits1+bnbamount;
        tokens=tokens-tnow;

        uint256 totaltokens=(tokens*bnbamount)/(initialiquiditynow+deposits1);
        if (totaltokens>tokenbalance) {totaltokens=tokenbalance;}

        IERC20(a).transfer(recipient,totaltokens);


    }



    function swapTokensForBNB(address a, uint256 tokensamt) public {

        uint256 deposits1=deposits[a];
        uint256 initialiquidity=initialLiquidity[a];
        uint256 tokens=IERC20(a).balanceOf(address(this));
        
        uint256 bnow=(tokensamt*(initialiquidity+deposits1))/tokens;
        

        if (deposits1>bnow)
        {
            deposits1=deposits1-bnow;
        }
        tokens=tokens+tokensamt;

        uint256 subtotalbnb=(tokensamt*(initialiquidity+deposits1))/tokens;

        uint256 tokentax=(subtotalbnb*tax[a])/1000;
        uint256 platformfee=(subtotalbnb * 15)/1000;
        uint256 bnbamount=subtotalbnb-(tokentax+platformfee);

        if (bnbamount> (initialLiquidity[a] +deposits[a]) )
        {
            bnbamount=(initialLiquidity[a]+deposits[a]);
        }


        payable(taxrecipient[a]).transfer(tokentax);
        payable(platformFeeRecipient).transfer(platformfee);

        IERC20(a).transferFrom(address(msg.sender),address(this),tokensamt);
        payable(msg.sender).transfer(bnbamount);


    }





    function swapTokensForTokens(address a, address b, uint256 tokensamt) public {

        uint256 deposits1=deposits[a];
        uint256 initialiquidity=initialLiquidity[a];
        uint256 tokens=IERC20(a).balanceOf(address(this));
        
        uint256 bnow=(tokensamt*(initialiquidity+deposits1))/tokens;
        

        if (deposits1>bnow)
        {
            deposits1=deposits1-bnow;
        }
        tokens=tokens+tokensamt;

        uint256 subtotal=(tokensamt*(initialiquidity+deposits1))/tokens;

        uint256 tokentax=(subtotal*tax[a])/1000;
        uint256 platformfee=(subtotal * 15)/1000;
        uint256 bnbamount=subtotal-(tokentax+platformfee);

        if (bnbamount> (initialLiquidity[a] +deposits[a]) )
        {
            bnbamount=(initialLiquidity[a]+deposits[a]);
        }


        payable(taxrecipient[a]).transfer(tokentax);
        payable(platformFeeRecipient).transfer(platformfee);

        IERC20(a).transferFrom(address(msg.sender),address(this),tokensamt);
        
        swapBNBAmtForTokens(bnbamount,b,address(msg.sender));

        
    }





}