/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

pragma solidity 0.8.0;


contract Test {
    event payment(string data);
    fallback(bytes calldata _data) external payable returns(bytes memory) {
        // emit payment(_data);
        // {"userId":"user123","txId":"tx123","receiver":"oxadjk123hdhjwedwe"}
        emit payment(string(msg.data));
    }
    event TakePayment(address from, address to, uint amount, string stuff);

    function takePayment(address from, address to, uint amount, string calldata stuff) public {
        TakePayment(from, to , amount, stuff);
    }
}