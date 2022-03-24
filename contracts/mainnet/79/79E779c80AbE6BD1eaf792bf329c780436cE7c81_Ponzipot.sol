// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";


interface YieldMarket {
    
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function underlying() external view returns (address);
}

interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


contract Ponzipot is ReentrancyGuard {

    address public constant EMPTY_ADDRESS = address(0);
    
    uint public constant LOCK_LOTTERY = 2592000;
    uint public constant TICKET_PRICE = 50000000;
    uint public constant MAX_TVL = 2000000000000;
    uint public constant MAX_WALLET = 20000000000;
    uint public constant HARVEST_TIME = 1296000;
    uint public constant MAX_TICKETS_PLAYER = 200;
    uint public constant MAX_TICKETS_TRANSACTIONS = 10;
    uint public constant YIELD_RATE = 10457996;
    uint public constant LOTTERY_PERCENTAGE = 70;
    uint public constant VOTING_TIME = 1296000;
    AggregatorV3Interface internal constant priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);

    YieldMarket public yieldmarket;
    ERC20 public underlyingpot;
    uint public decimalstoken;
    string public nametoken;
    
    uint public reservevalue;
    uint public reserveavailable;
    uint public reservetojackpot;
    uint public reservetodividends;
    uint public investorvalue;
    uint public totalplayers;
    uint public totalsponsors;
    uint public jackpotvalue;
    uint80 private nonce;
    uint private blockNumber;
    bool public spinning;
    bool public picking;
    uint public jackpotsettled;
    uint public investorfee;
    uint public developfee;
    uint public timejackpot;
    uint public jackpotspaid;
    address public developer;
    uint public lotterycounter;
    uint public totaltickets;
    uint public balancepool;
    uint public balancepoolsponsors;
    uint public balancepoolcompound;
    uint public investorspaidpool;

    struct Lottery {
        uint lotteryid;
        uint lotterydate;
        uint lotteryresult;
        address lotterywinner;
        uint lotteryamount;
        uint datablock;
        uint80 datanonce;
    }    
    
    Lottery[] public lotteryresults;
    
    address[] private players;
    
    mapping(address => uint) public balanceplayers;
    mapping(uint => uint) public indexcrossplayers;
    mapping(address => uint[]) public indexplayers;
    mapping(address => uint) public balancesponsors;
    mapping(address => uint) public balancecompound;
    mapping(address => uint) public investorspaid;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public balancerewards;
    mapping(address => uint256) public rewardscollected;
    mapping(address => uint256) public blockdeposits;
    mapping(address => uint) public balancesubsidy;
    mapping(address => uint) public balancecompoundplayer;

    mapping(address => uint256) public cycleprizeplayer;
    mapping(address => uint) public balancecompoundplayeractual;
    mapping(address => uint) public balancecompoundplayernext;
    mapping(address => uint) public prizeswonplayer;

    uint public balancepoolsubsidy;
    uint public balancepoolcompoundplayer;

    mapping(address => uint256) public votingpoweractual;
    mapping(address => uint256) public votingpowernext;
    mapping(address => uint256) public votingpower;

    uint public balancerewardspool;
    uint public rewardscollectedpool;
    uint public investorvaluetime;
    
    mapping(address => uint256) public balancerewardsmature;

    struct Proposal {
        uint datecreation;
        address creator;
        uint timesnapshot;
        uint transtype;
        uint amount;
        uint dateend;
        uint dateexecution;
        uint signaturesCountYES;
        uint signaturesCountNO;
        uint signaturesweightYES;
        uint signaturesweightNO;
        uint status;
}

    Proposal[] public proposals;

    mapping (address => mapping(uint => uint)) public signatures;

    uint public reservesjackpot;
    uint public reservesdividends;
    uint public dividendscyclecounter;

    mapping(address => uint256) public balancerewardsactual;
    mapping(address => uint256) public balancerewardsnext;
    mapping(address => uint256) public cycledividendsnext;

    struct Voter {
        address voter;
        uint castvote;
        uint power;
}

    mapping(uint => Voter[]) public voterlist;


    event Stake(address indexed sender, uint amount);
    event Unstake(address indexed to, uint amount);
            

    constructor
    (address _developer, address _yieldmarket) {
        
        yieldmarket = YieldMarket(_yieldmarket);
        underlyingpot = ERC20(yieldmarket.underlying());
        decimalstoken = underlyingpot.decimals();
        nametoken = underlyingpot.symbol();
        developer = _developer;
    }


    // Returns historical price feed

    function getHistoricalPrice(uint80 roundId) internal view returns (int, uint) {
        (,int price, uint startedAt,,) = priceFeed.getRoundData(roundId);
        
        return (price, startedAt);
    }


    // Returns latest price feed

    function getLatestPrice() internal view returns (uint80) {
        (uint80 roundID,,,,) = priceFeed.latestRoundData();
        return roundID;
    }


    // Modifies the address of the developer
    
    function transferDeveloper(address _newdeveloper) external {
        require(_newdeveloper != EMPTY_ADDRESS && msg.sender == developer);
        developer = _newdeveloper;
    }

    
    // Accrues potshares and voting power of liquidity providers and players

    function _accrueRewards(address _user) internal {
        uint end = block.timestamp;
        uint256 rewardsaccrued = _calculateYieldTotal(_user, end);
        
        balancerewards[_user] += rewardsaccrued;
        votingpower[_user] += rewardsaccrued;
                
        if (cycledividendsnext[_user] <= dividendscyclecounter) {
            balancerewardsactual[_user] += balancerewardsnext[_user];
            balancerewardsnext[_user] = 0;
            votingpoweractual[_user] += votingpowernext[_user];
            votingpowernext[_user] = 0;
        }
        
        if (startTime[_user] > investorvaluetime) {
            balancerewardsnext[_user] += rewardsaccrued;
            votingpowernext[_user] += rewardsaccrued;
            cycledividendsnext[_user] = dividendscyclecounter + 1;
        }
        
        if (startTime[_user] <= investorvaluetime) {
            uint256 rewardsaccrued1 = _calculateYieldTotal(_user, investorvaluetime);
            balancerewardsactual[_user] += rewardsaccrued1;
            balancerewardsnext[_user] += rewardsaccrued - rewardsaccrued1;
            votingpoweractual[_user] += rewardsaccrued1;
            votingpowernext[_user] += rewardsaccrued - rewardsaccrued1;
            cycledividendsnext[_user] = dividendscyclecounter + 1;
        }

        startTime[_user] = end;
    }


    // Deposit underlying of players to mint potcoins

    function buyTickets(uint _tickets) external nonReentrant {
        require(!spinning && msg.sender != EMPTY_ADDRESS && _tickets > 0);
        require(_tickets <= MAX_TICKETS_TRANSACTIONS && block.number > blockdeposits[msg.sender]);
        require((_tickets + indexplayers[msg.sender].length) <= MAX_TICKETS_PLAYER);
                
        uint amount = (TICKET_PRICE * (_tickets * 10 ** decimalstoken)) / 10 ** decimalstoken;
        
        require(underlyingpot.balanceOf(msg.sender) >= amount);
        require(underlyingpot.allowance(msg.sender, address(this)) >= amount);
        require(underlyingpot.transferFrom(msg.sender, address(this), amount));

        require(underlyingpot.approve(address(yieldmarket), amount));
        require(yieldmarket.mint(amount) == 0);   

        _accrueRewards(msg.sender);
                
        if (balanceplayers[msg.sender] == 0) {
            totalplayers += 1;
        }

        for (uint i = 0; i < _tickets; i++) {
        players.push(msg.sender);    
        uint index = players.length - 1;
        indexplayers[msg.sender].push(index);
        uint indexcross =  indexplayers[msg.sender].length - 1;
        indexcrossplayers[index] = indexcross;
        }
        
        if (totaltickets == 0) {
            timejackpot = block.timestamp;
        }
        
        totaltickets += _tickets;

        balanceplayers[msg.sender] += amount; 
        balancepool += amount;
        blockdeposits[msg.sender] = block.number + 2;
        
        emit Stake(msg.sender, amount);
    }
    

    // Redeem potcoins and widhtraw underlying of players
        
    function redeemTickets(uint _tickets) external nonReentrant {
        require(!spinning && msg.sender != EMPTY_ADDRESS && _tickets > 0);
        require(_tickets <= MAX_TICKETS_TRANSACTIONS && block.number > blockdeposits[msg.sender]);
        
        uint amount = (TICKET_PRICE * (_tickets * 10 ** decimalstoken)) / 10 ** decimalstoken;
        
        require(balanceplayers[msg.sender] >= amount);
        require(yieldmarket.getCash() >= amount);
        
        _accrueRewards(msg.sender);

        balancepool -= amount;
        balanceplayers[msg.sender] -= amount; 
        totaltickets -= _tickets;
        
        require(yieldmarket.redeemUnderlying(amount) == 0);

        if (balanceplayers[msg.sender] == 0) {
            totalplayers -= 1;
        }
        
        for (uint i = 0; i < _tickets; i++) {
        uint indextowithdraw = indexplayers[msg.sender].length - 1;
        uint indextoremove = indexplayers[msg.sender][indextowithdraw];
        indexplayers[msg.sender].pop();
    
        uint indexmove = players.length - 1;
        address addressmove = players[indexmove];
                
            if (indexmove ==  indextoremove) {
                players.pop();
                delete indexcrossplayers[indexmove];
        
            } else { 

            players[indextoremove] = addressmove;
            players.pop();
        
            uint indextoreplace = indexcrossplayers[indexmove];
            indexplayers[addressmove][indextoreplace] = indextoremove;
            indexcrossplayers[indextoremove] = indextoreplace;
        
            delete indexcrossplayers[indexmove];
            }
        }

        if (totaltickets == 0) {
            timejackpot = 0;
            spinning = false;
            picking = false;
            jackpotsettled = 0;
            investorfee = 0;
            developfee = 0;
        }    

        require(underlyingpot.transfer(msg.sender, amount));

        emit Unstake(msg.sender, amount);
    }


    // Deposit underlying of liquidity providers and subsidiary depositors 
    // _flag 1 = Liquidity Providers
    // _flag 2 = Subsidiry Depositors
  
    function depositSponsor(uint _amount, uint _flag) external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS && _amount > 0);
        require(underlyingpot.balanceOf(msg.sender) >= _amount);
        require(underlyingpot.allowance(msg.sender, address(this)) >= _amount);
        require(block.number > blockdeposits[msg.sender]);
        require(_flag == 1 || _flag == 2);

        if (_flag == 1) {
        require(balancesponsors[msg.sender] + _amount <= MAX_WALLET);
        require(balancepoolsponsors < MAX_TVL);
        }

        require(underlyingpot.transferFrom(msg.sender, address(this), _amount));
        require(underlyingpot.approve(address(yieldmarket), _amount));
        require(yieldmarket.mint(_amount) == 0);   

        _accrueRewards(msg.sender);

        if (balancesponsors[msg.sender] == 0 && _flag == 1) {
            totalsponsors += 1;
        }

        if (_flag == 1) {
            balancesponsors[msg.sender] += _amount;
            balancepoolsponsors += _amount;
            blockdeposits[msg.sender] = block.number + 2;
        }

        if (_flag == 2) {
            balancesubsidy[msg.sender] += _amount;
            balancepoolsubsidy += _amount;
        }    

        emit Stake(msg.sender, _amount);
    }


    // Withdraw underlying of liquidity providers and subsidiary depositors
    // _flag 1 = Removes from liquidity balance
    // _flag 2 = Cash out from compound balance
    // _flag 3 = Removes from subsidiary balance 
    // _flag 4 = Cash out from compound prizes balance
    
    function withdrawSponsor(uint _amount, uint _flag) external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS && _amount > 0 && (_flag == 1 || _flag == 2 || _flag == 3 || _flag == 4));
        
        _accrueRewards(msg.sender);

        if (_flag == 1) {
            require(balancesponsors[msg.sender] >= _amount && block.number > blockdeposits[msg.sender]);
            balancesponsors[msg.sender] -= _amount;
            balancepoolsponsors -= _amount;
        }
        
        if (_flag == 2) {
            require(balancecompound[msg.sender] >= _amount);
            balancecompound[msg.sender] -= _amount;
            balancepoolcompound -= _amount;
        }
        
        if (_flag == 3) {
            require(balancesubsidy[msg.sender] >= _amount);
            balancesubsidy[msg.sender] -= _amount;
            balancepoolsubsidy -= _amount;
        }

        if (_flag == 4) {
            if (cycleprizeplayer[msg.sender] <= dividendscyclecounter) {
                balancecompoundplayeractual[msg.sender] += balancecompoundplayernext[msg.sender];
                balancecompoundplayernext[msg.sender] = 0;
            }
            
            require(balancecompoundplayeractual[msg.sender] >= _amount);

            balancecompoundplayeractual[msg.sender] -= _amount;
            balancecompoundplayer[msg.sender] -= _amount;
            balancepoolcompoundplayer -= _amount;
        }

        require(yieldmarket.getCash() >= _amount);
        require(yieldmarket.redeemUnderlying(_amount) == 0);
       
        if (balancesponsors[msg.sender] == 0 && _flag == 1) {
        totalsponsors -= 1;
        }

        require(underlyingpot.transfer(msg.sender, _amount));

        emit Unstake(msg.sender, _amount);
    }


    // Splits yield between pot prize and reserves
    
    function _splitYield() internal {
        
        uint interest = (yieldmarket.balanceOfUnderlying(address(this)) - balancepool - balancepoolsponsors - reservevalue - jackpotvalue - investorvalue - balancepoolcompound - reservesjackpot - reservesdividends - reserveavailable - balancepoolsubsidy- balancepoolcompoundplayer);
        
        uint jackpotinterest = (interest * (LOTTERY_PERCENTAGE * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
        jackpotvalue += jackpotinterest;
        
        uint reserveinterest = interest - jackpotinterest;
        reservevalue += reserveinterest;
    }


    // Settles pot prize, bonus prize, dividends and developer fee
        
    function settlejackpot() external nonReentrant {
        require(!spinning && totaltickets > 0 && timejackpot > 0 && block.number > blockNumber);
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;
        require(totaltime >= LOCK_LOTTERY);

        spinning = true;
        blockNumber = block.number;

        _splitYield();
    
        require(jackpotvalue > 0);
        
        jackpotvalue += reservesjackpot;
        reservetojackpot += reservesjackpot;
        reservesjackpot = 0;

        jackpotsettled = jackpotvalue;
        
        investorfee = (jackpotsettled * (27 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
        developfee = (jackpotsettled * (8 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
                
        jackpotsettled = jackpotsettled - developfee - investorfee;

        nonce = getLatestPrice() + 5;        
        picking = true;
    }
    
    
    // RNG (Random Number Generator)
    
    function generaterandomnumber() internal view returns (uint) {
        uint randnum;
        (int theprice, uint thestartround) = getHistoricalPrice(nonce);
        randnum = uint(keccak256(abi.encode(blockhash(blockNumber), theprice, thestartround))) % players.length;
        return randnum;  
    }


    // Select a winner and award the pot prize, distribute dividends and developer fee
            
    function pickawinner() external nonReentrant {
        require(picking && block.number > blockNumber);
        
        uint totransferbeneficiary = jackpotsettled;
        uint totransferinvestor = investorfee;
        uint totransferdevelop = developfee;

        jackpotsettled = 0;
        investorfee = 0;
        developfee = 0;

        _splitYield();

        lotterycounter++;
        uint end = block.timestamp;
        
        if (block.number - blockNumber > 250) {
    
            lotteryresults.push(Lottery(lotterycounter, end, 2, EMPTY_ADDRESS, 0, blockNumber, nonce));
        
        } else {

            require(getLatestPrice() > nonce);
        
            uint randomnumber;
        
            randomnumber = generaterandomnumber();
        
            address beneficiary = players[randomnumber];
            
                jackpotspaid += totransferbeneficiary;
                
                uint reservestounlock = (reservevalue * (25 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;

                reserveavailable += reservestounlock;
                reservevalue -= reservestounlock;
                jackpotvalue = jackpotvalue - totransferbeneficiary - totransferdevelop - totransferinvestor;
            
                investorvaluetime = end;
                dividendscyclecounter++;

                _accrueRewards(beneficiary);
                balancecompoundplayer[beneficiary] += totransferbeneficiary;
                balancepoolcompoundplayer += totransferbeneficiary;
                lotteryresults.push(Lottery(lotterycounter, end, 1, beneficiary, totransferbeneficiary, blockNumber, nonce));
                prizeswonplayer[beneficiary] += totransferbeneficiary;

                balancecompoundplayeractual[beneficiary] += balancecompoundplayernext[beneficiary];
                balancecompoundplayernext[beneficiary] = 0;
                balancecompoundplayernext[beneficiary] = totransferbeneficiary;
                cycleprizeplayer[beneficiary] = dividendscyclecounter + 1;
                        
                _accrueRewards(developer);
                uint developercompound = (reservesdividends * (30 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
                balancecompound[developer] = balancecompound[developer] + developercompound + totransferdevelop;
                balancepoolcompound = balancepoolcompound + developercompound + totransferdevelop;

                investorvalue = investorvalue + reservesdividends + totransferinvestor - developercompound;
                reservetodividends += reservesdividends;
                reservesdividends = 0;

                timejackpot = block.timestamp;
        }
        
        spinning = false;
        picking = false;
    }


    // Returns if condition is met to execute function settlejackpot()
    // 1 = met
    // 2 = not met 
    
    function calculatesettlejackpot() public view returns (uint) {
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;

        if (!spinning && totaltickets > 0 && timejackpot > 0 && block.number > blockNumber && totaltime >= LOCK_LOTTERY) {
            return 1;
    
        } else {
            return 2;
        }    
    }        


    // Returns if condition is met to execute function pickawinner()
    // 1 = met
    // 2 = not met
        
    function calculatepickawinner() public view returns (uint) {

        if (picking && block.number > blockNumber && block.number - blockNumber > 250) {
            return 1;

        } else {

            if (picking && getLatestPrice() > nonce && block.number > blockNumber) {
                return 1;
        
            } else {
                return 2;
            }
        }
    }
  

    // Returns yield generated to the front end
    // _amount = balance of underlying in yield source
    
    function calculateinterest(uint _amount) external view returns(uint, uint, uint) {
        
        uint yield = (_amount - balancepool - balancepoolsponsors - reservevalue - jackpotvalue - investorvalue - balancepoolcompound - reservesjackpot - reservesdividends - reserveavailable - balancepoolsubsidy - balancepoolcompoundplayer);
        
        uint jackpot = (yield * (LOTTERY_PERCENTAGE * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
                
        uint reserve = yield - jackpot;
        reserve = reserve + reservevalue;

        jackpot = jackpot + jackpotvalue - jackpotsettled - investorfee - developfee;
            
        uint dividends = (jackpot * (27 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
        
        jackpot = (jackpot * (65 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
        
        return (jackpot, reserve, dividends);
    }
    

    // Returns data to the front end

    function calculatedata() external view returns (uint [] memory) {

        uint end = block.timestamp;
        
        uint[] memory datafront = new uint[](39);
        
        datafront[0] = balancepool + balancepoolsponsors + balancepoolcompound + balancepoolsubsidy + balancepoolcompoundplayer;
        datafront[1] = yieldmarket.getCash();

        datafront[2] = 0;

        if (end - timejackpot < LOCK_LOTTERY) {
            datafront[2] = LOCK_LOTTERY - (end - timejackpot);
        }

        datafront[3] = calculatesettlejackpot();
        datafront[4] = calculatepickawinner();
        
        datafront[5] = balancepool;
        datafront[6] = reservetojackpot;
        datafront[7] = balancepoolsponsors;
        datafront[8] = totalplayers;
        
        datafront[9] = lotterycounter;
        datafront[10] = jackpotsettled;
        datafront[11] = jackpotspaid;
        
        datafront[12] = end;
        datafront[13] = (reservesjackpot * (65 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;
        datafront[14] = totaltickets;
        
        datafront[15] = reservesdividends;
        datafront[16] = balancepoolcompound;
        datafront[17] = reservetodividends;
        
        datafront[18] = TICKET_PRICE;
        datafront[19] = balancepoolcompoundplayer;
        datafront[20] = LOCK_LOTTERY;
        
        datafront[21] = MAX_TICKETS_PLAYER;
        datafront[22] = MAX_TICKETS_TRANSACTIONS;
        datafront[23] = HARVEST_TIME;
        datafront[24] = YIELD_RATE;
        datafront[25] = MAX_TVL;
    
        datafront[26] = rewardscollectedpool;
        datafront[27] = balancerewardspool;
        
        datafront[28] = LOTTERY_PERCENTAGE;
        datafront[29] = decimalstoken;
        datafront[30] = investorvalue;
        datafront[31] = investorspaidpool;
        datafront[32] = MAX_WALLET;
        datafront[33] = investorfee;
        datafront[34] = totalsponsors;
    
        datafront[35] = 0;

        if (end - investorvaluetime < HARVEST_TIME) {
            datafront[35] = HARVEST_TIME - (end - investorvaluetime);
        }

        datafront[36] = reserveavailable;
        datafront[37] = balancepoolsubsidy;
        datafront[38] = VOTING_TIME;
                
        return (datafront);
    }

   
   // Returns data to the front end
    
    function calculatedataaccount(address _account) external view returns (uint [] memory) {
                
        uint end = block.timestamp;
        uint256 rewardsaccrued = _calculateYieldTotal(_account, end);

        uint[] memory datafrontaccount = new uint[](18);
        
        datafrontaccount[0] = balanceplayers[_account];
        datafrontaccount[1] = underlyingpot.balanceOf(_account);
        datafrontaccount[2] = underlyingpot.allowance(_account, address(this));
        datafrontaccount[3] = indexplayers[_account].length;
        datafrontaccount[4] = balancesponsors[_account];
        datafrontaccount[5] = balancecompound[_account];
        datafrontaccount[6] = balancerewards[_account] + rewardsaccrued;
        datafrontaccount[7] = balancerewardsmature[_account];
        datafrontaccount[8] = rewardscollected[_account];
        datafrontaccount[9] = investorspaid[_account];
        datafrontaccount[10] = votingpower[_account] + rewardsaccrued;
        datafrontaccount[11] = _checkmaturerewards(_account, votingpoweractual[_account], votingpowernext[_account]);
        datafrontaccount[12] = _checkmaturerewards(_account, balancerewardsactual[_account], balancerewardsnext[_account]);
        datafrontaccount[13] = balancesubsidy[_account];
        datafrontaccount[14] = balanceplayers[_account] + balancesponsors[_account] + balancecompound[_account] + balancecompoundplayer[_account];
        datafrontaccount[15] = balancecompoundplayer[_account];
        datafrontaccount[16] = _checkmatureprizecashout(_account);
        datafrontaccount[17] = prizeswonplayer[_account];

        return (datafrontaccount);
    }


    // Check deposits
    // _flag 1 = Liquidity Providers
    // _flag 2 = Subsidiary Depositors
    // _flag 3 = Buy Tickets
    
    function checkdeposits(uint _amount, address _account, uint _flag) external view returns (uint) {
        uint result = 0;
	    uint amount;	
 
	    if (_flag == 3) {
            amount = ((_amount * 10 ** decimalstoken) * TICKET_PRICE) / 10 ** decimalstoken;
        } else {
		    amount = _amount;
	    }

        if (spinning && _flag == 3) {
            result = 2;
        } else {
            if (block.number <= blockdeposits[_account] && (_flag == 1 || _flag == 3)) {
                result = 1;
            } else {
                if ((_amount + indexplayers[_account].length) > MAX_TICKETS_PLAYER && _flag == 3) {
                    result = 3;
                } else {
                    if (_amount > MAX_TICKETS_TRANSACTIONS && _flag == 3) {
                        result = 4;
                    } else {
                        if (amount > underlyingpot.balanceOf(_account)) {
                            result = 5;
                        } else {
                            if (amount > underlyingpot.allowance(_account, address(this))) {
                                result = 6;
                            } else {
                				if (balancesponsors[_account] + amount > MAX_WALLET && _flag == 1) {
                            		result = 7;
                        		} else {
                            		if (balancepoolsponsors >= MAX_TVL && _flag == 1) {
                                    	result = 8;
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
   
    
    // Check withdraw to redeem potcoins
    
    function checkredeemtickets(uint _tickets, address _account) external view returns (uint) {
                
        uint result = 0;
        uint amount = ((_tickets * 10 ** decimalstoken) * TICKET_PRICE) / 10 ** decimalstoken;
        
        if (spinning) {
            result = 1;
        } else {
            if (_tickets > indexplayers[_account].length || amount > balanceplayers[_account]) {
                result = 2;
            } else {
                if (_tickets > MAX_TICKETS_TRANSACTIONS) {
                    result = 3;
                } else {
                    if (amount > yieldmarket.getCash()) {
                        result = 4;
                    } else {
                        if (block.number <= blockdeposits[_account]) {
                            result = 5;
                        }
                    }
                }   
            }                        
        }   

        return result;
    }


    // Check balance of compounded prizes to cash out

    function _checkmatureprizecashout(address _account) internal view returns (uint) {
        uint balanceprize = balancecompoundplayeractual[_account];
        if (cycleprizeplayer[_account] <= dividendscyclecounter) {
            balanceprize += balancecompoundplayernext[_account];
        }

        return balanceprize;
    }

    
    // Check withdraw of liquidity providers and subsidiary depositors
    // _flag 1 = Liquidity Providers
    // _flag 2 = Cash out compound balance
    // _flag 3 = Cash out subsidiary balance
    // _flag 4 = Cash out compound prize balance

    function checkwithdrawsponsor(uint _amount, address _account, uint _flag) external view returns (uint) {
         
        uint result = 0;
        
        if (_amount > balancesponsors[_account] && _flag == 1) {
            result = 1;
        } else {
            if (_amount > balancecompound[_account] && _flag == 2) {
                result = 2;
            } else {
                if (_amount > balancesubsidy[_account] && _flag == 3) {    
                    result = 5;
                } else {
                    if (_amount > _checkmatureprizecashout(_account) && _flag == 4) {
                        result = 6;
                    } else {       
                        if (_amount > yieldmarket.getCash()) {
                            result = 3;
                        } else {
                            if (block.number <= blockdeposits[_account] && _flag == 1) {
                                result = 4;
                            }
                        }
                    }   
                }
            } 
        }   

        return result;
    }


    // Returns potshares balance available to harvest and voting power available to vote

    function _checkmaturerewards(address _account, uint _balanceactual, uint _balancenext) internal view returns (uint) {

        uint maturepoints = _balanceactual;

        if (cycledividendsnext[_account] <= dividendscyclecounter) {
            maturepoints += _balancenext;
        }

        if (startTime[_account] <= investorvaluetime) {
            uint matured = _calculateYieldTotal(_account, investorvaluetime);
            maturepoints += matured;
        }

        return maturepoints;
    }


    // Check harvest potshares

    function checkharvestrewards(address _account) external view returns (uint) {
        
        uint result = 0;
        
        if (block.timestamp - investorvaluetime >= HARVEST_TIME) {
            result = 1;
        } else {
            if (_checkmaturerewards(_account, balancerewardsactual[_account], balancerewardsnext[_account]) == 0) {  
                result = 2;
            }
        } 
        
        return result;
    }


    // Check dividends claims to compound
    
    function checkwithdrawrewards(address _account) external view returns (uint) {
        
        uint result = 0;
    
        if (balancerewardsmature[_account] == 0) {
            result = 1;
        } else {
            if (investorvalue == 0) {
                result = 2;
            } else {
                if (block.timestamp - investorvaluetime <= HARVEST_TIME) {   
                    result = 3;
                }
            }
            
        }
        
        return result;
    }


    // Check add a new proposal

    function checkaddproposal(uint _amount, address _account) external view returns (uint) {
        
        uint result = 0;
        uint activeproposal;

        if (proposals.length > 0 && proposals[proposals.length - 1].status == 0) {
		    activeproposal = 1;
        }

        if (activeproposal == 1) {
            result = 1;
        } else {
            if (_checkmaturerewards(_account, votingpoweractual[_account], votingpowernext[_account]) == 0) {  
                result = 2;
            } else {
                if (_amount > reserveavailable) {
                    result = 3;
                }
            }
        }
                
        return result;
    }


    // Check vote proposal

    function checksignproposal(address _account, uint _index) external view returns (uint) {
        
        uint result = 0;
        
        if (proposals.length == 0 || (proposals.length > 0 && _index > proposals.length - 1)) {
            result = 1;
        } else {
            if (proposals[_index].status > 0) {
                result = 2;
            } else {
                if (block.timestamp >= proposals[_index].dateend) {
                    result = 3;
                } else {
                    if (signatures[_account][_index] > 0) {
                        result = 4;
                    } else {
                        if (_checkmaturerewards(_account, votingpoweractual[_account], votingpowernext[_account]) == 0) {
                            result = 5;
                        }
                    }
                }
            }
        }
                       
        return result;
    }


    // Check close proposal

    function checkclosevotation(uint _index) external view returns (uint) {
        
        uint result = 0;
        
        if (proposals.length == 0 || (proposals.length > 0 && _index > proposals.length - 1)) {
            result = 1;
        } else {
            if (proposals[_index].status > 0) {
                result = 2;
            } else {
                if (block.timestamp <= proposals[_index].dateend) {
                    result = 3;
                }
            }
        }
    
        return result;
    }


    // Calculates potshares and voting power of liquidity providers and players

    function _calculateYieldTotal(address _user, uint _end) internal view returns (uint) {
        
        uint256 time = (_end - startTime[_user]) * 10 ** decimalstoken;
        uint256 rate = YIELD_RATE;
        uint256 timeRate = time / rate;
        uint rawYield1 = ((balancesponsors[_user] + balancecompound[_user]) * timeRate) / 10 ** decimalstoken;
        uint rawYield2 = ((balanceplayers[_user] + balancecompoundplayer[_user]) * timeRate) / 10 ** decimalstoken;
        rawYield2 = (rawYield2 * (10 * 10 ** decimalstoken / 100)) / 10 ** decimalstoken;

        return (rawYield1 + rawYield2);
    }     
    

    // Harvest potshares
    
    function harvestRewards() external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS && block.timestamp - investorvaluetime < HARVEST_TIME);
        
        _accrueRewards(msg.sender);

        require(balancerewardsactual[msg.sender] > 0);
        
        balancerewardsmature[msg.sender] += balancerewardsactual[msg.sender];
        balancerewards[msg.sender] -= balancerewardsactual[msg.sender];
        balancerewardspool += balancerewardsactual[msg.sender];
        balancerewardsactual[msg.sender] = 0;
    }


    // Claim Dividends to compound
        
    function withdrawRewards() external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS && balancerewardsmature[msg.sender] > 0 && 
	    investorvalue > 0 && block.timestamp - investorvaluetime > HARVEST_TIME);

        _accrueRewards(msg.sender);

        uint totransfer = balancerewardsmature[msg.sender];
        balancerewardsmature[msg.sender] = 0;
        uint participation = totransfer * 100 * 10 ** decimalstoken / (balancerewardspool);
        uint transferunderlying = (investorvalue * (participation) / 100) / 10 ** decimalstoken;
        
        investorvalue -= transferunderlying;
        balancerewardspool -= totransfer;
        
        balancecompound[msg.sender] += transferunderlying;
        balancepoolcompound += transferunderlying;

        investorspaid[msg.sender] += transferunderlying;
        investorspaidpool += transferunderlying;

        rewardscollected[msg.sender] += totransfer; 
        rewardscollectedpool += totransfer; 
    }
 

    // Adds new proposal
    // _transtype 1 = tranfer reserves to next pot prize
    // _transtype 2 = transfer reserves to next dividends distribution

    function addProposal(uint _amount, uint _transtype) external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS && (_transtype == 1 || _transtype == 2) && _amount > 0);
        require(reserveavailable >= _amount);

        if (proposals.length > 0) {
		    require(proposals[proposals.length - 1].status > 0); 
 	    }

        _accrueRewards(msg.sender);

        require(votingpoweractual[msg.sender] > 0);
	    
        uint powertovote = votingpoweractual[msg.sender];
        votingpower[msg.sender] -= votingpoweractual[msg.sender];
        votingpoweractual[msg.sender] = 0;

        proposals.push(Proposal(block.timestamp, msg.sender, investorvaluetime, _transtype, _amount, block.timestamp + VOTING_TIME, 
        0, 1, 0, powertovote, 0, 0));

        signatures[msg.sender][proposals.length - 1] = 1;
        voterlist[proposals.length - 1].push(Voter(msg.sender, 1, powertovote));
    }


    // Vote proposal
    // _flag 1 = YES
    // _flag 2 = NO

    function signProposal(uint _index, uint _flag) external nonReentrant {
        require(proposals.length > 0 && msg.sender != EMPTY_ADDRESS && _index <= proposals.length - 1);
        require(_flag == 1 || _flag == 2);

        Proposal storage voting = proposals[_index];

        _accrueRewards(msg.sender);

        require(voting.status == 0 && block.timestamp < voting.dateend && signatures[msg.sender][_index] == 0);
        require(votingpoweractual[msg.sender] > 0);

        signatures[msg.sender][_index] = 1;

        uint powertovote = votingpoweractual[msg.sender];
        votingpower[msg.sender] -= votingpoweractual[msg.sender];
        votingpoweractual[msg.sender] = 0;

        voterlist[_index].push(Voter(msg.sender, _flag, powertovote));
	    
        if (_flag == 1) {
        voting.signaturesCountYES += 1;
        voting.signaturesweightYES += powertovote;
        }

        if (_flag == 2) {
        voting.signaturesCountNO += 1;
        voting.signaturesweightNO += powertovote;
        }
    }


    // Close Proposal

    function closeVotation(uint _index) external nonReentrant {
        require(proposals.length > 0 && msg.sender != EMPTY_ADDRESS && _index <= proposals.length - 1);
        
        Proposal storage voting = proposals[_index];

        require(voting.status == 0 && block.timestamp > voting.dateend);
        
        voting.dateexecution = block.timestamp;

        if (voting.signaturesCountYES > voting.signaturesCountNO && 
            voting.signaturesweightYES > voting.signaturesweightNO) {

            if (reserveavailable < voting.amount) {
                voting.status = 3;
            } else {

                reserveavailable -= voting.amount;

                voting.status = 1;

                if (voting.transtype == 1) {
                    reservesjackpot += voting.amount;    
                }

                if (voting.transtype == 2) {
                    reservesdividends += voting.amount;    
                }
            }

        } else {
            voting.status = 2;
        }
    }

   // Returns an array of proposals

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }


    // Returns an array of struct of voters
    
    function getVoterList(uint _index) external view returns (Voter[] memory) {
        return voterlist[_index];
    }


     // Returns the length of the array of lottery results
    
    function getLotteryResultsLength() external view returns (uint) {
        return lotteryresults.length;
    }

}