// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(
        address indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _ruling
    );

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IArbitrable.sol";

contract MockArbitrator {
    mapping(address => uint256) public disputes;
    mapping(uint256 => uint256) public choices;
    uint256 public currentDisputeId;
    uint256 private immutable cost;

    event DisputeCreation(
        uint256 indexed _disputeID,
        address indexed _arbitrable
    );

    constructor(uint256 _cost) {
        cost = _cost;
    }

    function executeRuling(address _arbitrable, uint256 _ruling) external {
        uint256 disputeId = disputes[_arbitrable];
        IArbitrable(_arbitrable).rule(disputeId, _ruling);
    }

    function executeRulingWithDisputeId(
        address _arbitrable,
        uint256 _ruling,
        uint256 _disputeId
    ) external {
        IArbitrable(_arbitrable).rule(_disputeId, _ruling);
    }

    function createDispute(
        uint256 _choices,
        bytes calldata
    ) external payable returns (uint256 disputeID) {
        require(msg.value == 10, "!cost");
        currentDisputeId = currentDisputeId + 1;
        disputes[msg.sender] = currentDisputeId;
        choices[currentDisputeId] = _choices;
        emit DisputeCreation(currentDisputeId, msg.sender);
        return currentDisputeId;
    }

    function arbitrationCost(bytes calldata) external view returns (uint256) {
        return cost;
    }

    // to be avoided in testing
    function test() public {}
}