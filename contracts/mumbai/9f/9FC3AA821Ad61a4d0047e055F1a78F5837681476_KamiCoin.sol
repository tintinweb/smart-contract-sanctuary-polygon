//Contract-Kami_Coin
// SPDX-License-Identifier: MIT
/*
 *
 *OpenZeppelin Contracts helps you minimize risk by using battle-tested libraries of smart contracts for Ethereum and other blockchains. It includes the most used implementations of ERC standards.
 *
 *Reduce the risk of vulnerabilities in your applications by using standard, tested, community reviewed code
 *
 *Using top level standard contracts security patterns and best practices.
 *
 *Simple, robust code. Easy collaboration and auditing.
 *
 *Community-driven. Used by the biggest players in the industry.
 */
/*
 *We are a totally reputable company we do not accept any illegal practice, any act of crime against the monetary laws must be denounced we do not accept any practice that puts the transactions carried out in our facilities at risk.
 *Please check our contracts with OpenZeppelin's Github if you have any questions.
 *(Black Mamba Games)
 */


pragma solidity >=0.7.0 <0.9.0;


import "./ERC1155.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol
 *https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 * _Available since v3.1._
 */

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract KamiCoin is  IERC20{

    string public constant name = "Kami Coin";
    string public constant symbol = "KAMI";
    uint8 public constant decimals = 18;
    uint256 public constant NON_FUNGIBLE = 1;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10 ether;


   constructor() {
       
   
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}
contract BEP1155 is ERC1155 {
    
    uint256 public constant NON_FUNGIBLE = 1;

    constructor() ERC1155("JSON_URI") {
        
        _mint(msg.sender, NON_FUNGIBLE, 1, "");
    }
}