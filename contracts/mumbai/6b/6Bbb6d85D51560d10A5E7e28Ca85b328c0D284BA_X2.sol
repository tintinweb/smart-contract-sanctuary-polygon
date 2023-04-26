/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

contract X2 is IStargateReceiver {
    event Fallback(address indexed sender, uint256 value, bytes data);

    event SgReceive(
        uint16 chainId,
        bytes srcAddress,
        uint256 nonce,
        address token,
        uint256 amountLD,
        bytes payload
    );


    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external {
        emit SgReceive(
            _chainId,
            _srcAddress,
            _nonce,
            _token,
            amountLD,
            payload
        );
    }

    fallback() external payable {
        emit Fallback(msg.sender, msg.value, msg.data);
    }
}