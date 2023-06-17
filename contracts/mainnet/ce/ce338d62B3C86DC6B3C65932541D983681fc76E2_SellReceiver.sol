/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

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


interface IBurnableToken {
    function burn(uint256 amount) external returns (bool);
}

interface IYieldFarm {
    function depositRewards(uint256 amount) external;
}

interface ISellableToken {
    function sellFor(uint256 amount, address recipient) external returns (bool);
}

contract SellReceiver {

    // STS token
    address public token;

    // Recipients Of Fees
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;

    // Fee receivers
    address public singleStake = 0xc6B2C8783Cb12436FA89253A746c5B92BfF43F6B;
    address public yield1 = 0xaE6324Ae020436be7d652e0e41316aA7483007E4;
    address public yield2 = 0xeE491003C3A3F0D6f69f9469C3ca7d157c27dFcc;
    address public treasury = 0xB81d870BA59B03f1Bec8FDFF28dab09D7fEf7A6b;

    // Fee breakdowns
    uint256 public treasuryPercent = 40;
    uint256 public stakingPercent = 10;
    uint256 public yield1FarmPercent = 20;
    uint256 public yield2FarmPercent = 20;

    // Minimum to trigger
    uint256 public minimumToTrigger = 100_000 * 10**18;

    // Events
    event Trigger();
    event SetMinimumToTrigger(
        uint256 newMin
    );
    event AdminSet(
        address admin,
        bool isAdmin
    );
    event SetFeeReceivers(
        address[] receivers,
        uint256[] fees
    );
    event SetPercentage(
        uint256 treasury_,
        uint256 staking_,
        uint256 yieldFarm1_,
        uint256 yieldFarm2_
    );
    event SetAddresses(
        address treasury_,
        address staking_,
        address yieldFarm1_,
        address yieldFarm2_
    );

    mapping(address => bool) public admins;

    modifier onlyAdmins() {
        require(admins[msg.sender], 'Caller is not an admin');
        _;
    }

    constructor(address token_) {
        // initialize
        token = token_;

        // set admins
        admins[msg.sender] = true;

    }

    function setAdmin(
        address _admin,
        bool _isAdmin
    ) 
    external 
    onlyAdmins 
    {
        admins[_admin] = _isAdmin;
        emit AdminSet(_admin, _isAdmin);
    }


    function trigger() external {
        // STS Balance In Contract
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance < minimumToTrigger) {
            return;
        }

        // fraction out tokens
        uint256 partStaking = balance * stakingPercent / 100;
        uint256 partTreasury = balance * treasuryPercent / 100;
        uint256 partYield1 = balance * yield1FarmPercent / 100;
        uint256 partYield2 = balance * yield2FarmPercent / 100;
        uint256 partBurn = balance - ( partStaking + partTreasury + partYield1 + partYield2 );

        // sell token for matic, sending to treasury
        if (partTreasury > 0) {
            ISellableToken(token).sellFor(partTreasury, treasury);
        }

        // Stake rewards in farms
        if (partYield1 > 0) {
            IERC20(token).approve(yield1, partYield1);
            IYieldFarm(yield1).depositRewards(partYield1);
        }

        if (partYield2 > 0) {
            IERC20(token).approve(yield2, partYield2);
            IYieldFarm(yield2).depositRewards(partYield2);
        }

        if (partStaking > 0) {
            // Stake rewards in staking
            IERC20(token).approve(singleStake, partStaking);
            IYieldFarm(singleStake).depositRewards(partStaking);
        }

        // if any excess, burn it
        if (partBurn > 0) {
            IBurnableToken(token).burn(partBurn);
        }
        
        emit Trigger();
    }

    function setPercentages(
        uint treasury_, 
        uint staking_, 
        uint yieldFarm1_, 
        uint yieldFarm2_
        ) 
        external 
        onlyAdmins 
    {
        require(
            treasury_ + staking_ + yieldFarm1_ + yieldFarm2_ <= 100,
            'Percents Too Large'
        );

        treasuryPercent = treasury_;
        stakingPercent = staking_;
        yield1FarmPercent = yieldFarm1_;
        yield2FarmPercent = yieldFarm2_;

        emit SetPercentage(treasury_, staking_, yieldFarm1_, yieldFarm2_);
    }

    function setAddresses(
        address treasury_,
        address staking_,
        address yieldFarm1_,
        address yieldFarm2_
    ) 
        external 
        onlyAdmins 
    {
        require(goodAddress(treasury_) == true, 'Invalid Address!');
        require(goodAddress(staking_) == true, 'Invalid Address!');
        require(goodAddress(yieldFarm1_) == true, 'Invalid Address!');
        require(goodAddress(yieldFarm2_) == true, 'Invalid Address!');

        treasury = treasury_;
        singleStake = staking_;
        yield1 = yieldFarm1_;
        yield2 = yieldFarm2_;

        emit SetAddresses(address(treasury_), address(staking_), address(yieldFarm1_),  address(yieldFarm2_));
    }

    function setMinimumToTrigger(uint newMin) external onlyAdmins {
        require(newMin > 0, 'Cannot trigger with zero tokens');
        minimumToTrigger = newMin;

        emit SetMinimumToTrigger(newMin);
    }
    
    function withdraw() external onlyAdmins {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    
    function withdraw(address _token) external onlyAdmins {
        require(goodAddress(_token) == true, 'Invalid Address!');
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    receive() external payable {}

    function goodAddress(address _target) internal view returns (bool) {
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