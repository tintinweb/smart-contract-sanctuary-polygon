/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getNFM() external pure returns (address);

    function _getNFMStaking() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external pure returns (address);

    function _getNFMStakingTreasuryETH() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMSTAKINGRESERVEERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmStakingReserveERC20 {
    function _updateStake() external returns (bool);

    function _returnDayCounter() external view returns (uint256);

    function _returnNextUpdateTime() external view returns (uint256);

    function _returnCurrenciesArrayLength() external view returns (uint256);

    function _returnCurrencies()
        external
        view
        returns (address[] memory CurrenciesArray);

    function _returnTotalAmountPerDayForRewards(address Coin, uint256 Day)
        external
        view
        returns (uint256);

    function _returnDailyRewardPer1NFM(address Coin, uint256 Day)
        external
        view
        returns (uint256);

    function _realizePayments(
        address Coin,
        uint256 Amount,
        address Staker
    ) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMStaking.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract holds all deposits of the investors and manages them as well as the interest calculations to be generated from them
/// @dev This contract holds all deposits of the investors and manages them as well as the interest calculations to be generated from them
///
///
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMStaking {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INfmController private _Controller;
    address private _Owner;
    address private _SController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    TotalDepositsOnStake        =>  total investments
    generalIndex                =>  Unique Index
    CurrenciesReserveArray      =>  Array includes all allowed currencies
    Staker                      =>  Tuple containing all information about a user and his investment
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public TotalDepositsOnStake;
    uint256 public generalIndex;
    address[] public CurrenciesReserveArray;
    uint256 private _locked = 0;
    //Struct for each deposit
    struct Staker {
        uint256 index;
        uint256 startday;
        uint256 inicialtimestamp;
        uint256 deposittimeDays;
        uint256 amountNFMStaked;
        address ofStaker;
        bool claimed;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    StakerInfo(UniqueIndex => Tuple Staker)        =>  //GIndex => Staker
    DepositsOfStaker(Staker address => UniqueIndexes)        =>  //Address Staker => Array GIndexes by Staker
    TotalStakedPerDay(DayIndex => Totaldeposits)        =>  //Day => TotalDeposits
    ClaimingConfirmation(UniqueIndex => (Staker address => 0=false 1=true))        =>  //GIndex => Coin address => 1 if paid
    RewardsToWithdraw(UniqueIndex => Array Amounts)        =>  //Gindex => Array of Claimed Rewards
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(uint256 => Staker) public StakerInfo;    
    mapping(address => uint256[]) public DepositsOfStaker;    
    mapping(uint256 => uint256) public TotalStakedPerDay;    
    mapping(uint256 => mapping(address => uint256)) public ClaimingConfirmation;    
    mapping(uint256 => uint256[]) public RewardsToWithdraw;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /* 
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    reentrancyGuard       => secures the protocol against reentrancy attacks
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
        generalIndex = 0;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_updateCurrenciesList() returns (bool);
        This function checks the currencies in the NFMStakingReserveERC20. If the array in the NFMStakingReserveERC20 is longer, then update array
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateCurrenciesList() internal onlyOwner returns (bool) {
        if (
            CurrenciesReserveArray.length <
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnCurrenciesArrayLength()
        ) {
            CurrenciesReserveArray = INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnCurrencies();
        }
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnTotalDepositsOnStake() returns (uint256);
        This function returns the total amount of all deposits
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnTotalDepositsOnStake() public view returns (uint256) {
        return TotalDepositsOnStake;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returngeneralIndex() returns (uint256);
        This function returns the unique Index
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returngeneralIndex() public view returns (uint256) {
        return generalIndex;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnStakerInfo(uint256) returns (struct Staker);
        This function returns the complete information of a specific deposit
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnStakerInfo(uint256 Gindex)
        public
        view
        returns (Staker memory)
    {
        return StakerInfo[Gindex];
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnDepositsOfDay(uint256) returns (uint256);
        This function returns all deposits of a specific day
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnDepositsOfDay(uint256 Day) public view returns (uint256) {
        return TotalStakedPerDay[Day];
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnDepositsOfStaker() returns (uint256[]);
        This function returns all deposits from a specific investor
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnDepositsOfStaker() public view returns (uint256[] memory) {
        return DepositsOfStaker[msg.sender];
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnClaimingConfirmation(address, uint256) returns (uint256);
        This function returns a numeric boolean whether the withdrawal has occurred
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnClaimingConfirmation(address Coin, uint256 Gindex)
        public
        view
        returns (uint256)
    {
        return ClaimingConfirmation[Gindex][Coin];
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_setDepositOnDailyMap(uint256,uint256,uint256) returns (bool);
        This function saves the deposit in the appropriate times for calculation.
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _setDepositOnDailyMap(
        uint256 Amount,
        uint256 Startday,
        uint256 Period
    ) internal onlyOwner returns (bool) {
        for (uint256 i = Startday; i < (Startday + Period); i++) {
            TotalStakedPerDay[i] += Amount;
        }
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_calculateRewardPerDeposit(address, uint256, uint256) returns (uint256);
        This function calculates interest on a specific day for a specific deposit.
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _calculateRewardPerDeposit(
        address Coin,
        uint256 RewardAmount,
        uint256 DepositAmount
    ) public view returns (uint256) {
        uint256 CoinDecimal = IERC20(address(Coin)).decimals();
        if (CoinDecimal < 18) {
            return
                SafeMath.div(
                    SafeMath.div(
                        SafeMath.mul(
                            (RewardAmount * 10**(18 - CoinDecimal)),
                            DepositAmount
                        ),
                        10**18
                    ),
                    (10**(18 - CoinDecimal))
                );
        } else {
            return
                SafeMath.div(SafeMath.mul(RewardAmount, DepositAmount), 10**18);
        }
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_calculateEarnings(address, uint256, uint256, uint256) returns (uint256);
        This function calculates the total interest on a specific day for a specific period on a deposit.
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _calculateEarnings(
        address Coin,
        uint256 StakedAmount,
        uint256 StartDay,
        uint256 Period
    ) public view returns (uint256) {
        uint256 Earned;
        for (uint256 i = StartDay; i < (StartDay + Period); i++) {
            Earned += _calculateRewardPerDeposit(
                Coin,
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._returnDailyRewardPer1NFM(Coin, i),
                StakedAmount
            );
        }
        return Earned;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_deposit(uint256, uint256) returns (bool);
        This function invests an amount X of NFM in this contract. The NFM must be released beforehand to the contract by means of approval
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _deposit(uint256 Amount, uint256 Period) public returns (bool) {
        if (
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnNextUpdateTime() < block.timestamp
        ) {
            require(
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._updateStake() == true,
                "NU"
            );
        }
        _updateCurrenciesList();
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                address(this),
                Amount
            ) == true,
            "<A"
        );
        require(
            _setDepositOnDailyMap(
                Amount,
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._returnDayCounter(),
                Period
            ) == true,
            "NDD"
        );
        StakerInfo[generalIndex] = Staker(
            generalIndex,
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnDayCounter(),
            block.timestamp,
            Period,
            Amount,
            msg.sender,
            false
        );
        TotalDepositsOnStake += Amount;
        DepositsOfStaker[msg.sender].push(generalIndex);
        generalIndex++;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_claimRewards(uint256) returns (bool);
        This function is responsible for claiming the interest
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _claimRewards(uint256 Index) public reentrancyGuard returns (bool) {
        if (
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnNextUpdateTime() < block.timestamp
        ) {
            require(
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._updateStake() == true,
                "NU"
            );
        }
        _updateCurrenciesList();
        require(StakerInfo[Index].ofStaker == msg.sender, "oO");
        require(
            StakerInfo[Index].inicialtimestamp +
                (300 * StakerInfo[Index].deposittimeDays) <
                block.timestamp,
            "CNT"
        );
        require(StakerInfo[Index].claimed == false, "AC");
        for (uint256 i = 0; i < CurrenciesReserveArray.length; i++) {
            RewardsToWithdraw[Index].push(
                _calculateEarnings(
                    CurrenciesReserveArray[i],
                    StakerInfo[Index].amountNFMStaked,
                    StakerInfo[Index].startday,
                    StakerInfo[Index].deposittimeDays
                )
            );
        }
        StakerInfo[Index].claimed = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_withdrawDepositAndRewards(uint256) returns (bool);
        This function is responsible for the payment and withdrawal of interest and deposit
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _withdrawDepositAndRewards(uint256 Index) public reentrancyGuard returns (bool) {
        require(ClaimingConfirmation[Index][_Controller._getNFM()] == 0, "AW");
        require(
            StakerInfo[Index].inicialtimestamp +
                (300 * StakerInfo[Index].deposittimeDays) <
                block.timestamp,
            "CNT"
        );
        require(StakerInfo[Index].claimed == true, "AC");
        require(StakerInfo[Index].ofStaker == msg.sender, "oO");
        for (uint256 i = 0; i < RewardsToWithdraw[Index].length; i++) {
            require(
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._realizePayments(
                        CurrenciesReserveArray[i],
                        RewardsToWithdraw[Index][i],
                        msg.sender
                    ) == true,
                "NP"
            );
            ClaimingConfirmation[Index][CurrenciesReserveArray[i]] = 1;
        }
        require(
            IERC20(address(_Controller._getNFM())).transfer(
                msg.sender,
                StakerInfo[Index].amountNFMStaked
            ) == true,
            "NDP"
        );
        TotalDepositsOnStake -= StakerInfo[Index].amountNFMStaked;
        return true;
    }
}