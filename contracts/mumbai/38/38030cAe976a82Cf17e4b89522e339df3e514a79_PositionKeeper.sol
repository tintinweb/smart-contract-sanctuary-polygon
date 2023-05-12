// SPDX-License-Identifier: MIT
import "../core/interfaces/IPositionRouter.sol";

pragma solidity ^0.6.0;

contract PositionKeeper {
    address public PositionRouter;
    address public owner;

    constructor(address _positionRouter) public {
        PositionRouter = _positionRouter;
        owner = msg.sender;
    }    
    
    function execute() external {
        IPositionRouter positionRouter = IPositionRouter(PositionRouter);
        (, uint256 _maxIncreasePositions, , uint256 _maxDecreasePositions) = positionRouter.getRequestQueueLengths(); 

        positionRouter.executeIncreasePositions(_maxIncreasePositions, payable(owner));
        positionRouter.executeDecreasePositions(_maxDecreasePositions, payable(owner));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPositionRouter {
    function increasePositionRequestKeysStart() external returns (uint256);
    function decreasePositionRequestKeysStart() external returns (uint256);
    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);
}