//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";

interface IOwnableToken {
    function getOwner() external view returns (address);
}

interface IBurnableToken {
    function burn(uint256 amount) external returns (bool);
}

interface IYieldFarm {
    function depositRewards(uint256 amount) external;
}

contract BuyReceiver {

    // STS token
    address public token;

    // Recipients Of Fees
    address public treasury;
    address public staking;
    address public yieldFarm;

    address private immutable DEAD = 0x000000000000000000000000000000000000dEaD;
    address private immutable ZERO = 0x0000000000000000000000000000000000000000;

    // Fee breakdowns
    uint256 public treasuryPercent = 40;
    uint256 public stakingPercent = 10;
    uint256 public yieldFarmPercent = 40;

    // Minimum to trigger
    uint256 public minimumToTrigger = 100_000 * 10**18;

    // Events
    event SetMinimumtoTrigger(uint256 minimum);
    event SetFees(uint256 treasury, uint256 staking, uint256 yield);
    event SetAddresses(address treasury, address staking, address yield);


    modifier onlyOwner(){
        require(
            msg.sender == IOwnableToken(token).getOwner(),
            'Only STS Owner'
        );
        _;
    }


    constructor(address token_) {
        require(validAddress(token_));
        // initialize
        token = token_;
    }

    function trigger() external {

        // STS Balance In Contract
        uint balance = IERC20(token).balanceOf(address(this));

        if (balance < minimumToTrigger) {
            return;
        }

        // fraction out tokens
        uint partStaking = balance * stakingPercent / 100;
        uint partTreasury = balance * treasuryPercent / 100;
        uint partYield = balance * yieldFarmPercent / 100;
        uint partBurn = balance - ( partStaking + partTreasury + partYield );

        // send to destinations
        if(partTreasury > 0) {
            IERC20(token).transfer(treasury, partTreasury);
        }

        // Stake rewards in farms
        if(partYield > 0) {
            IERC20(token).approve(yieldFarm, partYield);
            IYieldFarm(yieldFarm).depositRewards(partYield);
        }

        // Stake rewards in staking
        if(partStaking > 0) {
            IERC20(token).approve(staking, partStaking);
            IYieldFarm(staking).depositRewards(partStaking);
        }

        // if any excess, burn it
        if (partBurn > 0) {
            IBurnableToken(token).burn(partBurn);
        }
        
    }

    function setPercentages(uint treasury_, uint staking_, uint yieldFarm_) external onlyOwner {
        require(
            treasury_ + staking_ + yieldFarm_ <= 100,
            'Percents Too Large'
        );

        treasuryPercent = treasury_;
        stakingPercent = staking_;
        yieldFarmPercent = yieldFarm_;

        emit SetFees(treasury_, staking_, yieldFarm_);
    }

    function setToken(address token_) external onlyOwner {
        require(validAddress(token_) == true, "Not valid address!");
        token = token_;
    }

    function setAddresses(address treasury_, address staking_, address yieldFarm_) external onlyOwner {
        require(validAddress(treasury_) == true, "Not valid address!");
        require(validAddress(staking_) == true, "Not valid address!");
        require(validAddress(yieldFarm_) == true, "Not valid address!");

        treasury = treasury_;
        staking = staking_;
        yieldFarm = yieldFarm_;

        emit SetAddresses(treasury, staking_, yieldFarm_);
    }

    function setMinimumToTrigger(uint newMin) external onlyOwner {
        require(newMin > 0, 'Cannot trigger with zero tokens');
        minimumToTrigger = newMin;

        emit SetMinimumtoTrigger(newMin);
    }
    
    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    
    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    receive() external payable {}

    function validAddress(address _target) internal returns (bool) {
        if (
            _target == DEAD || 
            _target == ZERO
        ) {
            return false;
        } else {
            return true;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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