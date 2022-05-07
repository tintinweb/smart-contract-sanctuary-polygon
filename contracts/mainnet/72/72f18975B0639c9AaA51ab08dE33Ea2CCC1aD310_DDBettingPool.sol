/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface DDDataBase {/*DDDataBase = is the contract where DubbleDapp Users and their Referrals are tracked for "cross-contract referral linking". 
    Basically, your Referrals will be your Referrals for all of DubbleDapps games and any future contracts released by interacting with the DDDatabase contract*/
    function checkUser(address,address) external returns(address);
}
interface IERC20 {/*IERC20 = the ERC20 Token Standard contract interface for interacting with ERC20 Tokens*/
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface CERC20 {/*CERC20 = the CERC20 Token Standard contract interface for interacting with CERC20 Tokens (a.k.a. Cream Tokens, but could also be Aave, Compound, Venus, etc.)*/
    function balanceOfUnderlying(address owner) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IUniswapV2Router {/*IUniswapV2Router = the Token Swap Router interface for swapping our Token for more LINK Token (meant to automate resupplying LINK for VRF Requests)*/
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
} 
interface IUniswapV2Pair {/*IUniswapV2Pair = the Token Swap Pairing interface for swapping our Token for more LINK Token (meant to automate resupplying LINK for VRF Requests)*/
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}
interface IUniswapV2Factory {/*IUniswapV2Factory = the Token Swap Factory interface for swapping our Token for more LINK Token (meant to automate resupplying LINK for VRF Requests)*/
    function getPair(address token0, address token1) external returns (address);
}
interface Pegger {/*Pegger = the Peg Swap interface for swapping LINK Token for more wLINK Token (meant to automate resupplying LINK for VRF Requests)*/
    function swap(uint256,address,address) external;
}
library SafeMathChainlink {/*SafeMathChainlink = the safeMath functions used by the VRF Coordinator*/
  function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;require(c >= a, "SafeMath: addition overflow");return c;}
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {require(b <= a, "SafeMath: subtraction overflow");uint256 c = a - b;return c;}
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;}
  function div(uint256 a, uint256 b) internal pure returns (uint256) {require(b > 0, "SafeMath: division by zero");uint256 c = a / b;return c;}
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {require(b != 0, "SafeMath: modulo by zero");return a % b;}
}
interface LinkTokenInterface {/*The LINK Token Interface = for interacting with LINK Token directly*/
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}
contract VRFRequestIDBase {
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}
abstract contract VRFConsumerBase is VRFRequestIDBase {/*VRFConsumerBase = is the contract interface we must use to interact with the Chainlink VRF Coordinator*/
  using SafeMathChainlink for uint256;
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;
  uint256 private constant USER_SEED_PLACEHOLDER = 0;
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }
  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}
