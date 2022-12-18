/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

contract ReceiveEth
{

function transferFunds(address _address, uint amount) external{
    address rec = payable(_address);
    payable(rec).transfer(amount);
}
}