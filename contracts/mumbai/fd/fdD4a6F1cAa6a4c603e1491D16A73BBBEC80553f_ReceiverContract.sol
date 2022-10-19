// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./stateSyncer/IStateReceiver.sol";

contract ReceiverContract is IStateReceiver {
    address private _stateSender;

    struct Data {
        bytes32 hashTx;
        address contractAddress;
        uint256 externalId;
        address creatorAccount;
        address sellerAccount;
        uint256 price;
        address payableToken;
        uint256 date;
    }

    mapping(uint256 => Data) private _stateIdToData;

    function stateIdToData(uint256 stateId) public view returns(Data memory){
        return _stateIdToData[stateId];
    }

    constructor(address stateSender_) {
        _stateSender = stateSender_;
    }

    function onStateReceive(uint256 stateId, bytes calldata data)onlyStateSender public  {
        (bytes32 hashTx,
        address contractAddress,
        uint256 externalId,
        address creatorAccount,
        address sellerAccount,
        uint256 price,
        address payableToken,
        uint256 date) = abi.decode(data, (bytes32, address, uint256, address, address, uint256, address, uint256)); 

        Data memory dataStructur = Data(hashTx,
        contractAddress,
        externalId,
        creatorAccount,
        sellerAccount,
        price,
        payableToken,
        date);
        
        _stateIdToData[stateId] = dataStructur;
    }

    modifier onlyStateSender {
        require(msg.sender == _stateSender);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// IStateReceiver represents interface to receive state
interface IStateReceiver {
  function onStateReceive(uint256 stateId, bytes calldata data) external;
}