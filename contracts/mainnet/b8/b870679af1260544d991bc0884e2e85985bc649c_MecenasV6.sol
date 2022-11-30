// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";


interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


interface CreamYield {
    
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function underlying() external view returns (address);
}


contract MecenasV6 is ReentrancyGuard {

    address public constant EMPTY_ADDRESS = address(0);
    uint public immutable LOCK_LOTTERY;
    uint public immutable PERCENTAGE_LOTTERY;
    uint public immutable FEE_LOTTERY;
    uint public immutable FEE_WITHDRAW;

    CreamYield public marketcream;
    ERC20 public underlying;
    AggregatorV3Interface internal priceFeed;
    
    uint public totaldevelopfee;
    uint public totalinterestpaid;
    uint public supporters;
    uint public lockdeposits;
    uint public jackpotvalue;
    uint public interestvalue;
    uint80 private nonce;
    uint private blockNumber;
    
    uint public generatorRNG;

    bool public spinning;
    bool public picking;

    uint public jackpotsettled;
    uint public timejackpot;

    uint public jackpotspaid;
    uint public developsettled;
    uint public balancedonations;
    uint public totaldonations;
    uint public totaldonationspaid;

    mapping(address => uint) public balancedonators;
    mapping(address => uint) public balancepatrons;

    uint public balancepool;

    uint public decimalstoken;
    string public nametoken;

    address[] private players;
    
    mapping(address => uint) private indexplayers;
    
    address public owner;
    address public developer;
    
    uint public lotterycounter;
    
    struct Lottery {
        uint lotteryid;
        uint lotterydate;
        uint lotteryresult;
        address lotterywinner;
        uint lotteryamount;
        uint datablock;
        uint80 datanonce;
    }    
    
    Lottery[] public lotteryResults;
    
    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);
    event DepositDonation(address indexed from, uint amount);
    event WithdrawDonation(address indexed to, uint amount);
    event CollectYield(address indexed to, uint amount);
    event PayWinner(address indexed to, uint amount);
    event PayDeveloper(address indexed to, uint amount);
    event ChangeOwner(address indexed oldowner, address indexed newowner);
    event ChangeDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangePoolLock(address indexed ownerchanger, uint newlock);
    event LotteryAwarded(uint counter, uint date, address indexed thewinner, uint amount, uint result);
    event ChangeGeneratorRNG(address indexed ownerchanger, uint newRNG);

    
    constructor(address _owner, address _marketcream, address _developer, uint _cyclelottery, address _priceFeed, uint _generatorRNG, uint _feelottery, uint _feewithdraw, uint _percentagelottery) {
        
        require(_generatorRNG == 1 || _generatorRNG == 2);
        require(_feelottery > 0 && _feelottery < 100);
        require(_feewithdraw > 0 && _feewithdraw < 100);
        require(_percentagelottery > 0 && _percentagelottery < 100);
        require(_cyclelottery > 0);
        require(_priceFeed != EMPTY_ADDRESS);
        require(_developer != EMPTY_ADDRESS);
        require(_marketcream != EMPTY_ADDRESS);
        require(_owner != EMPTY_ADDRESS);

        marketcream = CreamYield(_marketcream);
        underlying = ERC20(marketcream.underlying());
        owner = _owner;
        developer = _developer;
        decimalstoken = underlying.decimals();
        nametoken = underlying.symbol();
        LOCK_LOTTERY = _cyclelottery;
        priceFeed = AggregatorV3Interface(_priceFeed);
        generatorRNG = _generatorRNG;
        FEE_LOTTERY = _feelottery;
        FEE_WITHDRAW = _feewithdraw;
        PERCENTAGE_LOTTERY = _percentagelottery;
    }


    // Checks if msg.sender is the owner
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    // Returns historical price feed

    function _getHistoricalPrice(uint80 roundId) internal view returns (int, uint) {
        (,int price, uint startedAt,,) = priceFeed.getRoundData(roundId);
        
        return (price, startedAt);
    }


    // Returns latest price feed

    function _getLatestPrice() internal view returns (uint80) {
        (uint80 roundID,,,,) = priceFeed.latestRoundData();
        return roundID;
    }

    
    // Modifies the address of the owner
    
    function transferOwner(address _newowner) external onlyOwner {
        require(_newowner != EMPTY_ADDRESS);
        address oldowner = owner;
        owner = _newowner;
    
        emit ChangeOwner(oldowner, owner);
    }


    // Modifies the address of the developer

    function transferDeveloper(address _newdeveloper) external {
        require(_newdeveloper != EMPTY_ADDRESS && msg.sender == developer);
        address olddeveloper = developer;
        developer = _newdeveloper;
    
        emit ChangeDeveloper(olddeveloper, developer);
    }


    // Locks or unlocks pool deposits
    // 0 = unlocked 
    // 1 = locked
    
    function lockPool() external onlyOwner {
            
        if (lockdeposits == 0) {
            lockdeposits = 1;
        }

        if (lockdeposits == 1) {
            lockdeposits = 0;
        }

        emit ChangePoolLock(owner, lockdeposits);
    }
    

    // Changes RNG generator
    // 1 = PRICE FEED 
    // 2 = FUTURE BLOCKHASH
    
    function changeGenerator() external onlyOwner {
    
        if (generatorRNG == 1) {
            generatorRNG = 2;
        }
    
        if (generatorRNG == 2) {
            generatorRNG = 1;
        }
    
        spinning = false;
        picking = false;
        jackpotsettled = 0;
        developsettled = 0;
    
        emit ChangeGeneratorRNG(owner, generatorRNG);
    }


    // Deposit underlying as lending and participate in lottery
        
    function deposit(uint _amount) external nonReentrant {
        require(!spinning && lockdeposits == 0 && msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount);
        require(underlying.allowance(msg.sender, address(this)) >= _amount);
        
        require(underlying.transferFrom(msg.sender, address(this), _amount));
        
        if (balancepatrons[msg.sender] == 0) {
            supporters += 1;
            players.push(msg.sender);
            indexplayers[msg.sender] = players.length - 1;
        }

        if (supporters > 0 && timejackpot == 0 && !spinning) {
            timejackpot = block.timestamp;
        }
        
        require(underlying.approve(address(marketcream), _amount));
        require(marketcream.mint(_amount) == 0);   

        balancepatrons[msg.sender] += _amount;
        balancepool += _amount;
        
        emit Deposit(msg.sender, _amount);
    }
    
    
    // Deposit underlying as donation
  
    function depositDonation(uint _amount) external nonReentrant {
        require(lockdeposits == 0 && msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount);
        require(underlying.allowance(msg.sender, address(this)) >= _amount);
        
        require(underlying.transferFrom(msg.sender, address(this), _amount));
        
        require(underlying.approve(address(marketcream), _amount));
        require(marketcream.mint(_amount) == 0);   

        balancedonators[msg.sender] += _amount;
        balancedonations += _amount;
        totaldonations += _amount;
                
        emit DepositDonation(msg.sender, _amount);
    }
    
    
    // Withdraw underlying lended
        
    function withdraw(uint _amount) external nonReentrant {
        require(!spinning && msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && balancepatrons[msg.sender] >= _amount);
        require(marketcream.getCash() >= _amount);
        
        balancepatrons[msg.sender] -= _amount; 
        balancepool -= _amount;

        require(marketcream.redeemUnderlying(_amount) == 0);

        if (balancepatrons[msg.sender] == 0) {
            supporters -= 1;
                
            uint index = indexplayers[msg.sender];
            uint indexmove = players.length - 1;
            address addressmove = players[indexmove];
                
            if (index == indexmove) {
                delete indexplayers[msg.sender];
                players.pop();
                    
            } else {
                delete indexplayers[msg.sender];
                players[index] = addressmove;
                indexplayers[addressmove] = index;
                players.pop();
            }
        } 
        
        if (supporters == 0) {
            timejackpot = 0;
            spinning = false;
            picking = false;
            jackpotsettled = 0;
            developsettled = 0;
        }    
        
        require(underlying.transfer(msg.sender, _amount));
    
        emit Withdraw(msg.sender, _amount);
    }


    // Accrues yield and splits into interests and jackpot
    
    function _splitYield() internal {
        uint interest = _interestAccrued();
        
        uint jackpotinterest = interest * (PERCENTAGE_LOTTERY * 10 ** decimalstoken / 100);
        jackpotinterest = jackpotinterest / 10 ** decimalstoken;
        jackpotvalue += jackpotinterest;
        
        uint totransferinterest = interest - jackpotinterest;
        interestvalue += totransferinterest;
    }


    // Calculates yield generated in yield source
    
    function _interestAccrued() internal returns (uint) {
        uint interest = (marketcream.balanceOfUnderlying(address(this)) - balancepool - balancedonations - jackpotvalue - interestvalue); 
        return interest;
    }


    // Draw the Lottery
    
    function settleJackpot() external nonReentrant {
        
        require(!spinning && supporters > 0 && timejackpot > 0);
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;
        require(totaltime >= LOCK_LOTTERY);

        spinning = true;
        timejackpot = 0;
        
        _splitYield();
    
        require(jackpotvalue > 0);
        
        jackpotsettled = jackpotvalue;
        uint distjackpot = jackpotsettled;
        
        developsettled = distjackpot * (FEE_LOTTERY * 10 ** decimalstoken / 100);
        developsettled = developsettled / 10 ** decimalstoken;
        
        jackpotsettled = jackpotsettled - developsettled;
        
        if (generatorRNG == 1) {
            nonce = _getLatestPrice() + 10;
            blockNumber = block.number + 10;
        }

        if (generatorRNG == 2) {
            blockNumber = block.number + 10;
        }

        picking = true;
    }
    
    
    // RNG or PRNG (random or pseudo random number generator)
    
    function _generateRandomNumber() internal view returns (uint) {
        
        uint randnum;

        if (generatorRNG == 1) {
        (int theprice, uint thestartround) = _getHistoricalPrice(nonce);
        randnum = uint(keccak256(abi.encode(theprice, thestartround))) % players.length;
        }
        
        if (generatorRNG == 2) {
        randnum = uint(keccak256(abi.encode(blockhash(blockNumber)))) % players.length;
        }

        return randnum;  
    }


    // Award the Lottery Winner
        
    function pickWinner() external nonReentrant {
        
        if (generatorRNG == 1) {
        require(picking && _getLatestPrice() > nonce);
        }

        if (generatorRNG == 2) {
        require(picking && block.number > blockNumber);
        }

        uint toredeem =  jackpotsettled + developsettled;
        require(marketcream.getCash() >= toredeem);  
        
        uint totransferbeneficiary = jackpotsettled;
        uint totransferdevelop = developsettled;
        
        jackpotsettled = 0;
        developsettled = 0;
        
        lotterycounter++;
        uint end = block.timestamp;
        
        if (block.number - blockNumber > 250) {
    
            lotteryResults.push(Lottery(lotterycounter, end, 2, EMPTY_ADDRESS, 0, blockNumber, nonce));

            emit LotteryAwarded(lotterycounter, end, EMPTY_ADDRESS, 0, 2);
        
        } else {
            
            uint randomnumber = _generateRandomNumber();
            address beneficiary = players[randomnumber];
            
            jackpotspaid += totransferbeneficiary;
            totaldevelopfee += totransferdevelop;
                    
            require(marketcream.redeemUnderlying(toredeem) == 0);
            jackpotvalue -= toredeem;
            
            require(underlying.transfer(beneficiary, totransferbeneficiary));
            require(underlying.transfer(developer, totransferdevelop));
                        
            lotteryResults.push(Lottery(lotterycounter, end, 1, beneficiary, totransferbeneficiary, blockNumber, nonce));
        
            emit PayWinner(beneficiary, totransferbeneficiary);
            emit PayDeveloper(developer, totransferdevelop);
                        
            emit LotteryAwarded(lotterycounter, end, beneficiary, totransferbeneficiary, 1);
        }
          
        timejackpot = block.timestamp;
        spinning = false;
        picking = false;
    }
        
    
    // Returns the timeleft to draw lottery
    // 0 = no time left

    function calculateTimeLeft() public view returns (uint) {
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;
        
        if(totaltime < LOCK_LOTTERY) {
            uint timeleft = LOCK_LOTTERY - totaltime;
            return timeleft;
        } else {
            return 0;
        }
    }
    
    
    // Returns if conditions are met to draw lottery
    // 1 = met
    // 2 = not met 
    
    function checkJackpotReady() public view returns (uint) {
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;

        if (!spinning && supporters > 0 && timejackpot > 0 && totaltime > LOCK_LOTTERY) {
            return 1;
    
        } else {
            return 2;
        }    
    }        
            
    
    // Returns if conditions are met to award a lottery winner
    // 1 = met
    // 2 = not met 
        
    function checkWinnerReady() public view returns (uint) {
        
        uint toredeem = jackpotsettled + developsettled;
        uint metwinner;
        
        if (generatorRNG == 1) {
            if (picking && marketcream.getCash() >= toredeem && _getLatestPrice() > nonce) {
                metwinner = 1;
            } else {
                metwinner = 2;
            }
        }

        if (generatorRNG == 2) {
            if (picking && block.number > blockNumber && marketcream.getCash() >= toredeem) {
                metwinner = 1;
            } else {
                metwinner = 2;
            }
        }
        
        return metwinner;
    }
    
    
    // Returns if account is the owner
    // 1 = is owner
    // 2 = is not owner
    
    function verifyOwner(address _account) public view returns (uint) {
        
        if (_account == owner) {
            return 1;
        } else {
            return 2;
        }
    }
    
  
    // Returns an array of struct of jackpots drawn results
  
    function getLotteryResults() external view returns (Lottery[] memory) {
    return lotteryResults;
    }
  
    
    // Withdraw interests by the owner
    
    function withdrawYield(uint _amount) external nonReentrant onlyOwner {
        
        _splitYield();

        require(_amount > 0);
        require(_amount <= interestvalue);
        require(marketcream.getCash() >= _amount);  

        uint developfee;
        uint amountowner;

        totalinterestpaid += _amount;
        interestvalue -= _amount;
        
        developfee = _amount * (FEE_WITHDRAW * 10 ** decimalstoken / 100);
        developfee = developfee / 10 ** decimalstoken;
        amountowner = _amount - developfee;
        totaldevelopfee += developfee;

        require(marketcream.redeemUnderlying(_amount) == 0);
        require(underlying.transfer(owner, amountowner));
        require(underlying.transfer(developer, developfee));

        emit CollectYield(owner, amountowner);
        emit PayDeveloper(developer, developfee);
    }
    
    
    // Withdraw donations by the owner     
    
    function withdrawDonations(uint _amount) external nonReentrant onlyOwner {
        require(_amount > 0);
        require(balancedonations >= _amount);
        require(marketcream.getCash() >= _amount);  
        
        require(marketcream.redeemUnderlying(_amount) == 0);
        balancedonations -= _amount;
        totaldonationspaid += _amount;
        
        uint developfee;
        uint amountowner;

        developfee = _amount * (FEE_WITHDRAW * 10 ** decimalstoken / 100);
        developfee = developfee / 10 ** decimalstoken;
        amountowner = _amount - developfee;
        totaldevelopfee += developfee;

        require(underlying.transfer(owner, amountowner));
        require(underlying.transfer(developer, developfee));

        emit WithdrawDonation(owner, amountowner);
        emit PayDeveloper(developer, developfee);
    }
    

    // Returns yield generated
    // _amount = balance of underlying of yieldsource
    
    function calculateInterest(uint _amount) external view returns(uint, uint) {
        
        uint yield = (_amount - balancepool - balancedonations - jackpotvalue - interestvalue);
        
        uint jackpot = yield * (PERCENTAGE_LOTTERY * 10 ** decimalstoken / 100);
        jackpot = jackpot / 10 ** decimalstoken;

        uint interest = yield - jackpot;
        interest += interestvalue;

        jackpot = jackpot + jackpotvalue - jackpotsettled - developsettled;

        uint feejackpot = jackpot * (FEE_LOTTERY * 10 ** decimalstoken / 100); 
        feejackpot = feejackpot / 10 ** decimalstoken;

        jackpot -= feejackpot;

        return (interest, jackpot);
    }
    

    // Returns data to the front end

    function pullData() external view returns (uint [] memory) {
        
        uint[] memory datafront = new uint[](18);
        
        datafront[0] = balancepool + balancedonations;
        datafront[1] = marketcream.getCash();
        datafront[2] = calculateTimeLeft();
        datafront[3] = checkJackpotReady();
        datafront[4] = checkWinnerReady();
        datafront[5] = totalinterestpaid;
        datafront[6] = generatorRNG;
        datafront[7] = totaldonationspaid;
        datafront[8] = balancedonations;
        datafront[9] = totaldonations;
        datafront[10] = jackpotsettled;
        datafront[11] = jackpotspaid;
        datafront[12] = lockdeposits;
        datafront[13] = supporters;
        datafront[14] = LOCK_LOTTERY;
        datafront[15] = decimalstoken;
        datafront[16] = balancepool;
        datafront[17] = lotterycounter;        
        
        return (datafront);
    }

   
   // Returns data to the front end
    
    function pullDataAccount(address _account) external view returns (uint [] memory) {
        require(_account != EMPTY_ADDRESS);

        uint[] memory datafrontaccount = new uint[](5);
        
        datafrontaccount[0] = balancepatrons[_account];
        datafrontaccount[1] = underlying.balanceOf(_account);
        datafrontaccount[2] = underlying.allowance(_account, address(this));
        datafrontaccount[3] = verifyOwner(_account);
        datafrontaccount[4] = balancedonators[_account];
        
        return (datafrontaccount);
    }


    // Checks conditions of transactions
    // flag 1 = deposits lending
    // flag 2 = deposits donations
    // flag 3 = withdraw lending
    // flag 4 = withdraw donations
    // flag 5 = withdraw yield

    function checkOperations(uint _amount, uint _amount1, address _account, uint _flag) external view returns (uint) {
                
        uint result = 0;
        
        if (lockdeposits == 1 && (_flag == 1 || _flag == 2)) {
            result = 1;
        } else {
            if (spinning && (_flag == 1 || _flag == 3)) {
                result = 2;
            } else {
                if (_amount > underlying.balanceOf(_account) && (_flag == 1 || _flag == 2)) {
                    result = 3;
                } else {
                    if (_amount > underlying.allowance(_account, address(this)) && (_flag == 1 || _flag == 2)) {
                        result = 4;
                    } else {
                        if (_amount > balancepatrons[_account] && _flag == 3) {
                            result = 5;            
                        } else {
                             if (verifyOwner(_account) == 2 && (_flag == 4 || _flag == 5)) {
                                result = 6;
                            } else {
                                if (_amount > balancedonations && _flag == 4) {
                                    result = 7;
                                } else {
                                    if (_amount > _amount1 && _flag == 5) {
                                        result = 8;
                                    } else {
                                        if (_amount > marketcream.getCash() && (_flag == 3 || _flag == 4 || _flag == 5)) {
                                            result = 9;
                                        }
                                    }
                                }
                            }     
                        }
                    }                        
                }
            }
        }
        
        return result;
    }

}