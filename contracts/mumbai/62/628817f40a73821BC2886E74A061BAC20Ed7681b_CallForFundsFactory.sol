// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {CallForFundsProxy} from "./CallForFundsProxy.sol";

contract CallForFundsFactory {
    address public immutable logicAddress;

    event CallForFundsCreated(
        address indexed CallForFunds,
        address indexed creator,
        string title,
        string description,
        string indexed image,
        string category,
        string genre,
        string subgenre,
        uint8 timelineInDays,
        uint256 minFundingAmount,
        string deliverableMedium
    );

    constructor(address _logicAddress) {
        logicAddress = _logicAddress;
    }

    function createCallForFunds(
        string memory _title,
        string memory _description,
        string memory _image,
        string memory _category,
        string memory _genre,
        string memory _subgenre,
        uint8 _timelineInDays,
        uint256 _minFundingAmount,
        string memory _deliverableMedium
    ) external returns (address proxy) {
        proxy = address(
            new CallForFundsProxy{
                salt: keccak256(abi.encode(msg.sender, _title))
            }(
                msg.sender,
                _title,
                _description,
                _image,
                _category,
                _genre,
                _subgenre,
                _deliverableMedium,
                _timelineInDays,
                _minFundingAmount
            )
        );

        emit CallForFundsCreated(
            proxy,
            msg.sender,
            _title,
            _description,
            _image,
            _category,
            _genre,
            _subgenre,
            _timelineInDays,
            _minFundingAmount,
            _deliverableMedium
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {CallForFundsStorage} from "./CallForFundsStorage.sol";

interface ICallForFundsFactory {
    function logicAddress() external returns (address);
}

contract CallForFundsProxy is CallForFundsStorage {
    constructor(
        address _creator,
        string memory _title,
        string memory _description,
        string memory _image,
        string memory _category,
        string memory _genre,
        string memory _subgenre,
        string memory _deliverableMedium,
        uint8 _timelineInDays,
        uint256 _minFundingAmount
    ) {
        logicAddress = ICallForFundsFactory(msg.sender).logicAddress();

        creator = _creator;
        title = _title;
        description = _description;
        image = _image;
        category = _category;
        genre = _genre;
        subgenre = _subgenre;
        deliverableMedium = _deliverableMedium;
        timelineInDays = _timelineInDays;
        minFundingAmount = _minFundingAmount;

        fundingState = FundingState.OPEN;
    }

    fallback() external payable {
        address _impl = logicAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract CallForFundsStorage {
    enum FundingState {
        OPEN,
        CLOSED,
        MATCHED,
        DELIVERED
    }

    address public logicAddress;

    address public creator;
    string public title;
    string public description;
    string public image;
    string public category;
    string public genre;
    string public subgenre;
    string public deliverableMedium;
    uint8 public timelineInDays;
    uint256 public minFundingAmount;

    FundingState public fundingState;

    // @Funding Round
    // @Calls for collaborators (optional)
}