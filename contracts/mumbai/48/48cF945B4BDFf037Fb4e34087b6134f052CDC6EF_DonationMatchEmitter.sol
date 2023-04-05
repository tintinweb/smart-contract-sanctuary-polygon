// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {DonationMatchStorage} from "./storage.sol";

contract DonationMatchEmitter {
    bool initialized = false;
    address accountsContract;
    mapping(address => bool) public isDonationMatch;

    function initDonationMatchEmiiter(address curAccountscontract) public {
        require(
            curAccountscontract != address(0),
            "Invalid accounts contract address"
        );
        require(!initialized, "Already initialized");
        initialized = true;
        accountsContract = curAccountscontract;
    }

    modifier isOwner() {
        require(msg.sender == accountsContract, "Unauthorized");
        _;
    }
    modifier isEmitter() {
        require(isDonationMatch[msg.sender], "Unauthorized");
        _;
    }
    event DonationMatchInitialized(
        uint256 endowmentId,
        address donationMatch,
        DonationMatchStorage.Config config
    );
    event Erc20ApprovalGiven(
        uint256 endowmentId,
        address tokenAddress,
        address spender,
        uint amount
    );
    event Erc20Transfer(
        uint256 endowmentId,
        address tokenAddress,
        address recipient,
        uint amount
    );
    event Erc20Burned(uint256 endowmentId, address tokenAddress, uint amount);
    event DonationMatchExecuted(
        address donationMatch,
        address tokenAddress,
        uint amount,
        address accountsContract,
        uint256 endowmentId,
        address donor
    );

    function initializeDonationMatch(
        uint256 endowmentId,
        address donationMatch,
        DonationMatchStorage.Config memory config
    ) public isOwner {
        isDonationMatch[donationMatch] = true;
        emit DonationMatchInitialized(endowmentId, donationMatch, config);
    }

    function giveApprovalErC20(
        uint256 endowmentId,
        address tokenAddress,
        address recipient,
        uint amount
    ) public isEmitter {
        emit Erc20ApprovalGiven(endowmentId, tokenAddress, recipient, amount);
    }

    function transferErC20(
        uint256 endowmentId,
        address tokenAddress,
        address recipient,
        uint amount
    ) public isEmitter {
        emit Erc20Transfer(endowmentId, tokenAddress, recipient, amount);
    }

    function burnErC20(
        uint256 endowmentId,
        address tokenAddress,
        uint amount
    ) public isEmitter {
        emit Erc20Burned(endowmentId, tokenAddress, amount);
    }

    function executeDonorMatch(
        address tokenAddress,
        uint256 amount,
        address curAccountsContract,
        uint256 endowmentId,
        address donor
    ) public isEmitter {
        emit DonationMatchExecuted(
            msg.sender,
            tokenAddress,
            amount,
            curAccountsContract,
            endowmentId,
            donor
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library DonationMatchStorage {
    struct Config {
        address reserveToken;
        address uniswapFactory;
        address usdcAddress;
        address registrarContract;
        uint24 poolFee;
    }

    struct State {
        Config config;
    }
}

contract Storage {
    DonationMatchStorage.State state;
}