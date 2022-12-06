/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

interface IHakkaIntelligence {
    function reveal(address _player) external returns (uint256 score);
    function revealOpen() external view returns (uint256);
    function revealClose() external view returns (uint256);
    function periodStop() external view returns (uint256);
    function periodStart() external view returns (uint256);
    function proceed() external;
}

contract HakkaIntelligenceMock {
    uint256 internal ro;
    uint256 internal rc;
    uint256 internal pst;
    uint256 internal psp;
    uint256 internal flag;
    mapping(address => bool) public revealed;

    constructor() {
        pst = block.timestamp + 60;
        psp = block.timestamp + 120;
        flag = 1;
    }

    function reveal(address _player) external returns (uint256 score) {
        require(block.timestamp > ro && block.timestamp < rc);
        require(!revealed[_player]);
        revealed[_player] = true;
        return 1;
    }
    function proceed() external {
        if(flag == 1) {
            require(block.timestamp > pst);
            flag = 2;
        }
        else if(flag == 2){
            require(block.timestamp > psp);
            ro = block.timestamp + 300;
            rc = block.timestamp + 1800;
            flag = 3;
        }
    }
    function periodStart() external view returns (uint256) {
        return pst;
    }
    function periodStop() external view returns (uint256) {
        return psp;
    }
    function revealOpen() external view returns (uint256) {
        return ro;
    }
    function revealClose() external view returns (uint256) {
        return rc;
    }
}

contract keeper {
    IHakkaIntelligence public HI;

    uint256 public cost;
    uint256 public index;
    address public owner;
    address[] public queue;
    uint256 public flag;

    event Register(address indexed user);
    event Perform(address indexed user);
    event Init(address HI, uint256 cost);
    event Proceed(address indexed HI);

    constructor() {
        owner = msg.sender;
    }

    function init(address _HI, uint256 _cost) external {
        require(msg.sender == owner, "not owner");
        require(queue.length == index, "Work not done yet");
        HI = IHakkaIntelligence(_HI);
        cost = _cost;
        index = 0;
        delete queue;
        flag = 1;
        emit Init(_HI, _cost);
    }

    function getQueueLength() external view returns (uint256) {
        return queue.length;
    }

    function register() external payable {
        require(msg.value >= cost);
        queue.push(msg.sender);
        emit Register(msg.sender);
    }

    function validate() internal view returns (bool) {
        if(flag == 3)
            return HI.revealOpen() < block.timestamp && HI.revealClose() > block.timestamp && queue.length > index;
        else if(flag == 2)
            return HI.periodStop() <= block.timestamp;
        else if(flag == 1)
            return HI.periodStart() <= block.timestamp;
        else return false;
    }

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        return (validate(), bytes(""));
    }

    function performUpkeep(bytes calldata) external {
        require(validate(), "invalid upkeep");

        if(flag == 3) {
            address target = queue[index];
            bytes memory data = abi.encodeWithSelector(HI.reveal.selector, target);
            (bool success, ) = address(HI).call(data);
            if (success) emit Perform(target);
            ++index;
        }
        else if(flag == 2) {
            bytes memory data = abi.encodeWithSelector(HI.proceed.selector);
            (bool success, ) = address(HI).call(data);
            if(success) emit Proceed(address(HI));
            flag = 3;
        }
        else if(flag == 1) {
            bytes memory data = abi.encodeWithSelector(HI.proceed.selector);
            (bool success, ) = address(HI).call(data);
            if(success) emit Proceed(address(HI));
            flag = 2;
        }
    }

    function withdraw() external {
        (bool success, ) = payable(owner).call{value:address(this).balance}("");
        require(success, "withdraw fail");
    }

}