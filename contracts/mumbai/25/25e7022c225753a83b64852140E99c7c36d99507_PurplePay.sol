// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title PurplePay task
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "hardhat/console.sol";


contract PurplePay {
    address public admin;
    uint256 public adminFeePercentage;
    uint256 public totalFeeCollected; 

    mapping (address => mapping(address => uint256)) public userData;

    event Deposit(address indexed _from, address indexed _tokenAddress, uint256 _amount);
    event Withdraw(address indexed _to, address indexed _tokenAddress, uint256 _amount);

    constructor() {
        admin = msg.sender;
        adminFeePercentage = 1;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin is allowed");
        _;
    }

    function deposit(address _tokenAddress, uint256 _amount) external {
        IERC20 token = IERC20(_tokenAddress);

        // console.log("Starting transferFrom: %s", address(token));
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        uint256 adminFee = _amount * adminFeePercentage / 100;
        totalFeeCollected += adminFee;
        userData[msg.sender][_tokenAddress] += (_amount - adminFee);
        
        require(token.transfer(admin, adminFee), "Admin fee transfer failed");

        emit Deposit(msg.sender, _tokenAddress, _amount);
    }

    function withdraw(address _tokenAddress, uint256 _amount) external {
        address sender = msg.sender;
        require(userData[sender][_tokenAddress] >= _amount, "Insufficient balance");
        userData[sender][_tokenAddress] -= _amount;
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(sender, _amount), "Token transfer failed");

        emit Withdraw(sender, _tokenAddress, _amount);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
    }

    function setAdminFeePercentage(uint256 _adminFeePercentage) external onlyAdmin {
        require(_adminFeePercentage <= 100, "Invalid Admin Fee Percentage");
        adminFeePercentage = _adminFeePercentage;
    }

    function getAdminFeePercentage() external view returns (uint256){
        return adminFeePercentage;
    }

    function getAdmin() external view returns (address){
        return admin;
    }

    function getTotalFeeCollected() external view returns (uint256){
        return totalFeeCollected;
    }
}