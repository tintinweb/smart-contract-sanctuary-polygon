/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TokenBridge {
    event BridgeDeposit(
        uint8 destinationChainId,
        uint256 amount,
        address tokenContractAddress,
        bytes destinationWallet
    );

    event BridgeRelease(
        uint256 amount,
        address tokenContractAddress,
        address destinationWallet,
        // Deposit UUID + Circle Release UUID
        bytes32 depositId
    );

    modifier onlyAdmin {
        require(msg.sender == admin, "only callable by admin");
        _;
    }

    address public admin;

    constructor(
        address _admin
    ) {
        admin = _admin;
    }
    /**
     * Anyone can call this method
     * needs ERC20 allowance from the respective
     * signer
     */
    function deposit(
        uint8 chain,
        uint256 amount,
        address circleDepositAddress,
        address erc20Address,
        bytes memory destinationWallet
    ) public {
        IERC20(erc20Address).transferFrom(
            msg.sender,
            circleDepositAddress,
            amount
        );

        emit BridgeDeposit(chain, amount, erc20Address, destinationWallet);
    }
    /**
     * To be called only by our
     * middle address on the respective EVM
     * chain, needs ERC20 allowance
     */
    function release(
        uint256 amount,
        address destinationWallet,
        address erc20Address,
        bytes32 bridgeTransferId
    ) public onlyAdmin {
        IERC20(erc20Address).transferFrom(
            msg.sender,
            destinationWallet,
            amount
        );

        emit BridgeRelease(amount, erc20Address, destinationWallet, bridgeTransferId);
    }
}