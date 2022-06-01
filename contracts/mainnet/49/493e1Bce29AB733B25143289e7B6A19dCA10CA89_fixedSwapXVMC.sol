/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: xvmc-contracts/helper/fixedSwap.sol


pragma solidity ^0.8.0;



interface IToken {
	function governor() external view returns (address);
}
interface IGovernor {
	function treasuryWallet() external view returns (address);
}
interface IChainlink {
	function latestAnswer() external view returns (int256);
}

contract fixedSwapXVMC is ReentrancyGuard {
	address public immutable XVMCtoken;
	address public immutable wETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
	address public immutable usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

	uint256 public rate; //amount of XVMC per 1 USDC

	address public chainlinkWETH = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
	address public chainlinkMATIC = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;

	event Swap(address sender, address sendToken, uint256 depositAmount, uint256 withdrawAmount);
    
	constructor(address _xvmc, uint256 _rate) {
		XVMCtoken = _xvmc;
		rate = _rate;
	}

	
	function swapWETHforXVMC(uint256 amount) external nonReentrant {
		address _governor = IToken(XVMCtoken).governor();
		address _treasuryWallet = IGovernor(_governor).treasuryWallet();

		uint256 _toSend = getWETHinfo(amount);
		require(IERC20(wETH).transferFrom(msg.sender, _treasuryWallet, amount));
		IERC20(XVMCtoken).transfer(msg.sender, _toSend);

		emit Swap(msg.sender, wETH, amount, _toSend);
	}

	function swapMATICforXVMC(uint256 amount) payable public nonReentrant {
		require(msg.value == amount);

		address _governor = IToken(XVMCtoken).governor();
		address _treasuryWallet = IGovernor(_governor).treasuryWallet();

		payable(_treasuryWallet).transfer(amount);

		uint256 _toSend = getMaticInfo(amount);

		IERC20(XVMCtoken).transfer(msg.sender, _toSend);

		emit Swap(msg.sender, 0x0000000000000000000000000000000000001010, amount, _toSend);
	}

	function swapUSDCforXVMC(uint256 amount) external nonReentrant {
		address _governor = IToken(XVMCtoken).governor();
		address _treasuryWallet = IGovernor(_governor).treasuryWallet();

		uint256 _toSend = amount * 1e12 * rate;

		require(IERC20(usdc).transferFrom(msg.sender, _treasuryWallet, amount));
		IERC20(XVMCtoken).transfer(msg.sender, _toSend);

		emit Swap(msg.sender, usdc, amount, _toSend);
	}

	//governing contract can cancle the sale and withdraw tokens
	//leaves possibility to withdraw any kind of token in case someone sends tokens to contract
	function withdrawTokens(uint256 amount, address _token, bool withdrawAll) external {
		address _governor = IToken(XVMCtoken).governor();
		require(msg.sender == _governor, "Governor only!");
		if(withdrawAll) {
			IERC20(_token).transfer(_governor, IERC20(_token).balanceOf(address(this)));
		} else {
			IERC20(_token).transfer(_governor, amount);
		}
	}
	
	// change swap rate
	function changeSwapRate(uint256 amount) external {
		address _governor = IToken(XVMCtoken).governor();
		require(msg.sender == _governor, "Governor only!");
		
		rate = amount;
	}

	function getWETHinfo(uint256 _amount) public view returns (uint256) {
		uint256 wETHprice = uint256(IChainlink(chainlinkWETH).latestAnswer());

		return (_amount * wETHprice * rate / 1e8); //amount deposited * price of eth * rate(of XVMC per 1udc)
	}

	function getMaticInfo(uint256 _amount) public view returns (uint256) {
		uint256 maticPrice = uint256(IChainlink(chainlinkMATIC).latestAnswer());

		return (_amount * maticPrice * rate / 1e8); 
	}
	
}