/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// File: contracts/artifacts/Keeper.sol


pragma solidity >=0.7.5;

interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}

interface IUni {
    function swapExactInputSingle(uint256, address) external returns (uint256);
}

contract Keeper is KeeperCompatibleInterface {

    IUni uni;
    uint public immutable interval;
    uint public lastTimeStamp;


    mapping(address => uint256) public amount;
    address[] public users;

    constructor(uint updateInterval, address _addr) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      uni = IUni(_addr);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        return(upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            for(uint256 i = 0; i < users.length; i++) {
                uni.swapExactInputSingle(amount[users[i]], users[i]);
            }
        }
    }

    function register(uint256 _amount) public {
        amount[msg.sender] = _amount;
        users.push(msg.sender);
    }
}