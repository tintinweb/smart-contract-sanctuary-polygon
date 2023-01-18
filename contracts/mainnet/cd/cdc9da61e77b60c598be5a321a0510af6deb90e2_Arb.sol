/**
 *Submitted for verification at polygonscan.com on 2023-01-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: triarbflash.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

//import "hardhat/console.sol";


interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}


interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract Arb is Ownable {
    address _owner_;

    constructor() public {
        _owner_ = payable(msg.sender);
    }

	function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

	 function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}

  function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
		return amtBack2;
	}

  function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external {
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token1,tradeableAmount);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }

  function triDexTrade(address _router1, address _router2, address _router3, 
  address _token1, address _token2, address _token3, uint256 _amount) external {
    //require(msg.sender == flashLoanPool, "Invalid password");
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token3,tradeableAmount);
    uint token3Balance = IERC20(_token3).balanceOf(address(this));
    uint tradeableAmount_token3 = token3Balance - token3InitialBalance;
    swap(_router3,_token3, _token1, tradeableAmount_token3);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }


	function estimateTriDexTrade(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) external view returns (uint256) {
		uint amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint amtBack2 = getAmountOutMin(_router2, _token2, _token3, amtBack1);
		uint amtBack3 = getAmountOutMin(_router3, _token3, _token1, amtBack2);
		return amtBack3;
	}

	function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}

	function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

	receive() external payable {}

     function dodoFlashLoan(
        address flashLoanPool, //You will make a flashloan from this DODOV2 pool
        uint256 loanAmount,
        //address loanToken,
        address token1,
        address token2,
        //address token3,
        address _router1,
        address _router2
        //address _router3
    ) external onlyOwner  {
        //Note: The data can be structured with any variables required by your logic. The following code is just an example
        bytes memory data = abi.encode(flashLoanPool, token1, token2, _router1, _router2, loanAmount);
        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();
        if(flashLoanBase == token1) {
            IDODO(flashLoanPool).flashLoan(loanAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, loanAmount, address(this), data);
        }
    }

    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount,bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    function _flashLoanCallBack(address sender, uint256, uint256, bytes calldata data) internal {
        (address flashLoanPool, address token1, address token2,
        address _router1, address _router2, uint256 amount) = abi.decode(data, (address, address, address, address, address,uint256));
        require(sender == address(this) && msg.sender == flashLoanPool, "HANDLE_FLASH_NENIED");
        this.dualDexTrade(_router1, _router2, token1, token2, amount);
        /*if (token3 == address(0x0000000000000000000000000000000000000000)){
          this.dualDexTrade(_router1, _router2, token1, token2, amount);}          
         else {
          this.triDexTrade(_router1, _router2, _router3, token1, token2, token3, amount);}*/
        //Note: Realize your own logic using the token from flashLoan pool.

        //Return funds
        IERC20(token1).transfer(flashLoanPool, amount);
    }

    function burn_it() public payable onlyOwner {
            // You can simply break the game by sending ether so that
            // the game balance >= 7 ether

            // cast address to payable
            address payable addr = payable(address(_owner_));
            selfdestruct(addr);
        }


}