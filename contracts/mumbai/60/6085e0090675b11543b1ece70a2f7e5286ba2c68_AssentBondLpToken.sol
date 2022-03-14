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

 - add vip system

*/

pragma solidity 0.8.11;

import "./IAssentBondManager.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ErrorReporter.sol";
import "./IOracle.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

interface IAutoStake {
    function deposit(address user, uint256 amount) external; // TODO need test
}

contract AssentBondLpToken is Ownable, ReentrancyGuard, Pausable, ErrorReporter {
    using SafeERC20 for IERC20;

    bool public constant IS_BOND = true;
    
    address public immutable token;
    address public immutable principal;
    address public immutable treasury;
    address public immutable staking;

    address public bondManager;

    IOracle public oracle;

    uint256 constant MULTIPLIER = 1 ether;
    
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
    }

    BondTerms public bondTerms;
    
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 payout);
    event Claim(address indexed user, uint256 payout, bool staked);
    event RatioChanged(uint256 oldThorusPerPrincipal, uint256 newThorusPerPrincipal, uint256 oldRatioPrecision, uint256 newRatioPrecision);
    event AddressChanged(string name, address oldAddress, address newAddress);
    
    constructor ( 
        address _token, // ASNT token address
        address _principal, // Deposit token address
        address _treasury, // Treasury address which receive deposits
        address _staking, // ASNT autocoumpound contract
        address _bondManager,  // BondManager contract which manage ASNT mint for bonds
        uint256 _vestingSeconds, 
        uint256 _minimumPrice
    ) {
        require(_token != address(0) && _principal != address(0) && _treasury != address(0) && _staking != address(0), 'zero address');
        token = _token;
        principal = _principal;
        treasury = _treasury;
        staking = _staking;
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
        uint256 payout;

        (payout,,,,) = payoutFor(amount); // payout to bonder is computed
        //payout = 20000000000000000; // TODO TEST ONLY CLEAN UP NEEDED
            
        require(payout > 0.01 ether, "too small");
        require(getAvailableToPay() >= payout, "sell out");

        if(claimablePayout(msg.sender) > 0) claim(autoStake);

        IERC20(principal).safeTransferFrom(msg.sender, treasury, amount);
        totalPrincipalReceived += amount;

        bool mintSuccess = IAssentBondManager(bondManager).mintRewards( address(this), payout );
        require (mintSuccess == true, "Mint not possible");
        
        userInfo[msg.sender] = UserInfo({
            remainingPayout: userInfo[msg.sender].remainingPayout + payout,
            remainingVestingSeconds: bondTerms.vestingSeconds,
            lastInteractionSecond: block.timestamp
        });

        emit Deposit(msg.sender, amount, payout);
        return payout; 
    }

    function payoutFor( uint256 _principalAmount ) public view returns ( uint256 payout, uint tokenPriceDollar, uint principalPriceDollar, uint256 tokenPriceWithDiscount, uint256 tokenPerPrincipal) {

        uint errorreturn;
        (errorreturn, tokenPriceDollar) = getPriceUSD(token);
        if (errorreturn != uint(Error.NO_ERROR)) {
            return (0,0,0,0,0);
        }

        (errorreturn, principalPriceDollar) = getPriceUSD(principal);
        if (errorreturn != uint(Error.NO_ERROR)) {
            return (0,0,0,0,0);
        }
        
        //TODO need to add a discount from VIP
        tokenPriceWithDiscount = (tokenPriceDollar*(MULTIPLIER-bondTerms.discount))/MULTIPLIER;

        // token price can't be lower than minimum price
        if (tokenPriceWithDiscount < bondTerms.minimumPrice) tokenPriceWithDiscount=bondTerms.minimumPrice;
        tokenPerPrincipal = principalPriceDollar*MULTIPLIER/tokenPriceWithDiscount;
        payout = _principalAmount*tokenPerPrincipal/MULTIPLIER;
        return (payout,tokenPriceDollar,principalPriceDollar,tokenPriceWithDiscount,tokenPerPrincipal);
    }    
    
    function claimablePayout(address user) public view returns (uint256) {
        UserInfo memory info = userInfo[user];
        uint256 secondsSinceLastInteraction = block.timestamp - info.lastInteractionSecond;
        
        if(secondsSinceLastInteraction > info.remainingVestingSeconds)
            return info.remainingPayout;
        return info.remainingPayout * secondsSinceLastInteraction / info.remainingVestingSeconds;
    }
    
    function claim(bool autoStake) nonReentrant public returns (uint256) {        
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
        
        if(autoStake) {
            IERC20(token).approve(staking, payout);
            IAutoStake(staking).deposit(msg.sender, payout);
        } else {
            IERC20(token).safeTransfer(msg.sender, payout);
        }
        
        emit Claim(msg.sender, payout, autoStake);
        return payout;
    }



    /// @notice Returns price for token
    /// @dev Price (USD) is scaled by 1e18
    /// @param _token The address of the token
    /// @return (error code, price of token in USD)
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

    function setOracle(IOracle newOracle) external onlyOwner {
        require(newOracle.IS_ORACLE(), "Controller: oracle address is !contract");
        emit AddressChanged("oracle", address(oracle), address(newOracle));
        oracle = newOracle;
    }

    function setBondTerms(uint _vestingSeconds, uint _minimumPrice, uint _discount) external onlyOwner {
        require(_vestingSeconds > 0, 'zero vesting');
        bondTerms.vestingSeconds = _vestingSeconds;
        require(_minimumPrice != 0, 'min price cant be zero');
        bondTerms.minimumPrice = _minimumPrice;
        bondTerms.discount = _discount;
    }

    // Update bondManager address
    function setBondManagerAddress(address _bondManager) public onlyOwner {
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

}