/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

contract TestContract is IMessageRecipient {
    event TestEvent(address messageSender, uint32 origin, bytes32 sender, bytes message);

    function handle(
        uint32 origin,
        bytes32 sender,
        bytes memory message
    ) external override {
        emit TestEvent(msg.sender, origin, sender, message);
    }
}