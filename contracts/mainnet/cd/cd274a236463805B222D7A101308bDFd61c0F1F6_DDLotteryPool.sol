/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
/*[ CONTRACT INFORMATION ]----------------------------------------------------------------------------------------------------------*//*


DDLotteryPool - Version 1.0 - Deployed by Rakent Studios, LLC on 04/12/2022


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
    The DubbleDapp Lottery Pool works like a crypto savings account that generates interest. 
    However, instead of offering each participant a steady return on their Deposits, the Interest generated is pooled together and given 
    out as prizes to random users in the form of a Lottery. Aside from simply saving your cryptocurrency, the DubbleDapp 
    Lottery Pool offers you the opportunity to Win up to (2x)(200% ROI)(Double) the amount you have Deposited without actually using any of it
    to Play with.


Here is how it works:
    -Users Deposit a specific amount of Tokens (Ticket Price) in exchange for a Lottery Ticket.
    -All Deposits are routed into 3rd party Lending Protocols where they generate interest, or Yield, at varying APY's.
    -The Yield generated is then used as a Payout to reward each random user who wins the Lottery.
    -There are no fees to Deposit into or Withdraw from the contract.
    -A Winner can be drawn once the generated Yield reaches the Ticket Price + 5%.
    -Each chosen Winner will receive up to the full Ticket Price as a Reward, essentially doubling their investment.
    -Each Lottery Ticket is perpetual, so it can Win over and over again with just a single Deposit/Ticket.
    -Users can Withdraw their Winnings, and leave their Ticket in Play, or Chashout both their Deposit, AND Winnings, at ANY time.


When you Draw a Winner:
    - The Payout amount is placed on Hold, so other users do not Draw with the same Yield.
    - The contract sends a request (with a payment of wLINK Token) to the Chainlink VRF (see "Results" section).
    - The Chainlink VRF, immediately returns back a request ID which is logged with that specific Drawing details:
        {isReqID} = Wether a ReqID exists                                            
        {reqDID} = A ReqID in relation to the DrawingID its located at   
        {drawReqId} = The RequestID for a specific Drawing 
        {drawersID} = The Drawers UID when they Initiated a Drawing
        {winnersID} = The Winners UID when they Won a Drawing
        {winnersAddy} = The Winners Address when they Won a Drawing
        {drawSeed} = The Seed Provided when a Draw was Initiated
        {drawTimestamp} = The UNIX Timestamp of when a Draw was Initiated
        {drawResponse} = Chainlinks Response to a Request
        {drawModdResult} = Modified Result to fit our desired range (totalTickets)
        {winnersReward} = The Amount Awarded to the Drawings Winner
    - Once the transaction is confirmed, Users will have to wait for Chainlinks response.
    - After a few moments Chainlink will call the fulfillRandomness function in our contract with the request ID they provided 
        earlier, and the new random number they generated.
    - This random number is between 0 and 
        1,157,920,900,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
    -If the number received is less than or equal to the total number of tickets in play, than that is the winning number. A zero would be the last Ticket in play.
    -If the number is greater than the total number of tickets in play, we take the random number given and divide it by the total number of tickets in play. 
    -The remainder is our Winning number. A zero in this case, would also be the last Ticket in play.
    -The "winning#" will be the index of the Ticket array, and the UID inside that specific index, will be the Winning User.
    -The Winning User will receive the Payout, however, Payouts actually received will depend on how long a Ticket has been in Play.
    -This keeps users from hopping in and out when Drawings are about to be initiated.
        If your Ticket has only been in play for:
        1 Drawing = You receive 10% of the Payout amount
        2 Drawings= You receive 20% of the Payout amount
        3 Drawings= You receive 30% of the Payout amount
        4 Drawings= You receive 40% of the Payout amount
        5 Drawings= You receive 50% of the Payout amount
        6 Drawings= You receive 60% of the Payout amount
        7 Drawings= You receive 70% of the Payout amount
        8 Drawings= You receive 80% of the Payout amount
        9 Drawings= You receive 90% of the Payout amount
        10 Drawings= You receive 100% of the Payout amount
        Anything after = You receive 100% of the Payout amount if you Win


Random Shuffling:
    -Due to the nature of smart contracts, and the way this game was designed, there are instances where Lottery Tickets will change their place in line.
    -Lottery Ticket Numbers are given out in consecutive order, and choosing a winner is between 1 and the total number of Tickets, 
        ensuring there is always an actual winner with each drawing.
    -Therefore, whenever a Ticket is cashed out and deleted from the line, we take the last Ticket in Line and place it in the recently removed Tickets spot, 
        reducing the Total number of Tickets as intended, but sustaining the consecutive order of each individual Lottery Ticket.


Auto-Release:  
    -The contract will automatically release 10% of the Reserves and Insured balances into Yield for users to Win once every 30 days.
    -However, it will ONLY release 10% of the Insured balance if it is more than 2x whats Deposited in Total.


Insurances:
    -As stated above, 1% of every Drawing will be pulled from the Protocol and placed in the contract as Insured.
        If for any reason a user is unable to Withdraw their Balance from the Protocol, the Withdraw function will automatically divert 
        their requested Withdraw amount from the Insured balance in the contract instead of from the Lending Protocol.
    -As a secondary function, the Tokens in the Insured balance will also be used to resupply the contracts wLINK supply 
        (see "Auto-Resupply" section for more details).


Auto-Resupply:
    -In order to request verifiable random numbers from the Chainlink Oracles, the contract must pay a small fee in wLINK (or LINK in the ERC-677 standard). 
    -This contract will hold and use a balance of wLINK for each call made to the Chainlink Oracles.
    -If the contracts balance of wLINK gets below a certain threshold, it will automatically resupply the contract by swapping some Tokens from the Insured balance into LINK Tokens (ERC-20), 
    -It will then wrap them in wLINK (ERC-677), and then store it in the contract to be used for further Drawings.


Referral System (On-Chain & Cross-Contract):
    -Refer someone to any of the DubbleDapp smart contracts, and you will receive 1% of EVERY Drawing they WIN!
    -If NO ONE Refers them, the 1% will go back into the available Yield to Win. 
    -Referrals are tracked across all the DubbleDapp smart contracts using the DDDatabase smart contract, 
        so you will receive 1% from ANY Lottery Pool they WIN on!


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
contract DDLotteryPool is VRFConsumerBase {
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
    uint256 public ticketPrice = 100000000;                         /* The Required Deposit Amount to be given a Ticket                 */
    bytes32 public tokenName = "USDT";                              /* TOKEN name                                                       */
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
    uint256[] public usersTicketID;                                 /* [UID] = A Users Ticket ID in the Tickets Array                   */
    uint256[] public usersEarnings;                                 /* [UID] = A Users Earnings balance                                 */
    uint256[] public usersDeposit;                                  /* [UID] = A Users Deposited balance                                */
    uint256[] public userDepositedOn;                               /* [UID] = The Drawing Number before a User Deposited               */
    uint256[] public totalWins;                                     /* [UID] = The Total Number of times a User has Won a Drawing       */ 
    uint256[] public totalEarnings;                                 /* [UID] = The Total a User has Earned Altogether                   */
    uint256[] public totalWinnings;                                 /* [UID] = The Total a User has Earned from Drawings                */
    uint256[] public totalCompensations;                            /* [UID] = The Total a User has Earned in Caller Compensations      */
    uint256[] public totalCommissions;                              /* [UID] = The Total a User has Earned in Referral Commissions      */
    bytes32[] public lastReqID;                                     /* [UID] = The Last Request ID made by a User                       */
    uint256[][] public myWins;                                      /* [UID][I] = An Array of a User's WON Draw ID's                    */
