/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

//SPDX-License-Identifier:MIT

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
// INFMSTAKING
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmStaking {
    function _returnDepositsOfDay(uint256 Day) external view returns (uint256);
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
/// @notice This contract holds the entire ERC-20 Reserves of the NFM Staking Pool. This contract regulates the
///         interest to be generated from the investments in the NFM Staking Contract
/// @dev This contract holds the entire ERC-20 Reserves of the NFM Staking Pool. This contract regulates the
///      interest to be generated from the investments in the NFM Staking Contract
///
///
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMStakeReserveERC20 {
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
    DayCounter          =>  total investments
    Time24Hours         =>  24 Hours imestamp value
    NextUpdateTime      =>  Next timestamp to update balances
    Currencies          =>  Array of all allowed Currencies
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public DayCounter = 0;
    uint256 public Time24Hours = 86400;
    uint256 public NextUpdateTime;
    address[] public Currencies;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    TotalAmountPerDayForRewards(address => (uint256 => uint256)          =>  //Coin => DayCounter => Total Amount per Day for rewards.
    DailyRewardPer1NFM(address => (uint256 => uint256)                   =>  //Coin => DayCounter => Amount per Day for 1 NFM.
    TotalRewardSupply(address => uint256)                                =>  //Coin => TotalAmount of Rewards all Time - Payouts
    TotalRewardsPaid(address => uint256)                                 =>  //Coin => Total of Rewards paid
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => mapping(uint256 => uint256))
        public TotalAmountPerDayForRewards;
    mapping(address => mapping(uint256 => uint256)) public DailyRewardPer1NFM;
    mapping(address => uint256) public TotalRewardSupply;
    mapping(address => uint256) public TotalRewardsPaid;
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

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
        NextUpdateTime = block.timestamp + 86400;
        Currencies.push(Cont._getNFM());
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_addCurrencies(address) returns (bool);
        This function adds new currencies to the array
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addCurrencies(address Coin) public onlyOwner returns (bool) {
        Currencies.push(Coin);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnBalanceContract(address) returns (uint256);
        This function returns the contract balance
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnBalanceContract(address Currency)
        public
        view
        returns (uint256)
    {
        return IERC20(address(Currency)).balanceOf(address(this));
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnDayCounter() returns (uint256);
        This function returns the actual Day
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnDayCounter() public view returns (uint256) {
        return DayCounter;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnNextUpdateTime() returns (uint256);
        This function returns the next update timestamp
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnNextUpdateTime() public view returns (uint256) {
        return NextUpdateTime;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnCurrencies() returns (address[]);
        This function returns an Array of all allowed currencies
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnCurrencies()
        public
        view
        returns (address[] memory CurrenciesArray)
    {
        return Currencies;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnCurrenciesArrayLength() returns (uint256);
        This function returns the length of the Array of all allowed currencies
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnCurrenciesArrayLength() public view returns (uint256) {
        return Currencies.length;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnTotalAmountPerDayForRewards(address, uint256) returns (uint256);
        This function returns the daily total amount of reward
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnTotalAmountPerDayForRewards(address Coin, uint256 Day)
        public
        view
        returns (uint256)
    {
        return TotalAmountPerDayForRewards[Coin][Day];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnDailyRewardPer1NFM(address, uint256) returns (uint256);
        This function returns the daily amount of reward for 1 NFM
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnDailyRewardPer1NFM(address Coin, uint256 Day)
        public
        view
        returns (uint256)
    {
        return DailyRewardPer1NFM[Coin][Day];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnDailyRewardPer1NFM(address, uint256) returns (uint256);
        This function returns the daily amount of reward for 1 NFM
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnSecondRewardPer1NFM(address Coin, uint256 Day)
        public
        view
        returns (uint256)
    {
        return SafeMath.div(DailyRewardPer1NFM[Coin][Day], 86400);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnTotalRewardSupply(address) returns (uint256);
        This function returns the total monitored Reward balance
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnTotalRewardSupply(address Coin)
        public
        view
        returns (uint256)
    {
        return TotalRewardSupply[Coin];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_returnTotalRewardsPaid(address) returns (uint256);
        This function returns the total Rewards paid
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnTotalRewardsPaid(address Coin)
        public
        view
        returns (uint256)
    {
        return TotalRewardsPaid[Coin];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_remainingFromDayAgoRewards(address, uint256) returns (uint256);
        This function returns the total remaining rewards from a day ago
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _remainingFromDayAgoRewards(address Currency, uint256 Day)
        public
        view
        returns (uint256)
    {
        uint256 CoinDecimal = IERC20(address(Currency)).decimals();
        if (CoinDecimal < 18) {
            return
                SafeMath.sub(
                    TotalAmountPerDayForRewards[Currency][Day],
                    SafeMath.div(
                        SafeMath.div(
                            SafeMath.mul(
                                INfmStaking(_Controller._getNFMStaking())
                                    ._returnDepositsOfDay(Day),
                                (DailyRewardPer1NFM[Currency][Day] *
                                    10**(18 - CoinDecimal))
                            ),
                            10**18
                        ),
                        (10**(18 - CoinDecimal))
                    )
                );
        } else {
            return
                SafeMath.sub(
                    TotalAmountPerDayForRewards[Currency][Day],
                    SafeMath.div(
                        SafeMath.mul(
                            INfmStaking(_Controller._getNFMStaking())
                                ._returnDepositsOfDay(Day),
                            DailyRewardPer1NFM[Currency][Day]
                        ),
                        10**18
                    )
                );
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_calculateRewardPerNFM(address, uint256) returns (uint256);
        This function calculates the rewards per 1 NFM
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _calculateRewardPerNFM(address Currency, uint256 Day)
        public
        view
        returns (uint256)
    {
        uint256 CoinDecimal = IERC20(address(Currency)).decimals();
        if (CoinDecimal < 18) {
            //Totalamountperdayforrewards divided by totalssupply of NFM Contract
            return
                SafeMath.div(
                    SafeMath.div(
                        (
                            (TotalAmountPerDayForRewards[Currency][Day] *
                                10**(18 - CoinDecimal) *
                                10**18)
                        ),
                        IERC20(address(_Controller._getNFM())).totalSupply()
                    ),
                    (10**(18 - CoinDecimal))
                );
        } else {
            return
                SafeMath.div(
                    (TotalAmountPerDayForRewards[Currency][Day] * 10**18),
                    IERC20(address(_Controller._getNFM())).totalSupply()
                );
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_updateStake() returns (bool);
        This function updates all important balances for the necessary calculations
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateStake() public onlyOwner returns (bool) {
        require(NextUpdateTime < block.timestamp, "NT");
        if (NextUpdateTime < block.timestamp) {
            DayCounter++;
            NextUpdateTime = NextUpdateTime + Time24Hours;
        }
        for (uint256 i = 0; i < Currencies.length; i++) {
            TotalAmountPerDayForRewards[Currencies[i]][DayCounter] =
                (_returnBalanceContract(Currencies[i]) -
                    TotalRewardSupply[Currencies[i]]) +
                _remainingFromDayAgoRewards(Currencies[i], DayCounter - 1);
            TotalRewardSupply[Currencies[i]] = _returnBalanceContract(
                Currencies[i]
            );
            DailyRewardPer1NFM[Currencies[i]][
                DayCounter
            ] = _calculateRewardPerNFM(Currencies[i], DayCounter);
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
        @_realizePayments(address, uint256, address) returns (bool);
        This function executes the payouts
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _realizePayments(
        address Coin,
        uint256 Amount,
        address Staker
    ) public onlyOwner returns (bool) {
        require(msg.sender != address(0), "0A");
        require(Staker != address(0), "0A");
        if (Amount > 0) {
            if (IERC20(address(Coin)).transfer(Staker, Amount) == true) {
                TotalRewardSupply[Coin] -= Amount;
                TotalRewardsPaid[Coin] += Amount;
            }
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getWithdraw(address Coin,address To,uint256 amount,bool percent) returns (bool);
    This function is used by Vault Contracts.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getWithdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) public onlyOwner returns (bool) {
        require(To != address(0), "0A");
        uint256 CoinAmount = IERC20(address(Coin)).balanceOf(address(this));
        if (percent == true) {
            //makeCalcs on Percentatge
            uint256 AmountToSend = SafeMath.div(
                SafeMath.mul(CoinAmount, amount),
                100
            );
            TotalRewardSupply[Coin] -= AmountToSend;
            IERC20(address(Coin)).transfer(To, AmountToSend);
            return true;
        } else {
            if (amount == 0) {
                TotalRewardSupply[Coin] -= CoinAmount;
                IERC20(address(Coin)).transfer(To, CoinAmount);
            } else {
                TotalRewardSupply[Coin] -= amount;
                IERC20(address(Coin)).transfer(To, amount);
            }
            return true;
        }
    }
}