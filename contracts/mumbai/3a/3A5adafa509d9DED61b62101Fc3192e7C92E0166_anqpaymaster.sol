pragma solidity ^0.8.0;

contract anqpaymaster{

    function EXECUTE_MULTIPLE_CALL(bytes[]memory data, uint256[]memory value,address[]memory wallet)public{
        for (uint256 i = 0; i < data.length; i++) {
           executeTransaction(wallet[i], value[i], data[i]);
        }
    }

    function executeTransaction(address Anq_wallet,uint256 value, bytes memory data)
        public
    {
        (bool success,) = Anq_wallet.call(
              data
        );
        require(success, "tx failed");
    }
}