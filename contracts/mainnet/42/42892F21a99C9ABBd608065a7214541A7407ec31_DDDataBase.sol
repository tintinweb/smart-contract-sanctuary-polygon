/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
/*[ CONTRACT INFORMATION ]----------------------------------------------------------------------------------------------------------*//*  

DDDatabase - Version 1.0 - Published by Rakent Studios, LLC on 04/12/2022

THIS IS A SMART CONTRACT: 
    By interacting with this smart contract, you are agreeing to its terms. 
    If you do NOT agree with its terms, then please do NOT interact with this smart contract.

CREATORS DISCLAIMER: 
    (Rakent Studios, LLC) developed, tested, and published this smart contract, and can control, and manipulate this smart contract at any time.
    However, the functions available to (Rakent Studios, LLC) are nothing more than "adding" additional contract addresses for various pools, 
    as well as "adding" categories for various pools. 
    Nothing in this smart contract will affect users or the various other contract addresses linked to this smart contract. 

What does this contract do:
    This smart contract is simply a hub for tracking users and their referrals across all of the DubbleDapp smart contracts.
    When a new category of pools is created, the Developers will add a new array for holding each pool's information.
    When a new pool is created, the Developers will add its information to the contracts array with its information.
/*----------------------------------------------------------------------------------------------------------------------------------*/   
contract DDDataBase {
  /*[ SAFEMATH ]--------------------------------------------------------------------------------------------------------------------*/
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c=a*b;assert(a==0 || c / a==b);return c;}/*           */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b;return c;}/*                                */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a);return a - b;}/*                               */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;assert(c >= a);return c;}/*                 */
  /*[ CONTRACT ADDRESSES ]----------------------------------------------------------------------------------------------------------*/
  address public developer = address(0xACd8D73A748F330c656D4670764C66D6D31BFecD); /* Development Teams Address                      */
  address public blank = address(0x0000000000000000000000000000000000000000);     /*                                                */
  bytes32 internal blankByte;/*                                                                                                     */
  /*[ USER DATA ]-------------------------------------------------------------------------------------------------------------------*/
  mapping(address => bool) public isUser;                           /* Wether a User exists                                         */
  mapping(address => address) public usersReferrer;                 /* Address of Referrer                                          */
  mapping(address => uint) public referralQty;                      /* Total Referral Quantity                                      */ 
  mapping(address => bool) public verifyWhitelist;                  /* Whitelisted Contract Addresses                               */
  mapping(address => bool) public hasDeposited;                     /* Wether a User has Deposited at least once (actual user)      */
  address[][] public contracts;                                     /* Contracts Array                                              */
  uint256[] public contractQty;                                     /* Total Number of Contracts in each Group                      */
  uint256 public contractGroups;                                    /* Total Number of Contract Groups                              */
  bytes32[][] public protocols;                                     /* Protocols Array                                              */
  uint256[] public protocolQty;                                     /* Total Number of Protocols in each Group                      */
  uint256 public protocolGroups;                                    /* Total Number of Protocol Groups                              */
  bytes32[][] public tokenNames;                                    /* Token Names Array                                            */
  uint256[] public tokenNameQty;                                    /* Total Number of Token Names in each Group                    */
  uint256 public tokenNameGroups;                                   /* Total Number of Token Name Groups                            */
  address[][] public tokenAddresses;                                /* Token Addresses Array                                        */
  uint256[] public tokenAddressQty;                                 /* Total Number of Token Addresses in each Group                */
  uint256 public tokenAddressGroups;                                /* Total Number of Token Address Groups                         */
  address[][] public cTokenAddresses;                               /* cToken Addresses Array                                       */
  uint256[] public cTokenAddressQty;                                /* Total Number of cToken Addresses in each Group               */
  uint256 public cTokenAddressGroups;                               /* Total Number of cToken Address Groups                        */
  uint256[][] public decimals;                                      /* Decimal Array                                                */
  uint256[] public decimalQty;                                      /* Total Number of Decimals in each Group                       */
  uint256 public decimalGroups;                                     /* Total Number of Decimal Groups                               */
  /*[ CONSTRUCTORS ]----------------------------------------------------------------------------------------------------------------*/
  constructor() {
    contracts.push([blank]);
    protocols.push([blankByte]);
    tokenNames.push([blankByte]);
    tokenAddresses.push([blank]);
    cTokenAddresses.push([blank]);
    decimals.push([0]);
    contractQty.push(0);
    protocolQty.push(0);
    tokenNameQty.push(0);
    tokenAddressQty.push(0);
    cTokenAddressQty.push(0);
    decimalQty.push(0);
    hasDeposited[developer]=true;
  }
  /*[ BASIC FUNCTIONS ]-------------------------------------------------------------------------------------------------------------*/
  function checkUser (address _addy, address _ref) external returns(address) {
    require(verifyWhitelist[msg.sender],"NotListed");
    if(isUser[_addy]){_ref=usersReferrer[_addy];}else{
      isUser[_addy]=true;
      hasDeposited[_addy]=true;
      referralQty[_addy]=0;
      if(_ref==_addy){_ref=blank;}
      if(_ref==blank){}else{
        if(!isUser[_ref]){isUser[_ref]=true;}
        referralQty[_ref]=add(referralQty[_ref],1);
      }
      usersReferrer[_addy]=_ref;
    }
    return(_ref);
  }
  function newCategory() external {
    require(msg.sender == developer,'NotDev');
    contracts.push([blank]);
    protocols.push([blankByte]);
    tokenNames.push([blankByte]);
    tokenAddresses.push([blank]);
    cTokenAddresses.push([blank]);
    decimals.push([0]);
    contractGroups=add(contractGroups,1);
    protocolGroups=add(protocolGroups,1);
    tokenNameGroups=add(tokenNameGroups,1);
    tokenAddressGroups=add(tokenAddressGroups,1);
    cTokenAddressGroups=add(cTokenAddressGroups,1);
    decimalGroups=add(decimalGroups,1);
    contractQty.push(0);
    protocolQty.push(0);
    tokenNameQty.push(0);
    tokenAddressQty.push(0);
    cTokenAddressQty.push(0);
    decimalQty.push(0);
  }
  function newContract(uint256 _cat, address _cont, bytes32 _proto, bytes32 _name, address _addy, address _cAddy, uint256 _deci) external {
    require(msg.sender == developer,'NotDev');
    require(_cat<=contractGroups);
    contracts[_cat].push(_cont);
    protocols[_cat].push(_proto);
    tokenNames[_cat].push(_name);
    tokenAddresses[_cat].push(_addy);
    cTokenAddresses[_cat].push(_cAddy);
    decimals[_cat].push(_deci);
    contractQty[_cat]=add(contractQty[_cat],1);
    protocolQty[_cat]=add(protocolQty[_cat],1);
    tokenNameQty[_cat]=add(tokenNameQty[_cat],1);
    tokenAddressQty[_cat]=add(tokenAddressQty[_cat],1);
    cTokenAddressQty[_cat]=add(cTokenAddressQty[_cat],1);
    decimalQty[_cat]=add(decimalQty[_cat],1);
    verifyWhitelist[_cont]=true;
  }
}