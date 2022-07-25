/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

// SPDX-License-Identifier: MIT
// File: DAO/SafeMath.sol


pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;


// Implementacion de la libreria SafeMath para realizar las operaciones de manera segura
// Fuente: "https://gist.github.com/giladHaimov/8e81dbde10c9aeff69a1d683ed6870be"

library SafeMath{
    // Restas
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    // Sumas
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
    // Multiplicacion
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}
// File: DAO/ERC20.sol




/// @title <ERC20.sol>
/// @author <IvanFitro>
/// @notice <Creation of an ERC20 token>

interface IREC20 {
    //Returns the quantity of tokens existency
    function totalSupply() external view returns(uint256);

    //Returns the quantity of tokens of an specific address
    function balanceOf(address _account) external view returns(uint256);

    //Returns the quantity of tokens that the spender can spend in the name of the owner
    function allowance(address _owner, address _spender) external view returns(uint256);

    //Returns a bool result of the indicated operation
    function transfer(address _recipient, uint256 _amount) external returns(bool);

    //Returns a bool result of the indicated operation
    function DAOTransfer(address sender, address receiver, uint256 numTokens) external returns (bool);

    //Returns a bool with the result of the spend transaction
    function approve(address _spender, uint256 _amount) external returns(bool);

    //Returns a bool with the result of the operation of transfer tokens with the allowance() method
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool);

    //Event when a quantity of tokens is transfered to an origien to a destiny
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    //Event when a quantity of tokens is transfered to an origion to a destiny using the allowance() method
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

}

contract ERC20 is IREC20 {

    string public constant name = "FitroDAO";
    string public constant symbol = "FDAO";
    uint8 public constant decimals = 2;
    address Owner;

    using SafeMath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed; //allows another address to spend tokens on my behalf
    uint256 totalSupply_;

    constructor (uint256 initialSupply) {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
        Owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }

    function totalSupply() public override view returns(uint256) {
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public onlyOwner {
        totalSupply_ +=newTokensAmount;
        balances[msg.sender] +=newTokensAmount;
    } 

    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns(uint256) {
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function DAOTransfer(address sender, address receiver, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[sender]);
        balances[sender] = balances[sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(sender,receiver,numTokens);
        return true;
    } 

    function approve(address delegate, uint256 numTokens) public override returns(bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

}
// File: DAO/DAO.sol



contract DAO {

    //----------------------------------------Initial Declarations----------------------------------------

    //Instance for the token contract 
    ERC20 private token;
    //Owner address
    address payable public owner;

    constructor()  {
        token = new ERC20(10000);
    }

     modifier onlyOwner {
        require(msg.sender == owner, "You don't have permisions");
        _;
    }

    struct proposal {
        string name;
        string desc;
        uint date;
        uint inFavor;
        uint against;
    }

    //Mapping to realationate the structs
    mapping (string => proposal) public Proposals;
    //Mapping to relationate the tokens contributed of a proposal
    mapping (address => mapping (string => uint)) tokensContributed;
    //Mapping to relationate a name of a propsal with their direction
    mapping (string => address) public ProposalDirection;

    //Events
    event newProposal(string, address, address);
    event Result(string, string, address);

    //----------------------------------------Token Management--------------------------------------------

    //Function to see the price of a token respect the Ether
    function tokenPrice(uint _numTokens) internal pure returns(uint) {
        return _numTokens*(1 gwei);
    }

    //Function to buy tokens
    function buyTokens(uint _numTokens) public payable {

        address payable member = payable(msg.sender);
        //Stablish the token price
        uint cost = tokenPrice(_numTokens);
        //Evaluates the money pay for the tokens
        require(msg.value >= cost, "You need more ethers.");
        //Diference that member pays
        uint returnValue = msg.value - cost;
        //The DAOs returns the quantity of tokens to the member
        member.transfer(returnValue);
        //Obtain the available tokens
        uint Balance = token.balanceOf(address(this));
        require(_numTokens <= Balance, "Buy less tokens");
        //Transfer the tokens to the client
        token.transfer(member, _numTokens);
    }

    //Function to see the available tokens in the DAO contract
    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    //Function to see the member tokens
    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    //Function to create more tokens
    function createTokens(uint _numTokens) public onlyOwner {
        token.increaseTotalSupply(_numTokens);
    }

    //----------------------------------------DAO Management--------------------------------------------

    //Function to create a smart contract for each proposal
    function Factory(string memory _name) internal {
        address smartContractDirection = address (new ProposalContract(msg.sender));
        ProposalDirection[_name] = smartContractDirection;
        emit newProposal(_name, msg.sender, smartContractDirection);
    }


    //Function to create a proposal
    function createProposal(string memory _name, string memory _desc, uint _date) public {
        //Set the finishing date
        uint Date = block.timestamp + (_date * 86400 seconds );
        //Create the struct
        Proposals[_name] = proposal(_name, _desc, Date, 0, 0);
        //Create a smart contract
        Factory(_name);
    }

    //Function to vote in Favor/Against of a proposal
    function vote(string memory _name, string memory _action, uint _numTokens) public returns(bool) {
        require(_numTokens <= myTokens(),"You need to put less tokens");
        //Comprove that the propsal is available
        require(block.timestamp <= Proposals[_name].date, "This proposals has ended");
        //Transfer the tokens to the smart contract Proposal
        token.DAOTransfer(msg.sender, ProposalDirection[_name], _numTokens);
        //Resgister the transfer into the mapping
        tokensContributed[msg.sender][_name] = _numTokens;
        //Add the votes inFavor or Against
        if (keccak256(abi.encodePacked((_action))) == keccak256(abi.encodePacked(("inFavor")))) {
            Proposals[_name].inFavor += _numTokens; 
            return true;
        } else if (keccak256(abi.encodePacked((_action))) == keccak256(abi.encodePacked(("Against")))) {
            Proposals[_name].against += _numTokens;
            return true;
        }
        return false;
    }

    //Function to see the result of the proposal
    function seeResult(string memory _name) public returns(string memory) {
        //Comprove that the proposal has ended
        require(block.timestamp >= Proposals[_name].date, "The proposal is still active");
        string memory result;
        //See which is the final result
        if (Proposals[_name].inFavor > Proposals[_name].against) {
            result = "inFavor";
        } else if (Proposals[_name].inFavor < Proposals[_name].against) {
            result = "Against";
        } else {
            result = "Draw";
        }
        
        emit Result(_name, result, ProposalDirection[_name]);
        return result;
        
    }

    //Function to recover the tokens when the proposal finishes
    function recoverTokens(string memory _name) public returns(bool) {
        require(block.timestamp >= Proposals[_name].date, "The proposal is still active");
        //Comprove that the member participate in the proposal
        require(tokensContributed[msg.sender][_name] > 0, "You don not participate in this proposal");
        //Transfer the tokens to the smart contract Proposal to the member
        token.DAOTransfer(ProposalDirection[_name], msg.sender, tokensContributed[msg.sender][_name]);
        //Update the mapping
        tokensContributed[msg.sender][_name] -= tokensContributed[msg.sender][_name];
        return true;

    }

}

contract ProposalContract {

    address public owner;

    constructor (address _direction) {
        owner = _direction;
    }

}