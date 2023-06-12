/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: Crowd.sol


pragma solidity ^0.8.0;


contract ICOCrowdsale {
    address payable public owner;
    IERC20 public tokenContract;
    IERC20 public cusdtContract;
    
    uint256 public tokenPrice;  // Price of token in CUSDT (in wei).
    uint256 public minPurchase; // Min purchase limit in CUSDT (in wei).
    uint256 public maxPurchase; // Max purchase limit in CUSDT (in wei).

    event TokensPurchased(address indexed purchaser, uint256 amount);

    constructor(
        address tokenContractAddress, 
        address cusdtContractAddress, 
        uint256 _tokenPrice, 
        uint256 _minPurchase, 
        uint256 _maxPurchase
    ) {
        owner = payable(msg.sender);
        tokenContract = IERC20(tokenContractAddress);
        cusdtContract = IERC20(cusdtContractAddress);
        tokenPrice = _tokenPrice;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }

    receive() external payable {
        revert("Direct payment not accepted");
    }

    function buyTokens(uint256 cusdtAmount) public {
    require(cusdtAmount >= minPurchase, "CUSDT amount less than minimum purchase limit");
    require(cusdtAmount <= maxPurchase, "CUSDT amount exceeds maximum purchase limit");
    require(cusdtAmount % tokenPrice == 0, "Cannot purchase fractional tokens");

    // Check allowance
    uint256 allowed = cusdtContract.allowance(msg.sender, address(this));
    require(allowed >= cusdtAmount, "Must approve contract to spend CUSDT token first");
        
    uint256 tokenAmount = cusdtAmount * 10**18 / tokenPrice;

    require(tokenContract.balanceOf(address(this)) >= tokenAmount, "Not enough tokens in contract");

    cusdtContract.transferFrom(msg.sender, address(this), cusdtAmount);
    tokenContract.transfer(msg.sender, tokenAmount);

    emit TokensPurchased(msg.sender, tokenAmount);
}



    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = cusdtContract.balanceOf(address(this));
        cusdtContract.transfer(owner, balance);
    }
    
    function withdrawTokens() public {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner, balance);
    }
}