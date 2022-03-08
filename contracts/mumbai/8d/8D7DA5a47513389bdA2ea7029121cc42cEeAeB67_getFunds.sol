/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

contract getFunds{
    address public requester;
    address[] public senders;

function generateRequest() public {
    requester = msg.sender;
}
function donate() public payable {
    require(msg.value > .01 ether);
    senders.push(msg.sender);
}
function makePayment() public{
    require(requester == msg.sender);
    requester.transfer(this.balance);
    senders = new address[](0);
}
function getSenders() public view returns(address[]){
    return senders;
}
}