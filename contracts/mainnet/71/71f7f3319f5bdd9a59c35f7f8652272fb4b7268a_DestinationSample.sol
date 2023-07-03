/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

contract DestinationSample {
    event doSomthingEvent();
    address public boyoLinkRelayer;
    address owner;
    constructor(){
        owner=msg.sender;
    }
    modifier onlyOwner(){
        require(owner==msg.sender,"Only owner");
        _;
    }
    function  setBoyoLinkRelayer(address newAddress) public onlyOwner{
        boyoLinkRelayer=newAddress;
    }
    modifier  onlyBoyoLinkRelayer(){
        require(msg.sender==boyoLinkRelayer,"Must be called by BoyoLink relayer");
        _;
    }
    function doSomething() onlyBoyoLinkRelayer public{
        emit doSomthingEvent();
    }
}