/*[ CONTRACT VARIABLES ]----------------------------------------------------------------------------------------------------------------*/
    bool internal reentrantLock;                                    /* Wether the Reentrancy Lock is in Place                           */
    uint256 public totalPaidout;                                    /* Total Amount of Tokens Paidout to Users                          */
    uint256 public totalOnHold;                                     /* Total Amount of Tokens Held for pending Results                  */
    uint256 public totalTickets;                                    /* Total Number of Tickets currently in Play                        */
    uint256 public totalDeposited;                                  /* Total Amount Deposited into the Protocol                         */
    uint256 public totalReserved;                                   /* Total Amount Reserved for continued growth                       */
    uint256 public totalInsured;                                    /* Total Amount Insured in the Contract itself                      */
    uint256 public lastDID=1;                                       /* Last Draw ID created                                             */
    uint256 public lastUID=0;                                       /* Last User ID created                                             */
    uint256 public lastRelease;                                     /* The last UNIX Timestamp that a Balance was Released              */
    uint256[] public tickets;                                       /* [i] = An Array of Tickets currently in Play, contains owners UID */
/*[ DRAW VARIABLES ]--------------------------------------------------------------------------------------------------------------------*/
    mapping(bytes32 => bool) public isReqID;                        /* Wether a ReqID exists                                            */
    mapping(bytes32 => uint256) public reqDID;                      /* A ReqID in relation to the DrawingID its located at              */
    bytes32[] public drawReqId;                                     /* [RID] = The RequestID for a specific Drawing                     */  
    uint256[] public drawersID;                                     /* [DID] = The Drawers UID when they Initiated a Drawing            */
    uint256[] public winnersID;                                     /* [DID] = The Winners UID when they Won a Drawing                  */
    address[] public winnersAddy;                                   /* [DID] = The Winners Address when they Won a Drawing              */
    uint256[] public drawSeed;                                      /* [DID] = The Seed Provided when a Draw was Initiated              */
    uint256[] public drawTimestamp;                                 /* [DID] = The UNIX Timestamp of when a Draw was Initiated          */
    uint256[] public drawResponse;                                  /* [DID] = Chainlinks Response to a Request                         */
    uint256[] public drawModdResult;                                /* [DID] = Modified Result to fit our desired range (totalTickets)  */
    uint256[] public winnersReward;                                 /* [DID] = The Amount Awarded to the Drawings Winner                */
