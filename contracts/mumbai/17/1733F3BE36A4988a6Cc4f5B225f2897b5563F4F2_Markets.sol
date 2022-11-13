pragma solidity ^0.8.0;

import "./maths/Maths.sol";
import "./ERC20_contracts/IERC20.sol";
import "./chainlink_contracts/price_feeders/PriceFeeder.sol";
import "./chainlink_contracts/keepers/KeeperCompatibleInterface.sol";


contract Markets is KeeperCompatibleInterface{

    using MathContract for *;

    //player within market representation
    struct Player{
        //the amount of shares owned by the player on each of the outcomes
        uint256[2] sharesOwned;
        //the amount of money waged by the player on each of the outcomes
        uint256[2] moneyWaged;
        //reward recieved by the player when he withdraws after market resolution
        uint256 reward;
        //expert score recieved by the player when he withdraws after market resolution
        uint256 expertScore;
        //flag representing whether the player withdrawed or not
        bool withdrawed;
    }


    // market representation
    struct Market{
        //mapping(address => player) players of the market
        mapping(address => Player) players;
        //total amount of shares owned for each outcome
        uint256[2] sharesOwned;
        //total amount of money waged for each outcome
        uint256[2] moneyWaged;
        //the asset name
        address priceFeedAddress;
        //value to compare the price of the asset with to determine the outcome
        uint256 strikePrice;
        //resolution price
        uint256 resolutionPrice;
        //The last date to wage money on a bet
        uint256 wageDeadline;
        //Resolution date
        uint256 resolutionDate;
        //winning outcome
        uint256 winningOutcome;
        //resolved flag
        bool resolved;
    }

    //multiplier used in computations
    uint256 constant MULTIPLIER = 10 ** 18;
    //the maximum amount of markets that can be resolved within one block
    uint256 constant MAX_MARKETS_UPDATE = 30;
    //maximum amount of markets that can be stored in the contract
    uint256 constant MAX_AMOUNT_MARKETS = 1000;

    //payToken
    IERC20 payToken;
    //price feeder contract
    PriceFeeder priceFeeder;

    //the amount of markets created
    uint256 public numMarkets;

    //mapping to store all the bets. The bet is identified by its betId
    mapping(uint256 => Market) markets;

    constructor(
        address payesTokenAddress,
        address priceFeederAddress
    ) public {
        payToken = IERC20(payesTokenAddress);
        priceFeeder = PriceFeeder(priceFeederAddress);
    }

    //function to create a bet
    function createMarket(
        uint256[2] memory _sharesOwned,
        uint256[2] memory _moneyWaged,
        address _priceFeedAddress,
        uint256 _strikePrice,
        uint256 _resolutionDate,
        uint256 _wageDeadline
    ) external {

        // check the the amount of markets does not exceed the max amount
        require(
            numMarkets < MAX_AMOUNT_MARKETS,
            "the market amount limit reached, redeploy the contract"
        );

        //check that resolution date has not passed
        require(
            block.timestamp < _resolutionDate,
            "resolution date has passed"
        );

        //check that wage deadline date has not passed
        require(
            block.timestamp < _wageDeadline,
            "wage deadline has passed"
        );

        //check that wage deadline date does not exceed the resolution date
        require(
            _wageDeadline <= _resolutionDate,
            "resolution happens after last wage"
        );

        //trasfer amount
        uint256 _transferAmount = _moneyWaged.sumArr();

        //check that person has funds
        require(
            payToken.balanceOf(msg.sender) > _transferAmount,
            "insufficient player funds in pay token"
        );

        //initialize the market
        Market storage market = markets[numMarkets];

        //initialize the player (one who creates a market is the first player)
        {
            Player memory _player;
            _player.sharesOwned = _sharesOwned;
            _player.moneyWaged = _moneyWaged;
            //add player to market players
            market.players[msg.sender] = _player;
        }

        //assign shares owned
        market.sharesOwned = _sharesOwned;
        // assign money waged
        market.moneyWaged = _moneyWaged;
        //assign price feed address
        market.priceFeedAddress = _priceFeedAddress;
        //assign strike price
        market.strikePrice = _strikePrice;
        // assign resolution date
        market.resolutionDate = _resolutionDate;
        // assign wage  deadline
        market.wageDeadline = _wageDeadline;

        // validate the market
        _validateMarket(numMarkets);

        //increment the num markets by 1
        numMarkets += 1;

        // transfer funds
        payToken.transferFrom(
            msg.sender,
            address(this),
            _transferAmount
        );

    }

    //waging money on a market
    function wageMoney(
        uint256 _marketId,
        uint256[2] memory _moneyToWage
    ) external {

        //check that wage deadline is not passed
        require(
            markets[_marketId].wageDeadline > block.timestamp,
            "wage deadline has passed"
        );

        //validate the market
        _validateMarket(_marketId);

        uint256[2] memory _sharesToPurchase;

        //amount of money to be waged for each outcome
        for(uint256 i = 0; i < _sharesToPurchase.length; i++){
            _sharesToPurchase[i] += numSharesForPrice(
                _marketId,
                i,
                _moneyToWage[i]
            );
        }



        //check tha the player has sufficient funds
        require(
            payToken.balanceOf(msg.sender) >= _moneyToWage.sumArr()
        );

        //update moneyWage and sharesOwned both for market and for a player
        for(uint256 i; i <  _sharesToPurchase.length; i++){

            //update the shares owned of each outcome for the market
            markets[_marketId].sharesOwned[i] += _sharesToPurchase[i];
            //update the money waged on each outcome for the market
            markets[_marketId].moneyWaged[i] += _moneyToWage[i];

            //update the shares owned of each outcome for the player within the market
            (
                markets
                [_marketId]
                .players
                [msg.sender]
                .sharesOwned
                [i]
            ) += _sharesToPurchase[i];

            //update the money waged on each outcome for the player within the market
            (
                markets
                [_marketId]
                .players
                [msg.sender]
                .moneyWaged
                [i]
            ) += _moneyToWage[i];

        }

        _validateMarket(_marketId);

        //transfer funds
        payToken.transferFrom(
            msg.sender,
            address(this),
            _moneyToWage.sumArr()
        );

    }

    //withdrawing money from a market
    function withdraw(uint256 _marketId) external {

        //validate the market
        _validateMarket(_marketId);

        //check that the market is resolved
        require(markets[_marketId].resolved);
        /*
            check that the player had not previously
            withdrawed money from this market
        */
        require(!markets[_marketId].players[msg.sender].withdrawed);

        //calculate reward
        uint256 _rewardAmount = _calcReward(_marketId, msg.sender);
        //calculate expert score
        uint256 _expertScore = _calcExpertScore(_marketId, msg.sender);

        //update the player's reward info (within the market)
        (
            markets
            [_marketId]
            .players
            [msg.sender]
            .reward
        ) = _rewardAmount;

        //update the player's expert score info (within the market)
        (
            markets
            [_marketId]
            .players
            [msg.sender]
            .expertScore
        ) = _expertScore;

        //update the player's withdrawed flag (within the market)
        (
            markets
            [_marketId]
            .players
            [msg.sender]
            .withdrawed
        ) = true;

        //reward the player
        payToken.transfer(msg.sender, _rewardAmount);

    }

    //check events for resolution
    function checkUpkeep(bytes calldata checkData) external view override returns (
        bool upkeepNeeded,
        bytes memory performData
    )
    {
        //an array to store markets ids of the markets to be resolved
        uint256[MAX_MARKETS_UPDATE] memory _resolvedMarketIds;


        uint256 _count;

        for(uint256 i; i < numMarkets; i++){
            //check that number of markets to be resolved < MAX_MARKETS_UPDATE
            if(_count >= MAX_MARKETS_UPDATE){
                break;
            }

            if(
                (!markets[i].resolved) &&
                (markets[i].resolutionDate <= block.timestamp)
            ){
                //fill array with id of the market
                _resolvedMarketIds[_count] = i;
                _count += 1;
            }
        }

        //check that upkeep is needed
        if(_count > 0){
            upkeepNeeded = true;
        }
        return (upkeepNeeded, abi.encode(_resolvedMarketIds));
    }

    //update prices
    function performUpkeep(bytes calldata performData) external override {

        //get an array of markets ids for which to query price
        uint256[MAX_MARKETS_UPDATE] memory _resolvedMarketIds = abi.decode(
            performData,
            (uint256[30])
        );

        uint256 _marketId;

        for(uint256 i; i < _resolvedMarketIds.length; i++){
            _marketId = _resolvedMarketIds[i];

            //check that the market is not resolved
            if(
                (!markets[_marketId].resolved) &&
                (markets[_marketId].resolutionDate <= block.timestamp)
            ){

                //get latest price
                markets[_marketId].resolutionPrice = (
                    priceFeeder.getLatestPrice(
                        markets[_marketId].priceFeedAddress
                    )
                );

                //mark the market as resolved
                markets[_marketId].resolved = true;

                //set winning outcome
                markets[_marketId].winningOutcome = _getWinningOutcome(_marketId);
            }
        }
    }

    //get market info
    function getMarketInfo(uint256 _marketId) external view returns(
        address,
        uint256[2] memory,
        uint256[2] memory,
        uint256[2] memory,
        uint256[2] memory,
        bool,
        uint256
    ){
         return(
            markets[_marketId].priceFeedAddress,
            [
                markets[_marketId].strikePrice,
                markets[_marketId].resolutionPrice
            ],
            [
                markets[_marketId].wageDeadline,
                markets[_marketId].resolutionDate
            ],
            markets[_marketId].sharesOwned,
            markets[_marketId].moneyWaged,
            markets[_marketId].resolved,
            markets[_marketId].winningOutcome
        );
    }

    //get player info
    function getPlayerInfo(address _player, uint256 _marketId) external view returns(
        uint256[2] memory,
        uint256[2] memory,
        uint256,
        uint256,
        bool
    ) {
        return (
            markets[_marketId].players[_player].sharesOwned,
            markets[_marketId].players[_player].moneyWaged,
            markets[_marketId].players[_player].reward,
            markets[_marketId].players[_player].expertScore,
            markets[_marketId].players[_player].withdrawed
        );
    }

    //get num markets
    function getNumMarkets() external view returns(uint256){
        return numMarkets;
    }

    //caclulating reward
    function _calcReward(
        uint256 _marketId,
        address _playerAddress
    ) public view returns(uint256){
        //require for market to be resolved;
        require(markets[_marketId].resolved);

        //money waged on each outcome in the market
        uint256[2] memory _moneyWaged = markets[_marketId].moneyWaged;
        //the player
        Player memory _player = markets[_marketId].players[_playerAddress];
        //the winning outcome of the market
        uint256 _winningOutcome = markets[_marketId].winningOutcome;


        //total amount of money waged on losing outcomes
        uint256 _totalLoserMoney = (
            _moneyWaged[1 - _winningOutcome]
        );
        //the amount money waged by the player on the winning outcomes
        uint256 _winOutcomeMoney = (
            _player.moneyWaged[_winningOutcome]
        );
        //total amount of winning shares owned by th player
        uint256 _winSharesOwned = (
            _player.sharesOwned[_winningOutcome]
        );
        //total win shares
        uint256 _totalWinShares = (
            markets[_marketId].sharesOwned[_winningOutcome]
        );
        //denominator > 0
        require( _winSharesOwned > 0);

        return (
            (
                _winSharesOwned * _totalLoserMoney +
                _totalWinShares * _winOutcomeMoney
            ) /
            _totalWinShares
        );
    }

    //caclulating expert score
    function _calcExpertScore(
        uint256 _marketId,
        address _playerAddress
    ) public view returns(uint256){

        //require for market to be resolved;
        require(markets[_marketId].resolved);

        //money waged on each outcome in the market
        uint256[2] memory _moneyWaged = markets[_marketId].moneyWaged;

        //shares owned of each outcome for the market
        uint256[2] memory _sharesOwned = markets[_marketId].sharesOwned;

        //the player
        Player memory _player = markets[_marketId].players[_playerAddress];

        //the winning outcome of the market
        uint256 _winningOutcome = markets[_marketId].winningOutcome;

        //total amount of shares owned by the player
        uint256 _totalSharesPlayer = (
            _player.sharesOwned.sumArr()
        );

        //total amount of winning outcome shares owned by the player
        uint256 _totalWinSharesPlayer = (
            _player.sharesOwned[_winningOutcome]
        );

        //total amount of winning outcome shares
        uint256 _totalWinShares = (
            _sharesOwned[_winningOutcome]
        );

        //total amount of losing outcomes shares
        uint256 _totalLosingShares = (
            _sharesOwned[1 - _winningOutcome]
        );

        //total amount of shares owned
        uint256 _totalShares = (
            _totalWinShares + _totalLosingShares
        );

        //total amount of money waged on a market
        uint256  _totalMoneyWaged = (
            _moneyWaged.sumArr()
        );

        return (
            (
                (_totalMoneyWaged * _totalWinSharesPlayer) /
                (_totalWinShares + _totalSharesPlayer)
            ) *
            (2 * _totalLosingShares) /
            _totalShares
        );
    }

    //calculating price of buying n shares of outcome i
    function numSharesForPrice(
        uint256 _marketId,
        uint256 _outcome,
        uint256 _moneyToWage
    ) public view returns(uint256){

        //amount of money waged on the outcome to be bought
        uint256 _moneyOutcome = (
            markets
            [_marketId]
            .moneyWaged
            [_outcome]
        );

        //the amount of money waged on the opposite outcome
        uint256 _sharesOppositeOutcome = (
            markets
            [_marketId]
            .sharesOwned
            [1 - _outcome]
        );

        //ln(1 + m1 / M1) * N2
        //ln((M1 + m1) * ONE / M1) * N2 / ONE
        return (
            (
                (
                    MathContract.one() *
                    (_moneyOutcome + _moneyToWage) /
                    _moneyOutcome
                ).ln()
            ) *
            _sharesOppositeOutcome /
            MathContract.one()
        );
    }

    //getting winning outcome based on the price
    function _getWinningOutcome(
        uint256 _marketId
    ) internal view returns(uint256) {

        //get resolution price
        uint256 _resolutionPrice = markets[_marketId].resolutionPrice;
        //get strike price
        uint256 _strikePrice = markets[_marketId].strikePrice;

        //compare them to one another
        if(_resolutionPrice >= _strikePrice){
            return 1;
        } else {
            return 0;
        }
    }

    //validating the market
    function _validateMarket(
        uint256 _marketId
    ) internal view{
        //validating money waged
        {
            uint256[2] memory _moneyWaged = markets[_marketId].moneyWaged;
            for(uint256 i = 0; i < _moneyWaged.length; i++){
                require(
                    _moneyWaged[i] > 0,
                    "money waged can't be 0"
                );
            }
        }

        //validating shares Owned
        {
            uint256[2] memory _sharesOwned = markets[_marketId].sharesOwned;
            for(uint256 i = 0; i < _sharesOwned.length; i++){
                require(
                    _sharesOwned[i] > 0,
                    "shares owned can't be 0"
                );
            }
        }
    }

}

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

