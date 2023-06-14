/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: GPL-3.0

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

// File: sale.sol


pragma solidity ^0.8.18;


contract TokenSale {
    IERC20 public tokenToSell;
    IERC20 public usdtToken;
    address public owner;
    uint256 public price;
    uint256 public tokensSold;

    mapping(address => uint256) public tokenClaims;
    mapping(address => address) public referrers; // Mapping to keep track of who referred whom
    mapping(address => uint256) public referralBonuses;
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public lastRefClaim;

    event Sold(address buyer, uint256 amount);

    constructor(address _tokenToSell, address _usdtTokenAddress) {
        tokenToSell = IERC20(_tokenToSell);
        usdtToken = IERC20(_usdtTokenAddress);
        owner = msg.sender;
        price = 10 * (10**6); //Price of token in USDT
    }

    receive() external payable {
        revert("ETH deposits are not accepted in this contract");
    }

    // function registerReferrer(address referrer) public {
    //     referrers[msg.sender] = referrer;
    // }

    function buyTokens(uint256 usdtAmount, address referralCodeOwner) public {
        uint256 tokenAmount = usdtAmount / price;
        require(tokenAmount > 0, "Insufficient payment");

        uint256 availableTokens = tokenToSell.balanceOf(address(this)) -
            tokensSold;
        require(availableTokens >= tokenAmount, "Not enough tokens available");

        require(referrers[msg.sender] == address(0), "Error: User already registered!");

        // Approve the contract to spend the buyer's USDT tokens
        require(
            usdtToken.approve(address(this), usdtAmount),
            "USDT approval failed"
        );

        // Transfer the approved USDT tokens to the contract
        require(
            usdtToken.transferFrom(msg.sender, address(this), usdtAmount),
            "USDT transfer failed"
        );

        tokensSold += tokenAmount;
        emit Sold(msg.sender, tokenAmount);

        // Transfer the tokens to the buyer
        require(
            tokenToSell.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );

        // Store the token amount to be claimed by the buyer
        tokenClaims[msg.sender] += tokenAmount * 1e18;

        // Handle the referral bonuses
        address currentReferrer = referralCodeOwner;
        for (uint256 i = 0; i < 10; i++) {
            if (currentReferrer != address(0)) {
                uint256 referralBonus = (tokenAmount * (10 - i)) / 100;
                referralBonuses[currentReferrer] += referralBonus;
                currentReferrer = referrers[currentReferrer];
            } else {
                break;
            }
        }

        // Automatically register the referrer if not registered before
            referrers[msg.sender] = referralCodeOwner;
    }

    function claimTokens() public {
        require(tokenClaims[msg.sender] > 0, "No tokens to claim");

        // Calculate the maximum claim amount (20% of the tokenClaims)
        uint256 maxClaimAmount = tokenClaims[msg.sender] / 20;
        require(maxClaimAmount > 0, "No tokens available for the next claim");

        // Check if enough time has passed since the last claim
        require(
            block.timestamp >= lastClaimTime[msg.sender] + 2 minutes,
            "Cooldown period has not elapsed"
        );

        // Update the last claim time to the current time
        lastClaimTime[msg.sender] = block.timestamp;

        // Transfer the claimed tokens to the buyer
        require(
            tokenToSell.transfer(msg.sender, maxClaimAmount),
            "Token transfer failed"
        );

        // Update the remaining tokenClaims amount
        tokenClaims[msg.sender] -= maxClaimAmount;
    }

    function claimReferralBonus() public {
        require(referralBonuses[msg.sender] > 0, "No referral bonus available");

        // Calculate the maximum Ref claim amount (20% of the referralBonuses)
        uint256 referralBonus = referralBonuses[msg.sender] / 20;
        require(referralBonus > 0, "No tokens avaliable for the next claim");

        // Check if enough time has passed since the last claim
        require(
            block.timestamp >= lastRefClaim[msg.sender] + 2 minutes,
            "You can claim after 2 min"
        );

        // Update the last claim time to the current time
        lastRefClaim[msg.sender] = block.timestamp;

        // Transfer the referral bonus tokens to the referral code owner
        require(
            tokenToSell.transfer(msg.sender, referralBonus*1e16),
            "Referral token transfer failed"
        );

        // Update the remaining referralBonus amount
        referralBonuses[msg.sender] -= referralBonus;
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint256 balance = usdtToken.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        // Transfer the remaining USDT tokens to the owner
        require(usdtToken.transfer(owner, balance), "USDT transfer failed");
    }

    function getContractTokenBalance() public view returns (uint256) {
        return tokenToSell.balanceOf(address(this));
    }

    function tokenLeft() public view returns (uint256) {
        return tokenToSell.balanceOf(address(this)) - tokensSold;
    }
}