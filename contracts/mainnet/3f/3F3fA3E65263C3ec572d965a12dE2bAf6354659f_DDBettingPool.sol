/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
/*[ CONTRACT INFORMATION ]----------------------------------------------------------------------------------------------------------*//*  


DDBettingPool - Version 1.0 - Deployed by Rakent Studios, LLC on 04/12/2022


THIS IS A SMART CONTRACT: 
    By interacting with this smart contract, you are agreeing to its terms. 
    If you do NOT agree with its terms, then please do NOT interact with this smart contract.


CREATORS DISCLAIMER: 
    This smart contract is decentralized.
    (Rakent Studios, LLC) developed, tested, and deployed this smart contract, and will release multiple varying versions of this smart contract, 
    and will most likely receive a small portion of the interest generated from this smart contract for all of eternity, 
    but it can NOT change, control, or manipulate this smart contract any more than any other entity can after it has been deployed.
    (Rakent Studios, LLC) may host and provide a front-end website, app, and/or portal that facilitates the use of this smart contract, 
    which any other person or entity with the right skills and knowledge could do, but again, (Rakent Studios, LLC) will still NOT be able to change, control, or manipulate this 
    smart contract after it has been deployed.
    The level of control that (Rakent Studios, LLC) will have over this smart contract will be equal to that of any other entity that chooses to interact with this smart contract.
    There are NO OnlyOwner functions and no governance features because nothing was meant to be changed.
    Furthermore, to the best of the developers own knowledge, this smart contract was developed as secure as it could be, at the time it was created, but we can not guarantee you anything.
    Therefore, (Rakent Studios, LLC) will not be held liable for any negative experiences you may have from your interaction with this smart contract.
    You should ALWAYS Do Your Own Research and NEVER Invest More Than You Are Willing To Lose!


What does this contract do:
    The DubbleDapp Betting Pool works like a crypto savings account that generates interest. 
    However, instead of offering each participant a steady return on their Deposits, the Interest generated is pooled together and given 
    out as prizes for users who guess a random number correctly. Aside from simply saving your cryptocurrency, the DubbleDapp 
    Betting Pool offers you the opportunity to Win up to (2x)(200% ROI)(Double) the amount you have Deposited without actually using any of it
    to Bet with.


Here is how it works:
    -Deposits are routed into 3rd party Lending Protocol where they generate interest, or Yield, at varying APY's.
    -Yield generated is then available to Win by any User with a Deposit in the Protocol.
    -There are no fees to Deposit into or Withdraw from the contract.
    -Users can Withdraw their Deposit, plus any Winnings, at ANY time.
    -However, if you Withdraw, you can NOT Bet again in THIS pool for 24 hours.
    -A Users Deposit amount, plus any Winnings, are tracked as their Balance.
    -You can NOT Bet more than the amount in your Balance.
    -When a user Bets, they are Betting with the Yield in the Lending Protocol, NOT their Deposit.
    -Therefore, you can NOT Bet more than the current amount of Yield either.


When you Place a Bet:
    - The amount you Bet is placed on Hold, so other users do not Bet with the same Yield.
    - The contract sends a request (with a payment of wLINK Token) to the Chainlink VRF (see "Resupply" section below).
    - The Chainlink VRF, immediately returns back a request ID which is logged with that specific Bets details:
        {isReqID} = Wether a ReqID exists                                            
        {reqBID} = A ReqID in relation to the BettingID its located at   
        {betReqId} = The RequestID for a specific Bet that was Placed  
        {bettorsID} = The Bettors UID when they Placed a Bet
        {bettorsAddy} = The Bettors Address when they Placed a Bet
        {bettorsBet} = The Amount the Bettor Placed on a Bet
        {bettorsNum} = The Number the Bettor Bet On (1 to 100)
        {bettorsSeed} = The Seed Provided on a Placed Bet
        {betPayout} = The Amount that will be awarded if the Bettor Wins
        {betTimestamp} = The UNIX Timestamp of when a Bet was Placed Bet
        {betResponse} = Chainlinks Response to a Placed Bet
        {betModdResult} = Modif: (ChainLink Result) / 100 : remainder = "winning #"
        {bettorsReward} = The Amount Rewarded to the Bettor of a Placed Bet
    - Once the transaction is confirmed, Users will have to wait for Chainlinks response.
    - After a few moments Chainlink will call the fulfillRandomness function in our contract with the request ID they provided 
    earlier, and the new random number they generated.
    - This random number is between 0 and 
    1,157,920,900,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
    -If the number received is less than or equal to 100, than that is the winning number. A zero would be "100"(one hundred).
    -If the number is greater than 100, we take the random number given and divide it by 100. 
    -The remainder is our Winning number. A zero in this case, would also be "100"(one hundred).

    -If the Winning number is equal to the Users picked number, then that User Wins the entire amount of Yield that they Bet.
    -If the numbers are NOT equal, than that User will still receive 0.01% of the amount of Yield that they Bet (as a form of gas 
    compensation).
    -A LOST Bet will place 97.97% of the Bet amount back into Yield so others can Win it.
    -The other 2.03% will be distributed accordingly:
        1% will be pulled from the Protocol and placed in this contract as "Insured" Tokens (see "Insurance" section below).
        1% will be left in Protocol but designated as "Reserved" to continue Yield generation.
        0.01% will go to the User who Referred you (see "Referrals" section)
        0.01% will go to the original Contract creator
        the other (0.01% was your reward/gas compensation stated above)

    -If you Win a Bet, you can NOT Bet again for 1 hour
    -If you Lose a Bet, you can NOT Bet again for 15 minutes
    -If you Withdraw, you can NOT Bet again for 24 hours


Auto-Release:  
    -The contract will automatically release 10% of the Reserves and Insured balances into Yield for users to Win once every 30 days.
    -However, it will ONLY release 10% of the Insured balance if it is more than 2x whats Deposited in Total.


Insurances:
    -As stated above, 1% of every LOST Bet will be pulled from the Protocol and placed in the contract as Insured.
        If for any reason a user is unable to Withdraw their Balance from the Protocol, the Withdraw function will automatically divert 
        their requested Withdraw amount from the Insured balance in the contract instead of from the Lending Protocol.
    -As a secondary function, the Tokens in the Insured balance will also be used to resupply the contracts wLINK supply 
        (see "Resupply" section for more details).


Auto-Resupply:
    -In order to request verifiable random numbers from the Chainlink Oracles, the contract must pay a small fee in wLINK (or LINK in the ERC-677 standard). 
    -This contract will hold and use a balance of wLINK for each call made to the Chainlink Oracles.
    -If the contracts balance of wLINK gets below a certain threshold, it will automatically resupply the contract by swapping some Tokens from the Insured balance into LINK Tokens (ERC-20), 
    -It will then wrap them in wLINK (ERC-677), and then store it in the contract to be used for further Drawings.


 Referral System (On-Chain & Cross-Contract):
    -Refer someone to any of the DubbleDapp smart contracts, and you will receive 0.01% of EVERY Bet they LOSE!
    -If NO ONE Refers them, the 0.01% of EVERY Lost Bet will go back into the available Yield to Win. 
    -Referrals are tracked across all the DubbleDapp smart contracts using the DDDatabase smart contract, 
        so you will receive 0.01% from ANY Betting Pool the LOSE on!
    
*/
/*----------------------------------------------------------------------------------------------------------------------------------*/ 
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
    address public developer = address(0xACd8D73A748F330c656D4670764C66D6D31BFecD);     /* Development Teams Address                    */
    address public base_addy = address(0x42892F21a99C9ABBd608065a7214541A7407ec31);     /* DDDataBase contract Address - Polygon        */
    address public WMATIC_addy = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);   /* WMATIC Token Contract Address - Polygon      */
    address public LINK_addy = address(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);     /* LINK Token Contract Address - Polygon        */
    address public wLINK_addy = address(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);    /* Chainlink VRF LINK token  - Polygon          */
    address public VFRC_addy = address(0x3d2341ADb2D31f1c5530cDC622016af293177AE0);     /* Chainlink VRF Coordinator - Polygon          */
    address public Router_addy = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);   /* QuickSwap Routing Address - Polygon          */
    address public Pegger_addy = address(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);   /* PegSwap Routing Address - Polygon            */
