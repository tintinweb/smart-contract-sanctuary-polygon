//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

// SPDX-License-Identifier: MIT

/*

 TODO

 - NEED TEST : add vip system
 - NEED TEST : add the possibility to retreive any tokens expect ASNT & Principal
 - NEED TEST : update stacking contract addresse
 - NEED TEST : allow working without stacking contract
 - NEED TEST : add a max amount to buy per "user" or "tx", better "user"
 - STANDBY : save previous Oracle returns in this contract and set a max difference possible

*/

pragma solidity 0.8.11;

import "./IAssentBondManager.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ErrorReporter.sol";
import "./IOracle.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IAssentVIP.sol";

interface IAutoStake {
    function deposit(address user, uint256 amount) external;
}

contract AssentBondLpToken is Ownable, ReentrancyGuard, Pausable, ErrorReporter {
    using SafeERC20 for IERC20;

    bool public constant IS_BOND = true;
    
    address public immutable token;
    address public immutable principal;
    address public immutable treasury;
    address public stacking; // ASNT or partner autocoumpound contract (if available)

    address public bondManager;

    IOracle public oracle;

	// Assent VIP fee reduction contract
	IAssentVIP public vip;

    uint256 constant MULTIPLIER = 1 ether;
    uint constant MAXFEEREDUCTION = 0.8 ether; // 80% 
    
    uint256 public totalPrincipalReceived;
    
    struct UserInfo {
        uint256 remainingPayout;
        uint256 remainingVestingSeconds;
        uint256 lastInteractionSecond;
    }

    struct BondTerms {
        uint vestingSeconds; // in seconds
        uint minimumPrice; // 18 decimals in dollars
        uint discount; // discount on market price in percent (18 decimals)
        uint maxPayoutPerUser; // maximum payout in token amount per user (18 decimals)
    }

    BondTerms public bondTerms;
    
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 payout);
    event Claim(address indexed user, uint256 payout, bool staked);
    event AddressChanged(string name, address oldAddress, address newAddress);
    event VIPUpdated(IAssentVIP indexed previousAddress, IAssentVIP indexed newAddress);
    
    constructor ( 
        address _token, // ASNT or partner token address
        address _principal, // Deposit token address
        address _treasury, // Treasury address which receive deposits
        address _bondManager,  // BondManager contract which manage ASNT mint or partner token distribution for bonds
        uint256 _vestingSeconds, 
        uint256 _minimumPrice
    ) {
        require(_token != address(0) && _principal != address(0) && _treasury != address(0), 'zero address');
        token = _token;
        principal = _principal;
        treasury = _treasury;
        bondManager = _bondManager;
        require(_vestingSeconds > 0, 'zero vesting');
        bondTerms.vestingSeconds = _vestingSeconds;
        require(_minimumPrice != 0, 'min price cant be zero');
        bondTerms.minimumPrice = _minimumPrice;
        _pause(); //Paused at deployment
    }

    function getAvailableToPay() view public returns (uint256 availableToPay) {
        availableToPay = IAssentBondManager(bondManager).getMaxRewardsAvailableForBonds();
        return availableToPay;
    }
    
    function deposit(uint256 amount, bool autoStake) whenNotPaused nonReentrant external returns (uint256) {
        UserInfo memory info = userInfo[msg.sender];
        uint256 payout;

        (payout,,,,,) = payoutFor(amount,msg.sender); // payout to bonder is computed
            
        require(payout > 0.01 ether, "too small");
        require(getAvailableToPay() >= payout, "sell out");
        require(info.remainingPayout+payout < bondTerms.maxPayoutPerUser, "max payout for user reached");

        if(claimablePayout(msg.sender) > 0) _claim(autoStake);

        IERC20(principal).safeTransferFrom(msg.sender, treasury, amount);
        totalPrincipalReceived += amount;

        bool distributeSuccess = IAssentBondManager(bondManager).distributeRewards( address(this), payout );
        require (distributeSuccess == true, "Distribute not possible");
        
        userInfo[msg.sender] = UserInfo({
            remainingPayout: userInfo[msg.sender].remainingPayout + payout,
            remainingVestingSeconds: bondTerms.vestingSeconds,
            lastInteractionSecond: block.timestamp
        });

        emit Deposit(msg.sender, amount, payout);
        return payout; 
    }

    function payoutFor( uint256 _principalAmount, address _user) public view returns ( uint256 payout, uint tokenPriceDollar, uint principalPriceDollar, uint256 tokenPriceWithDiscount, uint256 tokenPriceWithVIPDiscount, uint256 tokenPerPrincipal) {

        uint errorreturn;
        (errorreturn, tokenPriceDollar) = getPriceUSD(token);
        if (errorreturn != uint(Error.NO_ERROR)) {
            return (0,0,0,0,0,0);
        }

        (errorreturn, principalPriceDollar) = getPriceUSD(principal);
        if (errorreturn != uint(Error.NO_ERROR)) {
            return (0,0,0,0,0,0);
        }

        // apply discount
        tokenPriceWithDiscount = (tokenPriceDollar*(MULTIPLIER-bondTerms.discount))/MULTIPLIER;

        // apply extra discount from VIP system (if set)
        uint userFeeReduction = getBondFeeReduction(_user);
        require (userFeeReduction <= MAXFEEREDUCTION, "Fee reduction too high");
        tokenPriceWithVIPDiscount = tokenPriceWithDiscount*(MULTIPLIER-userFeeReduction)/MULTIPLIER;        

        // token price can't be lower than minimum price
        if (tokenPriceWithVIPDiscount < bondTerms.minimumPrice) {
            tokenPriceWithDiscount=bondTerms.minimumPrice;
            tokenPriceWithVIPDiscount=bondTerms.minimumPrice;
        }
        tokenPerPrincipal = principalPriceDollar*MULTIPLIER/tokenPriceWithVIPDiscount;
        uint256 principalAmount18dec = _principalAmount * 10**(18 - IERC20(principal).decimals());
        payout = principalAmount18dec*tokenPerPrincipal/MULTIPLIER;
        return (payout,tokenPriceDollar,principalPriceDollar,tokenPriceWithDiscount,tokenPriceWithVIPDiscount,tokenPerPrincipal);
    }    
    
    function claimablePayout(address user) public view returns (uint256) {
        UserInfo memory info = userInfo[user];
        uint256 secondsSinceLastInteraction = block.timestamp - info.lastInteractionSecond;
        
        if(secondsSinceLastInteraction > info.remainingVestingSeconds)
            return info.remainingPayout;
        return info.remainingPayout * secondsSinceLastInteraction / info.remainingVestingSeconds;
    }
    
    function claim(bool autoStake) nonReentrant external {        
        _claim (autoStake);
    }

    function _claim(bool autoStake) internal {        
        UserInfo memory info = userInfo[msg.sender];
        uint256 secondsSinceLastInteraction = block.timestamp - info.lastInteractionSecond;
        uint256 payout;
       
        if(secondsSinceLastInteraction >= info.remainingVestingSeconds) {
            payout = info.remainingPayout;
            delete userInfo[msg.sender];
        } else {  
            payout = info.remainingPayout * secondsSinceLastInteraction / info.remainingVestingSeconds;
            userInfo[msg.sender] = UserInfo({
                remainingPayout: info.remainingPayout - payout,
                remainingVestingSeconds: info.remainingVestingSeconds - secondsSinceLastInteraction,
                lastInteractionSecond: block.timestamp
            });
        }
        
        if(autoStake && payout > 0) {
            require (stacking != address(0), "stacking must be != 0");
            IERC20(token).approve(stacking, payout);
            IAutoStake(stacking).deposit(msg.sender, payout);
        } else {
            IERC20(token).safeTransfer(msg.sender, payout);
        }
        
        emit Claim(msg.sender, payout, autoStake);
    }

    function getPriceUSD(address _token) public view returns (uint, uint) {
        if (address(oracle) == address(0)) {
            return (uint(Error.INVALID_ORACLE_ADDRESS), 0);
        }

        if (_token == address(0)) {
            return (uint(Error.INVALID_TOKEN_TO_GET_PRICE), 0);
        }

        try oracle.getPriceUSD(_token) returns (uint price) {
            if (price == 0) {
                return (uint(Error.INVALID_ORACLE_PRICE), 0);
            }
            return (uint(Error.NO_ERROR), price);
        } catch {
            return (uint(Error.INVALID_ORACLE_CALL), 0);
        }
    }

    // Get fee reduction from vip contract
    function getBondFeeReduction(address _user) public view returns(uint _bondFeeReduction) {
        if (address(vip) != address(0)) {
            return vip.getBondsReduction(_user);
        }
        else {
            return 0;
        }        
    }

    function setOracle(IOracle newOracle) external onlyOwner {
        require(newOracle.IS_ORACLE(), "Controller: oracle address is !contract");
        emit AddressChanged("oracle", address(oracle), address(newOracle));
        oracle = newOracle;
    }

    function setStacking(address newStacking) external onlyOwner {
        emit AddressChanged("staking", address(stacking), address(newStacking));
        stacking = newStacking;
    }

    function setBondTerms(uint _vestingSeconds, uint _minimumPrice, uint _discount, uint _maxPayoutPerUser) external onlyOwner {
        require(_vestingSeconds > 0, 'zero vesting');
        bondTerms.vestingSeconds = _vestingSeconds;
        require(_minimumPrice != 0, 'min price cant be zero');
        bondTerms.minimumPrice = _minimumPrice;
        bondTerms.discount = _discount;
        require(_maxPayoutPerUser != 0, 'max payout per user cant be zero');
        bondTerms.maxPayoutPerUser = _maxPayoutPerUser;
    }

    function setBondManagerAddress(address _bondManager) external onlyOwner {
        require(_bondManager != address(0), "setBondTreasuryAddress: ZERO");
        emit AddressChanged("bondManager", bondManager, _bondManager);
        bondManager = _bondManager;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function rescueTokens(IERC20 _token, uint256 value) external onlyOwner {
        require (address(_token) != token, "can't get reserved token for bonds");
        _token.transfer(msg.sender, value);
    }

    function setVIP(IAssentVIP _vip) external onlyOwner {
        require (_vip.isVIP(), "Not a vip contract");
        require (_vip.getFarmsDepFeeReduction(address(this)) == 0, "getFarmsDepFeeReduction wrong answer");
        emit VIPUpdated(vip, _vip);
        vip = _vip;
    }

}