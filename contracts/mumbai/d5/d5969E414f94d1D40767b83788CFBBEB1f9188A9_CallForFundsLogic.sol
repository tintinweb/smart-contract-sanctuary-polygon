// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {CallForFundsStorage} from "./CallForFundsStorage.sol";

contract CallForFundsLogic is CallForFundsStorage {
    //vars

    //events

    event ContributionReceivedETH(
        address indexed donator,
        uint256 indexed amount
    );

    //ClaimFunds
    //DeleteCallForFunds
    //ChangeMinimum

    // Plain ETH transfers.
    receive() external payable {
        emit ContributionReceivedETH(msg.sender, msg.value);
    }

    // function contributeERC20() onlyOpen // dai???

    // function claimFunds()
    // function StartSuperFluidStream() onlyCreator onlyMatched

    // modifier onlyCreator() require msg.sender===creator
    // modifier onlyOpen() require fundingState===FundingState.OPEN
    // modifier onlyMatched() require fundingState===FundingState.MATCHED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract CallForFundsStorage {
    enum FundingState {
        OPEN,
        CLOSED,
        MATCHED,
        DELIVERED
    }

    address public logicAddress;

    address public creator;
    string public title;
    string public description;
    string public image;
    string public category;
    string public genre;
    string public subgenre;
    string public deliverableMedium;
    uint8 public timelineInDays;
    uint256 public minFundingAmount;

    FundingState public fundingState;

    // @Funding Round
    // @Calls for collaborators (optional)
}