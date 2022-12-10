/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMarketplace {
    function buy(bytes32 projectId, uint subscriptionSeconds) external;
    function buyFor(bytes32 projectId, uint subscriptionSeconds, address recipient) external;
}

interface IOutbox {
    function dispatch(
        uint32 destinationDomain, // the chain where Marketplace is deployed and where messages are sent to. It is a unique ID assigned by hyperlane protocol (e.g. on polygon)
        bytes32 recipientAddress, // the address for the Marketplace contract. It must have the handle() function (e.g. on polygon)
        bytes calldata messageBody // encoded purchase info
    ) external returns (uint256);
}

/**
 * @title Streamr Remote Marketplace
 * The Remmote Marketplace through which the users on other networks can send cross-chain messages (e.g. buy projects)
 */
contract RemoteMarketplace is IMarketplace {

    uint32 public destinationDomain;
    bytes32 public recipientAddress;
    IOutbox public outbox;

    event CrossChainPurchase(bytes32 projectId, address subscriber, uint256 subscriptionSeconds);

    /**
     * @param _destinationDomain - the domain id of the destination chain assigned by the protocol (e.g. polygon)
     * @param _recipientAddress - the address of the recipient contract (e.g. MarketplaceV4 on polygon)
     * @param _outboxAddress - hyperlane core address for the chain where RemoteMarketplace is deployed (e.g. gnosis)
     */
    constructor(uint32 _destinationDomain, address _recipientAddress, address _outboxAddress) {
        destinationDomain = _destinationDomain;
        recipientAddress = _addressToBytes32(_recipientAddress);
        outbox = IOutbox(_outboxAddress);
    }

    function buy(bytes32 projectId, uint subscriptionSeconds) public {
        buyFor(projectId, subscriptionSeconds, msg.sender);
    }

    function buyFor(bytes32 projectId, uint256 subscriptionSeconds, address subscriber) public {
        outbox.dispatch(
            destinationDomain,
            recipientAddress,
            abi.encode(projectId, subscriptionSeconds, subscriber)
        );
        emit CrossChainPurchase(projectId, subscriber, subscriptionSeconds);
    }

    function _addressToBytes32(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}