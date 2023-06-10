/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
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

contract SERA {
    string public name = "SERA";
    string public symbol = "SERA";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public feePool;
    uint256 public feePercentage = 198; // 1.98%
    uint256 public feePoolMinimum = 500 * (10 ** 18); // Minimum fee pool amount required to continue SERA rewards (500 MATIC)
    address public owner;
    address public mintAddress;
    address public paymentGatewayAddress;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public rewardBalanceOf;
    mapping(address => uint256) public lastClaimTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardPaid(address indexed user, uint256 reward);
    event Mint(address indexed to, uint256 value);
    event Redeem(address indexed from, uint256 value);
    event Burn(address indexed account, uint256 amount);
    event FeePercentageChanged(uint256 newFeePercentage);
    event FeePoolMinimumChanged(uint256 newFeePoolMinimum);

    constructor(uint256 _initialSupply, address _paymentGatewayAddress) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        owner = msg.sender;
        paymentGatewayAddress = _paymentGatewayAddress;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        uint256 fee = (_value * feePercentage) / 10000; // calculate fee (0.98%)
        uint256 transferAmount = _value - fee; // calculate transfer amount
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        feePool += fee;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, address(this), fee);

        return true;
    }

    function mint(address _to, uint256 _value) public {
        require(msg.sender == owner || msg.sender == paymentGatewayAddress, "Only the Sera address or payment gateway can mint");
        balanceOf[_to] += _value;
        totalSupply += _value;

        emit Mint(_to, _value);
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        emit Burn(msg.sender, _value);
    }

    function calculateReward(address _user) public view returns (uint256) {
        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime[_user];
        uint256 rewardAmount = ((balanceOf[_user] + rewardBalanceOf[_user]) * timeSinceLastClaim) / (2 weeks);
        return rewardAmount;
    }

    function reward() public {
        uint256 rewardAmount = calculateReward(msg.sender);
        require(rewardAmount > 0, "No SERA rewards available");
        require(feePool >= feePoolMinimum, "Fee pool below minimum level");

        uint256 rewardProportion = (balanceOf[msg.sender] * rewardAmount) / (balanceOf[msg.sender] + rewardBalanceOf[msg.sender]);
        rewardBalanceOf[msg.sender] += rewardProportion;
        feePool -= rewardProportion;

        emit RewardPaid(msg.sender, rewardProportion);
    }

    function withdrawFees() public {
        require(msg.sender == owner, "Only Sera/contract owner can withdraw fees");
        require(feePool >= feePoolMinimum, "SERA Fee pool below minimum level");

        uint256 totalStablecoin = totalSupply - balanceOf[address(this)]; // calculate total SERA supply excluding fee pool
        uint256 userBalance = balanceOf[msg.sender];
        require(userBalance > 0, "No rewards available");

        uint256 rewardAmount = (feePool * userBalance) / totalStablecoin; // calculate reward proportionate to user's SERA balance
        require(rewardAmount > 0, "No rewards available");
        require(feePool >= rewardAmount, "Fee pool below reward amount");

        rewardBalanceOf[msg.sender] += rewardAmount;
        feePool -= rewardAmount;

        emit RewardPaid(msg.sender, rewardAmount);
    }

    function checkFeePoolBalance() public view returns (uint256) {
        require(msg.sender == owner, "Only Sera/contract owner can check the fee pool balance");
        return feePool;
    }

    function getRewardBalance(address _user) public view returns (uint256) {
        return rewardBalanceOf[_user];
    }

    function changeFeePercentage(uint256 _newFeePercentage) public {
        require(msg.sender == owner, "Only Sera/contract owner can change the fee percentage");
        feePercentage = _newFeePercentage;
    }

    function changeFeePoolMinimum(uint256 _newFeePoolMinimum) public {
        require(msg.sender == owner, "Only Sera/contract owner can change the fee pool minimum");
        feePoolMinimum = _newFeePoolMinimum * (10 ** uint256(decimals));
    }
}