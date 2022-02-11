/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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


// File contracts/Airdrop.sol

pragma solidity ^0.8.0;

contract Airdrop {

    IERC20 airdropToken;
    address owner;
    uint256 airdropAmount;
    uint256 startDate;
    uint256 endDate;

    modifier onlyAdmin() {
        require(msg.sender == owner, "Not admin");
        _;
    }

    event Claim(address indexed sender, uint256 amount);
    event WithdrawUnclaim(address owner, uint256 amount);
    event AdminChange(address newOwner);

    struct Claimed {
        bool eligible;
        bool claimed;
    }

    mapping (address => Claimed) public airdrop;

    constructor(address _tokenAddress, uint256 _amount, uint256 _starDate, uint256 _endDate, address[] memory _users) {
        owner = msg.sender;

        airdropToken = IERC20(_tokenAddress);
        airdropAmount = _amount;

        require(_endDate > _starDate);

        startDate = block.timestamp +  _starDate;
        endDate = _starDate + _endDate;

        for (uint256 i = 0; i < _users.length; i++) {
            airdrop[_users[i]].eligible = true;
            airdrop[_users[i]].claimed = false;
        }
    }

    function claim() public {
        Claimed memory user = airdrop[msg.sender];

        require(airdropToken.balanceOf(address(this)) > 0, "No more airdrops left.");
        require(block.timestamp > startDate, "Too soon to claim.");
        require(block.timestamp < endDate, "Airdrop has ended.");
        require(user.eligible, "Not eligible.");
        require(!user.claimed, "Airdrop already claimed.");

        user.claimed = true;
        airdrop[msg.sender] = user;

        emit Claim(msg.sender, airdropAmount);
        airdropToken.transfer(msg.sender, airdropAmount);
    }

    function withdrawRemainingTokens() public onlyAdmin {
        require(block.timestamp > endDate, "Not ended.");

        uint256 balance = airdropToken.balanceOf(address(this));
        airdropToken.transfer(owner, balance);

        emit WithdrawUnclaim(owner, balance);
    }

    function changeAdmin(address _newOwner) public onlyAdmin {
        owner = _newOwner;

        emit AdminChange(owner);
    }
}