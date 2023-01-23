// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10;

contract MockPayment {
    event MockRequestPayClaimed(
        address indexed claimer,
        uint256 submissionId,
        uint256 payAmount,
        address indexed to
    );

    event MockRemainderClaimed(
        address indexed claimer,
        uint256 requestId,
        uint256 remainderAmount
    );

    function emitPayClaimed(
        address claimer,
        uint256 submissionId,
        uint256 payAmount,
        address to
    ) public {
        emit MockRequestPayClaimed(claimer, submissionId, payAmount, to);
    }

    function emitRemainderClaimed(
        address claimer,
        uint256 requestId,
        uint256 remainderAmount
    ) public {
        emit MockRemainderClaimed(claimer, requestId, remainderAmount);
    }

    function mockExpectedPayments()
        public
        view
        returns (uint256 expectedPayments)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % 15;
    }
}