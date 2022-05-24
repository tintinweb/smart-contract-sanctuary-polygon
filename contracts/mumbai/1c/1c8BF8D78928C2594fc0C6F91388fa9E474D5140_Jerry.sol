//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./JerryPoints.sol";

contract Jerry is JerryPoints {
    mapping(address => string) public tokens;
    mapping(address => uint256[]) public completedQuests;

    function mintTo(address to, string calldata uri)
        external
        onlyOwner
        returns (uint256)
    {
        tokens[to] = uri;
        return 0;
    }

    function getJerry(address owner)
        external
        view
        returns (string memory, uint256)
    {
        return (tokens[owner], balances[owner]);
    }

    function completeQuest(
        address _user,
        uint256 _questId,
        uint256 reward
    ) public canGrant {
        completedQuests[_user].push(_questId);
        grant(_user, reward);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

error Unauthorized();

contract JerryPoints {
    mapping(address => uint256) balances;
    mapping(address => bool) whitelistedToGrant;
    address owner;

    modifier canGrant() {
        if (!whitelistedToGrant[msg.sender] && msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function grant(address _to, uint256 _amount) public canGrant {
        balances[_to] = balances[_to] + _amount;
    }

    function setWhitelist(address _to, bool allowed) public onlyOwner {
        whitelistedToGrant[_to] = allowed;
    }
}