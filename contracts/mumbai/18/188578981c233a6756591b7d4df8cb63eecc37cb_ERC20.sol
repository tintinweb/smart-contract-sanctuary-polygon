/**
 *Submitted for verification at polygonscan.com on 2022-06-28
*/

pragma solidity >=0.7.0 <0.9.0;	

contract ERC20 {

    string nameOfToken = "ERC20";
    string symbolOfToken = "* ERC20_TOKEN *";
    uint8 decimalsOfToken = 100;
    uint256 totalSupplyOfToken = 10000; //total token supply
    mapping(address=>uint256) balanceOfUser; //stores the users' balance with their address
    mapping (address => mapping (address => uint256)) allowanceValue; 
    //stores the token number the user is allowed to use of another account(allowanceValue[token account][allowed user who can use])

    constructor()
    {
        balanceOfUser[msg.sender] = totalSupplyOfToken; 
        //this is additional function, which is not included in basic ERC20
        //all the Token are sent to the contract deployer
    }

    //functions
    function name() public view returns (string memory)
    {
        return nameOfToken;
    } //optional

    function symbol() public view returns (string memory)
    {
        return symbolOfToken;
    } //optional

    function decimals() public view returns (uint8)
    {
        return decimalsOfToken;
    } //optional

    function totalSupply() public view returns (uint256)
    {
        return totalSupplyOfToken;
    }

    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balanceOfUser[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(balanceOfUser[msg.sender]>=_value);
        require(_to != address(0) );

        balanceOfUser[msg.sender]= balanceOfUser[msg.sender] - _value;
        balanceOfUser[_to] = balanceOfUser[msg.sender] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        require(balanceOfUser[_from] >= _value);
        require(allowanceValue[_from][msg.sender] >= _value);
        require(_to != address(0) );

        balanceOfUser[_from] -= _value;
        balanceOfUser[_to] += _value;
        allowanceValue[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    //SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender. THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before
    //see https://eips.ethereum.org/EIPS/eip-20
    //vulnerability
    {
        require(_spender != address(0));

        allowanceValue[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return allowanceValue[_owner][_spender];
    }

    //events
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    //MUST trigger when tokens are transferred, including zero value transfers.
    //A token contract which creates new tokens SHOULD trigger a Transfer event 
    //with the _from address set to 0x0 when tokens are created.

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //MUST trigger on any successful call to approve(address _spender, uint256 _value).

}