contract DDBettingPool is VRFConsumerBase {
/*[ CONTRACT ADDRESSES ]----------------------------------------------------------------------------------------------------------------*/
    address public blank = address(0x0000000000000000000000000000000000000000);         /* A blank Address                              */
    address public developer;                                                           /* Development Teams Address                    */
    address public base_addy;                                                           /* DDDataBase contract Address                  */
    address public wNATIVE_addy;                                                        /* wNATIVE Token Contract Address               */
    address public LINK_addy;                                                           /* LINK Token Contract Address                  */
    address public wLINK_addy;                                                          /* Chainlink VRF LINK token                     */
    address public VFRC_addy;                                                           /* Chainlink VRF Coordinator                    */
    address public Router_addy;                                                         /* DEX Routing Address                          */
    address public Pegger_addy;                                                         /* PegSwap Routing Address                      */
/*[ POOL SPECIFIC VARIABLES ]-----------------------------------------------------------------------------------------------------------*/
    address public TOKENaddy;                                                           /* TOKEN address                                */
    address public cTOKENaddy;                                                          /* cTOKEN address                               */
    uint256 public decimals;                                                            /* The Tokens Decimal format                    */
    uint256 public minimumBet;                                                          /* The Minimum Amount of Tokens a User can Bet  */
    bytes32 public tokenName;                                                           /* TOKEN name                                   */
    uint256 public loseRestrict = 900;                              /* Bet Restriction after Losing (in seconds)                        */
    uint256 public winRestrict = 3600;                              /* Bet Restriction after Winning (in seconds)                       */
    uint256 public withdrawRestrict = 86400;                        /* Bet Restriction after Withdrawing (in seconds)                   */
    uint256 public safeTnet = 100;                                  /* The minimum threshold before more wLINK is purchased             */
    uint256 public swapAmt;                                         /* The amount of Tokens to be swapped into wLINK                    */
/*[ CHAINLINK VARIABLES ]---------------------------------------------------------------------------------------------------------------*/
    uint256 internal LINK_fee;                                      /* LINK fee to use the VRF service                                  */
    bytes32 internal keyHash;                                       /* For final VRF step                                               */ 
/*[ USER VARIABLES ]--------------------------------------------------------------------------------------------------------------------*/
    mapping(address => uint) public UID;                            /* Each users assigned ID number                                    */
    mapping(address => bool) public isUser;                         /* Wether a User exists                                             */
    mapping(address => address) public usersReferrer;               /* Address of a Users Referrer                                      */
    address[] public userID;                                        /* [UID] = A Users address in relation to their ID                  */
    uint256[] public usersBalance;                                  /* [UID] = The Total Tokens a User has in the Contract              */
    uint256[] public usersTimeLimit;                                /* [UID] = When a User can Bet again (unix timestamp)               */
    uint256[] public totalWins;                                     /* [UID] = The Total Number of times a User has Won a Bet           */
    uint256[] public totalLosses;                                   /* [UID] = The Total Number of times a User has Lost a Bet          */
    uint256[] public totalEarnings;                                 /* [UID] = The Total a User has Earned Altogether                   */
    uint256[] public totalWinnings;                                 /* [UID] = The Total a User has Earned from Bets                    */
    uint256[] public totalCompensations;                            /* [UID] = The Total a User has Earned in Caller Compensations      */
    uint256[] public totalCommissions;                              /* [UID] = The Total a User has Earned in Referral Commissions      */
    uint256[] public lastDeposit;                                   /* [UID] = UNIX Timestamp of last Deposit                           */
    bytes32[] public lastReqID;                                     /* [UID] = The Last Request ID made by a User                       */
    uint256[] public lastBetID;                                     /* [UID] = The Last Bet ID made by a User                           */
    uint256[] public betPending;                                    /* [UID] = Wether a Bet is still waiting on results                 */
    uint256[][] public myBets;                                      /* [UID][I] = An Array of a User's Bet BID's                        */
    uint256[][] public myWins;                                      /* [UID][I] = An Array of a User's WON Bet BID's                    */
/*[ CONTRACT VARIABLES ]----------------------------------------------------------------------------------------------------------------*/
    bool public reentrantLock;                                      /* Wether the Reentrancy Lock is in Place                           */
    uint256 public totalPaidout;                                    /* Total Amount of Tokens Paidout to Users                          */
    uint256 public totalOnHold;                                     /* Total Amount of Tokens Held for pending Results                  */
    uint256 public totalDeposited;                                  /* Total Amount Deposited into the Protocol                         */
    uint256 public totalReserved;                                   /* Total Amount Reserved for continued growth                       */
    uint256 public totalInsured;                                    /* Total Amount Insured in the Contract itself                      */
    uint256 public totalWinners;                                    /* Total Number of Times Users have Won                             */
    uint256[] public allWins;                                       /* [I] = An Array of Won Bet BetID's                                */
    uint256 public lastBID = 1;                                     /* Last Bet ID created                                              */
    uint256 public lastUID = 0;                                     /* Last User ID created                                             */
    uint256 public lastRelease;                                     /* The last UNIX Timestamp that a Balance was Released              */
/*[ DRAW VARIABLES ]--------------------------------------------------------------------------------------------------------------------*/
    mapping(bytes32 => bool) public isReqID;                        /* Wether a ReqID exists                                            */
    mapping(bytes32 => uint256) public reqBID;                      /* A ReqID in relation to the BettingID its located at              */
    bytes32[] public betReqId;                                      /* [RID] = The RequestID for a specific Bet that was Placed         */  
    uint256[] public bettorsID;                                     /* [BID] = The Bettors UID when they Placed a Bet                   */
    address[] public bettorsAddy;                                   /* [BID] = The Bettors Address when they Placed a Bet               */
    uint256[] public bettorsBet;                                    /* [BID] = The Amount the Bettor Placed on a Bet                    */
    uint256[] public bettorsNum;                                    /* [BID] = The Number the Bettor Bet On (1 to 100)                  */
    uint256[] public bettorsSeed;                                   /* [BID] = The Seed Provided on a Placed Bet                        */
    uint256[] public betPayout;                                     /* [RID] = The Amount that will be awarded if the Bettor Wins       */
    uint256[] public betTimestamp;                                  /* [BID] = The UNIX Timestamp of when a Bet was Placed Bet          */
    uint256[] public betResponse;                                   /* [BID] = Chainlinks Response to a Placed Bet                      */
    uint256[] public betModdResult;                                 /* [BID] = Modified Result to fit within our desired range (100)    */
    uint256[] public bettorsReward;                                 /* [BID] = The Amount Rewarded to the Bettor of a Placed Bet        */
/*[ EVENTS ]----------------------------------------------------------------------------------------------------------------------------*/
    event Deposit(address indexed user,uint256 indexed amount,uint256 indexed time);/*                                                  */
    event Withdraw(address indexed user,uint256 indexed amount,uint256 indexed time);/*                                                 */
    event Donate(address indexed user,uint256 indexed method,uint256 amount,uint256 indexed time);/*                                    */
    event Bet(address indexed user,uint256 indexed bID,uint256 indexed time);/*                                                         */
    event Result(address indexed user,uint256 indexed bID,uint256 indexed time);/*                                                      */
/*[ DATA STRUCTURES ]-------------------------------------------------------------------------------------------------------------------*/
    struct varData {/*                                                                                                                  */
        address ref;address addy;uint256 uID;uint256 rID;uint256 tID;uint256 pID;uint256 bID;uint256 cost;uint256 cont;uint256 farm;/*  */
        uint256 amt;uint256 fee;uint256 req;/*                                                                                          */
    }/*                                                                                                                                 */
/*[ CONSTRUCTORS ]----------------------------------------------------------------------------------------------------------------------*/
    constructor(
        address _base_addy,
        address _wNATIVE_addy,
        address _LINK_addy,
        address _wLINK_addy,
        address _VFRC_addy,
        address _Router_addy,
        address _Pegger_addy,
        address _TOKENaddy,
        address _cTOKENaddy,
        uint256 _decimals,
        uint256 _minimumBet,
        bytes32 _tokenName,
        uint256 _swapAmt,
        uint256 _LINK_fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_VFRC_addy, _wLINK_addy) {
        /*CREATE THIS POOLS VARIABLES*/
        developer = msg.sender;
        base_addy = _base_addy;
        wNATIVE_addy = _wNATIVE_addy;
        LINK_addy = _LINK_addy;
        wLINK_addy = _wLINK_addy;
        VFRC_addy = _VFRC_addy;
        Router_addy = _Router_addy;
        Pegger_addy = _Pegger_addy;
        TOKENaddy = _TOKENaddy;
        cTOKENaddy = _cTOKENaddy;
        decimals = _decimals;
        minimumBet = _minimumBet;
        tokenName = _tokenName;
        swapAmt = _swapAmt;
        LINK_fee = _LINK_fee;
        keyHash = _keyHash;
        /*CREATE THE DEVELOPERS ACCOUNT*/
        isUser[developer] = true;
        UID[developer] = 0;
        userID.push(developer);
        usersBalance.push(0);
        usersTimeLimit.push(0);
        totalWins.push(0);
        totalLosses.push(0);
        totalEarnings.push(0);
        totalWinnings.push(0);
        totalCompensations.push(0);
        totalCommissions.push(0);
        lastDeposit.push(0);
        lastReqID.push(tokenName);
        lastBetID.push(0);
        betPending.push(0);
        myBets.push([0]);
        myWins.push([0]);
        /*CREATE A BLANK/BASE BET RECORD*/
        betReqId.push(tokenName);
        bettorsID.push(0);
        bettorsAddy.push(blank);
        bettorsBet.push(0);
        bettorsNum.push(0);
        bettorsSeed.push(0);
        betPayout.push(0);
        betTimestamp.push(0);
        betResponse.push(0);
        betModdResult.push(0);
        bettorsReward.push(0);
        allWins.push(0);
    }
/*[ MODIFIERS ]-------------------------------------------------------------------------------------------------------------------------*/
    modifier noReentrant() {require(!reentrantLock,'Nope');reentrantLock = true;_;reentrantLock = false;}/*                             */
    modifier onlyVFRC() {require(msg.sender == VFRC_addy,'NotVFRC');_;}/*                                                               */
/*[ SAFEMATH FUNCTIONS ]----------------------------------------------------------------------------------------------------------------*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a*b;assert(a == 0 || c / a == b);return c;}/*       */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b;return c;}/*                                  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a);return a - b;}/*                                 */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;assert(c >= a);return c;}/*                   */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}/*                                                */
/*[ DATE/TIME FUNCTIONS ]---------------------------------------------------------------------------------------------------------------*/
    function checkTime() public view returns(uint256) {uint256 time = block.timestamp;return(time);}/*                                  */