/*[ EVENTS ]----------------------------------------------------------------------------------------------------------------------------*/
    event Deposit(address indexed user,uint256 indexed amount,uint256 indexed time);/*                                                  */
    event Withdraw(address indexed user,uint256 indexed amount,uint256 indexed time);/*                                                 */
    event Cashout(address indexed user,uint256 indexed amount,uint256 indexed time);/*                                                  */
    event Donate(address indexed user,uint256 indexed method,uint256 amount,uint256 indexed time);/*                                    */
    event Draw(address indexed user,uint256 indexed dID,uint256 indexed time);/*                                                        */
    event Result(address indexed user,uint256 indexed dID,uint256 indexed time);/*                                                      */
/*[ DATA STRUCTURES ]-------------------------------------------------------------------------------------------------------------------*/
    struct varData {/*                                                                                                                  */
        address ref;address addy;uint256 uID;uint256 rID;uint256 tID;uint256 pID;uint256 dID;uint256 cost;uint256 cont;uint256 farm;/*  */
        uint256 amt;uint256 fee;uint256 req;uint256 drID;/*                                                                             */
    }/*                                                                                                                                 */
/*[ CONSTRUCTORS ]----------------------------------------------------------------------------------------------------------------------*/
    constructor() VRFConsumerBase(VFRC_addy, wLINK_addy) {
        LINK_fee = 0.0001*10**18;
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        /*CREATE THE DEVELOPERS ACCOUNT*/
        isUser[developer]=true;
        UID[developer]=0;
        userID.push(developer);
        usersTicketID.push(0);
        usersEarnings.push(0);
        usersDeposit.push(0);
        userDepositedOn.push(0);
        totalWins.push(0);
        totalEarnings.push(0);
        totalWinnings.push(0);
        totalCompensations.push(0);
        totalCommissions.push(0);
        lastReqID.push(tokenName);
        myWins.push([0]);
        /*CREATE A BLANK/BASE BET RECORD*/
        drawReqId.push(tokenName);
        drawersID.push(0);
        winnersID.push(0);
        winnersAddy.push(blank);
        drawSeed.push(0);
        drawTimestamp.push(0);
        drawResponse.push(0);
        drawModdResult.push(0);
        winnersReward.push(0);
        tickets.push(0);
    }
