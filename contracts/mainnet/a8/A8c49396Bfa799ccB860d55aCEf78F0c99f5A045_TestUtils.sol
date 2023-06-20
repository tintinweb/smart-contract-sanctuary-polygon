// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDexwinCore {
    function getBaseProvider(address token) external view returns (address);

    function getRandomProvider(address token, uint256 randomWord) external returns (address);

    function getUserBalance(address account, address token) external view returns (uint256);

    function getTotalFunds(address token) external view returns (uint256);

    function getUserTips(address account, address token) external view returns (uint256);

    function getTotalUserTips(address token) external view returns (uint256);

    function getUserStaked(address account, address token) external view returns (uint256);

    function getTotalStakes(address token) external view returns (uint256);

    function getDepositerHLBalance(address depositer, address token) external view returns (uint256);

    function getTotalHL(address token) external view returns (uint256);

    function getProviderPayout(address account, address token) external view returns (uint256);

    function getTotalPayout(address token) external view returns (uint256);

    function getBalancedStatus(address token) external view returns (bool);

    function setCoreOwnership(address newOwner) external;

    function disableCoreOwnership(address owwner) external;

    function setTrustedForwarder(address trustedForwarder) external;

    function addTokens(address token) external;

    function disableToken(address token) external;

    function setBaseProvider(address account, address token) external;

    function handleBalance(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleUserTips(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleStakes(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleHL(address bettor, address token, uint256 amount, uint256 operator) external;

    function handlePayout(address bettor, address token, uint256 amount, uint256 operator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IDexwinCore.sol";

contract TestUtils {
    address private s_owner;
    bool private allowed = true;
    IDexwinCore private immutable i_core;

    constructor(address owner, address payable core) {
        s_owner = owner;
        i_core = IDexwinCore(core);
    }

    modifier onlyUtilsOwner() {
        if (msg.sender != s_owner) {
            revert("Utils__OnlyOwnerMethod");
        }
        _;
    }

    modifier isAllowed() {
        if (!allowed) {
            revert("Disabled");
        }
        _;
    }

    function transferUtilsOwnership(address newOwner) public onlyUtilsOwner {
        _transferUtilsOwnership(newOwner);
    }

    function _transferUtilsOwnership(address newOwner) internal {
        require(newOwner != address(0), "Incorrect address");
        s_owner = newOwner;
    }

    function modifyAllow(bool status) public onlyUtilsOwner {
        allowed = status;
    }

    function setCoreOwnershipInUtils(address newOwner) public onlyUtilsOwner {
        i_core.setCoreOwnership(newOwner);
    }

    function disableCoreOwnershipInUtils(address owner) public onlyUtilsOwner {
        i_core.disableCoreOwnership(owner);
    }

    function addTokensToCore(address token) public onlyUtilsOwner {
        i_core.addTokens(token);
    }

    function disableCoreToken(address token) public onlyUtilsOwner {
        i_core.disableToken(token);
    }

    function handleTips(address token, uint256 amount) public isAllowed {
        uint256 tips = i_core.getUserTips(msg.sender, token);
        uint256 bal = i_core.getUserBalance(msg.sender, token);
        uint256 tipsToSubtract;
        if (amount > tips + bal) revert("Utils__StakeMorethanbal");
        if (tips > 0) {
            tipsToSubtract = (tips >= amount) ? amount : tips;
            i_core.handleUserTips(msg.sender, token, tipsToSubtract, 0);
            i_core.handleBalance(msg.sender, token, tipsToSubtract, 1);
        }
    }

    function getUtilsOwner() public view returns (address) {
        return s_owner;
    }
}