pragma solidity ^0.8.0;

library MathContract{

    uint256 public constant ONE = 10000000000;
    uint256 public constant LOG2_E = 14426950409;


    function sumArr(uint256[2] memory nums) external pure returns(uint256){
        uint256 _sum = 0;
        for(uint8 i; i < nums.length; i++){
            _sum += nums[i];
        }
        return _sum;
    }

    function one() external pure returns(uint256){
        return ONE;
    }

    function ln(uint256 x) public pure returns (uint) {
        require(x > 0);
        uint256 ilog2 = floorLog2(x);
        uint256 z = (x >> ilog2);
        uint256 term = (z - ONE) * ONE / (z + ONE);
        uint256 halflnz = term;
        uint256 termpow = term * term / ONE * term / ONE;
        halflnz += termpow / 3;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 5;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 7;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 9;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 11;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 13;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 15;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 17;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 19;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 21;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 23;
        termpow = termpow * term / ONE * term / ONE;
        halflnz += termpow / 25;
        return (ilog2 * ONE) * ONE / LOG2_E + 2 * halflnz;
    }

    function floorLog2(uint256 x) public pure returns (uint256) {
        x /= ONE;
        uint256 n;
        if (x >= 2**128) { x >>= 128; n += 128;}
        if (x >= 2**64) { x >>= 64; n += 64;}
        if (x >= 2**32) { x >>= 32; n += 32;}
        if (x >= 2**16) { x >>= 16; n += 16;}
        if (x >= 2**8) { x >>= 8; n += 8;}
        if (x >= 2**4) { x >>= 4; n += 4;}
        if (x >= 2**2) { x >>= 2; n += 2;}
        if (x >= 2**1) { x >>= 1; n += 1;}
        return n;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be!
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

pragma solidity ^0.8.0;
import "./AggregatorV3Interface.sol";

contract PriceFeeder {
    uint256 constant DENOMINATION = 10000000000;

    function getLatestPrice(address pairAddress) public view returns (uint256) {
         AggregatorV3Interface priceFeed = AggregatorV3Interface(pairAddress);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price) * DENOMINATION;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}