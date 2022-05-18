// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ILendGotchi {
  function lastExecuted() external view returns (uint256);
  function lendGotchis() external;
}

contract LazyLenderResolver {
    address public immutable lender;

    constructor(address _lender) {
        lender = _lender;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = ILendGotchi(lender).lastExecuted();

        canExec = (block.timestamp - lastExecuted) > 900;

        execPayload = abi.encodeWithSelector(
            ILendGotchi.lendGotchis.selector
        );
    }
}