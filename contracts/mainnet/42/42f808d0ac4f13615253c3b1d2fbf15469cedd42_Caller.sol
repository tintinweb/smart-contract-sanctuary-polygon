/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2 <0.9.0;

contract Test {
    event CalledFallback(address);
    // This function is called for all messages sent to
    // this contract (there is no other function).
    // Sending Ether to this contract will cause an exception,
    // because the fallback function does not have the `payable`
    // modifier.
    fallback() external {
        emit CalledFallback(msg.sender);
    }
}

contract TestPayable {
    event CalledFallback(address, uint);
    event CalledReceive(address, uint);
    // This function is called for all messages sent to
    // this contract, except plain Ether transfers
    // (there is no other function except the receive function).
    // Any call with non-empty calldata to this contract will execute
    // the fallback function (even if Ether is sent along with the call).
    fallback() external payable { 
        emit CalledFallback(msg.sender, msg.value);
    }

    // This function is called for plain Ether transfers, i.e.
    // for every call with empty calldata.
    receive() external payable {
        emit CalledReceive(msg.sender, msg.value);
    }
    
    function getBalance() external view returns (uint256){
        return address(this).balance;
    }
    
}

contract Caller {
    function callTest(Test test) public returns (bool) {
        (bool success,) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
        // CalledFallback will be logged.

        // address(test) will not allow to call ``send`` directly, since ``test`` has no payable
        // fallback function.
        // It has to be converted to the ``address payable`` type to even allow calling ``send`` on it.
        address payable testPayable = payable(address(test));

        // If someone sends Ether to that contract,
        // the transfer will fail, i.e. this returns false here.
        return testPayable.send(2 ether);
    }

    function callTestPayable(TestPayable test) public returns (bool) {
        (bool success,) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
        // CalledFallback will be logged. The balance will not change.
        (success,) = address(test).call{value: 1 ether}(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
        // CalledFallback will be logged. The balance will increase by 1 Ether.

        // If someone sends Ether to that contract, the receive function in TestPayable will be called.
        // Since that function writes to storage, it takes more gas than is available with a
        // simple ``send`` or ``transfer``. Because of that, we have to use a low-level call.
        (success,) = address(test).call{value: 2 ether}("");
        require(success);
        // CalledReceive will be logged. The balance will increase by 2 Ether.

        return true;
    }
    
    // Add a receive function to fund the contract
    receive() external payable {}
}