/*[ MODIFIERS ]-------------------------------------------------------------------------------------------------------------------------*/
    modifier noReentrant() {require(!reentrantLock,'Nope');reentrantLock = true;_;reentrantLock = false;}/*                             */
    modifier onlyVFRC() {require(msg.sender == VFRC_addy,'NotVFRC');_;}/*                                                               */
/*[ SAFEMATH FUNCTIONS ]----------------------------------------------------------------------------------------------------------------*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c=a*b;assert(a==0 || c / a==b);return c;}/*             */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b;return c;}/*                                  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a);return a - b;}/*                                 */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;assert(c >= a);return c;}/*                   */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}/*                                                */
/*[ DATE/TIME FUNCTIONS ]---------------------------------------------------------------------------------------------------------------*/
    function checkTime() public view returns(uint256) {uint256 time = block.timestamp;return(time);}/*                                  */
/*[ BASIC FUNCTIONS ]-------------------------------------------------------------------------------------------------------------------*/
    function deposit(address _link) external noReentrant {varData memory dat;
        /*Will deposit the ticketPrice specified by the contract, and places a ticket for you in the Tickets array.You can only Deposit ONCE!*/ 
        uint256 _amt = ticketPrice;dat.cont = 1;
        if(IERC20(TOKENaddy).balanceOf(msg.sender) < _amt){dat.cont = 0;}
        if(IERC20(TOKENaddy).allowance(msg.sender,address(this)) < _amt){dat.cont = 0;}
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
            usersTicketID.push(0);
            usersEarnings.push(0);
            usersDeposit.push(0);
            userDepositedOn.push(0);
            totalWins.push(0);
            totalEarnings.push(0);
            totalWinnings.push(0);
            totalCompensations.push(0);
            totalCommissions.push(0);
            lastReqID.push(tokenName);
            myWins.push([0]);
            dat.ref = DDDataBase(base_addy).checkUser(msg.sender,_link);
            if(dat.ref == blank){/*User was NOT referred, skip ahead*/}else
            if(!isUser[dat.ref]) {/*Referrer does NOT exist, Create an Account for them*/
                isUser[dat.ref] = true;
                lastUID = add(lastUID,1);
                UID[dat.ref] = lastUID;
                userID.push(dat.ref);
                usersTicketID.push(0);
                usersEarnings.push(0);
                usersDeposit.push(0);
                userDepositedOn.push(0);
                totalWins.push(0);
                totalEarnings.push(0);
                totalWinnings.push(0);
                totalCompensations.push(0);
                totalCommissions.push(0);
                lastReqID.push(tokenName);
                myWins.push([0]);
            }else{/*Referrer DOES exist, do nothing*/}
            usersReferrer[msg.sender] = dat.ref;
        }
        /*You can only have ONE Deposit/Ticket at a time! */
        require(usersDeposit[dat.tID] == 0,"DepoAlrdy");
        /*UPDATE USER*/
        usersDeposit[dat.tID] = _amt;
        /*UPDATE CONTRACT*/
        totalDeposited = add(totalDeposited,_amt);
        tickets.push(dat.tID);
        totalTickets = add(totalTickets,1);
        usersTicketID[dat.tID] = totalTickets;
        userDepositedOn[dat.tID] = lastDID;
        /*DEPOSIT INTO CONTRACT*/
        require(IERC20(TOKENaddy).transferFrom(msg.sender,address(this),_amt),"DepFail");
        /*APPROVE & SUPPLY TO PROTOCOL*/
        IERC20(TOKENaddy).approve(address(CERC20(cTOKENaddy)), _amt);
        assert(CERC20(cTOKENaddy).mint(_amt) == 0);
        /*EMIT EVENT*/
        emit Deposit(msg.sender,_amt,block.timestamp);
    }
    function withdraw() external noReentrant {varData memory dat;
        /*Will withdraw any earnings you have from the contract, but leaves your Deposit/Ticket in Play*/ 
        require(isUser[msg.sender],'NotUsr');
            dat.tID = UID[msg.sender];dat.req = 0;dat.cont = 1;
        /*Verify amount*/
            dat.amt = usersEarnings[dat.tID];
        if(dat.amt < 1){dat.cont = 0;}
            dat.farm = CERC20(cTOKENaddy).balanceOfUnderlying(address(this));
        if(dat.amt > dat.farm){dat.req = 2;
            if(dat.amt > totalInsured){dat.cont = 0;}
        }else{dat.req = 1;}
        require(dat.cont == 1,"ContErr");
        /*UPDATE USER*/
        usersEarnings[dat.tID] = 0;
        /*UPDATE CONTRACT*/
        totalDeposited = sub(totalDeposited,dat.amt); 
        if(dat.req == 1){/*WITHDRAW FROM PROTOCOL*/assert(CERC20(cTOKENaddy).redeemUnderlying(dat.amt) == 0);}
        else{/*DEDUCT FROM INSURED FUNDS*/totalInsured = sub(totalInsured,dat.amt);}
        /*WITHDRAW FROM CONTRACT*/
        require(IERC20(TOKENaddy).transfer(msg.sender,dat.amt), "TxnFai");
        /*EMIT EVENT*/
        emit Withdraw(msg.sender,dat.amt,block.timestamp);
    }
    function cashout() external noReentrant {varData memory dat;
        /*Will withdraw any earnings you have from the contract, AND will withdraw your Deposit and delete your ticket*/ 
        require(isUser[msg.sender],'NotUsr');
            dat.tID = UID[msg.sender];dat.req = 0;dat.cont = 1;
        /*Verify amount*/
            dat.amt = add(usersEarnings[dat.tID],usersDeposit[dat.tID]);
        if(dat.amt < 1){dat.cont = 0;}
            dat.farm = CERC20(cTOKENaddy).balanceOfUnderlying(address(this));
        if(dat.amt > dat.farm){dat.req = 2;if(dat.amt > totalInsured){dat.cont = 0;}}else{dat.req = 1;}
        require(dat.cont == 1,"ContErr");
        /*UPDATE USER*/
        usersEarnings[dat.tID] = 0;
        usersDeposit[dat.tID] = 0;
        uint256 tick = usersTicketID[dat.tID];
        usersTicketID[dat.tID] = 0;
        /*UPDATE CONTRACT*/
        if(tick < totalTickets){tickets[tick] = tickets[tickets.length - 1];}
        delete tickets[tickets.length - 1];
        tickets.pop();
        if(tick < totalTickets){        
            dat.uID = tickets[tick];
            usersTicketID[dat.uID] = tick;
        }
        totalTickets = sub(totalTickets,1);
        totalDeposited = sub(totalDeposited,dat.amt); 
        if(dat.req == 1){/*WITHDRAW FROM PROTOCOL*/assert(CERC20(cTOKENaddy).redeemUnderlying(dat.amt) == 0);}
        else{/*DEDUCT FROM INSURED FUNDS*/totalInsured = sub(totalInsured,dat.amt);}
        /*WITHDRAW FROM CONTRACT*/
        require(IERC20(TOKENaddy).transfer(msg.sender,dat.amt), "TxnFai");
        /*EMIT EVENT*/
        emit Cashout(msg.sender,dat.amt,block.timestamp);
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
        /*EMIT EVENT*/
        emit Donate(msg.sender,_meth,_amt,block.timestamp);
    }
    function draw(uint256 _seed) external noReentrant returns (bool) {varData memory dat;
        /*Initiates Drawing a Winner*/ 
        require(isUser[msg.sender],'NotUsr');
        require(totalTickets > 1,'NoTick');
        dat.cont = 1;dat.tID = UID[msg.sender];
        require(usersDeposit[dat.tID] > 0);
        if(_seed == 0){_seed = block.timestamp;}
        /*CHECK YIELD STATUS*/
        dat.req = add(ticketPrice,div(ticketPrice,20));
        dat.amt = CERC20(cTOKENaddy).balanceOfUnderlying(address(this));
        dat.farm = add(totalDeposited,totalReserved);
        require(dat.amt > dat.farm,"ContErr");
        dat.amt = sub(dat.amt,dat.farm);
        if(dat.amt < dat.req){dat.cont = 0;}dat.amt = dat.req;  
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
        uint256 bal = IERC20(wLINK_addy).balanceOf(address(this));
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
        /*PULL AMOUNT FROM POOL (prevent others from Drawing with the same Yield)*/
        totalDeposited = add(totalDeposited,dat.amt);
        totalOnHold = add(totalOnHold,dat.amt);
        /*CREATE THIS DRAWINGS RECORD*/
        drawersID.push(dat.tID);
        winnersID.push(0);
        winnersAddy.push(blank);
        drawSeed.push(_seed);
        drawTimestamp.push(block.timestamp);
        drawResponse.push(0);
        drawModdResult.push(0);
        winnersReward.push(0);
        dat.dID = lastDID;
        lastDID = add(lastDID,1);
        bytes32 requestId = getRandomNumber(_seed);
        isReqID[requestId] = true;
        reqDID[requestId] = dat.dID;
        drawReqId.push(requestId);
        lastReqID[dat.tID] = requestId;
        /*EMIT EVENT*/
        emit Draw(msg.sender,dat.dID,block.timestamp);
        return true;
    }
    function getRandomNumber(uint256 _seed) internal returns (bytes32 requestId) {
        /*Called from within the Draw Function*/ 
        require(LINK.balanceOf(address(this)) >= LINK_fee,"NoLINK");
        return requestRandomness(keyHash,LINK_fee,_seed);
    }
    function fulfillRandomness(bytes32 _reqId, uint256 randomness) internal override onlyVFRC {varData memory dat;
        /*Response back from Chainlink Oracles: 
        Will contain the randomized number that was sent back, anywhere between 0 and (a full uint256 integer, which is:
        1,157,920,900,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000 ).
        That number is then divided by the total number of Tickets in play, and the remainder (modulus) is the winning number.
        If the remainder is "0"(zero), then it is essentially the total number of Tickets in play (last ticket in play) because it divided evenly.
        
        Winning Payouts actually received will depend on how long a Ticket has been in Play.
        This keeps users from hopping in and out when Drawings are about to be initiated.
        If you Win, and your Ticket has only been in play for:
        1 Drawing   = You receive 10% of the Payout
        2 Drawings  = You receive 20% of the Payout
        3 Drawings  = You receive 30% of the Payout
        4 Drawings  = You receive 40% of the Payout
        5 Drawings  = You receive 50% of the Payout
        6 Drawings  = You receive 60% of the Payout
        7 Drawings  = You receive 70% of the Payout
        8 Drawings  = You receive 80% of the Payout
        9 Drawings  = You receive 90% of the Payout
        10 Drawings = You receive 100% of the Payout
        Anything after = You receive 100% of the Payout
        (Any portions you do NOT receive are put directly back into Yield)
 
        Yield required for a Payout will be 105% of the Ticket Price, so that:
        100% => will go to the Winner (or less, based on above)
        1% => will be designated Reserves (Compounded)
        1% => will be pulled and secured in-contract as Insured (Secured)
        1% => will go to the user who called the Draw function (Gas Compensation)
        1% => will go to the Winners Referrer (if exists)
        1% => will go to the Development Team
        */
        uint256 _rand = randomness;
        uint256 modul = 0;
        address Raddy = blank;
        if(isReqID[_reqId]){
            dat.dID = reqDID[_reqId];
            drawResponse[dat.dID] = _rand;
            /*MODULATE THE NUMBER WITHIN OUR DESIRED RANGE: 1 thru totalTickets */
            uint256 rang = totalTickets;
            if(_rand <= rang){modul = _rand;}else{modul = mod(_rand,rang);}
            if(modul <= 0){modul = rang;}
            drawModdResult[dat.dID] = modul;
            /*Pull winning UID from the winning spot in the Tickets array*/
            dat.uID = tickets[modul];
            winnersID[dat.dID] = dat.uID;
            winnersAddy[dat.dID] = userID[dat.uID];
            dat.drID = drawersID[dat.dID];
            uint256 jackpot = add(ticketPrice,div(ticketPrice,20));
            uint256 leftover = jackpot;
            /*Reward the Winner with their share, based on how long their Ticket is in Play*/
            uint256 lst = userDepositedOn[dat.uID];lst = sub(lastDID,lst);
            if(lst >= 10){dat.amt = ticketPrice;}else{
                dat.amt = div(ticketPrice,10);
                dat.amt = mul(dat.amt,lst);
            }
            usersEarnings[dat.uID] = add(usersEarnings[dat.uID],dat.amt);
            totalWinnings[dat.uID] = add(totalWinnings[dat.uID],dat.amt);
            totalEarnings[dat.uID] = add(totalEarnings[dat.uID],dat.amt);
            totalPaidout = add(totalPaidout,dat.amt);
                winnersReward[dat.dID] = dat.amt;
            myWins[dat.uID].push(dat.dID);
            totalWins[dat.uID] = add(totalWins[dat.uID],1);
                leftover = sub(leftover,dat.amt);
            /*Reward Winners Referrer their share of + 1%*/
            dat.amt = div(ticketPrice,100);
            dat.addy = userID[dat.uID];
            Raddy = usersReferrer[dat.addy];
            if(Raddy != blank){
                dat.rID = UID[Raddy];
                leftover = sub(leftover,dat.amt);
                usersEarnings[dat.rID] = add(usersEarnings[dat.rID],dat.amt);
                totalCommissions[dat.rID] = add(totalCommissions[dat.rID],dat.amt);
                totalEarnings[dat.rID] = add(totalEarnings[dat.rID],dat.amt);
                totalPaidout = add(totalPaidout,dat.amt);
            }else{/*No Referrer, direct into Yield*/}
            /*Update the Reserved Balance with + 1% */
            totalReserved = add(totalReserved,dat.amt);
            totalDeposited = sub(totalDeposited,dat.amt);
                leftover = sub(leftover,dat.amt);
            /*Update the Insured Balance with + 1% */
            totalInsured = add(totalInsured,dat.amt);
            totalDeposited = sub(totalDeposited,dat.amt);
            assert(CERC20(cTOKENaddy).redeemUnderlying(dat.amt) == 0);
                leftover = sub(leftover,dat.amt);
            /*Reward the Drawer with some gas compensation of + 1% */
            usersEarnings[dat.drID] = add(usersEarnings[dat.drID],dat.amt);
            totalCompensations[dat.drID] = add(totalCompensations[dat.drID],dat.amt);
            totalEarnings[dat.drID] = add(totalEarnings[dat.drID],dat.amt);
            totalPaidout = add(totalPaidout,dat.amt);
                leftover = sub(leftover,dat.amt);
            /*Reward Development Team with their share of + 1% */
            usersEarnings[0] = add(usersEarnings[0],dat.amt);
            totalCommissions[0] = add(totalCommissions[0],dat.amt);
            totalEarnings[0] = add(totalEarnings[0],dat.amt);
            totalPaidout = add(totalPaidout,dat.amt);
                leftover = sub(leftover,dat.amt);
            /*Release whatever was leftover back into the Yield */
            totalDeposited = sub(totalDeposited,leftover);
            totalOnHold = sub(totalOnHold,jackpot);
            /*EMIT EVENT*/ 
            emit Result(dat.addy,dat.dID,block.timestamp);
        }
    }
}