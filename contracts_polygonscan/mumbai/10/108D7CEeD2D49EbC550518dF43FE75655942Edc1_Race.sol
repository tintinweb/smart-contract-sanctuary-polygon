/**
 *Submitted for verification at polygonscan.com on 2022-02-05
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/Race.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



contract Race is Ownable{
    uint maxRacersCount;
    uint currentRacersCount;
    uint entryFeeWei;
    uint entryFeeMatic;
    bool raceEnded = false;
    AggregatorV3Interface internal btcFeed;
    AggregatorV3Interface internal ethFeed;
    AggregatorV3Interface internal usdtFeed;
    AggregatorV3Interface internal bnbFeed;
    AggregatorV3Interface internal adaFeed;
    AggregatorV3Interface internal solFeed;
    AggregatorV3Interface internal xrpFeed;
    AggregatorV3Interface internal lunaFeed;
    AggregatorV3Interface internal dogeFeed;
    AggregatorV3Interface internal dotFeed;
    struct Racer{
        string uname;
        address addr;
        int256 score;
        int256[] tokenPrices;
    }
    Racer[] public racers;
    int256[10] public initialPrices;
    int256[10] public finalPrices;
    int256[10] public deltaPrices;
    event NewRacer(string uname, address addr, uint position);
    event RaceBegan();
    
    constructor(){
        //initialize the price feeds
        btcFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        ethFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        usdtFeed = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
        bnbFeed = AggregatorV3Interface(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
        adaFeed = AggregatorV3Interface(0xAE48c91dF1fE419994FFDa27da09D5aC69c30f55);
        solFeed = AggregatorV3Interface(0x4ffC43a60e009B551865A93d232E33Fce9f01507);
        xrpFeed = AggregatorV3Interface(0xCed2660c6Dd1Ffd856A5A82C67f3482d88C50b12);
        lunaFeed = AggregatorV3Interface(0x91E9331556ED76C9393055719986409e11b56f73);
        dogeFeed = AggregatorV3Interface(0x2465CefD3b488BE410b941b1d4b2767088e2A028);
        dotFeed = AggregatorV3Interface(0x1C07AFb8E2B827c5A4739C6d59Ae3A5035f28734);
        //initialize the race constraints
        maxRacersCount = 4;
        currentRacersCount = 0;

        //set initialPrices, finalPrices and deltaPrices to 0
        for(uint8 i=0;i<10;i++){
            initialPrices[i] = 0;
            finalPrices[i] = 0;
            deltaPrices[i] = 0;
         }

        
        //define entry fee
        entryFeeMatic = 1;
        entryFeeWei = (10 ** 18) * entryFeeMatic;
        raceEnded = false;
    }
   
    function getLatestPrice(AggregatorV3Interface feedType) internal view returns(int){
        (,int price,,,) = feedType.latestRoundData();
        return price;
    }
    
 
    function addRacers(
    string memory _uname, 
    int256[] memory _tokenDistribution
    ) external payable{
        //verify staking amount, maxRacers and if race has ended
        require(msg.value >= entryFeeWei,"Insufficient staking amount to start the race");
        require(currentRacersCount < maxRacersCount, "Maximum limit reached for this race, try another one");
        require(!raceEnded, "Sorry, race has ended");
        //create new racer and push it to the racers array
        racers.push(Racer(_uname, msg.sender, 0, _tokenDistribution));
        
        //emit user acceptance event
        emit NewRacer(_uname, msg.sender, currentRacersCount+1);
        currentRacersCount++;
    }


    function beginRace() public onlyOwner{
        require(!raceEnded,"Race has ended");

        //get latest prices and assign them to initialPrices
        
        initialPrices[0] = getLatestPrice(btcFeed);
        initialPrices[1] = getLatestPrice(ethFeed);
        initialPrices[2] = getLatestPrice(usdtFeed);
        initialPrices[3] = getLatestPrice(bnbFeed);
        initialPrices[4] = getLatestPrice(adaFeed);
        initialPrices[5] = getLatestPrice(solFeed);
        initialPrices[6] = getLatestPrice(xrpFeed);
        initialPrices[7] = getLatestPrice(lunaFeed);
        initialPrices[8] = getLatestPrice(dogeFeed);
        initialPrices[9] = getLatestPrice(dotFeed);

      
        //emit beginning of the race
        emit RaceBegan();
    }


    function endRace() public onlyOwner{
        //get the latest prices and calculate the delta

        finalPrices[0] = getLatestPrice(btcFeed);
        finalPrices[1] = getLatestPrice(ethFeed);
        finalPrices[2] = getLatestPrice(usdtFeed);
        finalPrices[3] = getLatestPrice(bnbFeed);
        finalPrices[4] = getLatestPrice(adaFeed);
        finalPrices[5] = getLatestPrice(solFeed);
        finalPrices[6] = getLatestPrice(xrpFeed);
        finalPrices[7] = getLatestPrice(lunaFeed);
        finalPrices[8] = getLatestPrice(dogeFeed);
        finalPrices[9] = getLatestPrice(dotFeed);


        for(uint8 i=0;i<10;i++){
            deltaPrices[i] = finalPrices[i] - initialPrices[i];
        }
        //update score for each user
        for(uint8 i=0;i<maxRacersCount;i++){
            int256 _tempScore = 0;
            _tempScore += (racers[i].tokenPrices[0] * deltaPrices[0]);
            _tempScore += (racers[i].tokenPrices[1] * deltaPrices[1]);
            _tempScore += (racers[i].tokenPrices[2] * deltaPrices[2]);
            _tempScore += (racers[i].tokenPrices[3] * deltaPrices[3]);
            _tempScore += (racers[i].tokenPrices[4] * deltaPrices[4]);
            _tempScore += (racers[i].tokenPrices[5] * deltaPrices[5]);
            _tempScore += (racers[i].tokenPrices[6] * deltaPrices[6]);
            _tempScore += (racers[i].tokenPrices[7] * deltaPrices[7]);
            _tempScore += (racers[i].tokenPrices[8] * deltaPrices[9]);
            _tempScore += (racers[i].tokenPrices[9] * deltaPrices[8]);
            racers[i].score = _tempScore;
        }
        //sort the racers array based on their score
        for(uint i=0;i<maxRacersCount-1;i++){
            for(uint j=0;j<(maxRacersCount-1-i);j++){
                if(racers[j].score < racers[j+1].score){
                    Racer memory temp = racers[j];
                    racers[j] = racers[j+1];
                    racers[j+1] = temp;
                }
            }
        }
        //redestribute stakes
        payable(racers[0].addr).transfer(420000000000000000 * entryFeeMatic * currentRacersCount);
        payable(racers[1].addr).transfer(297500000000000000 * entryFeeMatic * currentRacersCount);
        payable(racers[2].addr).transfer(127500000000000000 * entryFeeMatic * currentRacersCount);
        //distribute the remaining among other racers
        uint remainingEach = (entryFeeMatic * currentRacersCount * 140000000000000000)/(currentRacersCount-3);
        for(uint8 i=3;i<currentRacersCount;i++){
            payable(racers[i].addr).transfer(remainingEach);
        }
    }

    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function getBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    
}