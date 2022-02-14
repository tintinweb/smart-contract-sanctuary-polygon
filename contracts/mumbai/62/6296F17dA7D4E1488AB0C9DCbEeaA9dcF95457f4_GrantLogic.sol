// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {GrantStorage} from "./GrantStorage.sol";

contract GrantLogic is GrantStorage {
    //vars

    //events

    event ContributionReceivedETH(
        address indexed donator,
        uint256 indexed amount
    );

    //ClaimFunds
    //DeleteGrant
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

contract GrantStorage {
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
    string public category; //(Music, Photography, Painting, Digital Art, Animation, Film, Sculpture, Poetry, Play, Dance)
    string public genre;
    uint256 public minFundingAmount;
    string public deliverableFormat;
    // @Funding Round
    // @Calls for collaborators (optional)
    uint8 public timeline; // number of days?
    FundingState public fundingState;
    //details
}