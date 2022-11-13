// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "./IBridge.sol";

contract Counter {
    IBridge public bridge;
    address public counterpartOnOtherChain;
    address public owner;
    uint256 public counter;

    constructor(address _bridge) {
        require(_bridge != address(0), "bridge cannot be address 0");
        owner = msg.sender;
        bridge = IBridge(_bridge);
    }

    /// @notice Function to set the counterpart on other chain.
    /// @notice Only the owner can call this function.
    /// @param _counterpartOnOtherChain Address of the counterpart contract on other chain.
    function setCounterpartOnOtherChain(address _counterpartOnOtherChain) external {
        require(msg.sender == owner, "only owner");
        require(_counterpartOnOtherChain != address(0), "counterpart address can't be address(0)");
        counterpartOnOtherChain = _counterpartOnOtherChain;
    }

    /// @notice Function to send a message to the bridge contract to be relayed to the other chain.
    /// @notice This calls the send function on the bridge with the data to be called on destination side.
    /// @notice The data contains the selector to the function to be called on destination chain contract
    /// and the address of this contract(sendingCounter) as the parameter to that function.
    function send() external {
        address _counterpartOnOtherChain = counterpartOnOtherChain;
        require(_counterpartOnOtherChain != address(0), "counterpart address on other chain not set");

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("increment(address)")), address(this));

        // solhint-disable
        bridge.send(_counterpartOnOtherChain, data);
    }

    /// @notice Function to increment the counter when a request is recieved from the bridge.
    /// @notice Only the bridge contract can call this function.
    /// @notice Only the request from the counterpart contract on source chain can be recieved here.
    /// @notice This is called when Bridge contract recieves a cross-chain communication request from relayer.
    /// @notice This function increases the value of counter by 1 when the checks are passed.
    /// @param  _senderOfRequest the address of sender of the request on source chain.
    function increment(address _senderOfRequest) external {
        require(msg.sender == address(bridge), "only bridge");
        require(counterpartOnOtherChain == _senderOfRequest, "sending counter invalid");
        counter += 1;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface IBridge {
    function send(address recievingCounter, bytes calldata data) external;
}