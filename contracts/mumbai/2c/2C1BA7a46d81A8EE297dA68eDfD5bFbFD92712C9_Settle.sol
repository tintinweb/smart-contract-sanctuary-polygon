pragma solidity ^0.5.16;

import "./SettleInterface.sol";

contract Settle is SettleInterface {
    address public owner;
    address public currency;
    address[] public walletToken;

    constructor(address _currency) public {
        owner = msg.sender;
        currency = _currency;
    }

    function getCurrency() external view returns (address) {
        return currency;
    }

    function getWalletToken() external view returns (address[] memory) {
        return walletToken;
    }

    function addWalletToken(address _token) external returns (bool) {
        require(msg.sender == owner, "permission denied");
        walletToken.push(_token);
        emit AddWalletToken(msg.sender, _token);
        return true;
    }

}

pragma solidity ^0.5.16;

interface SettleInterface {
    // views
    function getCurrency() external view returns (address);
    function getWalletToken() external view returns (address[] memory);
    // function getSavingsToken() external view returns (address[] memory);
    // function getPoolToken() external view returns (address[] memory);
    // function getDebtToken() external view returns (address[] memory);
    
    // function getWalletSettle(address account) external view returns (uint256);
    // function getSavingsSettle(address account) external view returns (uint256);
    // function getPoolSettle(address account) external view returns (uint256);
    // function getDebtSettle(address account) external view returns (uint256);
    // function getTotalSettle(address account) external view returns (uint256);

    // actions
    function addWalletToken(address Token) external returns (bool);
    // function addSavingsToken() external;
    // function addPoolToken() external;
    // function addDebtToken() external;

    // event
    event AddWalletToken(address _sender, address _token);
    // event addSavingsToken(address sender, address Token);
    // event addPoolToken(address sender, address Token);
    // event addDebtToken(address sender, address Token);

}