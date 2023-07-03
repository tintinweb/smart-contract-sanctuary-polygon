// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// ERC20 contract interface
interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// ERC1155 contract interface
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function isApprovedForAll(address account, address operator) external view returns (bool);
}

contract BalanceChecker {
    struct ERC20Info {
        uint256 balance;
        uint256 allowance;
        uint8 decimals;
    }

    /* Fallback function, don't accept any ETH */
    receive() external payable {
        revert("BalanceChecker does not accept payments");
    }

    function erc20Balance(address user, address token) public view returns (uint) {
        // check if token is actually a contract
        uint256 tokenCode;
        assembly {
            tokenCode := extcodesize(token)
        } // contract code size

        // is it a contract and does it implement balanceOf
        if (tokenCode > 0) {
            (bool success, bytes memory data) = token.staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, user)
            );
            if (success) {
                return abi.decode(data, (uint));
            }
        }
        return 0;
    }

    function getERC20Balances(
        address[] calldata users,
        address[] calldata tokens
    ) external view returns (uint[] memory) {
        uint[] memory addrBalances = new uint[](tokens.length * users.length);

        for (uint i = 0; i < users.length; i++) {
            for (uint j = 0; j < tokens.length; j++) {
                uint addrIdx = j + tokens.length * i;
                if (tokens[j] != address(0x0)) {
                    addrBalances[addrIdx] = erc20Balance(users[i], tokens[j]);
                } else {
                    addrBalances[addrIdx] = users[i].balance; // ETH balance
                }
            }
        }

        return addrBalances;
    }

    function getERC20Allowances(
        address[] calldata tokenAddresses,
        address[] calldata tokenOwers,
        address[] calldata tokenSpenders
    ) external view returns (uint[] memory allowances) {
        require(
            tokenAddresses.length == tokenOwers.length || tokenAddresses.length != tokenSpenders.length,
            "Array length mismatch"
        );
        allowances = new uint256[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 allowance = IERC20(tokenAddresses[i]).allowance(tokenOwers[i], tokenSpenders[i]);
            allowances[i] = allowance;
        }
        return allowances;
    }

    function getTokenAll(
        address[] calldata tokenAddresses,
        address[] calldata tokenOwers,
        address[] calldata tokenSpenders
    ) external view returns (ERC20Info[] memory infos) {
        require(
            tokenAddresses.length == tokenOwers.length || tokenAddresses.length != tokenSpenders.length,
            "Array length mismatch"
        );
        infos = new ERC20Info[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenOwer = tokenOwers[i];
            address tokenAddress = tokenAddresses[i];
            if (tokenAddress == address(0)) {
                infos[i] = ERC20Info(tokenOwer.balance, 0, 0);
            } else {
                uint256 balance = IERC20(tokenAddress).balanceOf(tokenOwer);
                uint256 allowance = IERC20(tokenAddress).allowance(tokenOwer, tokenSpenders[i]);
                uint8 decimals = IERC20(tokenAddresses[i]).decimals();
                infos[i] = ERC20Info(balance, allowance, decimals);
            }
        }
        return infos;
    }

    function getERC721Owners(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds
    ) external view returns (address[] memory owners) {
        require(tokenAddresses.length == tokenIds.length, "Array length mismatch");
        owners = new address[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address owner = IERC721(tokenAddresses[i]).ownerOf(tokenIds[i]);
            owners[i] = owner;
        }
        return owners;
    }

    function getERC721Approvals(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds
    ) external view returns (address[] memory operators) {
        require(tokenAddresses.length == tokenIds.length, "Array length mismatch");
        operators = new address[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address operator = IERC721(tokenAddresses[i]).getApproved(tokenIds[i]);
            operators[i] = operator;
        }
        return operators;
    }

    function getERC721ApprovalsForAll(
        address[] calldata tokenAddresses,
        address[] calldata tokenOwners,
        address[] calldata tokenOperators
    ) external view returns (bool[] memory approvals) {
        require(
            tokenAddresses.length == tokenOwners.length || tokenAddresses.length == tokenOperators.length,
            "Array length mismatch"
        );
        approvals = new bool[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            bool approval = IERC721(tokenAddresses[i]).isApprovedForAll(tokenOwners[i], tokenOperators[i]);
            approvals[i] = approval;
        }
        return approvals;
    }

    function getERC1155Balances(
        address[] calldata users,
        address[] calldata tokens,
        uint256[][] calldata ids
    ) public view returns (uint256[][] memory) {
        uint256[][] memory balances = new uint256[][](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            uint256[] memory idsInContract = ids[i];
            balances[i] = new uint256[](idsInContract.length);

            for (uint256 j = 0; j < idsInContract.length; j++) {
                (bool success, bytes memory data) = tokens[i].staticcall(
                    abi.encodeWithSelector(IERC1155.balanceOf.selector, users[i], idsInContract[j])
                );
                if (success) {
                    balances[i][j] = abi.decode(data, (uint256));
                }
            }
        }
        return balances;
    }

    function getERC1155ApprovalsForAll(
        address[] calldata tokenAddresses,
        address[] calldata tokenOwners,
        address[] calldata tokenOperators
    ) external view returns (bool[] memory approvals) {
        require(
            tokenAddresses.length == tokenOwners.length || tokenAddresses.length == tokenOperators.length,
            "Array length mismatch"
        );
        approvals = new bool[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            bool approval = IERC1155(tokenAddresses[i]).isApprovedForAll(tokenOwners[i], tokenOperators[i]);
            approvals[i] = approval;
        }
        return approvals;
    }
}