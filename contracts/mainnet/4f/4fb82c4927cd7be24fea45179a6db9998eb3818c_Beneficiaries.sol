pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";

contract Beneficiaries is Ownable {
    IERC20Metadata token = IERC20Metadata(0xe7359a30fA1f9925df406682673DC862513b7Bf9);

    address[] public accounts;
    uint256[] public shares; // %

    function withdraw() external {
        uint256 balance = token.balanceOf(address(this));
        for (uint8 i = 0; i < shares.length; i++) {
            uint256 value = (shares[i] * balance) / 100;
            if (value > 0) {
                token.transfer(accounts[i], value);
            }
        }
    }

    function sumShares() internal view returns (uint256 sum) {
        sum = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            sum += shares[i];
        }
    }

    function findAccountIndex(address account)
        internal
        view
        returns (bool accountFound, uint256 accountIndex)
    {
        accountFound = false;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == account) {
                accountIndex = i;
                accountFound = true;
            }
        }
    }

    function checkShares() internal view {
        require(
            sumShares() <= 100,
            "sum of shares should be less or equal than 100%"
        );
    }

    function setShare(address account, uint256 share) external onlyOwner {
        (bool accountFound, uint256 i) = findAccountIndex(account);
        require(accountFound, "the Account not found");
        shares[i] = share;
        checkShares();
    }

    function newBeneficiary(address account, uint256 share) external onlyOwner {
        (bool accountFound, uint256 i) = findAccountIndex(account);
        require(!accountFound, "the Account currently exists");
        accounts.push(account);
        shares.push(share);
        checkShares();
    }
}