/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

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

// File: contracts/Preslae.sol


pragma solidity ^0.8.0;


contract Presale {
    address public admin;
    address public tokenAddress;
    
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public priceInBNB;
    uint256 public hardcapInBNB;
    
    bool public presaleActive;
    bool public presaleFinished;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier duringPresale() {
        require(presaleActive && !presaleFinished, "Presale is not active");
        require(block.timestamp >= startTimestamp, "Presale has not started yet");
        require(block.timestamp <= endTimestamp, "Presale has ended");
        _;
    }
    
    constructor(
        address _tokenAddress,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _priceInBNB,
        uint256 _hardcapInBNB
    ) {
        admin = msg.sender;
        tokenAddress = _tokenAddress;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        priceInBNB = _priceInBNB;
        hardcapInBNB = _hardcapInBNB;
    }
    
    function setPresaleStatus(bool _active) external onlyAdmin {
        presaleActive = _active;
    }
    
    function pausePresale() external onlyAdmin {
        require(presaleActive, "Presale is not active");
        presaleActive = false;
    }
    
    function resumePresale() external onlyAdmin {
        require(!presaleActive, "Presale is already active");
        presaleActive = true;
    }
    
    function setTokenAddress(address _tokenAddress) external onlyAdmin {
        require(_tokenAddress != address(0), "Invalid token address");
        tokenAddress = _tokenAddress;
    }
    
    function setTokenPrice(uint256 _priceInBNB) external onlyAdmin {
        require(_priceInBNB > 0, "Invalid token price");
        priceInBNB = _priceInBNB;
    }
    
    function setStartTimestamp(uint256 _startTimestamp) external onlyAdmin {
        require(_startTimestamp > 0, "Invalid start timestamp");
        startTimestamp = _startTimestamp;
    }
    
    function setEndTimestamp(uint256 _endTimestamp) external onlyAdmin {
        require(_endTimestamp > 0, "Invalid end timestamp");
        endTimestamp = _endTimestamp;
    }
    
    function setHardcapInBNB(uint256 _hardcapInBNB) external onlyAdmin {
        require(_hardcapInBNB > 0, "Invalid hard cap");
        hardcapInBNB = _hardcapInBNB;
    }
    
    function getPresaleStatus() external view returns (bool) {
        return presaleActive;
    }
    
    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }
    
    function getTokenPrice() external view returns (uint256) {
        return priceInBNB;
    }
    
    function getStartTimestamp() external view returns (uint256) {
        return startTimestamp;
    }
    
    function getEndTimestamp() external view returns (uint256) {
        return endTimestamp;
    }
    
    function getBalance(address walletAddress) external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(walletAddress);
    }
    
    function getHardcapFilled() external view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        return (contractBalance * 1e18) / priceInBNB;
    }
    
    function withdrawFunds() external onlyAdmin {
        require(presaleFinished, "Presale is not finished");
        payable(admin).transfer(address(this).balance);
    }
    
    function finishPresale() external onlyAdmin {
        require(presaleActive, "Presale is not active");
        presaleFinished = true;
        presaleActive = false;
    }
}