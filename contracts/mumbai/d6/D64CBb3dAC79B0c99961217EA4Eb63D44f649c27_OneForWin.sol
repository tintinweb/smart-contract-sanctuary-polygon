// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

contract OneForWin is Ownable, IERC721Receiver {

    struct PledgeInfo {
        address owner;
        uint8 tokenType;  
        address tokenAddress;
        uint256 tokenValue;
        uint8 status;   
        uint256 amount;
        uint256 begin;
        uint256 end;
        uint256 players;
        address winner;
    }

    uint256 public currId = 1;
    mapping(uint256 => PledgeInfo) public pledgeInfos;
    mapping(address => uint256[]) public userPledgeIds;

    constructor() {}

    receive() payable external {}

    event PledgeEvent(uint256 indexed id, uint256 timestamp, address user);
    event CancelEvent(uint256 indexed id, uint256 timestamp);
    event WinEvent(uint256 indexed id, uint256 timestamp, address winner);

    function pledge(PledgeInfo memory info) public {
        require(Address.isContract(info.tokenAddress), "Token address error");
        require(info.tokenType == 1 || info.tokenType == 2, "Token type error");
        require(info.tokenValue > 0, "Token value error");
        require(info.amount > 0, "Amount error");
        require(info.end > block.timestamp, "end time error");
        require(info.players > 0, "Players error");

        if (info.tokenType == 1) {
            IERC20(info.tokenAddress).transferFrom(msg.sender, address(this), info.tokenValue);
        } else {
            ERC721(info.tokenAddress).safeTransferFrom(msg.sender, address(this), info.tokenValue);
        }

        pledgeInfos[currId] = PledgeInfo(msg.sender, info.tokenType, info.tokenAddress, info.tokenValue, 1, info.amount, info.begin, info.end, info.players, address(0));
        userPledgeIds[msg.sender].push(currId);
        currId ++;

        emit PledgeEvent(currId - 1, block.timestamp, msg.sender);
    }

    function cancel(uint256 id) public onlyOwner {
        PledgeInfo storage info = pledgeInfos[id];
        require(info.status == 1, "Cannot be cancel");

        info.status = 2;
        if (info.tokenType == 1) {
            IERC20(info.tokenAddress).transfer(info.owner, info.tokenValue);
        } else {
            ERC721(info.tokenAddress).safeTransferFrom(address(this), info.owner, info.tokenValue);
        }

        emit CancelEvent(id, block.timestamp);
    }

    function win(uint256 id, address winner) public onlyOwner {
        PledgeInfo storage info = pledgeInfos[id];
        require(info.status == 1, "Cannot be win");
        require(winner != address(0), "Winner error");

        info.status = 3;
        info.winner = winner;
        if (info.tokenType == 1) {
            IERC20(info.tokenAddress).transfer(winner, info.tokenValue);
        } else {
            ERC721(info.tokenAddress).safeTransferFrom(address(this), winner, info.tokenValue);
        }

        emit WinEvent(id, block.timestamp, winner);
    }

    function getBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}