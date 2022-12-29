// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract SpokePoolMock{
    uint32 public numberOfDeposits;

    event FundsDeposited(
        uint256 amount,
        uint256 originChainId,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 indexed depositId,
        uint32 quoteTimestamp,
        address indexed originToken,
        address recipient,
        address indexed depositor
    );

    function deposit(
            address recipient,
            address originToken,
            uint256 amount,
            uint256 destinationChainId,
            uint64 relayerFeePct,
            uint32 quoteTimestamp
        ) public payable {
            // Check that deposit route is enabled.
            // require(enabledDepositRoutes[originToken][destinationChainId], "Disabled route");

            // We limit the relay fees to prevent the user spending all their funds on fees.
            require(relayerFeePct < 0.5e18, "invalid relayer fee");
            

            _emitDeposit(
                amount,
                80001,
                destinationChainId,
                relayerFeePct,
                numberOfDeposits,
                quoteTimestamp,
                originToken,
                recipient,
                msg.sender
            );

            numberOfDeposits++;
        }

    function _emitDeposit(
        uint256 amount,
        uint256 originChainId,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 quoteTimestamp,
        address originToken,
        address recipient,
        address depositor
    ) internal {
        emit FundsDeposited(
            amount,
            originChainId,
            destinationChainId,
            relayerFeePct,
            depositId,
            quoteTimestamp,
            originToken,
            recipient,
            depositor
        );
    }

    }