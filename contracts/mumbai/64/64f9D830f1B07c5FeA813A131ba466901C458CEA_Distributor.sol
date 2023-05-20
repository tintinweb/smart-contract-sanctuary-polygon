// SPDX-License-Identifier: MIT
// Rewards Distributor
pragma solidity ^0.8.0;

import "ISheqelToken.sol"; 
import "IERC20.sol";
import "IReserve.sol";

contract Distributor {
    uint256 public lastDistribution;
    uint256 public currentShqToUBR;
    uint256 public currentShqToRewards;
    uint256 public currentUSDCToUBR;
    uint256 public currentUSDCToRewards;
    bool public shqSet = false;
    ISheqelToken public sheqelToken;
    IERC20 public USDC;
    address public teamAddress;
    IReserve public reserveContract;

    constructor(address _usdcAddress, address _reserveAddress) {
        teamAddress = msg.sender;
        USDC = IERC20(_usdcAddress);
        reserveContract = IReserve(_reserveAddress);
    }

    modifier onlyTeam() {
        require(msg.sender == teamAddress, "Caller must be team address");
        _;
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Caller must be Sheqel Token");
        _;
    }

    modifier onlyReserve() {
        require(msg.sender == address(reserveContract), "Caller must be Reserve");
        _;
    }

    function setShq(address _addr) external onlyTeam() {
        require(shqSet == false, "SHQ Already set");
        sheqelToken = ISheqelToken(_addr);
        shqSet = true;
    }

    function addToCurrentShqToUBR(uint256 _amount) external onlyToken() {
        currentShqToUBR += _amount;
    }

    function addToCurrentShqToRewards(uint256 _amount) external onlyToken() {
        currentShqToRewards += _amount;
    }

    function addToCurrentUsdcToRewards(uint256 _amount) external onlyReserve() {
        currentUSDCToRewards += _amount;
    }

    function addToCurrentUsdcToUBR(uint256 _amount) external onlyReserve() {
        currentUSDCToUBR += _amount;
    }

    function processAllRewards(address[] calldata _addresses , uint256[] calldata _balances, address[] calldata _ubrAddresses) onlyTeam() external{
        require(block.timestamp >= lastDistribution + 1 days, "Cannot distribute two times in a day");

        // Convert all SHQ to USDC
        if(currentShqToRewards > 0){
            currentUSDCToRewards += swapSHQToUSDC(currentShqToRewards);
            currentShqToRewards = 0;
        }
        if(currentShqToUBR > 0){
            currentUSDCToUBR += swapSHQToUSDC(currentShqToUBR);
            currentShqToUBR = 0;
        }   

        // Compute total balance by iterating over all balances and adding them
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < _balances.length; i++) {
            totalBalance += _balances[i];
        }

        // Iterate through all addresses
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Get the address
            address holder = _addresses[i];
            // Get the balance
            uint256 balance = _balances[i];

            // Calculate the rewards
            uint256 rewards = (balance * currentUSDCToRewards) / totalBalance;
            // Send the rewards
            USDC.transfer(holder, rewards);
            currentUSDCToRewards = 0;
        }
        // Compute the UBR
        uint256 ubrReward = ((USDC.balanceOf(address(this))) / _ubrAddresses.length) - 100;
        // Iterate through all UBR addresses
        for (uint256 i = 0; i < _ubrAddresses.length; i++) {
            // Get the address
            address holder = _ubrAddresses[i];

            // Send the UBR
            USDC.transfer(holder, ubrReward);
            currentUSDCToUBR = 0;
        }
        // Update last distribution
        lastDistribution = block.timestamp;

        // Send rest to the reserve 
        USDC.transfer(address(reserveContract), USDC.balanceOf(address(this)));
        sheqelToken.transfer(address(reserveContract), sheqelToken.balanceOf(address(this)));
    }

    function swapSHQToUSDC(uint256 amount) internal returns(uint256){
        uint256 balancePreswapUSDC = USDC.balanceOf(address(this));
        sheqelToken.approve(address(reserveContract), amount);
        reserveContract.sellShq(address(this), amount);

        return USDC.balanceOf(address(this)) - balancePreswapUSDC;
    }
}

pragma solidity ^0.8.0;

interface ISheqelToken {
    function getDistributor() external returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function MDOAddress() external returns (address);
    function liquidityManagerAddress() external returns (address);
    function reserveAddress() external view returns (address);



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.0;

interface IReserve {
    function sellShq(address _beneficiary, uint256 _shqAmount) external;
    function buyShq(address _beneficiary, uint256 _shqAmount) external;
    function buyShqWithUsdc(address _beneficiary, uint256 _usdcAmount) external;
}