/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

interface KeeperRegistrarInterface {
    function registerUpkeep(RegistrationParams calldata requestParams)
        external
        returns (uint256);
}

contract UpkeepIDConsumerExample {
    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable i_registrar;

    mapping(address => mapping(uint256 => uint256)) private _upkeepId;

    constructor(LinkTokenInterface link, KeeperRegistrarInterface registrar) {
        i_link = link;
        i_registrar = registrar;
    }

    function registerAndPredictID(RegistrationParams memory params) public {
        i_link.approve(address(i_registrar), params.amount);
        uint256 upkeepID = i_registrar.registerUpkeep(params);
        if (upkeepID != 0) {
            _upkeepId[msg.sender][block.timestamp] = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function getUpkeepId(address _address)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory upkeepIds = new uint256[](block.timestamp + 1);

        for (uint256 i = 0; i <= block.timestamp; i++) {
            upkeepIds[i] = _upkeepId[_address][i];
        }

        return upkeepIds;
    }
}