/*[ BASIC FUNCTIONS ]-------------------------------------------------------------------------------------------------------------------*/
    function deposit(address _link,uint256 _amt) external noReentrant {varData memory dat;
        /*Will deposit any amount above the minimum specified by the contract*/
        if(_amt<minimumBet){dat.cont = 0;}else{dat.cont = 1;}
        if(IERC20(TOKENaddy).balanceOf(msg.sender)<_amt){dat.cont = 0;}
        if(IERC20(TOKENaddy).allowance(msg.sender,address(this))<_amt){dat.cont = 0;}
            require(dat.cont == 1,"ContErr");
        /*Check isUser*/
        if(isUser[msg.sender]){
            dat.tID = UID[msg.sender];
            dat.ref = usersReferrer[msg.sender];
        }else{
            lastUID = add(lastUID,1);
            dat.tID = lastUID;
            UID[msg.sender] = lastUID;
            isUser[msg.sender] = true;
            userID.push(msg.sender);
            usersBalance.push(0);
            usersTimeLimit.push(0);
            totalWins.push(0);
            totalLosses.push(0);
            totalEarnings.push(0);
            totalWinnings.push(0);
            totalCompensations.push(0);
            totalCommissions.push(0);
            lastDeposit.push(0);
            lastReqID.push(tokenName);
            lastBetID.push(0);
            betPending.push(0);
            myBets.push([0]);
            myWins.push([0]);
            dat.ref = DDDataBase(base_addy).checkUser(msg.sender,_link);
            if(dat.ref == blank){/*User was NOT referred, skip ahead*/}else
            if(!isUser[dat.ref]) {/*Referrer does NOT exist, Create an Account for them*/
                isUser[dat.ref] = true;
                lastUID = add(lastUID,1);
                UID[dat.ref] = lastUID;
                userID.push(dat.ref);
                usersBalance.push(0);
                usersTimeLimit.push(0);
                totalWins.push(0);
                totalLosses.push(0);
                totalEarnings.push(0);
                totalWinnings.push(0);
                totalCompensations.push(0);
                totalCommissions.push(0);
                lastDeposit.push(0);
                lastReqID.push(tokenName);
                lastBetID.push(0);
                betPending.push(0);
                myBets.push([0]);
                myWins.push([0]);
            }else{/*Referrer DOES exist, do nothing*/}
            usersReferrer[msg.sender] = dat.ref;
        }
        /*UPDATE USER*/
        usersBalance[dat.tID] = add(usersBalance[dat.tID],_amt);
        lastDeposit[dat.tID] = block.timestamp;
        /*UPDATE CONTRACT*/
        totalDeposited = add(totalDeposited,_amt);
        /*DEPOSIT INTO CONTRACT*/
        require(IERC20(TOKENaddy).transferFrom(msg.sender,address(this),_amt),"DepFail");
        /*APPROVE & SUPPLY TO PROTOCOL*/
        IERC20(TOKENaddy).approve(address(CERC20(cTOKENaddy)), _amt);
        assert(CERC20(cTOKENaddy).mint(_amt) == 0);
        /*EMIT EVENT*/
        emit Deposit(msg.sender,_amt,block.timestamp);
    }
    function withdraw() external noReentrant {varData memory dat;
        /*Will withdraw any earnings plus your Deposit you have from the contract*/
        /*Can NOT Bet in this contract again for 24 hours if you withdraw*/ 
        require(isUser[msg.sender],'NotUsr');
            dat.tID = UID[msg.sender];dat.req = 0;dat.cont = 1;
            dat.amt = usersBalance[dat.tID];
        if(dat.amt<1){dat.cont = 0;}
            dat.farm = CERC20(cTOKENaddy).balanceOfUnderlying(address(this));
        if(dat.amt>dat.farm){dat.req = 2;if(dat.amt>totalInsured){dat.cont = 0;}}else{dat.req = 1;}
        if(block.timestamp < add(lastDeposit[dat.tID],60)){dat.cont = 0;}
        require(dat.cont == 1,"ContErr");
        /*UPDATE USER*/
        usersBalance[dat.tID] = 0;
        usersTimeLimit[dat.tID] = add(block.timestamp,withdrawRestrict);
        /*UPDATE CONTRACT*/
        totalDeposited = sub(totalDeposited,dat.amt); 
        if(dat.req == 1){/*WITHDRAW FROM PROTOCOL*/assert(CERC20(cTOKENaddy).redeemUnderlying(dat.amt) == 0);}
        else{/*DEDUCT FROM INSURED FUNDS*/totalInsured = sub(totalInsured,dat.amt);}
        /*WITHDRAW FROM CONTRACT*/
        require(IERC20(TOKENaddy).transfer(msg.sender,dat.amt), "TxnFai");
        /*EMIT EVENT*/
        emit Withdraw(msg.sender,dat.amt,block.timestamp);
    }
    function donate(uint256 _amt, uint256 _meth) external noReentrant {varData memory dat;
        /*Donate tokens directly into a particular balance*/ 
        /*Can be called by ANY Address for any reason*/
        /*Initially used for injecting startup funds*/
        if((_amt < 1)||(_meth < 1)||(_meth > 3)){dat.cont = 0;}else{dat.cont = 1;}
        if(IERC20(TOKENaddy).balanceOf(msg.sender) < _amt){dat.cont = 0;}
        if(IERC20(TOKENaddy).allowance(msg.sender,address(this)) < _amt){dat.cont = 0;}
            require(dat.cont == 1,"ContErr");
        /*DEPOSIT INTO CONTRACT*/
        require(IERC20(TOKENaddy).transferFrom(msg.sender,address(this),_amt),"DepFail");
        if(_meth == 1){/*Donate into Current Yield*/
            /*APPROVE & SUPPLY TO PROTOCOL*/
            IERC20(TOKENaddy).approve(address(CERC20(cTOKENaddy)), _amt);
            assert(CERC20(cTOKENaddy).mint(_amt) == 0);
        }else
        if(_meth == 2){/*Donate into Reserved*/
            totalReserved = add(totalReserved,_amt);
            /*APPROVE & SUPPLY TO PROTOCOL*/
            IERC20(TOKENaddy).approve(address(CERC20(cTOKENaddy)), _amt);
            assert(CERC20(cTOKENaddy).mint(_amt) == 0);
        }else
        if(_meth == 3){/*Donate into Insured*/
            totalInsured = add(totalInsured,_amt);
        }
        emit Donate(msg.sender,_meth,_amt,block.timestamp);
    }
    function bet(uint256 _amt,uint256 _num,uint256 _seed) external noReentrant returns (bool) {varData memory dat;
        /*Initiates a Users Bet*/ 
        require(isUser[msg.sender],'NotUsr');
            dat.tID = UID[msg.sender];dat.cont = 1;
        if(_seed == 0){_seed = block.timestamp;}
        /*CHECK if Bet still Pending*/
        if(betPending[dat.tID] == 1){uint256 iD = lastBetID[dat.tID];if(betModdResult[iD]<1){dat.cont = 0;}else{betPending[dat.tID] = 0;}}
        /*CHECK _num to BET ON*/
        if((_num<1)||(_num>100)){dat.cont = 0;}
        /*CHECK BET _amt*/
        if(_amt<minimumBet){dat.cont = 0;}
        if(_amt>usersBalance[dat.tID]){dat.cont = 0;}
        /*CHECK YIELD STATUS*/
        dat.req = _amt;
        dat.amt = CERC20(cTOKENaddy).balanceOfUnderlying(address(this));
        dat.farm = add(totalDeposited,totalReserved);
        require(dat.amt>dat.farm,"ContErr");
        dat.amt = sub(dat.amt,dat.farm);
        if(dat.amt<dat.req){dat.cont = 0;}dat.amt = dat.req;
        /*CHECK for ANY TIME RESTRICTIONS*/
        if(block.timestamp<usersTimeLimit[dat.tID]){dat.cont = 0;}
        /*Release 10% of Reserved AND Insured balances once every 30 day period*/
        if(add(lastRelease,(30 days)) <= block.timestamp){
            if(totalReserved >= 10){/*Release 10% of Reserved into Yield*/ totalReserved = sub(totalReserved,div(totalReserved,10));}
            if(totalInsured >= 10){/*Release 10% from Insured and place into Yield, but ONLY if totalInsured is more than twice what is Deposited*/
                if(totalInsured > mul(totalDeposited,2)){
                uint256 reqq2 = div(totalInsured,10);
                    totalInsured = sub(totalInsured,reqq2);
                    IERC20(TOKENaddy).approve(address(CERC20(cTOKENaddy)),reqq2);
                    assert(CERC20(cTOKENaddy).mint(reqq2) == 0);
                }
            }
            lastRelease = block.timestamp;
        }  
        /*CHECK wLINK BALANCE*/
        uint256 bal  =  IERC20(wLINK_addy).balanceOf(address(this));
        uint256 needed = LINK_fee * safeTnet;
        if(bal <= needed){
            /*Pulls funding from the Insured balance, then swaps it into LINK, then Pegs it to wLINK*/
            if((IERC20(TOKENaddy).balanceOf(address(this)) < swapAmt)||(totalInsured < swapAmt)){dat.cont = 0;}
            require(dat.cont == 1,"ContErr");
            IERC20(TOKENaddy).approve(Router_addy, swapAmt);
            totalInsured = sub(totalInsured,swapAmt);
            address[] memory path;
            if(TOKENaddy == wNATIVE_addy){
                path = new address[](2);
                path[0] = TOKENaddy;
                path[1] = LINK_addy;
            }else{
                path = new address[](3);
                path[0] = TOKENaddy;
                path[1] = wNATIVE_addy;
                path[2] = LINK_addy;
            }
            uint256[] memory amountOutMins = IUniswapV2Router(Router_addy).getAmountsOut(swapAmt, path);
            uint256 _amountOutMin = amountOutMins[path.length -1];
            IUniswapV2Router(Router_addy).swapExactTokensForTokens(swapAmt, _amountOutMin, path, address(this), block.timestamp);
            /*Make sure we actually received some LINK Tokens*/
            bal = IERC20(LINK_addy).balanceOf(address(this));
            require(bal > 0,"No LINK");
            IERC20(LINK_addy).approve(Pegger_addy, bal);
            Pegger(Pegger_addy).swap(bal, LINK_addy, wLINK_addy);
            /*Make sure we actually received some wLINK Tokens*/
            bal = IERC20(wLINK_addy).balanceOf(address(this));
            require(bal > 0,"No wLINK");
        }
        if(bal < LINK_fee){dat.cont = 0;}
        require(dat.cont == 1,"ContErr");
        /*PULL AMOUNT FROM POOL (prevent others from betting for the same Yield)*/
        totalDeposited = add(totalDeposited,dat.amt);
        totalOnHold = add(totalOnHold,dat.amt);
        /*CREATE THIS BETS RECORD*/
        bettorsID.push(dat.tID);
        bettorsAddy.push(msg.sender);
        bettorsBet.push(_amt);
        bettorsNum.push(_num);
        bettorsSeed.push(_seed);
        betPayout.push(dat.amt);
        betTimestamp.push(block.timestamp);
        betResponse.push(0);
        betModdResult.push(0);
        bettorsReward.push(0);
        dat.bID = lastBID;
        lastBID = add(lastBID,1);
        bytes32 requestId = getRandomNumber(_seed);
        isReqID[requestId] = true;
        reqBID[requestId] = dat.bID;
        betReqId.push(requestId);
        lastReqID[dat.tID] = requestId;
        lastBetID[dat.tID] = dat.bID;
        /*EMIT EVENT*/
        emit Bet(msg.sender,dat.bID,block.timestamp);
        return true;
    }
    function getRandomNumber(uint256 _seed) internal returns (bytes32 requestId) {
        /*Called from within the Bet Function*/ 
        require(LINK.balanceOf(address(this)) >= LINK_fee,"NoLINK");
        return requestRandomness(keyHash,LINK_fee,_seed);
    }
    function fulfillRandomness(bytes32 _reqId, uint256 randomness) internal override onlyVFRC {varData memory dat;
        /*Response back from Chainlink Oracles: 
        Will contain the randomized number that was sent back, anywhere between 0 and (a full uint256 integer, which is:
        1,157,920,900,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000 ).
        That number is then divided by 100, and the remainder (modulus) is the winning number.
        If the remainder is "0"(zero), then it is essentially the number "100" because it divided evenly*/
        /*  IF YOU WIN: 100.00% of the Bet will be Your Reward!
            IF YOU LOSE, only 2.03% of the Bet will be distributed:
                1.00% => Reserves (Compounded)
                1.00% => Insurance (Secured)
                0.01% => Your Gas Compensation
                0.01% => Your Referrer
                0.01% => Development Team
                97.97% => Is Left Alone as Yield
        */ 
        uint256 _rand = randomness; uint256 modul = 0;address Raddy = blank;
        if(isReqID[_reqId]){
            dat.bID = reqBID[_reqId];
            betResponse[dat.bID] = _rand;
            /*MODULATE THE NUMBER WITHIN OUR DESIRED RANGE: 1-100 */
            if(_rand <= 100){modul = _rand;}else{modul = mod(_rand,100);}
            if(modul <= 0){modul = 100;}
            betModdResult[dat.bID] = modul;
            dat.uID = bettorsID[dat.bID];
            betPending[dat.uID] = 0;
            myBets[dat.uID].push(dat.bID);
            uint256 jackpot = betPayout[dat.bID];
            if(modul == bettorsNum[dat.bID]){
                /*USER WON BET - 100% of Bet is won */
                allWins.push(dat.bID);
                myWins[dat.uID].push(dat.bID);
                totalWinners = add(totalWinners,1);
                totalWins[dat.uID] = add(totalWins[dat.uID],1);
                usersTimeLimit[dat.uID] = add(block.timestamp,winRestrict);
                /*Reward Bettor with the entire Bet = 100%*/
                usersBalance[dat.uID] = add(usersBalance[dat.uID],jackpot);
                totalWinnings[dat.uID] = add(totalWinnings[dat.uID],jackpot);
                totalEarnings[dat.uID] = add(totalEarnings[dat.uID],jackpot);
                totalPaidout = add(totalPaidout,jackpot);
                        bettorsReward[dat.bID] = jackpot;
            }else{
                /*USER LOST BET - 2.03% is given out and 97.97% is released back into the Protocol */
                uint256 leftover = jackpot;
                dat.fee = div(jackpot,10000);
                totalLosses[dat.uID] = add(totalLosses[dat.uID],1);
                usersTimeLimit[dat.uID] = add(block.timestamp,loseRestrict);
                /*Update the Reserved Balance with + 1.00% */
                dat.amt = mul(dat.fee,100);leftover = sub(leftover,dat.amt);
                totalReserved = add(totalReserved,dat.amt);
                totalDeposited = sub(totalDeposited,dat.amt);
                /*Update the Insured Balance with + 1.00% */
                leftover = sub(leftover,dat.amt);
                totalInsured = add(totalInsured,dat.amt);
                totalDeposited = sub(totalDeposited,dat.amt);
                assert(CERC20(cTOKENaddy).redeemUnderlying(dat.amt) == 0);
                /*Reward Bettor with some gas compensation of + 0.01% */
                leftover = sub(leftover,dat.fee);
                usersBalance[dat.uID] = add(usersBalance[dat.uID],dat.fee);
                totalCompensations[dat.uID] = add(totalCompensations[dat.uID],dat.fee);
                totalEarnings[dat.uID] = add(totalEarnings[dat.uID],dat.fee);
                totalPaidout = add(totalPaidout,dat.fee);
                        bettorsReward[dat.bID] = dat.fee;
                /*Reward Bettors Referrer their share of + 0.01%*/
                dat.addy = userID[dat.uID];
                Raddy = usersReferrer[dat.addy];
                if(Raddy != blank){
                    dat.rID = UID[Raddy];
                    leftover = sub(leftover,dat.fee);
                    usersBalance[dat.rID] = add(usersBalance[dat.rID],dat.fee);
                    totalCommissions[dat.rID] = add(totalCommissions[dat.rID],dat.fee);
                    totalEarnings[dat.rID] = add(totalEarnings[dat.rID],dat.fee);
                    totalPaidout = add(totalPaidout,dat.fee);
                }else{/*No Referrer, direct into Yield*/}
                /*Reward Development Team with their share of + 0.01% */
                leftover = sub(leftover,dat.fee);
                usersBalance[0] = add(usersBalance[0],dat.fee);
                totalCommissions[0] = add(totalCommissions[0],dat.fee);
                totalEarnings[0] = add(totalEarnings[0],dat.fee);
                totalPaidout = add(totalPaidout,dat.fee);
                /*Release 97.97% back into the Yield */
                totalDeposited = sub(totalDeposited,leftover);
            }
            totalOnHold = sub(totalOnHold,jackpot);
            /*EMIT EVENT*/ 
            emit Result(dat.addy,dat.bID,block.timestamp);
        }
    }
    function seize() external noReentrant {varData memory dat;
        /*For testing purposes only - will not be here in production*/
        require(msg.sender == developer,'NotDev');
        dat.farm = CERC20(cTOKENaddy).balanceOfUnderlying(address(this));
        assert(CERC20(cTOKENaddy).redeemUnderlying(dat.farm) == 0);
        dat.amt = IERC20(TOKENaddy).balanceOf(address(this));
        /*UPDATE CONTRACT*/
        totalDeposited = 0;
        totalReserved = 0; 
        totalInsured = 0;
        require(IERC20(TOKENaddy).transfer(developer,dat.amt), "TxnFai");
    }
}