/*[ PRESET VARIABLES ]------------------------------------------------------------------------------------------------------------------*/
    address public TOKENaddy = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);     /* TOKEN address                                */
    address public cTOKENaddy = address(0xf976C9bc0E16B250E0B1523CffAa9E4c07Bc5C8a);    /* cTOKEN address                               */
    uint256 public decimals = 1000000;                              /* The Tokens Decimal format                                        */
    uint256 public minimumBet = 10000000;                           /* The Minimum Amount of Tokens a User can Bet                      */
    bytes32 public tokenName = "USDT";                              /* TOKEN name                                                       */
    uint256 public loseRestrict = 900;                              /* Bet Restriction after Losing (in seconds)                        */
    uint256 public winRestrict = 3600;                              /* Bet Restriction after Winning (in seconds)                       */
    uint256 public withdrawRestrict = 86400;                        /* Bet Restriction after Withdrawing (in seconds)                   */
    uint256 public safeTnet = 100;                                  /* The minimum threshold before more wLINK is purchased             */
    uint256 public swapAmt = 1000000;                               /* The amount of Tokens to be swapped into wLINK                    */
/*[ CHAINLINK VARIABLES ]---------------------------------------------------------------------------------------------------------------*/
    uint256 internal LINK_fee;                                      /* LINK fee to use the VRF service = 0.0001 LINK                    */
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
    constructor() VRFConsumerBase(VFRC_addy, wLINK_addy) {
        LINK_fee = 0.0001*10**18;
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
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
            path = new address[](3);
            path[0] = TOKENaddy;
            path[1] = WMATIC_addy;
            path[2] = LINK_addy;
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
}